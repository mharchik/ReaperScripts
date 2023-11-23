---@diagnostic disable: param-type-mismatch
----------------------------------------
-- @noindex
-- @description Import Pro Tools Session From Text File
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

--TODO 
--Fix Duplicate Track names
--Fix Media Item getting renamed to add '-imported' at the end of the file if it already exists in your audio files folder
--Have it not import media that it can't find, and then print an error if there were any missing files
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------   
local path
local audiopath
----------------------------------------
--Script Variables
----------------------------------------
local ClipsSect = 'O N L I N E  C L I P S  I N  S E S S I O N'
local TrackSect = 'T R A C K  L I S T I N G'
local MarkerSect = 'M A R K E R S  L I S T I N G'
local TrackNumInfo = '# OF AUDIO TRACKS:'
local ClipsNumInfo = '# OF AUDIO CLIPS:'
local FilesNumInfo = '# OF AUDIO FILES:'
local FramesInfo = 'TIMECODE FORMAT:'
local NumOfTracks
local Framerate

local Clips = {}
local Tracks = {}
local Markers = {}

local extension_list = "Text file (.txt)\0*.txt\0\0"

----------------------------------------
--Functions
----------------------------------------

function ReadFile()
    local file = io.open(path:gsub('\\', '/'), 'r')
    io.input(file)

    local clipsSectStart
    local isClipsSect = false
    local isTracksSect = false
    local isMarkerSect = false
    local curTrackName
    local curTrackCount = 0
    local i = 1
    local tSectEmptyCount = 0
    for line in io.lines() do
        if line:find(TrackNumInfo) then
           NumOfTracks = line:gsub(TrackNumInfo .. '\t+', '')
           for j = 1, NumOfTracks do
            local track = {}
            Tracks[#Tracks+1] = track
           end
        elseif line:find(ClipsNumInfo) then
            NumOfClips = line:gsub(ClipsNumInfo .. '\t+', '')
        elseif line:find(FilesNumInfo) then
            NumOfFiles = line:gsub(FilesNumInfo .. '\t+', '')
        elseif line:find(FramesInfo) then
            Framerate = line:gsub(FramesInfo .. '\t+', '')
            Framerate = Framerate:gsub(' Frame', '')
        elseif line:find(ClipsSect) then
            clipsSectStart = i
            isClipsSect = true
        elseif line:find(TrackSect) then
            isTracksSect = true
        elseif line:find(MarkerSect) then
            isMarkerSect = true
        end

        --Store Clips/File Name info
        if isClipsSect and i >= clipsSectStart + 2 then
            local clip = ''
            if #line > 0 then
                for val in line:gmatch('([^\t]+)') do
                    val = TrimCharacer(val, " ")
                    if clip == '' then
                        clip = val
                    else
                        Clips[clip] = val
                    end
                end
            else
                isClipsSect = false
            end
        end
        --Store Track Info
        if isTracksSect then
            if not (#line > 0)  then
                tSectEmptyCount = tSectEmptyCount + 1
            end
            if tSectEmptyCount < NumOfTracks * 2 then
                if line:find('TRACK NAME:') then
                    curTrackName = line:gsub('TRACK NAME:\t+', '')
                    curTrackCount = curTrackCount + 1
                end
                if (line:sub(1,1)):match('%d') then
                    local j = 1
                    local clip
                    local startTime
                    local endTime
                    for val in line:gmatch('([^\t]+)') do
                        val = TrimCharacer(val, " ")
                        if j == 3 then
                            clip = val
                        elseif j == 4 then
                            startTime = val
                        elseif j == 5 then
                            endTime = val
                        end
                        j = j + 1
                    end
                    local clipInfo = {}
                    clipInfo[1] = curTrackName
                    clipInfo[2] = clip
                    clipInfo[3] = startTime
                    clipInfo[4] = endTime
                    table.insert(Tracks[curTrackCount],clipInfo)
                end
            end
        end
        --Store Marker Info
        if isMarkerSect then
            if #line > 0 then
                if (line:sub(1,1)):match('%d') then
                    local j = 1
                    local time
                    local text
                    for val in line:gmatch('([^\t]+)') do
                        val = TrimCharacer(val, " ")
                        if j == 2 then
                         time = val
                        elseif j == 5 then
                         text = val
                        end
                        j = j + 1
                    end
                    local marker = {}
                    marker[time] = text
                    Markers[#Markers+1] = marker
                end
            else
                isMarkerSect = false
            end
        end
        i = i + 1
    end
    io.close(file)
end

function TimecodeToPos(tc)
    local i = 1
    local pos
    for val in tc:gmatch('([^:]+)') do
        if i == 1 then
            pos = val * 3600
        elseif i == 2 then
            pos = pos + val * 60
        elseif i == 3 then
            pos = pos + val
        elseif i == 4 then
            pos = pos + val/Framerate
        end
        i = i +1
    end
    return pos
end

function CreateMarkers()
    local i = 1
    for index, marker in ipairs(Markers) do
        for time, name in pairs(marker) do
            local pos = TimecodeToPos(time)
            reaper.AddProjectMarker( 0, false, pos, 0, name, i )
            i = i + 1
        end
    end
end

function GetClipName(clip)
    for clipname, filename in pairs(Clips) do
        if clipname == clip then
            return filename
        end
    end
end

function CreateTracks()
    for i, track in ipairs(Tracks) do
        for j, trackInfo in ipairs(track) do
            local startPos, endPos
            local filename
            local selTrack
            local trackIdx = 0
            for k, val in ipairs(trackInfo) do
                if k == 1 then
                    local trackCount = r.CountTracks(0)
                    local doesTrackExist = false
                    if trackCount > 0 then
                        for l = 0, trackCount - 1 do
                            local nextTrack = r.GetTrack(0, l)
                            if ({r.GetTrackName(nextTrack)})[2] == val then
                                doesTrackExist = true
                                selTrack = nextTrack
                                r.SetOnlyTrackSelected(selTrack)
                            end
                        end
                    end
                    if not doesTrackExist then
                        reaper.InsertTrackAtIndex( trackIdx, false )
                        selTrack = reaper.GetTrack(0, trackIdx)
                        r.SetOnlyTrackSelected(selTrack)
                        reaper.GetSetMediaTrackInfo_String( selTrack, 'P_NAME', val, true )
                        trackIdx = trackIdx + 1
                    end
                    --GetTracks
                elseif k == 2 then
                    filename = GetClipName(val)
                elseif k == 3 then
                    startPos = TimecodeToPos(val)
                elseif k == 4 then
                    endPos = TimecodeToPos(val)
                end
            end
            reaper.InsertMedia((audiopath .. '/' .. filename):gsub('\\', '/'), 0)
            local itemCount = r.CountMediaItems(0)
            if itemCount > 0 then
                for l = 0, itemCount - 1 do
                    local item = r.GetMediaItem(0, l)
                    local take = r.GetActiveTake(item)
                    local name = r.GetTakeName(take)
                    if name == filename then
                        r.MoveMediaItemToTrack( item, selTrack )
                        r.SetMediaItemPosition( item, startPos, false)
                        break
                    end
                end
            end

        end
    end
end

function TrimCharacer(s, char)
    local l = 1
    while s:sub(l, l) == char do
      l = l + 1
    end
    local r = s:len(s)
    while s:sub(r, r) == char do
      r = r-1
    end
    return s:sub(l, r)
end

function Main()
    local isFile, fileNames = reaper.JS_Dialog_BrowseForOpenFiles('Select Session Text File', '', '', extension_list, false)
    if isFile == 0 then return end
    local isFolder, folder = reaper.JS_Dialog_BrowseForFolder( 'Selecte Folder With Audio Files to Import', '' )
    if isFolder == 0 then return end
    path = fileNames
    audiopath = folder
    ReadFile()
    CreateTracks()
    CreateMarkers()
end

----------------------------------------
--Main
----------------------------------------
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

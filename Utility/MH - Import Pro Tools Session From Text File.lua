----------------------------------------
-- @noindex
-- @description Import Pro Tools Session From Text File
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({r.get_action_context()})[2]:match('([^/\\_]+)%.[Ll]ua$')
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
local TimecodeOffsetInfo ='SESSION START TIMECODE:'
local TimecodeOffset
local RppStartTime = 60
local NumOfTracks
local Framerate

local Clips = {}
local Tracks = {}
local TrackNames = {}
local Markers = {}
local FailedFiles = {}

local TxtPath
local AudioFolderPath
----------------------------------------
--Functions
----------------------------------------

function ExtensionChecker()
    if not r.CF_GetSWSVersion then
        r.ShowMessageBox('SWS extension is missing!\n\nPlease install it before trying to run this script.', 'Error', 0)
        return false
    elseif not r.JS_ReaScriptAPI_Version then
        r.ShowMessageBox('js_ReaScriptAPI extension is missing!\n\nPlease install it via Reapack before trying to run this script.', 'Error', 0)
        return false
    else
        return true
    end
end

function ReadFile()
    local file = io.open(TxtPath:gsub('\\', '/'), 'r')
    io.input(file)

    local clipsSectStart
    local isClipsSect = false
    local isTracksSect = false
    local isMarkerSect = false
    local curTrackName
    local curTrackCount = 0
    local i = 1
    for line in io.lines() do
        if line:find(TrackNumInfo) then
            NumOfTracks = line:gsub(TrackNumInfo .. '\t+', '')
            for j = 1, NumOfTracks do
                local track = {}
                Tracks[#Tracks + 1] = track
            end
        elseif line:find(ClipsNumInfo) then
            NumOfClips = line:gsub(ClipsNumInfo .. '\t+', '')
        elseif line:find(FilesNumInfo) then
            NumOfFiles = line:gsub(FilesNumInfo .. '\t+', '')
        elseif line:find(FramesInfo) then
            Framerate = line:gsub(FramesInfo .. '\t+', '')
            Framerate = Framerate:gsub(' Frame', '')
        elseif line:find(TimecodeOffsetInfo) then
            TimecodeOffset = line:gsub(TimecodeOffsetInfo .. '\t+', '')
        elseif line:find(ClipsSect) then
            clipsSectStart = i
            isClipsSect = true
        elseif line:find(TrackSect) then
            isTracksSect = true
        elseif line:find(MarkerSect) then
            isMarkerSect = true
        end

        --Store Clips/File Name info
        if isClipsSect and i > clipsSectStart + 1 then -- +1 to skip the "Filenames" line
            local clip
            if #line > 0 then
                local j = 1
                for val in line:gmatch('([^\t]+)') do
                    val = TrimCharacer(val, " ")
                    if j == 1 then
                        clip = val
                    elseif j == 2 then
                        Clips[clip] = val
                    end
                    j = j + 1
                end
            else
                isClipsSect = false
            end
        end
        --Store Track Info
        if isTracksSect then
            if line:find('TRACK NAME:') then
                curTrackName = line:gsub('TRACK NAME:\t+', '')
                curTrackCount = curTrackCount + 1
                TrackNames[#TrackNames+1] = curTrackName
            end
            if (line:sub(1, 1)):match('1') then
                local j = 1
                local clipName
                local startTime
                local mute
                for val in line:gmatch('([^\t]+)') do
                    val = TrimCharacer(val, " ")
                    if j == 3 then
                        clipName = val
                    elseif j == 4 then
                        startTime = val
                    elseif j == 7 then
                        mute = val
                    end
                    j = j + 1
                end
                local clipInfo = {}
                clipInfo[1] = curTrackCount
                clipInfo[2] = clipName
                clipInfo[3] = startTime
                clipInfo[4] = mute
                table.insert(Tracks[curTrackCount], clipInfo)
            end
        end
        --Store Marker Info
        if isMarkerSect then
            isTracksSect = false
            if #line > 0 then
                if (line:sub(1, 1)):match('%d') then
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
                    Markers[#Markers + 1] = marker
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
            pos = pos + val / Framerate
        end
        i = i + 1
    end
    return pos
end

function CreateMarkers()
    local offset = TimecodeToPos(TimecodeOffset)
    for i, marker in ipairs(Markers) do
        for time, name in pairs(marker) do
            local pos = TimecodeToPos(time)
            reaper.AddProjectMarker(0, false, pos - offset + RppStartTime, 0, name, i)
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
    for idx, name in ipairs(TrackNames) do 
        reaper.InsertTrackAtIndex(idx - 1, false) -- need to -1 the index since it starts at 1 instead of 0
        local track = reaper.GetTrack(0, idx - 1)
        reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
    end
end

function ImportMedia()
    local offset = TimecodeToPos(TimecodeOffset)
    for i, track in ipairs(Tracks) do
        for j, trackInfo in ipairs(track) do
            local startPos, mute
            local filename
            local selTrack
            local trackIdx
            for k, val in ipairs(trackInfo) do
                if k == 1 then
                    trackIdx = val - 1 -- need to -1 the index since it starts at 1 instead of 0
                    selTrack = r.GetTrack(0, trackIdx)
                    r.SetOnlyTrackSelected(selTrack)
                elseif k == 2 then
                    filename = GetClipName(val)
                elseif k == 3 then
                    startPos = TimecodeToPos(val)
                elseif k == 4 then
                    mute = val
                end
            end
            if filename then
                local file = (AudioFolderPath .. '/' .. filename):gsub('\\', '/')
                if reaper.file_exists(file) then
                    reaper.InsertMedia(file, 0)
                    local itemCount = r.CountMediaItems(0)
                    if itemCount > 0 then
                        for l = 0, itemCount - 1 do
                            local item = r.GetMediaItem(0, l)
                            local take = r.GetActiveTake(item)
                            local name = r.GetTakeName(take)
                            if name == filename then
                                r.MoveMediaItemToTrack(item, selTrack)
                                r.SetMediaItemPosition(item, startPos - offset + RppStartTime, false)
                                if mute:match('Muted') then
                                    r.SetMediaItemInfo_Value(item, 'B_MUTE', 1)
                                end
                                break
                            end
                        end
                    end
                else
                    FailedFiles[#FailedFiles+1] = file
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
        r = r - 1
    end
    return s:sub(l, r)
end

function PrintFailedFiles()
    if #FailedFiles > 0 then
        local allpaths = ""
        for i, file in ipairs(FailedFiles) do
            allpaths = allpaths .. file .. '\n\n'
        end
        r.ShowMessageBox('Failed to import some files! Please ensure that they actually exist in the audio folder', 'Error', 0)
        r.ShowConsoleMsg('Missing files: \n\n' .. allpaths)
    end
end

function Main()
    if not ExtensionChecker() then return end
    r.SetEditCurPos(0, false, false)
    local isFile, file = reaper.JS_Dialog_BrowseForOpenFiles('Select Session Text File', '', '', "Text file (.txt)\0*.txt\0\0", false)
    if isFile == 0 then return end
    local isFolder, folder = reaper.JS_Dialog_BrowseForFolder( 'Select Folder With Audio Files to Import', '' )
    if isFolder == 0 then return end
    TxtPath = file
    AudioFolderPath = folder
    local trackCount = r.CountTracks(0)
    if trackCount == 0 then
        ReadFile()
        CreateTracks()
        ImportMedia()
        r.SetEditCurPos(RppStartTime, true, true)
        CreateMarkers()
        PrintFailedFiles()
    else
        r.ShowMessageBox('Please make sure your session is completely empty and has 0 tracks before running this script', 'Error', 0)
    end
end

----------------------------------------
--Main
----------------------------------------
r.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

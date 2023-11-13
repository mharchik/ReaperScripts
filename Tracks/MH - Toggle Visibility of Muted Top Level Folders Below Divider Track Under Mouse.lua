----------------------------------------
-- @description Toggle Visibility of Muted Top Level Folders Below Divider Track Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @about   Set this to a Mouse Modifier action on tracks/TCP. 
--          When clicking on a Divider Track, the script will look below it to see if any folder tracks are visible and muted. If so they will be hidden.
--          If no muted folder tracks are there, instead the script will unhide any folder tracks that were hidden.
--          The name of the Divider Track will also be updated to signal if any tracks below it are hidden.
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox( "This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Global Variables
----------------------------------------
local DividerTracks = {}
----------------------------------------
--Functions
----------------------------------------

--Stores the Names and Track Indexes of all Divider Tracks from your session in the 'DividerTracks' table
function GetDividerTracks()
    for index = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, index)
        if mh.IsDividerTrack(track) then
            local _, name = reaper.GetTrackName(track)
            local dividerTrack = {}
            dividerTrack[index] = name
            DividerTracks[#DividerTracks + 1] = dividerTrack
        end
    end
end

--Checks if the current moused over track is one of our Divider Tracks
function IsTrackDivider(track)
    local isDividerTrack = false
    local dividerIdx
    local _, trackName = reaper.GetTrackName(track)
    local trackIdx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
    trackName = string.gsub(trackName, " <Hidden>", "")
    for i, dTrack in ipairs(DividerTracks) do
        for index, name in pairs(dTrack) do
            if string.match(name, trackName) and index == trackIdx then
                isDividerTrack = true
                dividerIdx = i
            end
        end
    end
    return isDividerTrack, dividerIdx, trackIdx
end

--Determines the track indexs between which we'll be hidding/unhiding tracks
function GetRangeOfTracks(dividerIdx)
    local lastTrackIdx
    if dividerIdx + 1 <= #DividerTracks then
        local lastTrack = DividerTracks[dividerIdx + 1]
        for index, value in pairs(lastTrack) do
            lastTrackIdx = index
        end
    else
        lastTrackIdx = reaper.CountTracks(0) - 1
    end
    return lastTrackIdx
end

--Checksif any top level folder tracks are still visible and muted.
function DetermineVisibility(firstTrackIndex, lastTrackIndex)
    local shouldHide = false
    for i = 1, (lastTrackIndex - firstTrackIndex) - 1 do
        local track = reaper.GetTrack(0, firstTrackIndex + i)
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and reaper.GetTrackDepth(track) == 0 and reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 and reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
            shouldHide = true
            break
        end
    end
    return shouldHide
end

--Hides or unhides all muted folder tracks below the Divider Track
function ToggleVisibility(firstTrackIdx, lastTrackIdx, shouldHide)
    local didHide = false
    for i = 1, (lastTrackIdx - firstTrackIdx) do
        local track = reaper.GetTrack(0, firstTrackIdx + i)
        local folderDepth = reaper.GetTrackDepth(track)
        if shouldHide then
            if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and folderDepth == 0 and reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
                reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
                local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
                local isChild = true
                local j = 0
                while isChild and trackNum + j < reaper.CountTracks(0) do --need to make sure that we don't check tracks that don't exist if child track is the final track in the session.
                    local nextTrack = reaper.GetTrack(0, trackNum + j)
                    local nextTrackFolderDepth = reaper.GetTrackDepth(nextTrack)
                    if folderDepth < nextTrackFolderDepth and nextTrackFolderDepth ~= 0 then
                        reaper.SetMediaTrackInfo_Value(nextTrack, "B_SHOWINTCP", 0)
                        j = j + 1
                    else
                        isChild = false
                    end
                end
            end
            didHide = true
        else
            reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
        end
    end
    return didHide
end

--Renames the folder track to mark whether or not tracks below it are hidden
function RenameDividerTrack(isHidden, track)
    local _, trackName = reaper.GetTrackName(track)
    if isHidden then
        if not string.match(trackName, "<Hidden>") then
            reaper.GetSetMediaTrackInfo_String(track, "P_NAME", trackName .. " <Hidden>", true)
        end
    else
        reaper.GetSetMediaTrackInfo_String(track, "P_NAME", string.gsub(trackName, " <Hidden>", ""), true)
    end
end

function Main()
    local track = reaper.BR_TrackAtMouseCursor()
    if not track then return end
    GetDividerTracks()
    local isDividerTrack, dividerIdx, trackIdx = IsTrackDivider(track)
    if not isDividerTrack then return end
    local lastTrackIdx = GetRangeOfTracks(dividerIdx)
    local shouldHide = DetermineVisibility(trackIdx, lastTrackIdx)
    local didHide = ToggleVisibility(trackIdx, lastTrackIdx, shouldHide)
    RenameDividerTrack(didHide, track)
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(true)

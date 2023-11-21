----------------------------------------
-- @description Toggle Visibility of Muted Top Level Folders Below Divider Track Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about   Set this to a Mouse Modifier action on tracks/TCP. 
--          When clicking on a Divider Track, the script will look below it to see if any folder tracks are visible and muted. If so they will be hidden.
--          If no muted folder tracks are there, instead the script will unhide any folder tracks that were hidden.
--          The name of the Divider Track will also be updated to signal if any tracks below it are hidden.
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local DividerTracks = {}
----------------------------------------
--Functions
----------------------------------------

--Stores the Names and Track Indexes of all Divider Tracks from your session in the 'DividerTracks' table
function GetDividerTracks()
    for index = 0, r.CountTracks(0) - 1 do
        local track = r.GetTrack(0, index)
        if mh.IsDividerTrack(track) then
            local _, name = r.GetTrackName(track)
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
    local _, trackName = r.GetTrackName(track)
    local trackIdx = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
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
        lastTrackIdx = r.CountTracks(0) - 1
    end
    return lastTrackIdx
end

--Checksif any top level folder tracks are still visible and muted.
function DetermineVisibility(firstTrackIndex, lastTrackIndex)
    local shouldHide = false
    for i = 1, (lastTrackIndex - firstTrackIndex) - 1 do
        local track = r.GetTrack(0, firstTrackIndex + i)
        if r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and r.GetTrackDepth(track) == 0 and r.GetMediaTrackInfo_Value(track, "B_SHOWINTCP") == 1 and r.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
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
        local track = r.GetTrack(0, firstTrackIdx + i)
        local folderDepth = r.GetTrackDepth(track)
        if shouldHide then
            if r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and folderDepth == 0 and r.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
                r.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
                local trackNum = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
                local isChild = true
                local j = 0
                while isChild and trackNum + j < r.CountTracks(0) do --need to make sure that we don't check tracks that don't exist if child track is the final track in the session.
                    local nextTrack = r.GetTrack(0, trackNum + j)
                    local nextTrackFolderDepth = r.GetTrackDepth(nextTrack)
                    if folderDepth < nextTrackFolderDepth and nextTrackFolderDepth ~= 0 then
                        r.SetMediaTrackInfo_Value(nextTrack, "B_SHOWINTCP", 0)
                        j = j + 1
                    else
                        isChild = false
                    end
                end
            end
            didHide = true
        else
            r.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
        end
    end
    return didHide
end

--Renames the folder track to mark whether or not tracks below it are hidden
function RenameDividerTrack(isHidden, track)
    local _, trackName = r.GetTrackName(track)
    if isHidden then
        if not string.match(trackName, "<Hidden>") then
            r.GetSetMediaTrackInfo_String(track, "P_NAME", trackName .. " <Hidden>", true)
        end
    else
        r.GetSetMediaTrackInfo_String(track, "P_NAME", string.gsub(trackName, " <Hidden>", ""), true)
    end
end

function Main()
    local track = r.BR_TrackAtMouseCursor()
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
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.TrackList_AdjustWindows(true)

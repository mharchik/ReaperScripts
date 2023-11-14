----------------------------------------
-- @description Create New Track Accounting for Folder Tracks Above It
-- @author Max Harchik
-- @version 1.0
-- @about   Creates a new track under the last selected track. If the track is at the end of a folder it will be added to that folder. 
--          If the track is a parent that has its children hidden, it will be added at the next visible position instead.
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selTrackCount = reaper.CountSelectedTracks(0)
    if selTrackCount == 0 then return end
    local track = reaper.GetSelectedTrack(0, selTrackCount - 1)
    local folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    if folderDepth == 1 then
        local nextTrack = reaper.GetTrack(0, trackNum)
        local trackHeight = reaper.GetMediaTrackInfo_Value(nextTrack, "I_TCPH")
        while trackHeight == 0 do
            trackNum = trackNum + 1
            nextTrack = reaper.GetTrack(0, trackNum)
            trackHeight = reaper.GetMediaTrackInfo_Value(nextTrack, "I_TCPH")
        end
    end
    reaper.InsertTrackAtIndex(trackNum, true)
    local newTrack = reaper.GetTrack(0, trackNum)
    if folderDepth < 0 then
        reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
        reaper.SetMediaTrackInfo_Value(newTrack, "I_FOLDERDEPTH", folderDepth)
    end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

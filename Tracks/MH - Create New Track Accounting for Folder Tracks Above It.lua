----------------------------------------
-- @description Create New Track Accounting for Folder Tracks Above It
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about   Creates a new track under the last selected track. If the track is at the end of a folder it will be added to that folder. 
--          If the track is a parent that has its children hidden, it will be added at the next visible position instead.
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selTrackCount = r.CountSelectedTracks(0)
    if selTrackCount == 0 then return end
    local track = r.GetSelectedTrack(0, selTrackCount - 1)
    local folderDepth = r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    local trackNum = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    if folderDepth == 1 then
        local nextTrack = r.GetTrack(0, trackNum)
        local trackHeight = r.GetMediaTrackInfo_Value(nextTrack, "I_TCPH")
        while trackHeight == 0 do
            trackNum = trackNum + 1
            nextTrack = r.GetTrack(0, trackNum)
            trackHeight = r.GetMediaTrackInfo_Value(nextTrack, "I_TCPH")
        end
    end
    r.InsertTrackAtIndex(trackNum, true)
    local newTrack = r.GetTrack(0, trackNum)
    if folderDepth < 0 then
        r.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 0)
        r.SetMediaTrackInfo_Value(newTrack, "I_FOLDERDEPTH", folderDepth)
    end
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
r.UpdateArrange()

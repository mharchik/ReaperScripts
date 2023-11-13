----------------------------------------
-- @description Toggle Solo of Last Touched Track's Top Level Folder Track and Unsolo All Other Tracks
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function SwapValue(i)
    if i > 0 then
        i = 0
    else
        i = 2 --2 sets "Solo In Place" which will retain any sends you have active on the track
    end
    return i
end

function ToggleTrackSolo(track)
    local soloState = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
    reaper.Main_OnCommand("40340", 0) --Calls the Action "Track: Unsolo all tracks"
    reaper.SetMediaTrackInfo_Value(track, "I_SOLO", SwapValue(soloState))
end

function Main()
    local track = reaper.GetLastTouchedTrack()
    if not track then return end
    local retval, parentTrack = mh.GetTopParentTrack(track)
    if retval == 2  then
        ToggleTrackSolo(parentTrack)
    else
        ToggleTrackSolo(track)
    end
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
reaper.UpdateArrange()

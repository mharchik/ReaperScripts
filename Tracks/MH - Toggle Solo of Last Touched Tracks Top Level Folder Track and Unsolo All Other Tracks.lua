----------------------------------------
-- @description Toggle Solo of Last Touched Track's Top Level Folder Track and Unsolo All Other Tracks
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
----------------------------------------
--Functions
----------------------------------------
function SwapValue(i)
    if i > 0 then
        i = 0
    else
        i = 2 --2 sets 'Solo In Place' which will retain any sends you have active on the track
    end
    return i
end

function ToggleTrackSolo(track)
    local soloState = r.GetMediaTrackInfo_Value(track, 'I_SOLO')
    r.Main_OnCommand('40340', 0) --Calls the Action 'Track: Unsolo all tracks'
    r.SetMediaTrackInfo_Value(track, 'I_SOLO', SwapValue(soloState))
end

function Main()
    local track = r.GetLastTouchedTrack()
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
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

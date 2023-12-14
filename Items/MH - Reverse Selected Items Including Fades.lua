----------------------------------------
-- @description Reverse Selected Items
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
----------------------------------------
--Functions
----------------------------------------

function Main()
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount == 0 then mh.noundo() return end
    for i = 0, selItemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local inLength = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
        local inCurve = r.GetMediaItemInfo_Value(item, 'D_FADEINDIR')
        local outLength = r.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
        local outCurve = r.GetMediaItemInfo_Value(item, 'D_FADEOUTDIR')
        r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', outLength)
        r.SetMediaItemInfo_Value(item, 'D_FADEINDIR', outCurve * -1)
        r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', inLength)
        r.SetMediaItemInfo_Value(item, 'D_FADEOUTDIR', inCurve * -1)
    end
    reaper.Main_OnCommand(41051, 0)
end

----------------------------------------
--Main
----------------------------------------
--r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

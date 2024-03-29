----------------------------------------
-- @description Move Edit Cursor to Start of Selected Items
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
if not mh.SWS() or not mh.JS() then mh.noundo() return end

----------------------------------------
--Functions
----------------------------------------

function Main()
    local selItemsCount = r.CountSelectedMediaItems(0)
    if selItemsCount == 0 then mh.noundo() return end
    local retval, start = mh.GetVisibleSelectedItemsSize()
    if retval then
        r.SetEditCurPos(start, true, false)
    end
    mh.noundo()
end

----------------------------------------
--Main
----------------------------------------
--r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
Main()
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Fade In Item Under Mouse to Edit Cursor
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
function Main()
    local x, y = r.GetMousePosition()
    local item = r.GetItemFromPoint(x, y, true)
    if not item then return end
    local editPos = r.GetCursorPosition()
    local itemStart, itemEnd = mh.GetItemSize(item)
	if editPos >= itemEnd or editPos <= itemStart then mh.noundo() return end
    local fadeIn = editPos - itemStart
    local fadeOut = itemEnd - r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    if fadeOut < editPos then
        r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", itemEnd - editPos)
    end
    r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', fadeIn)
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

----------------------------------------
-- @description Trim Right Edge of Item Under Mouse to Edit Cursor Without Moving Fade Out Start Until Minimum Fade Length
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about Trims the right edge of the item under your mouse cursor to the edit cursor. This will also trim the fade out up to a minimum length, at which point the fade will move with the edge of the item
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local MIN_FADE_LENGTH = 0.016666667 --currently set to 1 frame at 60 fps
----------------------------------------
--Functions
----------------------------------------
function Main()
    local item = r.BR_ItemAtMouseCursor()
    if not item then return end
    local editPos = r.GetCursorPosition()
    local itemStart, itemEnd = mh.GetItemSize(item)
	if editPos <= itemStart then mh.noundo() return end
    local fadeLength = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    if fadeLength > 0 then
        local newFadeLength = fadeLength - (itemEnd - editPos)
        if newFadeLength < MIN_FADE_LENGTH then
            newFadeLength = MIN_FADE_LENGTH
        end
        r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", newFadeLength)
    end
    r.BR_SetItemEdges(item, itemStart, editPos)
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

----------------------------------------
-- @description Trim Left Edge of Item Under Mouse to Edit Cursor Without Moving Fade In End Until Minimum Fade Length
-- @author Max Harchik
-- @version 1.0
-- @about Trims the left edge of the item under your mouse cursor to the edit cursor. This will also trim the fade in up to a minimum length, at which point the fade will move with the edge of the item

-- Requires SWS Extensions
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
	if editPos >= itemEnd then mh.noundo() return end
    local fadeLength = r.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    if fadeLength > 0 then
        local newFadeLength = fadeLength - (editPos - itemStart)
        if newFadeLength < MIN_FADE_LENGTH then
            newFadeLength = MIN_FADE_LENGTH
        end
        r.SetMediaItemInfo_Value(item, "D_FADEINLEN", newFadeLength)
    end
    r.BR_SetItemEdges(item, editPos, itemEnd)
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

----------------------------------------
-- @noindex
-- @description Center Named Window
-- @author Max Harchik
-- @version 1.0
-- @about Moves a window to the center of the main Reaper window
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local WINDOW_NAME = "nvk_FOLDER_ITEMS" --Type the name of the window you'd like to center here
----------------------------------------
--Functions
----------------------------------------
function Main()
	if not mh.JsChecker then return end
	local win = reaper.JS_Window_Find(WINDOW_NAME, false)
	if not win then return end
	local _, left, top, right, bottom = reaper.JS_Window_GetRect(win)
	local _, mLeft, mTop, mRight, mBottom = reaper.JS_Window_GetRect(reaper.GetMainHwnd())
	local height = math.abs(bottom - top)
	local width = right - left
	left = math.floor((mRight - mLeft) / 2 + mLeft - width / 2)
	top = math.floor((mBottom - mTop) / 2 + mTop - height / 2)
	reaper.JS_Window_SetPosition(win, left, top, width, height)
end

----------------------------------------
--Main
----------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

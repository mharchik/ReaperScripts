----------------------------------------
-- @noindex
-- @description Center Fast FX Finder Window
-- @author Max Harchik
-- @version 1.0
-- @about Moves the active FX Window to the center of the Main Reaper Window
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------

function Main()
	local FX_win = reaper.JS_Window_Find("Fast FX Finder", false)
	if not FX_win then return end
	local _, left, top, right, bottom = reaper.JS_Window_GetRect(FX_win)
	local _, mLeft, mTop, mRight, mBottom = reaper.JS_Window_GetRect(reaper.GetMainHwnd())
	local height = math.abs(bottom - top)
	local width = right - left
	left = math.floor((mRight - mLeft)/2 + mLeft - width/2)
	top = math.floor((mBottom - mTop)/2 + mTop - height/2)
	reaper.JS_Window_SetPosition( FX_win, left, top, width, height)
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

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
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local WindowName = "ReaLauncher" --Type the name of the window you'd like to center here
----------------------------------------
--Functions
----------------------------------------
function Main()
	mh.CenterNamedWindow(WindowName)
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
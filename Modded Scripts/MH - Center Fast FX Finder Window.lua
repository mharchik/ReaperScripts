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
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local WindowName = "Fast FX Finder" --Type the name of the window you'd like to center here
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

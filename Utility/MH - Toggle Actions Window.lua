----------------------------------------
-- @description Toggle Actions Window
-- @author Max Harchik
-- @version 1.0
-- @about Toggles open and close the Actions Window with the same key command
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.JsChecker() then mh.noundo() return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local win = r.JS_Window_Find("Actions", true)
    if win then
        r.JS_Window_Destroy(win)
    else
        r.Main_OnCommand("40605", 0) --Calls Action "Show action list"
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

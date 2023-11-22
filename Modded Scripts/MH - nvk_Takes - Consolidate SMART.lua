----------------------------------------
-- @noindex
-- @about
-- @description
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--Functions
----------------------------------------

function Main()
    local selItems = r.CountSelectedMediaItems(0)
    if selItems == 0 then return end
    if selItems == 1 then
        r.Main_OnCommand(r.NamedCommandLookup('_RSeb359e5ae9360b01d06839005088f24a200a71e4'), 0) -- Calls Script: nvk_TAKES - Consolidate item splits as take markers in first item.lua
    else
        r.Main_OnCommand(r.NamedCommandLookup('_RS0e018a885c360e06abfc7b39311a1f2cd1c2be7b'), 0) -- Calls Script: nvk_TAKES - Consolidate takes with take markers SMART.eel
    end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) r.ShowConsoleMsg(msg .. '\n') end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()


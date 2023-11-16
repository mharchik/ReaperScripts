----------------------------------------
-- @noindex
-- @description
-- @author Max Harchik
-- @version 1.0
-- @about
----------------------------------------
--User Settings
----------------------------------------


----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end


----------------------------------------
--Functions
----------------------------------------

function Main()
    local item, position = reaper.BR_ItemAtMouseCursor()
    local take = reaper.GetActiveTake(item)
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local idx = reaper.BR_GetMouseCursorContext_StretchMarker()


    local slope = reaper.GetTakeStretchMarkerSlope(take, idx)
    local _, pos_a, srcpos_a = reaper.GetTakeStretchMarker(take, idx)
    local _, pos_b, srcpos_b = reaper.GetTakeStretchMarker(take, idx + 1)
    -- Calculation
    local len_init = srcpos_b - srcpos_a -- length between two SM source positions
    local len_after = pos_b - pos_a      -- Length between two SM actual item positions
    local rate_left = (len_init / len_after) * (1 - slope)
    local rate_right = (len_init / len_after) * (1 + slope)
    local rate_ratio = rate_right / rate_left
    --(1+slope)/(1-slope) = rateRight/rateLeft
    Msg(pos_b)
    pos_b = (1 + slope) / rate_left * (len_init) + pos_a
    Msg(pos_b)
    reaper.SetTakeStretchMarker(take, idx + 1, pos_b, srcpos_b)
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
reaper.ClearConsole() -- comment out once script is complete
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

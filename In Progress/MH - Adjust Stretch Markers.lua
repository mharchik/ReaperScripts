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
--Global Variables
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
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

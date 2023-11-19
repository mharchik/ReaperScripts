----------------------------------------
-- @noindex
-- @description
-- @provides /Functions/MH - Functions.lua
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
-- @about
----------------------------------------
--User Settings
----------------------------------------


----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end


----------------------------------------
--Functions
----------------------------------------

function Main()
    local item, position = r.BR_ItemAtMouseCursor()
    local take = r.GetActiveTake(item)
    local window, segment, details = r.BR_GetMouseCursorContext()
    local idx = r.BR_GetMouseCursorContext_StretchMarker()


    local slope = r.GetTakeStretchMarkerSlope(take, idx)
    local _, pos_a, srcpos_a = r.GetTakeStretchMarker(take, idx)
    local _, pos_b, srcpos_b = r.GetTakeStretchMarker(take, idx + 1)
    -- Calculation
    local len_init = srcpos_b - srcpos_a -- length between two SM source positions
    local len_after = pos_b - pos_a      -- Length between two SM actual item positions
    local rate_left = (len_init / len_after) * (1 - slope)
    local rate_right = (len_init / len_after) * (1 + slope)
    local rate_ratio = rate_right / rate_left
    --(1+slope)/(1-slope) = rateRight/rateLeft
    mh.Msg(pos_b)
    pos_b = (1 + slope) / rate_left * (len_init) + pos_a
    mh.Msg(pos_b)
    r.SetTakeStretchMarker(take, idx + 1, pos_b, srcpos_b)
end


----------------------------------------
--Main
----------------------------------------
r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @noindex
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
tsm = r.GetResourcePath() .. '/Scripts/MH Scripts/TrackStyleManager/MH - Track Style Manager Globals.lua'; if r.file_exists(tsm) then dofile(tsm); if not tsm then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------

----------------------------------------
--Script Variables
----------------------------------------
local Values = tsm.GetExtValues()
----------------------------------------
--Functions
----------------------------------------


function SetExtValues(retvals_csv)
    local i = 1
    for value in string.gmatch(retvals_csv, '([^,]+)') do
        r.SetExtState(tsm.ExtSection, tsm.Settings[i], value, true)
        i = i + 1
    end
end

function PromptUser()
    local retvals = ""
    local captions = ""
    for key, name in ipairs(tsm.Settings) do
        if retvals == "" then
            retvals = tostring(Values[name])
        else
            retvals = retvals .. "," .. tostring(Values[name])
        end
        if captions == "" then
            captions = name
        else
            captions = captions ..","..name
        end
    end
    return reaper.GetUserInputs( "Style Manager Settings", 10, captions.. ",extrawidth=100", retvals)
end


function Main()
    tsm.GetExtValues()
    local retval, retvals_csv = PromptUser()
    if not retval then
        tsm.ResetExtValues()
        mh.noundo()
        return
    end
    SetExtValues(retvals_csv)
end

----------------------------------------
--Main
----------------------------------------
--r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

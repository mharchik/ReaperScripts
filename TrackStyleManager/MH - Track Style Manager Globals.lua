----------------------------------------
-- @noindex
----------------------------------------
--Setup
----------------------------------------
r = reaper
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------

----------------------------------------
--Script Variables
----------------------------------------
tsm = {}

tsm.ExtSection = "MH - TSM"

tsm.Settings = {
--[[1]] "Divider Track Height",
--[[2]] "Divider Track Layout Name",
--[[3]] "Divider Track Color (Hex)",
--[[4]] "Folder Item Track Height",
--[[5]] "Folder Item Track Layout Name",
--[[6]] "Folder Item Track Color (Hex)",
--[[7]] "Folder Bus Track Height",
--[[8]] "Folder Bus Track Layout Name",
--[[9]] "Folder Bus Track Color (Hex)"
}

tsm.Defaults = {
    [tsm.Settings[1]] = 33,
    [tsm.Settings[2]] = "A - NO CONTROL",
    [tsm.Settings[3]] = "00FFFF",
    [tsm.Settings[4]] = 28,
    [tsm.Settings[5]] = "A - COLOR FULL",
    [tsm.Settings[6]] = "4A2C69",
    [tsm.Settings[7]] = 28,
    [tsm.Settings[8]] = "A - COLOR FULL",
    [tsm.Settings[9]] = "25255A"
}

tsm.TrackColorOverrides = {
    Video = "#FFFF00"
}
----------------------------------------
--Functions
----------------------------------------
function tsm.GetExtValues()
    local ExtVals = {}
    for key, name in ipairs(tsm.Settings) do
        if not r.HasExtState(tsm.ExtSection, name) then
            r.SetExtState(tsm.ExtSection, name, tsm.Defaults[name], true)
            ExtVals[name] = r.GetExtState(tsm.ExtSection, name)
        else
            ExtVals[name] = r.GetExtState(tsm.ExtSection, name)
        end
    end
    return ExtVals
end

function tsm.ResetExtValues()
    for i, name in pairs(tsm.Settings) do
        r.SetExtState(tsm.ExtSection, name, tsm.Defaults[name], true)
    end
end

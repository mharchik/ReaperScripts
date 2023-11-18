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
--[[1]] "Default Track Layout",
--[[2]] "Divider Track Height",
--[[3]] "Divider Track Layout Name",
--[[4]] "Divider Track Color (Hex)",
--[[5]] "Folder Item Track Height",
--[[6]] "Folder Item Track Layout Name",
--[[7]] "Folder Item Track Color (Hex)",
--[[8]] "Folder Bus Track Height",
--[[9]] "Folder Bus Track Layout Name",
--[[10]] "Folder Bus Track Color (Hex)"
}

tsm.Defaults = {
    [tsm.Settings[1]] = "Global layout default",
    [tsm.Settings[2]] = 33,
    [tsm.Settings[3]] = "A - NO CONTROL",
    [tsm.Settings[4]] = "00FFFF",
    [tsm.Settings[5]] = 28,
    [tsm.Settings[6]] = "A - COLOR FULL",
    [tsm.Settings[7]] = "4A2C69",
    [tsm.Settings[8]] = 28,
    [tsm.Settings[9]] = "A - COLOR FULL",
    [tsm.Settings[10]] = "25255A"
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
        if  not r.HasExtState(tsm.ExtSection, name) then
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


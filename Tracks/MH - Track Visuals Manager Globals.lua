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
--Script Variables
----------------------------------------
tvm = {}

tvm.ExtSection = "MH - TSM"

tvm.Settings = {
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

-- Default values for all settings
tvm.Defaults = {
    [tvm.Settings[1]] = 33,
    [tvm.Settings[2]] = "A - NO CONTROL",
    [tvm.Settings[3]] = "00FFFF",
    [tvm.Settings[4]] = 28,
    [tvm.Settings[5]] = "A - COLOR FULL",
    [tvm.Settings[6]] = "4A2C69",
    [tvm.Settings[7]] = 28,
    [tvm.Settings[8]] = "A - COLOR FULL",
    [tvm.Settings[9]] = "25255A"
}

--If you want tracks with a specific name to have a specific color, you can set that override here
tvm.TrackColorOverrides = {
    Video = "#FFFF00"
}

tvm.Recolor = true --set false if you don't want the script to change any of your track colors

----------------------------------------
--Functions
----------------------------------------
function tvm.GetExtValues()
    local ExtVals = {}
    for key, name in ipairs(tvm.Settings) do
        if not r.HasExtState(tvm.ExtSection, name) then
            r.SetExtState(tvm.ExtSection, name, tvm.Defaults[name], true)
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        else
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        end
    end
    return ExtVals
end

function tvm.ResetExtValues()
    for i, name in pairs(tvm.Settings) do
        r.SetExtState(tvm.ExtSection, name, tvm.Defaults[name], true)
    end
end

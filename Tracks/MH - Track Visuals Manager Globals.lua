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
--[[1]] "Divider_TrackHeight",
--[[2]] "Divider_TrackLayout",
--[[3]] "Divider_TrackColor",
--[[4]] "Divider_TrackRecolor",
--[[5]] "Folder_TrackHeight",
--[[6]] "Folder_TrackLayout",
--[[7]] "Folder_TrackColor",
--[[8]] "Folder_TrackRecolor",
--[[9]] "Bus_TrackHeight",
--[[10]] "Bus_TrackLayout",
--[[11]] "Bus_TrackColor",
--[[12]] "Bus_TrackRecolor",
--[[13]] "DividerSymbol",
--[[14]] "Overrides"
}

-- Default values for all settings
tvm.Defaults = {
    [tvm.Settings[1]] = 33,
    [tvm.Settings[2]] = "A - NO CONTROL",
    [tvm.Settings[3]] = "0x00000001",
    [tvm.Settings[4]] = "true",
    [tvm.Settings[5]] = 28,
    [tvm.Settings[6]] = "A - COLOR FULL",
    [tvm.Settings[7]] = "0x00000001",
    [tvm.Settings[8]] = "true",
    [tvm.Settings[9]] = 28,
    [tvm.Settings[10]] = "A - COLOR FULL",
    [tvm.Settings[11]] = "0x00000001",
    [tvm.Settings[12]] = "true",
    [tvm.Settings[13]] = "<",
    [tvm.Settings[14]] = ""
}
----------------------------------------
--Functions
----------------------------------------
function tvm.GetAllExtValues()
    local ExtVals = {}
    for key, name in ipairs(tvm.Settings) do
        if not r.HasExtState(tvm.ExtSection, name) then
            r.SetExtState(tvm.ExtSection, name, tostring(tvm.Defaults[name]), true)
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        else
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        end
    end
    return ExtVals
end

function tvm.SetExtValue(name, val)
    for index, setting in ipairs(tvm.Settings) do
        if setting == name then
            r.SetExtState(tvm.ExtSection, name, tostring(val), true)
        end
    end
end

function tvm.GetExtValue(name)
    for index, setting in ipairs(tvm.Settings) do
        if setting == name then
            return r.GetExtState(tvm.ExtSection, name)
        end
    end
end

function tvm.ResetAllExtValues()
    for i, name in pairs(tvm.Settings) do
        r.SetExtState(tvm.ExtSection, name, tvm.Defaults[name], true)
    end
end

function tvm.SetAllExtValues(table)
    for name, value in pairs(table) do
        r.SetExtState(tvm.ExtSection, name, value, true)
    end
end

function tvm.GetOverrides() -- Returns a table that whose values are single entry tables where key = track name, value = color
    local oString = tvm.GetExtValue('Overrides')
    local vals = {}
    for value in oString:gmatch('([^,]+)') do
        local pair = {}
        local key
        local i = 1
        for text in value:gmatch('([^*]+)') do
            if i == 1 then
                key = text
            else
                pair[key] = text
            end
            i = i + 1
        end
        vals[#vals + 1] = pair
    end
    return vals
end

function tvm.SetOverrides(table)
    local list
    for index, override in ipairs(table) do
        local pair
        for name, color in pairs(override) do
            pair = name .. '*' .. color
        end
        if not list then
            list = pair
        else
            list = list .. ',' .. pair
        end
    end
    tvm.SetExtValue('Overrides', list)
end

--[[
## Returns whether or not a track can be classified as a divider track.

### returns
**_bool_**
]]
function tvm.IsDividerTrack(track)
    local _, name = r.GetTrackName(track)
    name = string.gsub(name, " ", "")
    return string.sub(name, 1, 1) == tvm.GetExtValue("DividerTrackSymbol")
end


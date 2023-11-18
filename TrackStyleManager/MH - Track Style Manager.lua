----------------------------------------
-- @description Track Style Manager
-- @author Max Harchik
-- @version 1.0
-- @provides
--          [main] .
--          [main] MH - Track Style Manager Settings.lua
--          [data] MH - Track Style Manager Globals.lua
--  
-- @about   Auto sets track heights, colors, and layouts.
--          for folder parents that are used only as a bus, and any divider tracks
--          Requires using the HYDRA reaper theme if you want it to change the look of your divider tracks. Otherwise you'll need to change the Layout variables to match the Track Control Panel Layout names for your theme
----------------------------------------
--Setup
----------------------------------------
r = reaper
local _, _, section_ID, cmd_ID, _, _, _ = r.get_action_context()
r.SetToggleCommandState(section_ID, cmd_ID, 1)
r.RefreshToolbar2(section_ID, cmd_ID)
tsm = r.GetResourcePath() .. '/Scripts/MH Scripts/TrackStyleManager/MH - Track Style Manager Globals.lua'; if r.file_exists(tsm) then dofile(tsm); if not tsm then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
local lastActiveTime = r.time_precise()

local Values = {}
----------------------------------------
--User Settings
----------------------------------------
--[[
local DefaultLayout = "Global layout default"
local DividerHeight = 33
local DividerLayout = "A - NO CONTROL"
local DividerColor = { r = 0, g = 255, b = 255 }
local BusHeight = 28
local BusLayout = "A - COLOR FULL"
local BusColor = { r = 37, g = 37, b = 90 }
local FolderItemTrackHeight = 28
local FolderItemTrackLayout = "A - COLOR FULL"
local FolderItemTrackColor = { r = 74, g = 44, b = 105 }
]]

local Recolor = true --set false if you don't want the script to change any of your track colors
local RecolorTrackNameOverrides = { Video = "#FFFF00" } --If you want tracks with a specific name to have a specific color, you can set that override here
----------------------------------------
-- Script Variables
----------------------------------------
local refreshRate = 0.5
----------------------------------------
--Functions
----------------------------------------

function HexToRgb(num)
    num = num:gsub("#", "")
    num = num:gsub(" ", "")
    local rgb = {}
    for i = 1, #num, 2 do
        rgb[#rgb+1] = tonumber(num:sub(i, i+1), 16)
    end
    return rgb
end

function RgbToHex(rgb)
    local num = ""
    for i, val in ipairs(rgb) do
        local hex = string.format("%x", val)
        --making sure we have strings that are 2 characters long in the case that a value is small enough to only be 1 character
        if #hex == 1 then
            hex = "0" .. hex
        end
        if num == "" then
            num = hex
        else
            num = num .. hex
        end
    end
    return num
end


function SetTrackSettings(track, height, layout, lock, color)
    --mh.Msg(({r.GetTrackName(track)})[2] .. " height: " .. height .. ", Layout: " .. layout .. ", lock: " .. lock ..", Color: " .. color)
    --Check Height
    height = tonumber(height)
    if height > 0 then
        local curHeight = r.GetMediaTrackInfo_Value(track, "I_TPCH")
        if curHeight ~= height then
            r.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", height)
        end
    end
    --Check Layout
    local curLayout = ({r.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", "", false)})[2]
    if curLayout ~= layout then
        mh.Msg(({r.GetTrackName(track)})[2] .. " Layout changed")
        r.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", layout, true)
    end
    --Check Height Lock
    local curLock = r.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
    if curLock ~= lock then
        r.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", lock)
    end
    --Check Color
    if Recolor then
        --If the track has one of the override names, we'll use the color set in the table at the start of the script instead
        local trackName = string.lower(({r.GetTrackName(track)})[2])
        for name, newColor in pairs(RecolorTrackNameOverrides) do
            if string.match(trackName, string.lower(name)) then
                color = newColor
            end
        end
        local curColor = RgbToHex(({r.ColorFromNative(r.GetTrackColor(track))}))
        if curColor ~= color then
            if color == 0 then --Reset Color to Default
                r.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", 0)
            else
                local rgb = HexToRgb(color)
                r.SetTrackColor(track, r.ColorToNative(rgb[1], rgb[2], rgb[3]))
            end
        end
    end
end

function Main()
    local currentTime = r.time_precise()
    if currentTime - lastActiveTime > refreshRate then
        reaper.ClearConsole()
        local trackCount = r.CountTracks(0)
        if trackCount > 0 then
            Values = tsm.GetExtValues()
            for i = 0, trackCount - 1 do
                local track = r.GetTrack(0, i)
                if track then
                    local numOfItems = r.CountTrackMediaItems(track)
                    local folderDepth = r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
                    if mh.IsDividerTrack(track) then --Checking if the track is a Divider Track
                        SetTrackSettings(track, Values["Divider Track Height"], Values["Divider Track Layout Name"], 1, Values["Divider Track Color (Hex)"])
                    elseif folderDepth == 1 and numOfItems == 0 then --Checking if the track is a parent sub mix bus
                        SetTrackSettings(track, Values["Folder Bus Track Height"], Values["Folder Bus Track Layout Name"], 1, Values["Folder Bus Track Color (Hex)"])
                    elseif folderDepth == 1 and r.GetTrackDepth(track) == 0 and numOfItems > 0 then --Checking if the track is a top level Folder Item Track
                        if r.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2 then --if folder is fully collpased then minimize it's height and lock it
                            SetTrackSettings(track, Values["Folder Item Track Height"], Values["Folder Item Track Layout Name"], 1, Values["Folder Item Track Color (Hex)"])
                        else
                            SetTrackSettings(track, 0, Values["Folder Item Track Layout Name"], 0, Values["Folder Item Track Color (Hex)"])
                        end
                    else --if none of the above then we'll set it all back to default
                        SetTrackSettings(track, 0, "Global layout Default", 0, 0)
                    end
                end
            end
            r.TrackList_AdjustWindows(true)
        end
        lastActiveTime = currentTime
    end
    r.defer(Main)
end

function Exit()
    r.SetToggleCommandState(section_ID, cmd_ID, 0)
    r.RefreshToolbar2(section_ID, cmd_ID)
end

----------------------------------------
--Main
----------------------------------------
Values = tsm.GetExtValues()
Main()
r.atexit(Exit)

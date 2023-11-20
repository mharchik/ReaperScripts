----------------------------------------
-- @description Track Visuals Manager
-- @author Max Harchik
-- @version 1.0
-- @provides
--  [main] .
--  [main] MH - Track Visuals Manager Settings.lua
--  [nomain] MH - Track Visuals Manager Globals.lua
--
-- @about   Auto sets track heights, colors, and layouts.
--          Affects folder parents that are used only as a bus, and any divider tracks
--          Requires using the HYDRA reaper theme if you want it to change the look of your divider tracks. Otherwise you'll need to change the Layout variables to match the Track Control Panel Layout names for your theme
----------------------------------------
--Setup
----------------------------------------
r = reaper
local _, _, section_ID, cmd_ID, _, _, _ = r.get_action_context()
r.SetToggleCommandState(section_ID, cmd_ID, 1)
r.RefreshToolbar2(section_ID, cmd_ID)
tvm = r.GetResourcePath() .. '/Scripts/MH Scripts/Tracks/MH - Track Visuals Manager Globals.lua'; if r.file_exists(tvm) then dofile(tvm); if not tvm then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
local lastActiveTime = r.time_precise()

local Values = {}
----------------------------------------
--User Settings
----------------------------------------
----------------------------------------
-- Script Variables
----------------------------------------
local refreshRate = 0.2
----------------------------------------
--Functions
----------------------------------------

function HexToRgb(num)
    num = num:gsub("[^%x]", "") --removing all non hexidecimal characters from input
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

function SetTrackSettings(track, height, layout, lock, color, recolor)
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
        r.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", layout, true)
    end
    --Check Height Lock
    local curLock = r.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
    if curLock ~= lock then
        r.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", lock)
    end
    --Check Color
    local curColor = r.GetTrackColor(track)
    if recolor == "true" then
        if not color then --Reset Color to Default
            if curColor ~= 0 then
               r.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", 0)
            end
        else
            local r1, g1, b1 = r.ColorFromNative(color)
            local newColor = r.ColorToNative(b1, g1, r1)
            --If the track has one of the override names, we'll use the color set in the table at the start of the script instead
            local trackName = ({r.GetTrackName(track)})[2]:lower()
            --[[
            for name, newColor in pairs(tvm.TrackColorOverrides) do
                if trackName:match(name:lower()) then
                    color = newColor
                end
            end
            ]]
            --If track is hiding other tracks below it, then we'll dim the color to help make that more obvious
            if color ~= 0 then
                if trackName:match("<hidden>") then
                    local rgb = ({r.ColorFromNative(newColor)})
                    for key, value in ipairs(rgb) do
                        rgb[key] = math.floor(value * 0.5)
                    end
                    newColor = r.ColorToNative(rgb[1], rgb[2], rgb[3])
                end
            end
            --Check if we need to change color
            local curColor = r.GetTrackColor(track)
            if curColor ~= newColor then
                r.SetTrackColor(track, newColor)
            end
        end
    else
        if curColor ~= 0 then
            r.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", 0)
         end
    end
end

function Main()
    local currentTime = r.time_precise()
    if currentTime - lastActiveTime > refreshRate then
        reaper.ClearConsole()
        local trackCount = r.CountTracks(0)
        if trackCount > 0 then
            Values = tvm.GetAllExtValues()
            for i = 0, trackCount - 1 do
                local track = r.GetTrack(0, i)
                if track then
                    if r.GetMediaTrackInfo_Value(track, "I_TCPH") > 0 then --only update visuals on tracks that are actually visible
                        local numOfItems = r.CountTrackMediaItems(track)
                        local folderDepth = r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
                        if tvm.IsDividerTrack(track) then --Checking if the track is a Divider Track
                            SetTrackSettings(track, Values["Divider_TrackHeight"], Values["Divider_TrackLayout"], 1, Values["Divider_TrackColor"], Values["Divider_TrackRecolor"])
                        elseif folderDepth == 1 and numOfItems == 0 then --Checking if the track is a parent sub mix bus
                            SetTrackSettings(track, Values["Bus_TrackHeight"], Values["Bus_TrackLayout"], 1, Values["Bus_TrackColor"], Values["Bus_TrackRecolor"])
                        elseif folderDepth == 1 and r.GetTrackDepth(track) == 0 and numOfItems > 0 then --Checking if the track is a top level Folder Item Track
                            if r.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2 then --if folder is fully collpased then minimize it's height and lock it
                                SetTrackSettings(track, Values["Folder_TrackHeight"], Values["Folder_TrackLayout"], 1, Values["Folder_TrackColor"], Values["Folder_TrackRecolor"])
                            else
                                SetTrackSettings(track, 0, Values["Folder_TrackLayout"], 0, Values["Folder_TrackColor"], Values["Folder_TrackRecolor"])
                            end
                        else --if none of the above then we'll set it all back to default
                            SetTrackSettings(track, 0, "Global layout Default", 0, false, Values["Folder_TrackRecolor"])
                        end
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
Values = tvm.GetAllExtValues()
Main()
r.atexit(Exit)

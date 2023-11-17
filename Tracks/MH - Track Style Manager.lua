----------------------------------------
-- @description Track Style Manager
-- @author Max Harchik
-- @version 1.0
-- @about   Auto sets track heights, colors, and layouts.
            -- for folder parents that are used only as a bus, and any divider tracks

-- Requires using the HYDRA reaper theme if you want it to change the look of your divider tracks. Otherwise you'll need to change the Layout variables to match the Track Control Panel Layout names for your theme
----------------------------------------
--Setup
----------------------------------------
r = reaper
local _, _, section_ID, cmd_ID, _, _, _ = r.get_action_context()
r.SetToggleCommandState(section_ID, cmd_ID, 1)
r.RefreshToolbar2(section_ID, cmd_ID)
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
local lastActiveTime = r.time_precise()
----------------------------------------
--User Settings
----------------------------------------
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


local Recolor = true --set false if you don't want the script to change any of your track colors
local RecolorTrackNameOverrides = { Video = {r = 255, g = 255, b = 0} } --If you want tracks with a specific name to have a specific color, you can set that override here
----------------------------------------
-- Script Variables
----------------------------------------
local refreshRate = 0.5
----------------------------------------

--Functions
----------------------------------------
function SetTrackSettings(track, height, layout, lock, color)
    if height > 0 then
        r.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", height)
    end
    r.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", layout, true)
    r.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", lock)
    r.TrackList_AdjustWindows(true)
    if Recolor then
        if color == 0 then --Reset Color to Default
            r.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", 0)
        else
            --If the track has one of the override names, we'll swap out the color to the one set in the table at the start of the script
            local trackName = string.lower(({r.GetTrackName(track)})[2])
            for name, savedColor in pairs(RecolorTrackNameOverrides) do
                if string.match(trackName, string.lower(name)) then
                    color = savedColor
                end
            end
            r.SetTrackColor(track, r.ColorToNative(color["r"], color["g"], color["b"]))
        end
    end
end

function Main()
    local currentTime = r.time_precise()
    if currentTime - lastActiveTime > refreshRate then
        --reaper.ClearConsole()
        local trackCount = r.CountTracks(0)
        if trackCount > 0 then
            for i = 0, trackCount - 1 do
                local track = r.GetTrack(0, i)
                if track then
                    local isLocked = r.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
                    local numOfItems = r.CountTrackMediaItems(track)
                    local folderDepth = r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
                    if mh.IsDividerTrack(track) then --Checking if the track is a Divider Track
                        if isLocked == 0 then
                            SetTrackSettings(track, DividerHeight, DividerLayout, 1, DividerColor)
                        end
                    elseif folderDepth == 1 and numOfItems == 0 then --Checking if the track is a parent sub mix bus
                        if isLocked == 0 then
                            SetTrackSettings(track, BusHeight, BusLayout, 1, BusColor)
                        end
                    elseif folderDepth == 1 and r.GetTrackDepth(track) == 0 and numOfItems > 0 then --Checking if the track is a top level Folder Item Track
                        if r.GetMediaTrackInfo_Value(track, "I_FOLDERCOMPACT") == 2 then --if folder is fully collpased then minimize it's height and lock it
                            if isLocked == 0 then
                                SetTrackSettings(track, FolderItemTrackHeight, FolderItemTrackLayout, 1, FolderItemTrackColor)
                            end
                        else
                            if isLocked == 1 then
                                SetTrackSettings(track, 0, FolderItemTrackLayout, 0, FolderItemTrackColor)
                            end
                        end
                    else --if none of the above then we'll set it all back to default
                        if isLocked == 1 then
                            SetTrackSettings(track, 0, DefaultLayout, 0, 0)
                        end
                    end
                end
            end
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
Main()
r.atexit(Exit)

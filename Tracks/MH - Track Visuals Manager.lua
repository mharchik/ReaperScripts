----------------------------------------
-- @description Track Visuals Manager
-- @author Max Harchik
-- @version 1.0
-- @provides
--  [main] .
--  [main] MH - Track Visuals Manager Settings.lua
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
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
local OS = r.GetOS()
----------------------------------------
-- Script Variables
----------------------------------------
local RefreshRate = 0.1
local LastActiveTime = r.time_precise()
local Values = {}
----------------------------------------
--Functions
----------------------------------------
function UpdateTrackSettings(track, height, layout, lock, color, recolor)
    local didChange = false
    --Check Layout
    local curLayout = ({r.GetSetMediaTrackInfo_String(track, 'P_TCP_LAYOUT', '', false)})[2]
    if curLayout ~= layout then
        r.GetSetMediaTrackInfo_String(track, 'P_TCP_LAYOUT', layout, true)
        didChange = true
    end
    --Check Height Lock
    local curLock = r.GetMediaTrackInfo_Value(track, 'B_HEIGHTLOCK')
    if curLock ~= lock then
        r.SetMediaTrackInfo_Value(track, 'B_HEIGHTLOCK', lock)
        didChange = true
    end
    --Only change our height override if the track is/was locked
    if lock == 1 or curLock == 1 then
        --Check Height
        height = tonumber(height)
        if height > 0 then
            local curHeight = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
            if curHeight ~= height then
                r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', height)
                didChange = true
            end
        elseif height == 0 then
            if r.GetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE') ~= 0 then
                r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', 0)
                didChange = true
            end
        end
    end
    --Check Color
    if recolor then
        local curColor = r.GetTrackColor(track)
        if not color then --Reset Color to Default
            if curColor ~= 0 then -- if it's already 0 then we don't need to change it anymore
                r.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', 0)
                didChange = true
            end
        else
            --If the track has one of the override names, we'll use the color set in the table at the start of the script instead
            local trackName = ({r.GetTrackName(track)})[2]:lower()
            local overrides = tvm.GetOverrides()
            for index, pair in ipairs(overrides) do
                for name, newColor in pairs(pair) do
                    local newName = mh.TrimSpaces(name):lower()
                    --doing a quick check to make sure the name isn't empty after we removed all the spaces from it
                    if #newName > 0  then
                        if trackName:match(newName) then
                            color = newColor
                        end
                    end
                end
            end
            -- Red and Blue values from ImGui color picker are switched on windows for some reason
            color = SwapOSColors(color)
            --If track is hiding other tracks below it, then we'll dim the color to help make that more obvious
            if trackName:match('<hidden>') then
                local rgb = ({r.ColorFromNative(color)})
                for key, value in ipairs(rgb) do
                    rgb[key] = math.floor(value * 0.5)
                end
                color = r.ColorToNative(rgb[1], rgb[2], rgb[3])
            end
            --Check if we need to change color
            if curColor ~= color + 16777216 then
                r.SetTrackColor(track, color)
                didChange = true
            end
        end
    else
        if r.GetTrackColor(track) ~= 0 then -- if it's already 0 then we don't need to change it anymore
            r.SetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR', 0)
            didChange = true
        end
    end
    --Only refresh arrange view if we actually changed anything
    if didChange then
        mh.Msg('refresh')
        r.TrackList_AdjustWindows(true)
    end
end

function SwapOSColors(rgb)
    if OS == 'Win32' or OS == 'Win64' then
        local r1, g1, b1 = r.ColorFromNative(rgb)
        return r.ColorToNative(b1, g1, r1)
    end
    return rgb
end

function Main()
    local currentTime = r.time_precise()
    if currentTime - LastActiveTime > RefreshRate then
        r.ClearConsole()
        local trackCount = r.CountTracks(0)
        if trackCount > 0 then
            r.PreventUIRefresh(1)
            Values = tvm.GetAllExtValues()
            for i = 0, trackCount - 1 do
                local track = r.GetTrack(0, i)
                if track then
                    if r.GetMediaTrackInfo_Value(track, 'I_TCPH') > 0 then --only update visuals on tracks that are actually visible
                        local numOfItems = r.CountTrackMediaItems(track)
                        local folderDepth = r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
                        --Checking if track is a Divider Track
                        if tvm.IsDividerTrack(track) then --Checking if the track is a Divider Track
                            UpdateTrackSettings(track, Values['Divider_TrackHeight'], Values['Divider_TrackLayout'], 1, Values['Divider_TrackColor'], mh.ToBool(Values['Divider_TrackRecolor']))
                        --Checking if track is a folder item track    
                        elseif folderDepth == 1 and r.GetTrackDepth(track) == 0 and numOfItems > 0 then --Checking if the track is a top level Folder Item Track
                            if r.GetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT') == 2 then --if folder is fully collpased then minimize it's height and lock it
                                UpdateTrackSettings(track, Values['Folder_TrackHeight'], Values['Folder_TrackLayout'], 1, Values['Folder_TrackColor'], mh.ToBool(Values['Folder_TrackRecolor']))
                            else
                                UpdateTrackSettings(track, 0, Values['Folder_TrackLayout'], 0, Values['Folder_TrackColor'], mh.ToBool(Values['Folder_TrackRecolor']))
                            end
                        --Checking if track is a sub folder bus track
                        elseif folderDepth == 1 and numOfItems == 0 then --Checking if the track is a parent sub mix bus
                            UpdateTrackSettings(track, Values['Bus_TrackHeight'], Values['Bus_TrackLayout'], 1, Values['Bus_TrackColor'], mh.ToBool(Values['Bus_TrackRecolor']))
                        else --if none of the above then we'll set it all back to default
                            UpdateTrackSettings(track, 0, 'Global layout Default', 0, false)
                        end
                    end
                end
                r.PreventUIRefresh(-1)
            end
        end
        LastActiveTime = currentTime
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

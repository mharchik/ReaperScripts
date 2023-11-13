----------------------------------------
-- @description Track Height Manager
-- @author Max Harchik
-- @version 1.0
-- @about Auto sets track heights for folder parents that are used only as a bus, and any divider tracks

-- Requires using the HYDRA reaper theme if you want it to change the look of your divider tracks. Otherwise you'll need to change the Layout variables to match the Track Control Panel Layout names for your theme
----------------------------------------
--Setup
----------------------------------------
local _, _, section_ID, cmd_ID, _, _, _ = reaper.get_action_context()
reaper.SetToggleCommandState(section_ID, cmd_ID, 1)
reaper.RefreshToolbar2(section_ID, cmd_ID)
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox( "This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
local refreshRate = 0.5
local lastActiveTime = reaper.time_precise()
----------------------------------------
--User Settings
----------------------------------------
local DividerHeight = 33
local DividerLayout = "A - NO CONTROL"
local BusHeight = 28
local BusLayout = "A - COLOR FULL"
local BusColor = { r = 37, g = 37, b = 90 }

local Recolor = true --set false if you don't want the script to change any of your track colors
----------------------------------------
--Functions
----------------------------------------
function SetTrackSettings(track, height, layout, lock)
    if height > 0 then
        reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", height)
    end
    reaper.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", layout, true)
    reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", lock)
    reaper.TrackList_AdjustWindows(true)
end

function Main()
    local currentTime = reaper.time_precise()
    if currentTime - lastActiveTime > refreshRate then
        local trackCount = reaper.CountTracks(0)
        if trackCount > 0 then
            for i = 0, trackCount - 1 do
                local track = reaper.GetTrack(0, i)
                if track then
                    local isLocked = reaper.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
                    local numOfItems = reaper.CountTrackMediaItems(track)
                    local folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
                    local isDivider = mh.IsDividerTrack(track)
                    local isBus
                    if folderDepth == 1 and numOfItems == 0 then
                        isBus = true
                    end
                    if isDivider then
                        if isLocked == 0 then
                            SetTrackSettings(track, DividerHeight, DividerLayout, 1)
                        end
                    elseif isBus then
                        if isLocked == 0 and numOfItems == 0 then
                            local curHeight = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
                            local isVisible = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
                            if curHeight > 0 and isVisible == 1 then
                                SetTrackSettings(track, BusHeight, BusLayout, 1)
                                if Recolor then
                                    reaper.SetTrackColor(track, reaper.ColorToNative(BusColor["r"], BusColor["g"], BusColor["b"]))
                                end
                            end
                        end
                    elseif isLocked == 1 then
                        SetTrackSettings(track, 0, "Global layout default", 0)
                        if Recolor then
                            --reset color to default
                            reaper.SetMediaTrackInfo_Value(track, "I_CUSTOMCOLOR", 0)
                        end
                    end
                end
            end
        end
        lastActiveTime = currentTime
    end
    reaper.defer(Main)
end

function Exit()
    reaper.SetToggleCommandState(section_ID, cmd_ID, 0)
    reaper.RefreshToolbar2(section_ID, cmd_ID)
end

----------------------------------------
--Main
----------------------------------------
Main()
reaper.atexit(Exit)

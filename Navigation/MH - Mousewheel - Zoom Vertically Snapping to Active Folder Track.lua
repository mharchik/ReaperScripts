----------------------------------------
-- @description Mousewheel - Zoom Vertically Snapping to Active Folder Track
-- @author Max Harchik
-- @version 1.0
-- @about   This script should be bound to mousewheel. 
--          Zooms the arrange window vertically. If you are zooming into or out of a folder track, the zoom will snap to the bounds of that folder track until the full folder is in view.
--          This script is intended to be used with your zoom preferences being set to the default "Vertical Zoom Center: Track at View Center". You can set this value in the Reaper Preferences under "Appearance > Zoom/Scroll/Offset".
--          This script requires the js_ReaScriptAPI extension.
----------------------------------------
--Setup
----------------------------------------
local val = ({ reaper.get_action_context() })[7] --Must be first in the script to correctly get the mousewheel direction
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
if not reaper.HasExtState(scriptName, "firstrun") then reaper.SetExtState(scriptName, "firstrun", "true", true) reaper.ShowMessageBox("This script is intended to be used with the zoom preferences set to the default 'Vertical zoom center: Track at view center'. \n\n You can set this value in the REAPER Preferences under 'Appearance > Zoom/Scroll/Offset'", "Script Info", 0) end
----------------------------------------
--User Settings
----------------------------------------
local ZoomAmount = 2    --Higher values increase the strength of the zoom in/out
----------------------------------------
--Functions
----------------------------------------

function IsZoomIn()
    if val > 0 then
        return true
    else
        return false
    end
end

function Zoom()
    if not IsZoomIn() then
        ZoomAmount = ZoomAmount * -1
    end
    reaper.CSurf_OnZoom(0, ZoomAmount)
end

function ScrollToPosition(arrangeView, pTCPY)
    local retval, pos, _, _, _, _ = reaper.JS_Window_GetScrollInfo(arrangeView, "v")
    local newScroll = pTCPY + pos
    if retval then
        reaper.JS_Window_SetScrollPos(arrangeView, "v", newScroll)
    end
end

function GetCenterTrack(left, top, right, bottom)
    local track = reaper.GetLastTouchedTrack()
    local IsTrackVisible = false
    if track then
        local tcpy = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
        local tcph = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
        if tcpy >= 0 and tcpy - tcph <= bottom then
            IsTrackVisible = true
        end
    end
    --if we can't see the selected track, we'll default back to the track at the center of the arrange window
    if not IsTrackVisible then
        local x = left
        local y = (top + bottom) / 2
        local centerTrack
        while not centerTrack and x <= right do
            centerTrack = reaper.GetTrackFromPoint(x, y)
            x = x + 1
            if centerTrack then
                track = centerTrack
            end
        end
    end
    return track
end

--Checks if center track is in a folder track, and if so gets the first and last track of that folder
function GetFolderEndTracks(track)
    local retval = false
    local pRetval, parentTrack, cRetval, lastChildTrack
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 and reaper.GetTrackDepth(track) == 0 then
        parentTrack = track
        local nextTrack = reaper.GetTrack(0, reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER"))

        cRetval, lastChildTrack = mh.GetLastChildTrack(nextTrack)
    else
        pRetval, parentTrack = mh.GetTopParentTrack(track)
        cRetval, lastChildTrack = mh.GetLastChildTrack(track)
    end
    if pRetval ~= 0 and cRetval ~= 0 then
        retval = true
    end
    return retval, parentTrack, lastChildTrack
end

function Main()
    if not mh.JsChecker() then return end
    local arrangeView = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)
    local _, left, top, right, bottom = reaper.JS_Window_GetRect(arrangeView)
    local screenBottomEdge = bottom - top
    local track = GetCenterTrack(left, top, right, screenBottomEdge)
    --Checking to see if we're zooming out from anywhere inside a folder track
    local isFolder, firstTrack, lastTrack
    if track then
        isFolder, firstTrack, lastTrack = GetFolderEndTracks(track)
        local folderState = reaper.GetMediaTrackInfo_Value(firstTrack, "I_FOLDERCOMPACT")
        if folderState == 2 then --if the track is fully collapsed we'll pre
            isFolder = true
        end
    end

    if isFolder then
        --if we're already outside the folder track before we even zoom, don't let it scroll
        local canScrollUp, canScrollDown = true, true
        local firstTrackTopEdge = reaper.GetMediaTrackInfo_Value(firstTrack, "I_TCPY")
        local lastTrackBottomEdge = reaper.GetMediaTrackInfo_Value(lastTrack, "I_TCPY") + reaper.GetMediaTrackInfo_Value(lastTrack, "I_TCPH")
        --disabling scroll changes after zooming in for some edge case situations
        if IsZoomIn() then
            if firstTrackTopEdge < 0 then
                canScrollDown = false
            end
            if lastTrackBottomEdge >= screenBottomEdge then
                canScrollUp = false
            end
        end
        Zoom()
        --check if we should scroll
        firstTrackTopEdge = reaper.GetMediaTrackInfo_Value(firstTrack, "I_TCPY")
        lastTrackBottomEdge = reaper.GetMediaTrackInfo_Value(lastTrack, "I_TCPY") + reaper.GetMediaTrackInfo_Value(lastTrack, "I_TCPH")
        if IsZoomIn() then
            if firstTrackTopEdge <= 0 and lastTrackBottomEdge <= screenBottomEdge then
                if canScrollDown then
                    ScrollToPosition(arrangeView, firstTrackTopEdge)
                end
            elseif firstTrackTopEdge >= 0 and lastTrackBottomEdge >= screenBottomEdge then
                if canScrollUp then
                    ScrollToPosition(arrangeView, lastTrackBottomEdge - screenBottomEdge)
                end
            end
        else --zooming out
            if firstTrackTopEdge >= 0 and lastTrackBottomEdge >= screenBottomEdge then
                if canScrollDown then
                    ScrollToPosition(arrangeView, firstTrackTopEdge)
                end
            elseif firstTrackTopEdge <= 0 and lastTrackBottomEdge <= screenBottomEdge then
                if canScrollUp then
                    ScrollToPosition(arrangeView, lastTrackBottomEdge - screenBottomEdge)
                end
            end
        end
    else
        Zoom()
    end
    reaper.defer(mh.noundo)
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
Main()
reaper.UpdateArrange()

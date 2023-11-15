----------------------------------------
-- @noindex
-- @description
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--User Settings
----------------------------------------


----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local fxChain, track, take = FindActiveFxWindow()
    local selFX = GetSelectedFX(fxChain)
    for i = 1, #selFX do
        if track then
            local retval, curFx = reaper.TrackFX_GetFXName(track, selFX[i])
            if retval then
                Msg(curFx)
            end
        elseif take then
            local retval, curFx = reaper.TakeFX_GetFXName(take, selFX[i])
            if retval then
                Msg(curFx)
            end
        end
    end
end

function FindActiveFxWindow()
    local activeTrack = nil
    local activeTake = nil
    local fxChain = reaper.CF_GetFocusedFXChain()
    if not fxChain then return end
    local trackCount = reaper.CountTracks(0)
    if trackCount == 0 then return end
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        local trackFx = reaper.CF_GetTrackFXChain(track)
        if trackFx == fxChain then
            --found the track for your active fx chain. Now do something
            activeTrack = track
            break
        else
            local itemCount = reaper.CountTrackMediaItems(track)
            if itemCount > 0 then
                for j = 0, itemCount - 1 do
                    local item = reaper.GetTrackMediaItem(track, j)
                    local take = reaper.GetActiveTake(item)
                    local itemFx = reaper.CF_GetTakeFXChain(take)
                    if itemFx == fxChain then
                        activeTake = take
                        --found the item for you active fx chain. Now do something
                        break
                    end
                end
            end
        end
    end
    return fxChain, activeTrack, activeTake
end

function EnumSelectedFX(fxChain)
    local i = -1
    return function()
        i = reaper.CF_EnumSelectedFX(fxChain, i)
        if i < 0 then return end
        return i
    end
end

function GetSelectedFX(fxChain)
    local selFX = {}
    local i = 1
    for j in EnumSelectedFX(fxChain) do
        selFX[i] = j
        i = i + 1
        Msg(string.format('%d', j))
    end
    return selFX
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
reaper.ClearConsole() -- comment out once script is complete
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

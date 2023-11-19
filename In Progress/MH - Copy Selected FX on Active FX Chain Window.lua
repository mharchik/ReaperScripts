----------------------------------------
-- @noindex
-- @description
-- @provides /Functions/MH - Functions.lua
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--User Settings
----------------------------------------


----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWSCheckerChecker() then return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local fxChain, track, take = FindActiveFxWindow()
    local selFX = GetSelectedFX(fxChain)
    for i = 1, #selFX do
        if track then
            local retval, curFx = r.TrackFX_GetFXName(track, selFX[i])
            if retval then
                Msg(curFx)
            end
        elseif take then
            local retval, curFx = r.TakeFX_GetFXName(take, selFX[i])
            if retval then
                Msg(curFx)
            end
        end
    end
end

function FindActiveFxWindow()
    local activeTrack = nil
    local activeTake = nil
    local fxChain = r.CF_GetFocusedFXChain()
    if not fxChain then return end
    local trackCount = r.CountTracks(0)
    if trackCount == 0 then return end
    for i = 0, trackCount - 1 do
        local track = r.GetTrack(0, i)
        local trackFx = r.CF_GetTrackFXChain(track)
        if trackFx == fxChain then
            --found the track for your active fx chain. Now do something
            activeTrack = track
            break
        else
            local itemCount = r.CountTrackMediaItems(track)
            if itemCount > 0 then
                for j = 0, itemCount - 1 do
                    local item = r.GetTrackMediaItem(track, j)
                    local take = r.GetActiveTake(item)
                    local itemFx = r.CF_GetTakeFXChain(take)
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
        i = r.CF_EnumSelectedFX(fxChain, i)
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
        mh.Msg(string.format('%d', j))
    end
    return selFX
end

----------------------------------------
--Main
----------------------------------------
r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

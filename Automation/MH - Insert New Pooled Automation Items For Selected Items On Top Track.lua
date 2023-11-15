----------------------------------------
-- @description Create New Pooled Automation Items For All Selected Items On Top Track
-- @author Max Harchik
-- @version 1.0
-- @about Creates automation items for all selected items on the top track you have selected. It will default to the first Automation Lane, unless there is no active automation lane in which case it will create automation items for Volume.
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selItemCount = reaper.CountSelectedMediaItems(0)
    if selItemCount == 0 then return end
    local topTrackNum
    for i = 0, selItemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local track = reaper.GetMediaItem_Track(item)
        local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        if topTrackNum == nil or topTrackNum > trackNum then
            topTrackNum = trackNum
        end
    end
    local track = reaper.GetTrack(0, topTrackNum - 1)
    local itemCount = reaper.CountTrackMediaItems(track)
    local items = {}
    for i = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.IsMediaItemSelected(item) then
            items[#items + 1] = item
        end
    end

    local envCount = reaper.CountTrackEnvelopes(track)
    if envCount == 0 then
        reaper.Main_OnCommand(41866, 0) -- Show Volume Track Envelope
    end
    local env = reaper.GetTrackEnvelope(track, 0)
    if not env then
        return
    end
    local aiCount = reaper.CountAutomationItems(env)
    local pool = 0
    if aiCount > 0 then
        for i = 0, aiCount - 1 do
            local usedPool = reaper.GetSetAutomationItemInfo(env, i, "D_POOL_ID", 0, false)
            if usedPool >= pool then
                pool = usedPool + 1
            end
        end
    end
    local length
    local envValue
    for i = 1, #items do
        local pos = reaper.GetMediaItemInfo_Value(items[i], "D_POSITION")
        if i == 1 then
            length = reaper.GetMediaItemInfo_Value(items[i], "D_LENGTH")
            envValue = ({ reaper.Envelope_Evaluate(env, pos, 48000, 1) })[2]
        end
        local ai = reaper.InsertAutomationItem(env, pool, pos, length)
        reaper.InsertEnvelopePointEx(env, ai, pos, envValue, 0, 0, false, false)
        reaper.GetSetAutomationItemInfo(env, ai, "D_LOOPSRC", 0, true)
    end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole() -- comment out once script is complete
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

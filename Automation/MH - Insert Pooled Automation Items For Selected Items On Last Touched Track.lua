----------------------------------------
-- @description Insert Pooled Automation Items for Selected Items on Last Touched Track
-- @author Max Harchik
-- @version 1.0
-- @about   Creates automation items for all selected items on the last selected track. 
--          Automation items will be created on the selected envelope, unless there is no active automation lane in which case it will open up the automation lane for "Volume" and create automation items there.
--          Only one automation item will be created for groups of items that are overlapping, spanning their combined length
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function GetPoolID()
    local pool = 0
    local trackCount = r.CountTracks(0)
    for i = 0, trackCount - 1 do
        local track = r.GetTrack(0, i)
        local envCount = r.CountTrackEnvelopes(track)
        if envCount > 0 then
            for j = 0, envCount - 1 do
                local env = r.GetTrackEnvelope(track, j)
                local aiCount = r.CountAutomationItems(env)
                if aiCount > 0 then
                    for k = 0, aiCount - 1 do
                        local usedPool = r.GetSetAutomationItemInfo(env, k, "D_POOL_ID", 0, false)
                        if usedPool >= pool then
                            pool = usedPool + 1
                        end
                    end
                end
            end
        end
    end
    return pool
end

--each group of overlapping items will be stored into their own table, and then those tables will all be stored in a master table: itemGroups
function GetItemGroups(track)
    local itemGroups = {}
    local itemCount = r.CountTrackMediaItems(track)
    if itemCount > 0 then
        for i = 0, itemCount - 1 do
            local selItem = r.GetTrackMediaItem(track, i)
            if r.IsMediaItemSelected(selItem) then
                --first time through there's nothing that exists to compare our item to, so instead we need to make new table for our first group and put our item in it
                if i == 0 then
                    local itemGroup = {}
                    itemGroup[1] = selItem
                    itemGroups[1] = itemGroup
                else
                    local isOverlapping = false
                    --checking each group of items in our master table
                    for j, group in ipairs(itemGroups) do
                        --in each group we see if the item is overlapping.
                        for k, item in ipairs(group) do
                            if mh.CheckIfItemsOverlap(item, selItem) then
                                isOverlapping = true
                                break
                            end
                        end
                        --if the item were checking was overlapping an item in this group, then we can add it to the group.
                        if isOverlapping then
                            group[#group + 1] = selItem
                        end
                    end
                    --if the item wasn't overlapping with any existing group, we'll create a new group for it.
                    if not isOverlapping then
                        local itemGroup = {}
                        itemGroup[#itemGroup + 1] = selItem
                        itemGroups[#itemGroups + 1] = itemGroup
                    end
                end
            end
        end
    end
    return itemGroups
end

function Main()
    local track = r.GetLastTouchedTrack()
    if not track then return end

    -- Creating a master table to store all of our item groups in
    local itemGroups = GetItemGroups(track)
    if #itemGroups == 0 then return end

    --finding our active envelope. If there is no active envelope it will show the volume envelop instead
    local envCount = r.CountTrackEnvelopes(track)
    if envCount == 0 then
        r.Main_OnCommand(41866, 0) -- Show Volume Track Envelope
    end

    local env = r.GetSelectedEnvelope()
    if not env then
        env = r.GetTrackEnvelope(track, 0)
        if not env then
            return
        end
    end

    --Deciding what pool id the automaiton items should use.
    local pool = GetPoolID()
    if not pool then
        pool = 1
    end

    --Create Automation Items
    local envValue
    for i, itemGroup in ipairs(itemGroups) do
        local itemsStart
        local itemsEnd
        local itemsLength
        for j, item in ipairs(itemGroup) do
            local itemLeftEdge = r.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemRightEdge = r.GetMediaItemInfo_Value(item, "D_LENGTH") + itemLeftEdge
            if not itemsStart then
                itemsStart = itemLeftEdge
            elseif itemsStart > itemLeftEdge then
                itemsStart = itemLeftEdge
            end
            if not itemsEnd then
                itemsEnd = itemRightEdge
            elseif itemsEnd < itemRightEdge then
                itemsEnd = itemRightEdge
            end
            itemsLength = itemsEnd - itemsStart
        end
        --Grabbing the start value for the envelope position at the very first item. Since items are pooled we can't set different start values for each, so we'll just default to the first item's value
        if i == 1 then
            envValue = ({ r.Envelope_Evaluate(env, itemsStart, 48000, 1) })[2]
        end
        local autoItem = r.InsertAutomationItem(env, pool, itemsStart, itemsLength)
        r.InsertEnvelopePointEx(env, autoItem, itemsStart, envValue, 0, 0, false, false)
        r.GetSetAutomationItemInfo(env, autoItem, "D_LOOPSRC", 0, true)
    end
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Sorts all selected items alphebtically and groups variations together in 30 second intervals
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local CreateMarkers = false  --set to true to create a marker at the start of each set of items
local GroupSpacing = 30 --in seconds, the interval by which the different groups will be spaced. If one group would overlap with the next group, it is shifted over to the next interval
----------------------------------------
--Script Variables
----------------------------------------
local Groups = {}
local Items = {}
----------------------------------------
--Functions
----------------------------------------
function RepositionItems(table, start)
    r.SelectAllMediaItems(0, false)
    local minLength = 0
    for groupName, itemGroup in pairs(table) do
        if CreateMarkers then
            r.AddProjectMarker(0, false, start, 0, groupName, 0)
        end
        for i, item in ipairs(itemGroup) do
            r.SetMediaItemSelected(item, true)
            local _, _, itemLength = mh.GetItemSize(item)
            if itemLength > minLength then
                minLength = itemLength
            end
        end
    end
    minLength = math.floor(minLength) + 1
    for groupName, itemGroup in pairs(table) do
        for index, item in ipairs(itemGroup) do
            r.SetMediaItemPosition(item, start, false)
            start = start + minLength
        end
    end
    local _, _, _, itemsLength = mh.GetVisibleSelectedItemsSize()
    return itemsLength
end

function CheckTable(value)
    for i, itemGroup in ipairs(Groups) do
        for groupName, group in pairs(itemGroup) do
            if groupName == value then
                return true
            end
        end
    end
    return false
end

function SortItemsAlphebetical(a, b)
    local name1, name2
    for name, item in pairs(a) do
        name1 = name
    end
    for name, item in pairs(b) do
        name2 = name
    end
    return name1:lower() < name2:lower()
end

function RoundTime(pos) --rounds passed in value to the next 30 second interval
    if pos/GroupSpacing == math.floor(pos/GroupSpacing) then --if we're already at a 30 second interval don't move
        return pos
    else
        return (math.floor(pos/GroupSpacing) + 1) * GroupSpacing
    end
end

function Main()
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount == 0 then mh.noundo() return end
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'), 0) -- Calls Action 'SWS: Save selected item(s)'
    --sorts all selected items alphebtically
    for i = 0, selItemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        local name = r.GetTakeName(take)
        local itemInfo = {}
        itemInfo[name] = item
        Items[#Items+1] = itemInfo
    end
    table.sort(Items,SortItemsAlphebetical)
    --groups the items into sets with the same file names minus variation number
    for i, itemInfo in ipairs(Items) do
        for name, item in pairs(itemInfo) do
            local groupName = name:gsub('_%d+.[Ww]av', '' ):lower()
            if not CheckTable(groupName) then
                local itemGroup = {}
                itemGroup[#itemGroup+1] = item
                local groupIdentifier = {}
                groupIdentifier[groupName] = itemGroup
                Groups[#Groups+1] = groupIdentifier
            else
                for j, groupIdentifier in ipairs(Groups) do
                    for key, itemGroup in pairs(groupIdentifier) do
                        if groupName == key then
                            itemGroup[#itemGroup+1] = item
                            break
                        end
                    end
                end
            end
        end
    end
    local _, pos = mh.GetVisibleSelectedItemsSize()
    pos  = RoundTime(pos)
    for j, groupIdentifier in ipairs(Groups) do
        local itemsLength = RepositionItems(groupIdentifier, pos)
        pos = pos + RoundTime(itemsLength)
    end
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTALLSELITEMS1'), 0) -- Calls Action 'SWS: Restore saved selected item(s)''
end

----------------------------------------
--Main
----------------------------------------
--r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

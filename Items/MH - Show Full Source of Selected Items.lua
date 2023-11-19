----------------------------------------
-- @description Show Full Source of Selected Items
-- @provides /Functions/MH - Functions.lua
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about   This script will extend any selected items out to be their full length, and reposition them so that they do not overlap with each other. 
--          If any selected items are from the same source file, the duplicating item will be deleted
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Script Variables
----------------------------------------
local sources = {}
----------------------------------------
--Functions
----------------------------------------

function ShowItemSource(item, track, pos)
    local take = r.GetActiveTake(item)
    local source = r.GetMediaItemTake_Source(take)
    local isNewSource = true
    for i, prevSource in ipairs(sources) do
        if r.GetMediaSourceFileName(source) == r.GetMediaSourceFileName(prevSource)  then
            isNewSource = false
        end
    end
    if isNewSource then
        local itemStart = r.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = r.GetMediaSourceLength(source)
        r.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS", 0)
        r.SetMediaItemLength(item, length, false)
        if itemStart <= pos then
            r.SetMediaItemInfo_Value( item, "D_POSITION", pos + 1 )
            itemStart = pos + 1
        end
        return true, itemStart + length, source
    else
        r.DeleteTrackMediaItem(track, item)
        return false
    end
end

function Main()
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount == 0 then mh.noundo() return end
    local items = {}
    for i = 1, selItemCount do
        items[i] = r.GetSelectedMediaItem(0, i - 1)
    end
    local tracksLastPos = {}
    for index, item in ipairs(items) do
        local track = r.GetMediaItemTrack(item)
        local num = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        --storing seperate end points for each track. If an item is overlapping with a previous item it will be moved to the end of that item.
        if not tracksLastPos[num] then
            tracksLastPos[num] = 0
        end
        local retval, pos, source = ShowItemSource(item, track, tracksLastPos[num])
        if retval then
            tracksLastPos[num] = pos
            sources[#sources+1] = source
        end
    end
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

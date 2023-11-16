----------------------------------------
-- @description Mouse Modifier - Select Only Items on Track Under Mouse and Select All Children Tracks
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function SelectOnlyItemsOnTrackUnderMouse(track)
    local trackItemCount = reaper.CountTrackMediaItems(track)
    if trackItemCount == 0 then return end
    local selItems = {}
    for i = 0, trackItemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.IsMediaItemSelected(item) then
            selItems[#selItems + 1] = item
        end
    end
    if #selItems > 0 then
        reaper.SelectAllMediaItems(0, false)
        for i = 1, #selItems do
            reaper.SetMediaItemSelected(selItems[i], true)
        end
    else
        reaper.SelectAllMediaItems(0, false)
        for i = 1, trackItemCount do
            local item = reaper.GetTrackMediaItem(track, i - 1)
            reaper.SetMediaItemSelected(item, true)
            selItems[#selItems + 1] = item
        end
    end
    return selItems
end

function SelectFolderItemChildren(track, selItems)
    local depth = reaper.GetTrackDepth(track)
    local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local nextDepth = depth + 1
    while nextDepth > depth do
        local nextTrack = reaper.GetTrack(0, trackNum)
        nextDepth = reaper.GetTrackDepth(nextTrack)
        local nextTrackItemCount = reaper.CountTrackMediaItems(nextTrack)
        if nextTrackItemCount > 0 then
            for j = 0, nextTrackItemCount - 1 do
                local nextItem = reaper.GetTrackMediaItem(nextTrack, j)
                local nextItemStart, nextItemEnd = mh.GetItemSize(nextItem)
                for k = 1, #selItems do
                    local folderItemStart, folderItemEnd = mh.GetItemSize(selItems[k])
                    if nextItemStart >= folderItemStart and nextItemStart <= folderItemEnd then
                        reaper.SetMediaItemSelected(nextItem, true)
                        mh.SelectOverlappingGroupOfItems(nextItem)
                    elseif nextItemStart <= folderItemStart and nextItemEnd >= folderItemStart then
                        reaper.SetMediaItemSelected(nextItem, true)
                        mh.SelectOverlappingGroupOfItems(nextItem)
                    end
                end
            end
        end
        trackNum = trackNum + 1
    end
end

function Main()
    local track, _, _ = reaper.BR_TrackAtMouseCursor()
    reaper.SetOnlyTrackSelected(track)
    local selItems = SelectOnlyItemsOnTrackUnderMouse(track)
    if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SELCHILDREN2"), 0)
        SelectFolderItemChildren(track, selItems)
    end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

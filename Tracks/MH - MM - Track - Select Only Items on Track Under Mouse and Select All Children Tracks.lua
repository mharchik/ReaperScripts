----------------------------------------
-- @description Mouse Modifier - Select Only Items on Track Under Mouse and Select All Children Tracks
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--Functions
----------------------------------------
function SelectOnlyItemsOnTrackUnderMouse(track)
    local trackItemCount = r.CountTrackMediaItems(track)
    if trackItemCount == 0 then return end
    local selItems = {}
    for i = 0, trackItemCount - 1 do
        local item = r.GetTrackMediaItem(track, i)
        if r.IsMediaItemSelected(item) then
            selItems[#selItems + 1] = item
        end
    end
    if #selItems > 0 then
        r.SelectAllMediaItems(0, false)
        for i = 1, #selItems do
            r.SetMediaItemSelected(selItems[i], true)
        end
    else
        r.SelectAllMediaItems(0, false)
        for i = 1, trackItemCount do
            local item = r.GetTrackMediaItem(track, i - 1)
            r.SetMediaItemSelected(item, true)
            selItems[#selItems + 1] = item
        end
    end
    return selItems
end

function SelectFolderItemChildren(track, selItems)
    local depth = r.GetTrackDepth(track)
    local trackNum = r.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
    local nextDepth = depth + 1
    while nextDepth > depth do
        local nextTrack = r.GetTrack(0, trackNum)
        nextDepth = r.GetTrackDepth(nextTrack)
        local nextTrackItemCount = r.CountTrackMediaItems(nextTrack)
        if nextTrackItemCount > 0 then
            for j = 0, nextTrackItemCount - 1 do
                local nextItem = r.GetTrackMediaItem(nextTrack, j)
                local nextItemStart, nextItemEnd = mh.GetItemSize(nextItem)
                for k = 1, #selItems do
                    local folderItemStart, folderItemEnd = mh.GetItemSize(selItems[k])
                    if nextItemStart >= folderItemStart and nextItemStart <= folderItemEnd then
                        r.SetMediaItemSelected(nextItem, true)
                        mh.GetOverlappingItems(nextItem)
                    elseif nextItemStart <= folderItemStart and nextItemEnd >= folderItemStart then
                        r.SetMediaItemSelected(nextItem, true)
                        mh.GetOverlappingItems(nextItem)
                    end
                end
            end
        end
        trackNum = trackNum + 1
    end
end

function Main()
    local track, _, _ = r.BR_TrackAtMouseCursor()
    r.SetOnlyTrackSelected(track)
    local selItems = SelectOnlyItemsOnTrackUnderMouse(track)
    if r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
        r.Main_OnCommand(r.NamedCommandLookup('_SWS_SELCHILDREN2'), 0)
        SelectFolderItemChildren(track, selItems)
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

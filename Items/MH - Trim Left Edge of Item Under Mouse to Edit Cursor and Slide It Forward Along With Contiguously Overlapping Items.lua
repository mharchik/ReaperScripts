----------------------------------------
-- @description Trim Left Edge of Item Under Mouse to Edit Cursor and Slide It Forward Along With Contiguously Overlapping Items
-- @author Max Harchik
-- @version 1.0
-- @about Trims the start of any item, including fades, to the edit cursor and then moves it forward to it's previous start time, keeping the same relative timing to all items behind it that are contiguously connected by overlapping crossfades

-- Requires SWS Extensions
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------

function SelectOverlappingGroupOfItemsAfterItem(item)
	local track = reaper.GetMediaItem_Track(item)
	local itemCount = reaper.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	local itemsToCheck = {}
	local checkedItems = {}
	itemsToCheck[1] = item
	while #itemsToCheck > 0 do
		local itemStart, itemEnd = mh.GetItemSize(itemsToCheck[1])
		for i = 0, itemCount - 1 do
			local nextItem = reaper.GetTrackMediaItem(track, i)
			local nextItemStart = mh.GetItemSize(nextItem)
			if nextItemStart > itemStart and nextItemStart <= itemEnd then
				local isNewItem = true
				for _, checkedItem in ipairs(checkedItems) do
					if nextItem == checkedItem then
						isNewItem = false
					end
				end
				if isNewItem then
					reaper.SetMediaItemSelected(nextItem, true)
					itemsToCheck[#itemsToCheck + 1] = nextItem
					checkedItems[#checkedItems + 1] = nextItem
				end
			end
		end
		table.remove(itemsToCheck, 1)
	end
end

function Main()
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"),0) -- Calls Action: "SWS: Save selected item(s)"
	reaper.SelectAllMediaItems(0, false)
	local item = reaper.BR_ItemAtMouseCursor()
	if not item then
		reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_RESTALLSELITEMS1"),0) -- Calls Action: "SWS: Restore saved selected item(s)"
		reaper.defer(mh.noundo)
		return
	end
	local editPos = reaper.GetCursorPosition()
	local itemStart, ItemEnd = mh.GetItemSize(item)
	if editPos <= itemStart then mh.noundo() return end
	local fadeLength = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    if fadeLength > 0 then
        local newFadeLength = fadeLength - (editPos - itemStart)
        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", newFadeLength)
    end
	reaper.BR_SetItemEdges(item, editPos, ItemEnd)
	local moveAmount = itemStart - editPos
	reaper.SetMediaItemSelected(item, true)
	SelectOverlappingGroupOfItemsAfterItem(item)
	local selItemCount = reaper.CountSelectedMediaItems()
	for i = 0, selItemCount - 1 do
		local nextItem = reaper.GetSelectedMediaItem(0, i)
		local nextItemStart = mh.GetItemSize(nextItem)
		reaper.SetMediaItemPosition(nextItem, nextItemStart + moveAmount, false)
	end
	reaper.SetEditCurPos(itemStart, false, false)
end

--------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

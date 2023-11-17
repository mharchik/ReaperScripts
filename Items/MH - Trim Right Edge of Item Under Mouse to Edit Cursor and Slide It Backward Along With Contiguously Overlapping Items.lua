----------------------------------------
-- @description Trim Right Edge of Item Under Mouse to Edit Cursor and Slide It Backward Along With Contiguously Overlapping Items
-- @author Max Harchik
-- @version 1.0
-- @about Trims the end of any item, including fades, to the edit cursor and then moves it back to it's previous end time, keeping the same relative timing to all items in front of it that are contiguously connected by overlapping crossfades

-- Requires SWS Extensions
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------

function SelectOverlappingGroupOfItemsBeforeItem(item)
	local track = r.GetMediaItem_Track(item)
	local itemCount = r.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	local itemsToCheck = {}
	local checkedItems = {}
	itemsToCheck[1] = item
	while #itemsToCheck > 0 do
		local itemStart = mh.GetItemSize(itemsToCheck[1])
		for i = 0, itemCount - 1 do
			local nextItem = r.GetTrackMediaItem(track, i)
			local nextItemStart, nextItemEnd = mh.GetItemSize(nextItem)
			if nextItemStart < itemStart and nextItemEnd >= itemStart then
				local isNewItem = true
				for _, checkedItem in ipairs(checkedItems) do
					if nextItem == checkedItem then
						isNewItem = false
					end
				end
				if isNewItem then
					r.SetMediaItemSelected(nextItem, true)
					itemsToCheck[#itemsToCheck + 1] = nextItem
					checkedItems[#checkedItems + 1] = nextItem
				end
			end
		end
		table.remove(itemsToCheck, 1)
	end
end

function Main()
	r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"),0) -- Calls Action: "SWS: Save selected item(s)"
	r.SelectAllMediaItems(0, false)
	local item = r.BR_ItemAtMouseCursor()
	if not item then
		r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTALLSELITEMS1"),0) -- Calls Action: "SWS: Restore saved selected item(s)"
		mh.noundo()
		return
	end
	local editPos = r.GetCursorPosition()
	local itemStart, itemEnd = mh.GetItemSize(item)
	if editPos >= itemEnd then mh.noundo() return end
	local fadeLength = r.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    if fadeLength > 0 then
        local newFadeLength = fadeLength - (itemEnd - editPos)
        r.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", newFadeLength)
    end
	r.BR_SetItemEdges(item, itemStart, editPos)
	local moveAmount = editPos - itemEnd
	r.SetMediaItemSelected(item, true)
	SelectOverlappingGroupOfItemsBeforeItem(item)
	local selItemCount = r.CountSelectedMediaItems()
	for i = 0, selItemCount - 1 do
		local nextItem = r.GetSelectedMediaItem(0, i)
		local nextItemStart = mh.GetItemSize(nextItem)
		r.SetMediaItemPosition(nextItem, nextItemStart - moveAmount, false)
	end
	r.SetEditCurPos(itemEnd, false, false)
end

--------------------
--Main
----------------------------------------
--reaper.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

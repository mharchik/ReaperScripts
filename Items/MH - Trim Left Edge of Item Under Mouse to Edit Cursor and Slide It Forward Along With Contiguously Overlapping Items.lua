----------------------------------------
-- @description Trim Item Edges
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about Trims the start of any item, including fades, to the edit cursor and then moves it forward to it's previous start time, keeping the same relative timing to all items behind it that are contiguously connected by overlapping crossfades
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

function SelectOverlappingGroupOfItemsAfterItem(item)
	local track = r.GetMediaItem_Track(item)
	local itemCount = r.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	local itemsToCheck = {}
	local checkedItems = {}
	itemsToCheck[1] = item
	while #itemsToCheck > 0 do
		local itemStart, itemEnd = mh.GetItemSize(itemsToCheck[1])
		for i = 0, itemCount - 1 do
			local nextItem = r.GetTrackMediaItem(track, i)
			local nextItemStart = mh.GetItemSize(nextItem)
			if nextItemStart > itemStart and nextItemStart <= itemEnd then
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

function CheckForCrossfades(item)
	local itemStart, itemEnd  = mh.GetItemSize(item)
	local track = r.GetMediaItem_Track(item)
	local itemCount = r.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	for i = 0, itemCount - 1 do
		local nextItem = r.GetTrackMediaItem(track, i)
		if nextItem ~= item then
			local nextItemStart, nextItemEnd  = mh.GetItemSize(nextItem)
			if itemStart < nextItemEnd and itemStart > nextItemStart then
				local fadeLen = nextItemEnd - itemStart
				r.SetMediaItemInfo_Value(item, "D_FADEINLEN", fadeLen)
				r.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", 1)
				r.SetMediaItemInfo_Value(nextItem, "D_FADEOUTLEN", fadeLen)
				r.SetMediaItemInfo_Value(nextItem, "C_FADEOUTSHAPE", 1)
			end
		end
	end
end

function Main()
	r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'),0) -- Calls Action: 'SWS: Save selected item(s)'
	r.SelectAllMediaItems(0, false)
    local x, y = r.GetMousePosition()
    local item = r.GetItemFromPoint(x, y, true)
	if not item then
		r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTALLSELITEMS1'),0) -- Calls Action: 'SWS: Restore saved selected item(s)'
		mh.noundo()
		return
	end
	--Trim Item to edit cursor only if edit cursor is actually overlapping item
	local editPos = r.GetCursorPosition()
	local itemStart, ItemEnd = mh.GetItemSize(item)
	if editPos <= itemStart then mh.noundo() return end
	local fadeLength = r.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
    if fadeLength > 0 then
        local newFadeLength = fadeLength - (editPos - itemStart)
        r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', newFadeLength)
    end
	r.BR_SetItemEdges(item, editPos, ItemEnd)
	local moveAmount = itemStart - editPos
	r.SetMediaItemSelected(item, true)
	SelectOverlappingGroupOfItemsAfterItem(item)
	--Move all selected items forward
	local selItemCount = r.CountSelectedMediaItems()
	for i = 0, selItemCount - 1 do
		local nextItem = r.GetSelectedMediaItem(0, i)
		local nextItemStart = mh.GetItemSize(nextItem)
		r.SetMediaItemPosition(nextItem, nextItemStart + moveAmount, false)
	end
	CheckForCrossfades(item)
	r.SetEditCurPos(itemStart, true, false)
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

---@diagnostic disable: param-type-mismatch
----------------------------------------
-- @provides
--   [main] .
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
mh = {}
----------------------------------------
--Global Variables
----------------------------------------
mh.DividerTrackSymbol = "<" --When this character is added to the start of a track name, that track will be treated as a divider track
----------------------------------------
--Functions
----------------------------------------
--[[Checks the version of MH Scripts that you have Installed

    @return number t]]
function mh.version()
    local file = io.open((reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'):gsub('\\', '/'), "r")
    local vers_header = "-- @version "
    io.input(file)
    local t = 0
    for line in io.lines() do
        if line:find(vers_header) then
            t = line:gsub(vers_header, "")
            break
        end
    end
    io.close(file)
    return tonumber(t)
end

--Prints a message to the reaper console
function mh.Msg(msg)
    reaper.ShowConsoleMsg(tostring(msg) .. "\n")
end

--Checks If you have the js_ReaScriptAPI Installed
function mh.JsChecker()
    if not reaper.JS_ReaScriptAPI_Version or not reaper.JS_Window_Destroy then
        reaper.ShowMessageBox("Please install the js_ReaScriptAPI extension via Reapack before trying to run this script.", "Error", 0)
        return false
    else
        return true
    end
end

--Used to exit undo states in certain scripts
function mh.noundo() end

--Returns whether or not a track can be classified as a divider track
function mh.IsDividerTrack(track)
    local _, name = reaper.GetTrackName(track)
    name = string.gsub(name, " ", "")
    return string.sub(name, 1, 1) == mh.DividerTrackSymbol
end

--[[Gets the highest level parent folder track of input track.

    @param MediaTrack track : input track

    @return integer retval : '0 = No Parent track, 1 = Track is Parent Track, 2 = Track is Child Track.'
    @return MediaTrack parentTrack : 'Parent Folder Track if it exists, else returns input track.']]
function mh.GetTopParentTrack(track)
    local depth = reaper.GetTrackDepth(track)
    if depth > 0 then
        --get track index of the track above the track passed in
        local trackIdx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 2
        while depth > 0 do
            track = reaper.GetTrack(0, trackIdx)
            depth = reaper.GetTrackDepth(track)
            trackIdx = trackIdx - 1
        end
        return 2, track
    elseif reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
        return 1, track
    else
        return 0, track
    end
end

--[[Gets the last track in the folder track structure of input track

    @param MediaTrack track : input track

    @return integer retval : '0 = Track is not in Folder, 1 = Track is in Folder.''
    @return MediaTrack childTrack : 'The last child track if input track is in folder, else returns input track.']]
function mh.GetLastChildTrack(track)
    local childTrack
    local depth = reaper.GetTrackDepth(track)
    local folderDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
    if depth > 0 or folderDepth == 1 then
        --get track index of the track below the track passed in
        local trackIdx = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
        repeat
            childTrack = reaper.GetTrack(0, trackIdx)
            if childTrack then
                depth = reaper.GetTrackDepth(childTrack)
            end
            trackIdx = trackIdx + 1
        until depth <= 0 or not childTrack
        childTrack = reaper.GetTrack(0, trackIdx - 2)
        return 1, childTrack
    else
        return 0, childTrack
    end
end

--[[Gets the start position, end position, and length of any item

    @param MediaItem item: input item 

    @return integer itemStart : 'The start position of the item in seconds'
    @return integer itemEnd : 'The end position of the item in seconds'
    @return integer itemLength : 'The length of the item in seconds']]
function mh.GetItemSize(item)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemEnd = itemLength + itemStart
    return itemStart, itemEnd, itemLength
end

--[[Gets the combined start position, end position, and length of all selected items, ignoring any items that are on hidden tracks

    @return boolean retval : returns false if no selected items are visible
    @return integer itemStart : 'The start position of the item in seconds'
    @return integer itemEnd : 'The end position of the item in seconds'
    @return integer itemLength : 'The length of the item in seconds']]
function mh.GetVisibleSelectedItemsSize()
	--Getting the positions of all visible selected items to see where they start and end
    local selItemCount = reaper.CountSelectedMediaItems(0)
    if selItemCount > 0 then
        local itemsStart, itemsEnd
        for i = 0, selItemCount - 1 do
            local item = reaper.GetSelectedMediaItem(0, i)
            local track = reaper.GetMediaItem_Track(item)
            local trackHeight = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
            local isVisible = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
            if trackHeight > 0 and isVisible then
                local itemLeftEdge = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local itemRightEdge = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + itemLeftEdge
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
            end
        end
        local itemsLength
        if itemsStart and itemsEnd then
            itemsLength = itemsEnd - itemsStart
            return true, itemsStart, itemsEnd, itemsLength
        else
            return false
        end
    else
        return false
    end
end


--[[Selects all items that are overlapping with the input item, as well as any items overlapping those items, and so on.
    
    @param MediaItem item : 'Item to check.'
    @param boolean shouldSelect :  'Decides whether overlapping items should be selected.'

    @return table|MediaItem checkedItems : 'Table of all overlapping items.']]
function mh.SelectOverlappingGroupOfItems(item, shouldSelect)
	local track = reaper.GetMediaItem_Track(item)
	local itemCount = reaper.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	local itemsToCheck = {}
	local checkedItems = {}
	itemsToCheck[1] = item
	while #itemsToCheck > 0 do
		local itemStart, itemEnd = mh.GetItemSize(itemsToCheck[1])
		for i = 0, itemCount - 1 do
			local isOverlapping = false
			local nextItem = reaper.GetTrackMediaItem(track, i)
			local nextItemStart, nextItemEnd = mh.GetItemSize(nextItem)
			if itemStart < nextItemStart and itemEnd > nextItemStart then
				isOverlapping = true
			elseif itemStart > nextItemStart and itemStart < nextItemEnd then
				isOverlapping = true
			end
			if isOverlapping then
				local isNewItem = true
				for _, checkedItem in ipairs(checkedItems) do
					if nextItem == checkedItem then
						isNewItem = false
					end
				end
				if isNewItem then
                    if shouldSelect then
                        reaper.SetMediaItemSelected(nextItem, true)
                    end
					itemsToCheck[#itemsToCheck + 1] = nextItem
					checkedItems[#checkedItems + 1] = nextItem
				end
			end
		end
		table.remove(itemsToCheck, 1)
	end
    return checkedItems
end
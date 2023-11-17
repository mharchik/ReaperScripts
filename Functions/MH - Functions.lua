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

--When this character is added to the start of a track name, that track will be treated as a divider track
mh.DividerTrackSymbol = "<"
----------------------------------------
--Functions
----------------------------------------

--[[
## Checks the version of MH Scripts that you have Installed

### returns
**_t: number_** : current version of the script that is installed
]]
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

--[[  
## Prints a message to the reaper console

### params

**_msg: any_** : text to print

]]
function mh.Msg(msg)
    reaper.ShowConsoleMsg(tostring(msg) .. "\n")
end

--[[
## Checks If you have the js_ReaScriptAPI Installed

### returns
**_bool_**
]]
function mh.JsChecker()
    if not reaper.JS_ReaScriptAPI_Version or not reaper.JS_Window_Destroy then
        reaper.ShowMessageBox("Please install the js_ReaScriptAPI extension via Reapack before trying to run this script.", "Error", 0)
        return false
    else
        return true
    end
end

--## Used to exit scripts early without creating an undo point.
function mh.noundo() end

--[[
## Returns whether or not a track can be classified as a divider track.

### returns
**_bool_**
]]
function mh.IsDividerTrack(track)
    local _, name = reaper.GetTrackName(track)
    name = string.gsub(name, " ", "")
    return string.sub(name, 1, 1) == mh.DividerTrackSymbol
end

--[[
## Gets the highest level parent folder track of input track.

### params 
**_track: MediaTrack_**  : input track

### returns
**_retval: int_** : 0 = No Parent track, 1 = Track is Parent Track, 2 = Track is Child Track.

MediaTrack _parentTrack_ : 'Parent Folder Track if it exists, else returns input track.'
]]
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

--[[
## Gets the last track in the folder track structure of input track

### params
**_track: MediaTrack_** : input track

### returns
**_retval: int_** : 0 = Track is not in Folder, 1 = Track is in Folder.

**_childTrack: MediaTrack_** : The last child track if input track is in folder, else returns input track.
]]
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

--[[
## Gets the start position, end position, and length of any item

### params
**_item: MediaItem_** : input item 

### returns
**_itemStart: double_**  : The start position of the item in seconds

**_itemEnd: double_** : The end position of the item in seconds.
    
**_itemLength: double_** : The length of the item in seconds.
]]
function mh.GetItemSize(item)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local itemEnd = itemLength + itemStart
    return itemStart, itemEnd, itemLength
end

--[[
## Gets the combined start position, end position, and length of all selected items, ignoring any items that are on hidden tracks

### returns
**_retval: bool_** : returns false if no selected items are visible.

**_itemStart: int_** : The start position of the item in seconds.

**_itemEnd: int_** : The end position of the item in seconds.

**_itemLength: int_**  : The length of the item in seconds.
]]
function mh.GetVisibleSelectedItemsSize()
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
        if itemsStart and itemsEnd then
            local itemsLength = itemsEnd - itemsStart
            return true, itemsStart, itemsEnd, itemsLength
        else
            return false
        end
    else
        return false
    end
end


function mh.CheckIfItemsOverlap(item1, item2)
    local item1Start, item1End = mh.GetItemSize(item1)
    local item2Start, item2End = mh.GetItemSize(item2)
    if item1Start < item2Start and item1End > item2Start then
        return true
    elseif item1Start > item2Start and item1Start < item2End then
        return true
    end
    return false
end


--[[
## Selects all items that are overlapping with the input item, as well as any items overlapping those items, and so on.
    
### params
**_item: MediaItem_** : Item to check.
    
**_shouldSelect: bool_** :  Decides whether overlapping items should be selected.

### returns
**_checkedItems: table|MediaItem_** : Table of all overlapping items.
]]
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

--[[
## Finds the window with a name that matches the input string, and moves it 

### params
**_windowName: string_** : the name of the window you'd like to move. Does not need to match the full window name.
]]
function mh.CenterNamedWindow(windowName)
	if not mh.JsChecker then return end
	local win = reaper.JS_Window_Find(windowName, false)
	if not win then return end
	local _, left, top, right, bottom = reaper.JS_Window_GetRect(win)
	local _, mLeft, mTop, mRight, mBottom = reaper.JS_Window_GetRect(reaper.GetMainHwnd())
	local height = math.abs(bottom - top)
	local width = right - left
	left = math.floor((mRight - mLeft) / 2 + mLeft - width / 2)
	top = math.floor((mBottom - mTop) / 2 + mTop - height / 2)
	reaper.JS_Window_SetPosition(win, left, top, width, height)
end

--[[
## Checks if input item is a folder Item.

### params
**_item: MediaItem_** : item to check.
]]
function mh.IsFolderItem(item)
    local take = reaper.GetActiveTake(item)
    local source = reaper.GetMediaItemTake_Source(take)
    local typebuf = reaper.GetMediaSourceType(source)
    if typebuf == "EMPTY" then
        local track = reaper.GetMediaItemTrack(item)
        if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
            return true
        end
    end
    return false
end
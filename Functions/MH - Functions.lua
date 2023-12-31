---@diagnostic disable: param-type-mismatch
----------------------------------------
-- @provides [nomain] .
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
mh = {}
----------------------------------------
--Global Variables
----------------------------------------
----------------------------------------
--Functions
----------------------------------------

--[[
## Checks the version of MH Scripts that you have Installed

### returns
**_t: number_** : current version of the script that is installed
]]
function mh.version()
    local file = io.open((r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'):gsub('\\', '/'), 'r')
    local vers_header = '-- @version '
    io.input(file)
    local t = 0
    for line in io.lines() do
        if line:find(vers_header) then
            t = line:gsub(vers_header, '')
            break
        end
    end
    io.close(file)
    return tonumber(t)
end

--[[
## Gets current reaper settings

### params
**str: string_** : the name of the setting your checking.

### returns
**_val: number_** : value of the setting your checking.
]]
function mh.settings(str)
    local ini = io.open(reaper.get_ini_file(), 'r')
    io.input(ini)
    local val
    for line in io.lines() do
        if line:find(str) then
            val = line:gsub(str .. '=', '')
            break
        end
    end
    io.close(ini)
    return val
end

--[[  
## Prints a message to the reaper console

### params

**_msg: any_** : text to print
]]
function mh.Msg(msg)
    r.ShowConsoleMsg(tostring(msg) .. '\n')
end

--## Used to exit scripts early without creating an undo point.
function mh.noundo()
    r.defer(function () end)
end


--[[
## Checks If you have the js_ReaScriptAPI Extension Installed

### returns
**_bool_**
]]
function mh.JS()
    if not r.JS_ReaScriptAPI_Version then
        r.ShowMessageBox('Please install the js_ReaScriptAPI extension via Reapack before trying to run this script.', 'Error', 0)
        return false
    else
        return true
    end
end

--[[
## Checks If you have the SWS Extension Installed

### returns
**_bool_**
]]
function mh.SWS()
    if not r.CF_GetSWSVersion then
        r.ShowMessageBox('Please install the SWS extensions before trying to run this script.', 'Error', 0)
        return false
    else
        return true
    end
end

--[[
## Checks If you have the ReaImGui Extension Installed

### returns
**_bool_**
]]
function mh.ImGui ()
    if not r.ImGui_GetVersion then
        r.ShowMessageBox('Please install the ReaImGui extension via Reapack before trying to run this script.', 'Error', 0)
        return false
    else
        return true
    end
end

--[[
## Checks if input item is a folder Item.

### params
**_item: MediaItem_** : item to check.

### returns
**_bool_**
]]
function mh.IsFolderItem(item)
    if ({r.GetSetMediaItemInfo_String(item, 'P_EXT:nvk_item_type', '', 0)})[2] == 'folder' then
        return true
    end
    return false
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
    local depth = r.GetTrackDepth(track)
    if depth > 0 then
        --get track index of the track above the track passed in
        local trackIdx = r.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER') - 2
        while depth > 0 do
            track = r.GetTrack(0, trackIdx)
            depth = r.GetTrackDepth(track)
            trackIdx = trackIdx - 1
        end
        return 2, track
    elseif r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == 1 then
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
    local depth = r.GetTrackDepth(track)
    local folderDepth = r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')
    if depth > 0 or folderDepth == 1 then
        --get track index of the track below the track passed in
        local trackIdx = r.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
        repeat
            childTrack = r.GetTrack(0, trackIdx)
            if childTrack then
                depth = r.GetTrackDepth(childTrack)
            end
            trackIdx = trackIdx + 1
        until depth <= 0 or not childTrack
        childTrack = r.GetTrack(0, trackIdx - 2)
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
    local itemStart = r.GetMediaItemInfo_Value(item, 'D_POSITION')
    local itemLength = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
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
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount > 0 then
        local itemsStart, itemsEnd
        for i = 0, selItemCount - 1 do
            local item = r.GetSelectedMediaItem(0, i)
            local track = r.GetMediaItem_Track(item)
            local trackHeight = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
            local isVisible = r.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP')
            if trackHeight > 0 and isVisible then
                local itemLeftEdge = r.GetMediaItemInfo_Value(item, 'D_POSITION')
                local itemRightEdge = r.GetMediaItemInfo_Value(item, 'D_LENGTH') + itemLeftEdge
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

--[[
## Compares two items to see if they're are overlapping

### params
**_item1: MediaItem_** : first item to compare

**_item2: MediaItem_** : second item to compare
    
### returns
**_bool_**
]]
function mh.CheckIfItemsOverlap(item1, item2)
    local track1 = r.GetMediaItemTrack(item1)
    local track2 = r.GetMediaItemTrack(item2)
    if track1 == track2 then
        local itemStart1, itemEnd1 = mh.GetItemSize(item1)
        local itemStart2, itemEnd2 = mh.GetItemSize(item2)
        if itemStart1 < itemStart2 and itemEnd1 > itemStart2 then
            return true
        elseif itemStart1 > itemStart2 and itemStart1 < itemEnd2 then
            return true
        end
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
function mh.GetOverlappingItems(item, shouldSelect)
	local track = r.GetMediaItem_Track(item)
	local itemCount = r.CountTrackMediaItems(track)
	if itemCount == 0 then return end
	local itemsToCheck = {}
	local checkedItems = {}
	itemsToCheck[1] = item
	while #itemsToCheck > 0 do
		local itemStart, itemEnd = mh.GetItemSize(itemsToCheck[1])
		for i = 0, itemCount - 1 do
			local isOverlapping = false
			local nextItem = r.GetTrackMediaItem(track, i)
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
                        r.SetMediaItemSelected(nextItem, true)
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
	local win = r.JS_Window_Find(windowName, false)
	if not win then return end
	local _, left, top, right, bottom = r.JS_Window_GetRect(win)
	local _, mLeft, mTop, mRight, mBottom = r.JS_Window_GetRect(r.GetMainHwnd())
	local height = math.abs(bottom - top)
	local width = right - left
	left = math.floor((mRight - mLeft) / 2 + mLeft - width / 2)
	top = math.floor((mBottom - mTop) / 2 + mTop - height / 2)
	r.JS_Window_SetPosition(win, left, top, width, height)
end

--[[
## returns the minimum track height, and minimum record armed track height of the current theme.

### returns
**_minHeight: integer_** : the minimum track height in pixels

**_minRecarmHeight: integer_** : the minimum track height while record armed in pixels
]]
function mh.GetMinTrackHeights()
    r.PreventUIRefresh(1)
	local minHeight
	local minRecarmHeight
	local track = r.GetTrack(0,0)
	if not track then return end
	--get track current settings
	local height = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
	local recarm = r.GetMediaTrackInfo_Value(track, 'I_RECARM')
	local show = r.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP')
	local lock = r.GetMediaTrackInfo_Value(track, 'B_HEIGHTLOCK')
	--set track record armed to get its minimum recarm height
	r.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 1)
	r.SetMediaTrackInfo_Value(track, 'B_HEIGHTLOCK', 0)
	r.SetMediaTrackInfo_Value(track, 'I_RECARM', 1)
	r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', 1)
	minRecarmHeight = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
	--unarm and get it's actual minimum height
	r.SetMediaTrackInfo_Value(track, 'I_RECARM', 0)
	r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', 1)
	minHeight = r.GetMediaTrackInfo_Value(track, 'I_TCPH')
	--reset values
	r.SetMediaTrackInfo_Value(track, 'I_RECARM', recarm)
	r.SetMediaTrackInfo_Value(track, 'I_HEIGHTOVERRIDE', height)
	r.SetMediaTrackInfo_Value(track, 'B_HEIGHTLOCK', lock)
	r.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', show)
    r.PreventUIRefresh(-1)
    return minHeight, minRecarmHeight
end

function mh.ToBool(string)
    if string:lower() == 'true' then
        return true
    elseif string:lower() == false then
        return false
    end
end

function mh.InvertBool(b)
    if b then
        return false
    else
        return true
    end
end

function mh.HexToRgb(num)
    num = num:gsub('[^%x]', '') --removing all non hexidecimal characters from input
    local rgb = {}
    for i = 1, #num, 2 do
        rgb[#rgb+1] = tonumber(num:sub(i, i+1), 16)
    end
    return rgb
end

function mh.RgbToHex(rgb)
    local num = ''
    for i, val in ipairs(rgb) do
        local hex = string.format('%x', val)
        --making sure we have strings that are 2 characters long in the case that a value is small enough to only be 1 character
        if #hex == 1 then
            hex = '0' .. hex
        end
        if num == '' then
            num = hex
        else
            num = num .. hex
        end
    end
    return num
end

--[[
    ## removes spaces from the start and end of a string

    ### params
    **_s: string_** : string to be modified
]]
function mh.TrimSpaces(s)
    local l = 1
    while s:sub(l, l) == ' ' do
      l = l + 1
    end
    local r = s:len(s)
    while s:sub(r, r) == ' ' do
      r = r-1
    end
    return s:sub(l, r)
end


----------------------------------------
-- Track Visuals Manager Globals
----------------------------------------
tvm = {}

tvm.ExtSection = 'MH_TSM'
tvm.ExtTrack = 'MH_TSM_TrackType'
tvm.EmptyName = 'tvm_override_empty_name'

tvm.Settings = {
--[[1]] 'Divider_TrackHeight',
--[[2]] 'Divider_TrackLayout',
--[[3]] 'Divider_TrackColor',
--[[4]] 'Divider_TrackRecolor',
--[[5]] 'Folder_TrackHeight',
--[[6]] 'Folder_TrackLayout',
--[[7]] 'Folder_TrackColor',
--[[8]] 'Folder_TrackRecolor',
--[[9]] 'Bus_TrackHeight',
--[[10]] 'Bus_TrackLayout',
--[[11]] 'Bus_TrackColor',
--[[12]] 'Bus_TrackRecolor',
--[[13]] 'DividerSymbol',
--[[14]] 'Overrides'
}

-- Default values for all settings
tvm.Defaults = {
    [tvm.Settings[1]] = 40,
    [tvm.Settings[2]] = 'A - NO CONTROL',
    [tvm.Settings[3]] = '65508',
    [tvm.Settings[4]] = 'true',
    [tvm.Settings[5]] = 28,
    [tvm.Settings[6]] = 'A - COLOR FULL',
    [tvm.Settings[7]] = '65420',
    [tvm.Settings[8]] = 'true',
    [tvm.Settings[9]] = 28,
    [tvm.Settings[10]] = 'A - COLOR FULL',
    [tvm.Settings[11]] = '36095',
    [tvm.Settings[12]] = 'true',
    [tvm.Settings[13]] = '<',
    [tvm.Settings[14]] = 'Video*16776960'
}

----------------------------------------
--Track Visuals Manager Functions
----------------------------------------
function tvm.GetAllExtValues()
    local ExtVals = {}
    for key, name in ipairs(tvm.Settings) do
        if not r.HasExtState(tvm.ExtSection, name) then
            r.SetExtState(tvm.ExtSection, name, tostring(tvm.Defaults[name]), true)
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        else
            ExtVals[name] = r.GetExtState(tvm.ExtSection, name)
        end
    end
    return ExtVals
end

function tvm.SetExtValue(name, val)
    for index, setting in ipairs(tvm.Settings) do
        if setting == name then
            r.SetExtState(tvm.ExtSection, name, tostring(val), true)
        end
    end
end

function tvm.GetExtValue(name)
    for index, setting in ipairs(tvm.Settings) do
        if setting == name then
            return r.GetExtState(tvm.ExtSection, name)
        end
    end
end

function tvm.ResetAllExtValues()
    for i, name in pairs(tvm.Settings) do
        r.SetExtState(tvm.ExtSection, name, tvm.Defaults[name], true)
    end
end

function tvm.SetAllExtValues(table)
    for name, value in pairs(table) do
        r.SetExtState(tvm.ExtSection, name, value, true)
    end
end

function tvm.GetOverrides() -- Returns a table that whose values are single entry tables where key = track name, value = color
    local s = tvm.GetExtValue('Overrides')
    local overrides = {}
    for val in s:gmatch('([^,]+)') do
        local pair = {}
        local key
        local i = 1
        for text in val:gmatch('([^*]+)') do
            if i == 1 then
                key = text
            else
                pair[key] = text
            end
            i = i + 1
        end
        overrides[#overrides + 1] = pair
    end
    return overrides
end

function tvm.SetOverrides(t)
    local list
    for i, override in ipairs(t) do
        local pair
        for name, color in pairs(override) do
            pair = name .. '*' .. color
        end
        if not list then
            list = pair
        else
            list = list .. ',' .. pair
        end
    end
    tvm.SetExtValue('Overrides', list)
end

--[[
## Returns whether or not a track can be classified as a divider track.

### returns
**_bool_**
]]
function tvm.IsDividerTrack(track)
    local _, name = r.GetTrackName(track)
    name = string.gsub(name, ' ', '')
    return string.sub(name, 1, 1) == tvm.GetExtValue('DividerSymbol')
end

----------------------------------------

----------------------------------------
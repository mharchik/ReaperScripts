----------------------------------------
-- @description Mousewheel - Zoom Horizontally Dynamic
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about	This script should be bound to mousewheel. 
--			Zooms the arrange window in and out horizontally, adjusting the center point based on how far you are zoomed in/out.
--			When view is wider the zoom will focus on the center of either the active time selection, or of all onscreen selected items. 
--			As zoom moves in closer, the focus will shift towards the edit cursor position.
--			If there are no item/time selections, the zoom will default to always focusing on the edit cursor.
----------------------------------------
--Setup
----------------------------------------
r = reaper
local val = ({ r.get_action_context() })[7]	--This has to be the first thing in the script to correctly get the mousewheel direction
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not r.HasExtState(scriptName, 'firstrun') then r.SetExtState(scriptName, 'firstrun', 'true', true) r.ShowMessageBox('This script is intended to be used with the zoom preferences set to "Horizontal zoom center: Center of view". \n\n You can set this value in the REAPER Preferences under "Appearance > Zoom/Scroll/Offset"', 'Script Info', 0) end
----------------------------------------
--User Settings
----------------------------------------
local ZoomAmount = 3   --Higher values increase the strength of the zoom in/out
local CursorOffsetAmount = 40 --(0-100) This affects how far to the left the edit cursor will shift when focused on it. 0 will be the default center of the screen, while 100 will be full to the left edge of the screen 
----------------------------------------
--Functions
----------------------------------------

--Changes the zoom center point based on how close you're zooming in.
function FindZoomCenter()
	local cursorPos = r.GetCursorPosition()
	local focus
	local focusLength
	--getting the positions and lengths of the different elements of the arrange view
	local curStart, curEnd = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local arrlength = curEnd - curStart
	--getting the size of any selected items
	local itemsLength, itemsCenter = 0, 0
	local retval, itemsStart, itemsEnd = mh.GetVisibleSelectedItemsSize()
	if retval then
		itemsLength = itemsEnd - itemsStart
		itemsCenter = (itemsStart + itemsEnd) / 2
	end
	--getting the size of any time selection
	local timeSelStart, timeSelEnd = r.GetSet_LoopTimeRange(false, false, 0, 0, false)
	local timeSelLength = timeSelEnd - timeSelStart
	local timeSelCenter = (timeSelEnd + timeSelStart)/2
	local curOffset = GetCursorOffset()
	--Setting the center of our zoom point based on what exists/is on screen. Priority is Time selection > Item Selection > Edit Cursor > Center of View
	if timeSelCenter > curStart and timeSelCenter < curEnd then
		focus = timeSelCenter
		focusLength = timeSelLength
	elseif itemsCenter > curStart and itemsCenter < curEnd then
		focus = itemsCenter
		focusLength = itemsLength
	elseif cursorPos > curStart and cursorPos < curEnd then
		focus = cursorPos
		focusLength = arrlength
	else
		focus = curStart + arrlength/2
		focusLength = arrlength
	end
	--zoomBias will be the scaling amount that the zoom shifts from our zoomed out target to our edit cursor. 
	local zoomBias = (1 - focusLength/ arrlength) * 2
	--some vaguely questionable math above but this clamps the value so that we can reliably scale our final output
	if zoomBias > 1 then
		zoomBias = 1
	elseif zoomBias < 0 then
		zoomBias = 0
	end
	-- Centering the view on the cursor plus the scaled distance to our zoomed out center point. We also add the cursor offset which is scaled opposite from the zoomedOutCenter so that it only starts affecting our positioning when zooming in on the actual edit cursor
 	local center = cursorPos + (focus - cursorPos) * zoomBias + curOffset * (1 - zoomBias)
	return center
end

function Zoom()
	if val < 0 then
		ZoomAmount = ZoomAmount * -1
	end
	r.CSurf_OnZoom(ZoomAmount, 0)
end

function MoveToNewCenter(pos)
	local curStart, curEnd = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local newStart = pos - (curEnd - curStart) / 2
	local newEnd = pos + (curEnd - curStart) / 2
	--if new start is past the edge of the screen, shift it to the right until it starts at 0
	if newStart < 0 then
		newEnd = newEnd - newStart
		newStart = 0
	end
	r.GetSet_ArrangeView2(0, true, 0, 0, newStart, newEnd)
end

--Gets the optional offset for how much to the left we want to shift the edit cursor when zooming on it
function GetCursorOffset()
	local curStart, curEnd = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local arrlength = curEnd - curStart
	return (arrlength/2)*(CursorOffsetAmount/100)
end

function Main()

	Zoom()
	local zoomCenter = FindZoomCenter()
	MoveToNewCenter(zoomCenter)
	mh.noundo()
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
r.PreventUIRefresh(1)
Main()
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Mousewheel - Zoom Horizontally Dynamic
-- @author Max Harchik
-- @version 1.0
-- @about	This script should be bound to mousewheel. 
--			Zooms the arrange window in and out horizontally adjusting the center point based on how far you are zoomed in/out.
--			When view is wider the zoom will focus on the center of all selected items. As zoom moves in closer, the focus will shift towards the edit cursor position.
--			If no items are selected zoom will default to focusing on the edit cursor.
----------------------------------------
--Setup
----------------------------------------
local val = ({ reaper.get_action_context() })[7]	--This has to be the first thing in the script to correctly get the mousewheel direction
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
if not reaper.HasExtState(scriptName, "firstrun") then reaper.SetExtState(scriptName, "firstrun", "true", true) reaper.ShowMessageBox("This script is intended to be used with the zoom preferences set to 'Horizontal zoom center: Center of view'. \n\n You can set this value in the REAPER Preferences under 'Appearance > Zoom/Scroll/Offset'", "Script Info", 0) end
----------------------------------------
--User Settings
----------------------------------------
local ZoomAmount = 2   --Higher values increase the strength of the zoom in/out
----------------------------------------
--Functions
----------------------------------------

--This shifts the zoom point based on how close you're zooming in on your selected items. As you get closer to the items, zoom will start to shift towards the edit cursor instead
function FindZoomCenter(itemsStart, itemsEnd, cursorPos)
	local zoomedOutCenter
	local zoomCenterLength

	--getting the positions and lengths of the different elements of the arrange view
	local curStart, curEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local arrlength = curEnd - curStart
	local itemsLength = itemsEnd - itemsStart
	local itemsCenter = (itemsStart + itemsEnd) / 2
	local timeStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
	local timeLength = timeSelEnd - timeStart
	local timeCenter = (timeSelEnd + timeStart)/2

	--Setting the center of our zoom point based on what exists/is on screen. Priority is Time selection > Item Selection > Edit Cursor > Center of View
	if timeCenter > curStart and timeCenter < curEnd then
		zoomedOutCenter = timeCenter
		zoomCenterLength = timeLength
	elseif itemsCenter > curStart and itemsCenter < curEnd then
		zoomedOutCenter = itemsCenter
		zoomCenterLength = itemsLength
	elseif cursorPos > curStart and cursorPos < curEnd then
		zoomedOutCenter = cursorPos
		zoomCenterLength = arrlength
	else
		zoomedOutCenter = curStart + arrlength/2
		zoomCenterLength = arrlength
	end

	local zoomBias = math.log(arrlength / zoomCenterLength, 5)
	--some questionable math above but this clamps the value so that we can more reliably scale our final output
	if zoomBias > 1 then
		zoomBias = 1
	elseif zoomBias < 0 then
		zoomBias = 0
	end
	-- point when zoomed in + the extra space between the cursor and the center of selected items scaled by zoomBias + how much we're to the left we're going to shift that point when zoomed in
 	local center = cursorPos + (zoomedOutCenter - cursorPos) * zoomBias + (arrlength / 5) * (1 - zoomBias)
	
	return center
end

function Zoom(pos)
	if val < 0 then
		ZoomAmount = ZoomAmount * -1
	end
	reaper.CSurf_OnZoom(ZoomAmount, 0)
	local curStart, curEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local newStart = pos - (curEnd - curStart) / 2
	local newEnd = pos + (curEnd - curStart) / 2
	--if new start is past the edge of the screen, shift it to the right until it starts at 0
	if newStart < 0 then
		newEnd = newEnd - newStart
		newStart = 0
	end
	reaper.GetSet_ArrangeView2(0, true, 0, 0, newStart, newEnd)
end

function Main()
	local cursorPos = reaper.GetCursorPosition()
	local retval, itemsStart, itemsEnd = mh.GetVisibleSelectedItemsSize()
	if retval then
		local zoomCenter = FindZoomCenter(itemsStart, itemsEnd, cursorPos)
		Zoom(zoomCenter)
	else
		Zoom(cursorPos)
	end
	reaper.defer(mh.noundo)
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

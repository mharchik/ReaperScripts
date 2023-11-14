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
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
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
	local zoomedInCenter
	local zoomedOutCenter

	local curStart, curEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local arrlength = curEnd - curStart
	local itemsLength = itemsEnd - itemsStart
	local itemsCenter = (itemsStart + itemsEnd) / 2

	--setting our zoom points based on whats visible on screen
	if cursorPos > curStart and cursorPos < curEnd then
		zoomedInCenter = cursorPos
	elseif itemsStart > curStart and itemsStart < curEnd then
		zoomedInCenter = itemsStart
	else
		zoomedInCenter = curStart + arrlength/2
	end

	if itemsCenter > curStart and itemsCenter < curEnd then
		zoomedOutCenter = itemsCenter
	elseif cursorPos > curStart and cursorPos < curEnd then
		zoomedOutCenter = cursorPos
	else
		zoomedOutCenter = curStart + arrlength/2
	end

	local zoomBias = math.log(arrlength / itemsLength, 5)
	--some questionable math above but this clamps the value so that we can more reliably scale our final output
	if zoomBias > 1 then
		zoomBias = 1
	elseif zoomBias < 0 then
		zoomBias = 0
	end
	-- (point when zoomed in) + (point when zoomed out - point when zoomed in) * zoomBias + (how much we're to the left we're going to shift that point when zoomed in)
	return zoomedInCenter + (zoomedOutCenter - zoomedInCenter) * zoomBias + (arrlength / 8) * (1 - zoomBias)
end

function Zoom(pos)
	local curStart, curEnd = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	local newStart = pos - (curEnd - curStart) / 2
	local newEnd = pos + (curEnd - curStart) / 2
	reaper.GetSet_ArrangeView2(0, true, 0, 0, newStart, newEnd)

	if val < 0 then
		ZoomAmount = ZoomAmount * -1
	end
	reaper.CSurf_OnZoom(ZoomAmount, 0)
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

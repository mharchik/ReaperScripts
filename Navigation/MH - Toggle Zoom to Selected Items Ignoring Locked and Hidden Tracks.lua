----------------------------------------
-- @description Toggle Zoom to Selected Items Ignoring Locked and Hidden Tracks
-- @author Max Harchik
-- @version 1.0
-- @about Zooms arrange view to selected items while accounting for height locked tracks and hidden/supercollapsed tracks, and minimizing empty tracks.
----------------------------------------
--Setup
----------------------------------------
r = reaper
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWSChecker() or not mh.JsChecker() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local ZOOM_EXTRA_SPACE = 10 --% of screen left visible on either side of the zoomed in items
local ZOOM_SENSITIVITY = 1  --in seconds, how much you can scroll after zooming in before script will zoom in again rather than zooming out
----------------------------------------
--Script Variables
----------------------------------------
local scaledTracks = {} --stores references to all of the tracks that will have their heights changed when zooming in.
local unscaledTracks = {} --stores references to all of the tracks that are height locked or will be set to the minium height
local scaledEnv = {} --tracks the envelope lanes that will have their heights changed when zooming in
local unscaledEnv = {} --tracks the envelope lanes that won't be changed when zooming in
local envZoomScale = 0.5 --how many pixels envelopes take up are in comparison to a track --stored in reaper.ini - envzoomscale
local minTrackHeight = 28
local minTrackHeightOverrides = { minRecArmHeight = 60 } --Add any situations for tracks where they can't be scaled down to the miniume track height
local spacerHeight = 16 --stored in reaper.ini - trackgapmax
local numOfSpacers = 0
----------------------------------------
--Functions
----------------------------------------
function GetTracks()
	--determining range of items/tracks that we need to check
	local selItemCount = r.CountSelectedMediaItems()
	local firstItem = r.GetSelectedMediaItem(0, 0)
	local firstTrack = r.GetMediaItem_Track(firstItem)
	local firstTrackNum = r.GetMediaTrackInfo_Value(firstTrack, "IP_TRACKNUMBER")
	local lastItem = r.GetSelectedMediaItem(0, selItemCount - 1)
	local lastTrack = r.GetMediaItem_Track(lastItem)
	local lastTrackNum = r.GetMediaTrackInfo_Value(lastTrack, "IP_TRACKNUMBER")

	--check each track to see what settings it has that affect what height we can zoom it to
	for i = 0, lastTrackNum - firstTrackNum do
		local track = r.GetTrack(0, firstTrackNum + i - 1)
		local trackHeight = r.GetMediaTrackInfo_Value(track, "I_TCPH")
		local isLocked = r.GetMediaTrackInfo_Value(track, "B_HEIGHTLOCK")
		local isRecArm = r.GetMediaTrackInfo_Value(track, "I_RECARM")
		local numItems = r.CountTrackMediaItems(track)
		local isVisible = r.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
		if r.GetMediaTrackInfo_Value(track, "I_SPACER") == 1 then
			if i > 0 then --ignores spacer if its at the very top of the selection, since we'll just be scrolling down past it anyways
				numOfSpacers = numOfSpacers + 1
			end
		end

		--Checking if track actually has any items on it that are part of our selection. This ignores Empty items like folder items
		local isActiveTrack = false
		for j = 0, numItems - 1 do
			local itemOnTrack = r.GetTrackMediaItem(track, j)
			if r.IsMediaItemSelected(itemOnTrack) then
				if not mh.IsFolderItem(itemOnTrack) then
					isActiveTrack = true
				end
			end
		end

		-- Checking if has an envelopes that are actually visible and not displayed in the same lane as the track
		local numEnvs = r.CountTrackEnvelopes(track)
		if numEnvs > 0 then
			local ignoreEnvs = 0
			for j = 0, numEnvs - 1 do
				local env = r.GetTrackEnvelope(track, j)
				local envTCPY = r.GetEnvelopeInfo_Value(env, "I_TCPY")
				local envTCPH = r.GetEnvelopeInfo_Value(env, "I_TCPH")
				local envTCPH_Used = r.GetEnvelopeInfo_Value(env, "I_TCPH_USED")
				if envTCPH > envTCPY or envTCPH_Used == 0 then --if envTCPH > envTCPY that means the envelope is being displayed in the media lane and we don't need to scale it.
					ignoreEnvs = ignoreEnvs + 1
				end
			end
			numEnvs = numEnvs - ignoreEnvs
		end

		--Storing which tracks we actually want to zoom and which ones will stay at a minimum/locked height
		if trackHeight > 0 and isVisible then
			if isLocked == 0 and isActiveTrack then --if a track isn't locked and does have items on it we're zooming too, we'll want to scale that track's height later
				if isRecArm == 1 then
					scaledTracks[track] = minTrackHeightOverrides["minRecArmHeight"] --storing the minium record armed height for this track. We'll need this later if later we find out we wanted to scale this track to be too small.
					for j = 1, numEnvs do
						scaledEnv[#scaledEnv + 1] = minTrackHeightOverrides["minRecArmHeight"] --storing the minium record armed height for this track's envelope lane. We'll need this later if later we find out we wanted to scale this track to be too small.
					end
				else
					scaledTracks[track] = 0 --any tracks that we store with a height of 0 we can assume later that it's fine to scale to what ever height we want.
					for j = 1, numEnvs do
						scaledEnv[#scaledEnv + 1] = 0 --any envelope lanes that we store with a height of 0 we can assume later that it's fine to scale to what ever height we want.
					end
				end
			else
				if isLocked > 0 then --if a track is locked we'll save its current height
					unscaledTracks[track] = trackHeight
					for j = 1, numEnvs do
						unscaledEnv[#unscaledEnv + 1] = trackHeight
					end
				else --if the track is unlocked and doesn't have any items that we care about on it, we'll store it's height as being the minimum track height
					unscaledTracks[track] = minTrackHeight
					for j = 1, numEnvs do
						unscaledEnv[#unscaledEnv + 1] = minTrackHeight
					end
				end
			end
		end
	end
	return firstTrack --returning the track that we'll need to scroll to later
end

function CalculateTrackHeights()
	local _, _, top, _, bottom = r.JS_Window_GetClientRect(r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000))
	local arrangeViewHeight = bottom - top
	--grabbing the total height of all locked tracks or tracks that will be minimized.
	local newHeight = 0
	local unscaledTracksHeight = 0
	for _, height in pairs(unscaledTracks) do
		unscaledTracksHeight = unscaledTracksHeight + height
	end
	--grabbing the total height of any envelope lanes that won't have their height changed.
	local unscaledEnvHeight = 0
	for _, height in pairs(unscaledEnv) do
		unscaledEnvHeight = unscaledEnvHeight + height
	end
	--grabbing the total number of tracks we need to scale
	local scaledTrackCount = 0
	for _, _ in pairs(scaledTracks) do
		scaledTrackCount = scaledTrackCount + 1
	end
	--grabbing the total number of envelopes that we'll need to scale
	local scaledEnvCount = 0
	for _, _ in pairs(scaledEnv) do
		scaledEnvCount = scaledEnvCount + 1
	end
	-- the new track height is the total height of the arrangeView, not counting any space taken up by tracks/envelopes/spaces that can't be scaled, divided by the number of tracks/envelopes that we're going to have scale across that space.
	newHeight = (arrangeViewHeight - unscaledTracksHeight - unscaledEnvHeight * envZoomScale - numOfSpacers * spacerHeight) / (scaledTrackCount + scaledEnvCount * envZoomScale)

	-- if we have any special situations where a track can't get as small as our newHeight, we'll recalculate with that track's minimum possible height included
	local shouldRecalculate = false
	for key, height in pairs(minTrackHeightOverrides) do
		if newHeight < height then
			shouldRecalculate = true
		end
	end

	if shouldRecalculate then
		--checking each of our tracks to see if their stored minimum heights are less than the new height we just calculated. If so, we know the exact height of that track will be set to, and we can treat them as an unscaled track and subtract their height from the total arrange vew height
		scaledTrackCount = 0
		for track, height in pairs(scaledTracks) do
			if height > newHeight then
				unscaledTracksHeight = unscaledTracksHeight + height
			else
				scaledTrackCount = scaledTrackCount + 1
			end
		end
		--doing the same as above but with the envelope lanes this time
		scaledEnvCount = 0
		for env, height in pairs(scaledEnv) do
			if height > newHeight then
				unscaledEnvHeight = unscaledEnvHeight + height
			else
				scaledEnvCount = scaledEnvCount + 1
			end
		end
		--now we redo our 
		newHeight = (arrangeViewHeight - unscaledTracksHeight - unscaledEnvHeight * envZoomScale - numOfSpacers * spacerHeight) / (scaledTrackCount + scaledEnvCount * envZoomScale)
	end

	--if we're trying to scale any tracks to be smaller than they can be, we'll just default to using the default minimum and be fine with some tracks being off screen
	if newHeight < minTrackHeight then
		newHeight = minTrackHeight
	end
	return newHeight
end

function SetTrackHeights(newHeight)
	--setting the heights of all of our scaledtracks
	for track, savedHeight in pairs(scaledTracks) do
		--if we didn't save any height with the tracks earlier we can safely scale, or if the height we saved is less than the height we're scaling too, then we can scale the track height safely
		if savedHeight == 0 or savedHeight <= newHeight then
			r.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", newHeight)
		else --otherwise we need to fall back to the saved height
			r.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", savedHeight)
		end
	end
	--setting the heights of all of our unscaled tracks. locked tracks will just be set to the same height they're currently at, and unlocked tracks will be set to the minimume height.
	for track, savedHeight in pairs(unscaledTracks) do
		r.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", savedHeight)
	end
end

--Getting the bounds of where we'll zoom our arrange view 
function GetHorizontalZoomAmount(itemsStart, itemsEnd)
	local zoomChange = ((itemsStart - itemsEnd) * (ZOOM_EXTRA_SPACE / 100))
	local newStart = itemsStart + zoomChange
	local newEnd = itemsEnd - zoomChange
	return newStart, newEnd
end

--Checking if zoom wil actually move our view by any significant amount.
function DecideIfShouldZoom(firstTrack, newTrackHeight, newStart, newEnd)
	local tcpy = r.GetMediaTrackInfo_Value(firstTrack, "I_TCPY") --grabbing the position of the top track in our selection
	local curStart, curEnd = r.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
	--checking if the current start and end are close to what we would zoom to, if the top track is already at the top of the arrange view. If all of that is already true then we don't need to zoom in again and we'll zoom out instead later
	if CheckIfNumsAreClose(curStart, newStart) and CheckIfNumsAreClose(curEnd, newEnd) and CheckIfNumsAreClose(tcpy, 0) then
		return false
	else
		return true
	end
end

function ZoomIn(firstTrack, zoomStart, zoomEnd, itemsStart)
	--Zoom the arrange view to our new start and end
	r.GetSet_ArrangeView2(0, true, 0, 0, zoomStart, zoomEnd)
	--find the top track and scroll the arrange view down to the top of it
	local tcpy = r.GetMediaTrackInfo_Value(firstTrack, "I_TCPY")
	local arrangeView = r.JS_Window_FindChildByID(r.GetMainHwnd(), 1000)
	local retval, pos, _, _, _, _ = r.JS_Window_GetScrollInfo(arrangeView, "v")
	local newScroll = tcpy + pos
	if retval then
		r.JS_Window_SetScrollPos(arrangeView, "v", newScroll)
	end
	--Moving edit cursor to start of items as well
	r.SetEditCurPos(itemsStart, false, false)
end

function ZoomOut()
	r.Main_OnCommandEx(r.NamedCommandLookup("_SWS_UNDOZOOM"), 1, 0) -- calls action "View: Restore previous zoom/scroll position"
end

function CheckIfNumsAreClose(x, y)
	if math.abs(x - y) <= ZOOM_SENSITIVITY then
		return true
	else
		return false
	end
end

function Main()
	local retval, itemsStart, itemsEnd = mh.GetVisibleSelectedItemsSize()
	if not retval then mh.noundo() return end --if no items are selected we'll exit without creating any undo state
	local firstTrack = GetTracks()
	local zoomStart, zoomEnd = GetHorizontalZoomAmount(itemsStart, itemsEnd)
	local newTrackHeight = CalculateTrackHeights()
	local shouldZoom = DecideIfShouldZoom(firstTrack, newTrackHeight, zoomStart, zoomEnd)
	if shouldZoom then
		SetTrackHeights(newTrackHeight)
		r.TrackList_AdjustWindows(true) --need to refresh view in order to get an updated values for the arrange view dimensions/scroll position
		ZoomIn(firstTrack, zoomStart, zoomEnd, itemsStart)
	else
		ZoomOut()
	end
    mh.noundo() --used to avoid creating any undo state
end
----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
Main()
r.TrackList_AdjustWindows(true)

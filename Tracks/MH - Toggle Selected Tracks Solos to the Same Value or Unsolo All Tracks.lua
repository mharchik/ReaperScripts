----------------------------------------
-- @description Toggle Selected Tracks Solos to the Same Value or Unsolo All Tracks
-- @author Max Harchik
-- @version 1.0
-- @about	Toggles all selected track solos together, unsoloing any unselected tracks. If selected tracks are a mixture of soloed and unsoloed it will solo first. 
--			If only unsoloed tracks are selected and any unselected tracks are still soloed, it will unsolo all tracks
--			If parent track is muted it will solo that as well
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
----------------------------------------
--Functions
----------------------------------------
function SetSelectedTrackSolos(selTrackCount, solo)
	for i = 0, selTrackCount - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		reaper.SetMediaTrackInfo_Value(selTrack, "I_SOLO", solo)
		local selTrackDepth = reaper.GetTrackDepth(selTrack)
		while selTrackDepth > 0 do
			selTrack = reaper.GetParentTrack(selTrack)
			if reaper.GetMediaTrackInfo_Value(selTrack, "B_MUTE") == 1 then
				reaper.SetMediaTrackInfo_Value(selTrack, "I_SOLO", solo)
			end
			selTrackDepth = reaper.GetTrackDepth(selTrack)
		end
	end
end

function SetAllTrackSolos(trackCount, solo)
	for i = 0, trackCount - 1 do
		local selTrack = reaper.GetTrack(0, i)
		reaper.SetMediaTrackInfo_Value(selTrack, "I_SOLO", solo)
	end
end

function Main()
	local isAnySelTrackUnsolo = false
	local isAnySelTrackSolo = false
	local selTrackCount = reaper.CountSelectedTracks(0)
	if selTrackCount == 0 then return end
	for i = 0, selTrackCount - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		local trackSoloState = reaper.GetMediaTrackInfo_Value(selTrack, "I_SOLO")
		if trackSoloState == 0 then
			isAnySelTrackUnsolo = true
		else
			isAnySelTrackSolo = true
		end
	end

	local isAnyTrackSolo = false
	local trackCount = reaper.CountTracks(0)
	for i = 0, trackCount - 1 do
		local track = reaper.GetTrack(0, i)
		local trackSoloState = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
		if trackSoloState > 0 then
			if not reaper.IsTrackSelected(track) then
				isAnyTrackSolo = true
				break
			end
		end
	end

	if isAnySelTrackUnsolo then
		if isAnySelTrackSolo then
			SetAllTrackSolos(trackCount, 0)
			SetSelectedTrackSolos(selTrackCount, 2) --2 sets "Solo In Place" which will retain any sends you have active on the track
		elseif isAnyTrackSolo then
			SetAllTrackSolos(trackCount, 0)
		else
			SetSelectedTrackSolos(selTrackCount, 2)
		end
	else
		SetAllTrackSolos(trackCount, 0)
	end
end

----------------------------------------
--Main
----------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

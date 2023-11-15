----------------------------------------
-- @description Toggle Selected Tracks Solos to the Same Value or Unsolo All Tracks
-- @author Max Harchik
-- @version 1.0
-- @about	Solos all seleted tracks, If selected tracks are a mixture of soloed and unsoloed it will solo first. 
--			if any unselected tracks are soloed, it will unsolo those tracks
--			If parent track is muted it will solo that as well
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
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

function SetAllTrackSolos(solo)
	local trackCount = reaper.CountTracks(0)
	for i = 0, trackCount - 1 do
		local selTrack = reaper.GetTrack(0, i)
		reaper.SetMediaTrackInfo_Value(selTrack, "I_SOLO", solo)
	end
end

function Main()
	local isAnySelTrackUnsolo = false
	local soloSelTracks = {}
	local selTrackCount = reaper.CountSelectedTracks(0)
	if selTrackCount == 0 then return end
	for i = 0, selTrackCount - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		local trackSoloState = reaper.GetMediaTrackInfo_Value(selTrack, "I_SOLO")
		if trackSoloState == 0 then
			isAnySelTrackUnsolo = true
		else
			--Save track for later
			soloSelTracks[#soloSelTracks+1] = selTrack
			--Also grabbing all of that track's parents
			local selTrackDepth = reaper.GetTrackDepth(selTrack)
			while selTrackDepth > 0 do
				selTrack = reaper.GetParentTrack(selTrack)
				selTrackDepth = reaper.GetTrackDepth(selTrack)
				soloSelTracks[#soloSelTracks+1] = selTrack
			end
		end
	end
	--Checking to see if any unselected tracks are soloed.
	local isAnyOtherTrackSolo = false
	local trackCount = reaper.CountTracks(0)
	for i = 0, trackCount - 1 do
		local ignoreTrack = false
		local track = reaper.GetTrack(0, i)
		local trackSoloState = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
		if trackSoloState > 0 then
			--if the track is selected or a parent of a selected track, we don't need to check it
			for key, selTrack in ipairs(soloSelTracks) do
				if track == selTrack then
					ignoreTrack = true
				end
			end
			if not ignoreTrack then
				isAnyOtherTrackSolo = true
			end
		end
	end
	if isAnySelTrackUnsolo or isAnyOtherTrackSolo then
		SetAllTrackSolos(0)
		SetSelectedTrackSolos(selTrackCount, 2) --2 sets "Solo In Place" which will retain any sends you have active on the track
	else
		SetAllTrackSolos(0)
	end
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

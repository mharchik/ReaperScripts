----------------------------------------
-- @description Toggle Selected Tracks Mutes to the Same Value
-- @author Max Harchik
-- @version 1.0
-- @about Toggles all selected track mutes together. If unmuted tracks are selected it will mute first, otherwise it'll unmute.
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
----------------------------------------
--Functions
----------------------------------------
function Main()
	local isAnyTrackUnmuted = false
	local selCountTrack = reaper.CountSelectedTracks(0)
	if selCountTrack == 0 then return end
	for i = 0, selCountTrack - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		local TrackMuteState = reaper.GetMediaTrackInfo_Value(selTrack, "B_MUTE")
		if TrackMuteState == 0 then
			isAnyTrackUnmuted = true
			break
		end
	end
	if isAnyTrackUnmuted then
		SetTrackMutes(selCountTrack, 1)
	else
		SetTrackMutes(selCountTrack, 0)
	end
end

function SetTrackMutes(selCountTrack, mute)
	for i = 0, selCountTrack - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		reaper.SetMediaTrackInfo_Value(selTrack, "B_MUTE", mute)
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

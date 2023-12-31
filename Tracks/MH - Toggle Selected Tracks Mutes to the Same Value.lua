----------------------------------------
-- @description Toggle Selected Tracks Mutes to the Same Value
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about Toggles all selected track mutes together. If unmuted tracks are selected it will mute first, otherwise it'll unmute.
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
	local isAnyTrackUnmuted = false
	local selCountTrack = r.CountSelectedTracks(0)
	if selCountTrack == 0 then return end
	for i = 0, selCountTrack - 1 do
		local selTrack = r.GetSelectedTrack(0, i)
		local TrackMuteState = r.GetMediaTrackInfo_Value(selTrack, 'B_MUTE')
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
		local selTrack = r.GetSelectedTrack(0, i)
		r.SetMediaTrackInfo_Value(selTrack, 'B_MUTE', mute)
	end
end

----------------------------------------
--Main
----------------------------------------
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

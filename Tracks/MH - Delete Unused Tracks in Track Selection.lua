----------------------------------------
-- @description Delete Unused Tracks in Track Selection
-- @author Max Harchik
-- @version 1.0
-- @about Looks at your selected tracks for any tracks that are unused and deletes them
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function CheckIfChildrenActive(track)
	local depth = r.GetTrackDepth(track)
	local trackNum = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
	local i = 1
	local nextDepth = depth + 1
	while nextDepth > depth do
		local nextTrack = r.GetTrack(0, trackNum + i)
		nextDepth = r.GetTrackDepth(nextTrack)
		if r.CountTrackMediaItems(nextTrack) > 0 then
			return true
		end
		i = i + 1
	end
	return false
end

function IsTrackActive(track)
	if r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
		if CheckIfChildrenActive(track) then
			return true
		end
	elseif r.CountTrackMediaItems(track) > 0 then
		return true
	end
	return false
end

function Main()
	local selTrackCount = r.CountSelectedTracks()
	if selTrackCount == 0 then return end
	local toDelete = {}
	for i = 0, selTrackCount - 1 do
		local track = r.GetSelectedTrack(0, i)
		if not IsTrackActive(track) then
			toDelete[#toDelete + 1] = track
		end
	end
	if #toDelete > 0 then
		for index, track in ipairs(toDelete) do
			--Checking folder depth first to make sure tracks below the ones we're deleting aren't getting moved into folders by accident
			local trackDepth = r.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
			if trackDepth < 0 then
				local trackNum = r.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
				local prevTrack = r.GetTrack(0, trackNum - 2)
				r.SetTrackSelected(prevTrack, true)
				local prevTrackDepth = r.GetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH")
				r.SetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH", prevTrackDepth + trackDepth)
			end
			r.DeleteTrack(track)
		end
	end
end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.TrackList_AdjustWindows(true)

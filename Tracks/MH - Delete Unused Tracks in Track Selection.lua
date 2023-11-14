----------------------------------------
-- @description Delete Unused Tracks in Track Selection
-- @author Max Harchik
-- @version 1.0
-- @about Looks at your selected tracks for any tracks that are unused and deletes them
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function CheckIfChildrenActive(track)
	local depth = reaper.GetTrackDepth(track)
	local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
	local i = 1
	local nextDepth = depth + 1
	while nextDepth > depth do
		local nextTrack = reaper.GetTrack(0, trackNum + i)
		nextDepth = reaper.GetTrackDepth(nextTrack)
		if reaper.CountTrackMediaItems(nextTrack) > 0 then
			return true
		end
		i = i + 1
	end
	return false
end

function IsTrackActive(track)
	if reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") == 1 then
		if CheckIfChildrenActive(track) then
			return true
		end
	elseif reaper.CountTrackMediaItems(track) > 0 then
		return true
	end
	return false
end

function Main()
	local selTrackCount = reaper.CountSelectedTracks()
	if selTrackCount == 0 then return end
	local toDelete = {}
	for i = 0, selTrackCount - 1 do
		local track = reaper.GetSelectedTrack(0, i)
		if not IsTrackActive(track) then
			toDelete[#toDelete + 1] = track
		end
	end
	if #toDelete > 0 then
		for index, track in ipairs(toDelete) do
			--Checking folder depth first to make sure tracks below the ones we're deleting aren't getting moved into folders by accident
			local trackDepth = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
			if trackDepth < 0 then
				local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
				local prevTrack = reaper.GetTrack(0, trackNum - 2)
				reaper.SetTrackSelected(prevTrack, true)
				local prevTrackDepth = reaper.GetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH")
				reaper.SetMediaTrackInfo_Value(prevTrack, "I_FOLDERDEPTH", prevTrackDepth + trackDepth)
			end
			reaper.DeleteTrack(track)
		end
	end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(true)

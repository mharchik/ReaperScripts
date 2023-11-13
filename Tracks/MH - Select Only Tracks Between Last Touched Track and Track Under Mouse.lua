----------------------------------------
-- @description Select Only Tracks Between Last Touched Track and Track Under Mouse
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
----------------------------------------
--Functions
----------------------------------------
function Main()
	local nextTrack = reaper.BR_TrackAtMouseCursor
	local prevTrack = reaper.GetLastTouchedTrack()
	if not nextTrack or not prevTrack then return end
	local trackCount = reaper.CountTracks(0)
	for i = 0, trackCount - 1 do
		reaper.SetTrackSelected(reaper.GetTrack(0, i), false)
	end
	local prevTrackNum = reaper.GetMediaTrackInfo_Value(prevTrack, "IP_TRACKNUMBER")
	local newTrackNum = reaper.GetMediaTrackInfo_Value(nextTrack, "IP_TRACKNUMBER")
	local startIndex = 0
	if prevTrackNum > newTrackNum then
		startIndex = newTrackNum - 1
	else
		startIndex = prevTrackNum - 1
	end
	for i = 0, math.abs(prevTrackNum - newTrackNum) do
		reaper.SetTrackSelected(reaper.GetTrack(0, startIndex + i), true)
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
reaper.UpdateArrange()

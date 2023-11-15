----------------------------------------
-- @description Select Only Tracks Between Last Touched Track and Track Under Mouse
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
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

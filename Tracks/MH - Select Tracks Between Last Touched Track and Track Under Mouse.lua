----------------------------------------
-- @description Select Tracks Between Last Touched Track and Track Under Mouse
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
	local x, y = reaper.GetMousePosition()
	local newTrack = reaper.GetTrackFromPoint(x, y)
	local prevTrack = reaper.GetLastTouchedTrack()
	if not newTrack or not prevTrack then return end
	local prevTrackNum = reaper.GetMediaTrackInfo_Value(prevTrack, "IP_TRACKNUMBER")
	local newTrackNum = reaper.GetMediaTrackInfo_Value(newTrack, "IP_TRACKNUMBER")
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

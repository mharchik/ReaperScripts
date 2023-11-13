----------------------------------------
-- @noindex
-- @description Add Track Under Mouse To Selection
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
	local prevSelTracks = {}
	local selTrackCount = reaper.CountSelectedTracks(0)
	if selTrackCount > 0 then
		for i = 0, selTrackCount - 1 do
			prevSelTracks[#prevSelTracks + 1] = reaper.GetSelectedTrack(0, i)
		end
	end
	local x, y = reaper.GetMousePosition()
	local track = reaper.GetTrackFromPoint(x, y)
	if not track then return end
	reaper.SetTrackSelected(track, true)
	for _, prevTrack in ipairs(prevSelTracks) do
		reaper.SetTrackSelected(prevTrack, true)
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

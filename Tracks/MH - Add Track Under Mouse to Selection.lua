----------------------------------------
-- @noindex
-- @description Add Track Under Mouse To Selection
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
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

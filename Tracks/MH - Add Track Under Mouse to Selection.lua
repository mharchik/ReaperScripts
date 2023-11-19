----------------------------------------
-- @noindex
-- @description Add Track Under Mouse To Selection
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
	local prevSelTracks = {}
	local selTrackCount = r.CountSelectedTracks(0)
	if selTrackCount > 0 then
		for i = 0, selTrackCount - 1 do
			prevSelTracks[#prevSelTracks + 1] = r.GetSelectedTrack(0, i)
		end
	end
	local x, y = r.GetMousePosition()
	local track = r.GetTrackFromPoint(x, y)
	if not track then return end
	r.SetTrackSelected(track, true)
	for _, prevTrack in ipairs(prevSelTracks) do
		r.SetTrackSelected(prevTrack, true)
	end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) r.ShowConsoleMsg(msg .. "\n") end

----------------------------------------
--Main
----------------------------------------
--reaper.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

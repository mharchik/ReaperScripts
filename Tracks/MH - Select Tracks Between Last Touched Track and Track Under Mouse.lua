----------------------------------------
-- @description Select Tracks Between Last Touched Track and Track Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--Functions
----------------------------------------
function Main()
	local nextTrack = r.BR_TrackAtMouseCursor()
	local prevTrack = r.GetLastTouchedTrack()
	if not nextTrack or not prevTrack then return end
	local prevTrackNum = r.GetMediaTrackInfo_Value(prevTrack, "IP_TRACKNUMBER")
	local newTrackNum = r.GetMediaTrackInfo_Value(nextTrack, "IP_TRACKNUMBER")
	local startIndex = 0
	if prevTrackNum > newTrackNum then
		startIndex = newTrackNum - 1
	else
		startIndex = prevTrackNum - 1
	end
	for i = 0, math.abs(prevTrackNum - newTrackNum) do
		r.SetTrackSelected(r.GetTrack(0, startIndex + i), true)
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
r.UpdateArrange()

----------------------------------------
-- @description Toggle Selected Top Level Folder Track Mutes to the Same Value
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function CheckIfChildrenActive()
	local tracks = {}
	local prevSelTracks = {}
	local countSelTrack = r.CountSelectedTracks(0)
	if countSelTrack == 0 then return end
	for i = 0, countSelTrack - 1 do
		local selTrack = r.GetSelectedTrack(0, i)
		local trackDepth = r.GetTrackDepth(selTrack) + 1
		if not tracks[trackDepth] then
			local folderLevel = {}
			tracks[trackDepth] = folderLevel
			table.insert(tracks[trackDepth], #tracks[trackDepth] + 1, selTrack)
		else
			table.insert(tracks[trackDepth], #tracks[trackDepth] + 1, selTrack)
		end
		prevSelTracks[i + 1] = selTrack
	end
	return tracks, prevSelTracks
end

function DeselectChildren(tracks)
	local i = 0
	for depth, setOfTracks in pairs(tracks) do
		if i == 0 then
			if #setOfTracks ~= 0 then
				i = i + 1
			end
		else
			for num, track in pairs(setOfTracks) do
				r.SetTrackSelected(track, false)
			end
		end
	end
end

function ReselectTracks(prevSelTracks)
	for i = 1, #prevSelTracks do
		r.SetTrackSelected(prevSelTracks[i], true)
	end
end

function ToggleTrackMutes()
	local isAnyTrackUnmuted = false
	local selTrackCount = r.CountSelectedTracks(0)
	if selTrackCount == 0 then return end
	for i = 0, selTrackCount - 1 do
		local selTrack = r.GetSelectedTrack(0, i)
		local trackMuteState = r.GetMediaTrackInfo_Value(selTrack, "B_MUTE")
		if trackMuteState == 0 then
			isAnyTrackUnmuted = true
			break
		end
	end
	if isAnyTrackUnmuted then
		SetTrackMutes(selTrackCount, 1)
	else
		SetTrackMutes(selTrackCount, 0)
	end
end

function SetTrackMutes(selTrackCount, mute)
	for i = 0, selTrackCount - 1 do
		local selTrack = r.GetSelectedTrack(0, i)
		r.SetMediaTrackInfo_Value(selTrack, "B_MUTE", mute)
	end
end

function Main()
	local tracks, prevSelTracks = CheckIfChildrenActive()
	DeselectChildren(tracks)
	ToggleTrackMutes()
	ReselectTracks(prevSelTracks)
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

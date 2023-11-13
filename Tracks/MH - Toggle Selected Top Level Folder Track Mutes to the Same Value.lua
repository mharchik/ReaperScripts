----------------------------------------
-- @description Toggle Selected Top Level Folder Track Mutes to the Same Value
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
----------------------------------------
--Functions
----------------------------------------
function CheckIfChildrenActive()
	local tracks = {}
	local prevSelTracks = {}
	local countSelTrack = reaper.CountSelectedTracks(0)
	if countSelTrack == 0 then return end
	for i = 0, countSelTrack - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		local trackDepth = reaper.GetTrackDepth(selTrack) + 1
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
				reaper.SetTrackSelected(track, false)
			end
		end
	end
end

function ReselectTracks(prevSelTracks)
	for i = 1, #prevSelTracks do
		reaper.SetTrackSelected(prevSelTracks[i], true)
	end
end

function ToggleTrackMutes()
	local isAnyTrackUnmuted = false
	local selTrackCount = reaper.CountSelectedTracks(0)
	if selTrackCount == 0 then return end
	for i = 0, selTrackCount - 1 do
		local selTrack = reaper.GetSelectedTrack(0, i)
		local trackMuteState = reaper.GetMediaTrackInfo_Value(selTrack, "B_MUTE")
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
		local selTrack = reaper.GetSelectedTrack(0, i)
		reaper.SetMediaTrackInfo_Value(selTrack, "B_MUTE", mute)
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

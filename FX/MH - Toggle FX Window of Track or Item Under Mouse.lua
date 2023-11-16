----------------------------------------
-- @description Toggle FX Window of Track or Item Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @about 	Opens the FX Chain window of what ever item/track you're mousing over, and closes all other fx windows. 
--			If an FX Chain window is already open, you can mouse over that window to just close without opening a new window.
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function CloseActiveFxWindows(screen_x, screen_y, selItem, selTrack)
	local didMouseOverlap = false
	local wasSelFxOpen = false
	local wasFxWindowActive = false
	local numOfTracks = reaper.CountTracks(0)
	if numOfTracks > 0 then
		for i = 0, numOfTracks - 1 do
			local wasSelTrackFxOpen = false
			local wasMouseOverlappingTrack = false
			local track = reaper.GetTrack(0, i)
			if selTrack then
				if track == selTrack then
					if reaper.TrackFX_GetChainVisible(selTrack) ~= -1 then
						wasSelTrackFxOpen = true
						wasSelFxOpen = true
					end
				end
			end
			local trackFxCount = reaper.TrackFX_GetCount(track)
			if trackFxCount > 0 then
				if reaper.TrackFX_GetChainVisible(track) ~= -1 then
					local win = reaper.CF_GetTrackFXChain(track)
					if CheckMouseOverlap(screen_x, screen_y, win) then
						didMouseOverlap = true
						wasMouseOverlappingTrack = true
					end
					if not wasSelTrackFxOpen or wasMouseOverlappingTrack then
						reaper.JS_Window_Destroy(win)
						wasFxWindowActive = true
					end
				end
				for j = 0, trackFxCount - 1 do
					local win = reaper.TrackFX_GetFloatingWindow(track, j)
					if win then
						if CheckMouseOverlap(screen_x, screen_y, win) then
							didMouseOverlap = true
							wasMouseOverlappingTrack = true
						end
						if not wasSelTrackFxOpen or wasMouseOverlappingTrack then
							reaper.TrackFX_Show(track, j, 2)
							wasFxWindowActive = true
						end
					end
				end
			end
			local itemCount = reaper.CountTrackMediaItems(track)
			if itemCount > 0 then
				for k = 0, itemCount - 1 do
					local wasSelItemFxOpen = false
					local item = reaper.GetTrackMediaItem(track, k)
					local take = reaper.GetActiveTake(item)
					if selItem then
						if item == selItem then
							if reaper.TakeFX_GetChainVisible(take) ~= -1 then
								wasSelItemFxOpen = true
								wasSelFxOpen = true
							end
						end
					end
					local takeFxCount = reaper.TakeFX_GetCount(take)
					if takeFxCount > 0 then
						if reaper.TakeFX_GetChainVisible(take) ~= -1 then
							local win = reaper.CF_GetTakeFXChain(take)
							if CheckMouseOverlap(screen_x, screen_y, win) then
								didMouseOverlap = true
							end
							if not wasSelItemFxOpen then
								reaper.JS_Window_Destroy(win)
								wasFxWindowActive = true
							end
						end
						for m = 0, takeFxCount - 1 do
							local win = reaper.TakeFX_GetFloatingWindow(take, m)
							if win then
								if CheckMouseOverlap(screen_x, screen_y, win) then
									didMouseOverlap = true
								end
								if not wasSelItemFxOpen then
									reaper.TakeFX_Show(take, m, 2)
									wasFxWindowActive = true
								end
							end
						end
					end
				end
			end
		end
	end
	return wasFxWindowActive, didMouseOverlap, wasSelFxOpen
end

function SelectOnlyObjectUnderMouse(screen_x, screen_y)
	local trackInfo = reaper.GetTrackFromPoint(screen_x, screen_y)
	local itemInfo, takeInfo = reaper.GetItemFromPoint(screen_x, screen_y, true)
	if itemInfo then
		local SelItemCount = reaper.CountSelectedMediaItems(0)
		if SelItemCount > 0 then
			reaper.SelectAllMediaItems(0, false)
		end
		reaper.SetMediaItemSelected(itemInfo, true)
	elseif trackInfo then
		reaper.SetOnlyTrackSelected(trackInfo)
	end
	return itemInfo, trackInfo
end

function OpenFxWindow(item, track)
	if item then
		local take = reaper.GetActiveTake(item)
		if take then
			local fxCount = reaper.TakeFX_GetCount(take)
			if fxCount > 0 then
				reaper.Main_OnCommand(40638, 0) --Calls action "Item: Show FX chain for item take"
			end
		end
	elseif track then
		local fxCount = reaper.TrackFX_GetCount(track)
		if fxCount > 0 then
			reaper.Main_OnCommand(40291, 0) --Calls action "Track: View FX chain for current/last touched track"
		end
	end
end

function GetFxWindowDimensions(window)
	local retval, left, top, right, bottom = reaper.JS_Window_GetRect(window)
	if retval then
		local height = math.abs(bottom - top)
		local width = right - left
		return left, top, right, bottom, height, width
	end
end

function CheckMouseOverlap(x, y, window)
	local left, top, right, bottom = GetFxWindowDimensions(window)
	if x >= left and x <= right and y <= bottom and y >= top then
		return true
	end
	return false
end

function MoveFxWindow(selItem, selTrack)
	local FX_win
	if selItem then
		local take = reaper.GetActiveTake(selItem)
		FX_win = reaper.CF_GetTakeFXChain(take)
	elseif selTrack then
		FX_win = reaper.CF_GetTrackFXChain(selTrack)
	end
	if not FX_win then return end
	local _, _, _, _, height, width = GetFxWindowDimensions(FX_win)
	local mLeft, mTop = GetFxWindowDimensions(reaper.GetMainHwnd())
	reaper.JS_Window_SetPosition(FX_win, mLeft + 50, mTop + 50, width, height)
end

function Main()
	if not mh.JsChecker then return end
	local screen_x, screen_y = reaper.GetMousePosition()
	local selItem, selTrack = SelectOnlyObjectUnderMouse(screen_x, screen_y)
	local wasWindowClosed, didMouseOverlap, wasSelFxOpen = CloseActiveFxWindows(screen_x, screen_y, selItem, selTrack)
	local shouldOpen = false
	if not wasWindowClosed and not wasSelFxOpen then
		shouldOpen = true
	elseif not didMouseOverlap and not wasSelFxOpen then
		shouldOpen = true
	end
	if shouldOpen then
		OpenFxWindow(selItem, selTrack)
		MoveFxWindow(selItem, selTrack)
	end
end

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

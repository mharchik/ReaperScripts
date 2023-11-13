----------------------------------------
-- @description Toggle FX Window of Selected Take
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
function CloseActiveFxWindows(selItem)
	local selTake = reaper.GetActiveTake(selItem)
	local wasSelItemFxOpen = false
	local wasFxWindowClosed = false
	local numOfTracks = reaper.CountTracks(0)
	if numOfTracks > 0 then
		for i = 0, numOfTracks - 1 do
			local track = reaper.GetTrack(0, i)
			local trackFxCount = reaper.TrackFX_GetCount(track)
			if trackFxCount > 0 then
				local chain = reaper.TrackFX_GetChainVisible(track)
				if chain ~= -1 then
					reaper.TrackFX_Show(track, chain, 0)
					wasFxWindowClosed = true
				end
				for j = 0, trackFxCount - 1 do
					if reaper.TrackFX_GetFloatingWindow(track, j) then
						reaper.TrackFX_Show(track, j, 2)
						wasFxWindowClosed = true
					end
				end
			end
			local numOfItems = reaper.CountTrackMediaItems(track)
			if numOfItems > 0 then
				for k = 0, numOfItems - 1 do
					local item = reaper.GetTrackMediaItem(track, k)
					local take = reaper.GetActiveTake(item)
					if take == selTake then
						if reaper.TakeFX_GetChainVisible(selTake) ~= -1 then
							wasSelItemFxOpen = true
						end
					end
					local takeFxCount = reaper.TakeFX_GetCount(take)
					if takeFxCount > 0 then
						local chain = reaper.TakeFX_GetChainVisible(take)
						if chain ~= -1 then
							reaper.TakeFX_Show(take, chain, 0)
							wasFxWindowClosed = true
						end
						for m = 0, takeFxCount - 1 do
							if reaper.TakeFX_GetFloatingWindow(take, m) then
								reaper.TakeFX_Show(take, m, 2)
								wasFxWindowClosed = true
							end
						end
					end
				end
			end
		end
	end
	return wasFxWindowClosed, wasSelItemFxOpen
end

function OpenFxWindow(item)
	if item then
		local take = reaper.GetActiveTake(item)
		if take then
			if reaper.TakeFX_GetCount(take) > 0 then
				reaper.Main_OnCommand(40638, 0) --Calls action "Item: Show FX chain for item take"
			end
		end
	end
end

function MoveFxWindow(selItem)
	local take = reaper.GetActiveTake(selItem)
	local FX_win = reaper.CF_GetTakeFXChain(take)
	if not FX_win then return end
	local _, _, _, _, height, width = GetFxWindowDimensions(FX_win)
	local mLeft, mTop = GetFxWindowDimensions(reaper.GetMainHwnd())
	reaper.JS_Window_SetPosition(FX_win, mLeft + 50, mTop + 50, width, height)
end

function GetFxWindowDimensions(window)
	local retval, left, top, right, bottom = reaper.JS_Window_GetRect(window)
	if retval then
		local height = math.abs(bottom - top)
		local width = right - left
		return left, top, right, bottom, height, width
	end
end

function Main()
	if not mh.JsChecker() then return end
	local selItem = reaper.GetSelectedMediaItem(0, 0)
	local wasWindowClosed, wasSelItemFxOpen = CloseActiveFxWindows(selItem)
	if not wasSelItemFxOpen or not wasWindowClosed then
		OpenFxWindow(selItem)
		MoveFxWindow(selItem)
	end
end

----------------------------------------
--Main
----------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

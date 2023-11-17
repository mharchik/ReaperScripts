----------------------------------------
-- @description Toggle FX Window of Selected Take
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
function CloseActiveFxWindows(selItem)
	local selTake = r.GetActiveTake(selItem)
	local wasSelItemFxOpen = false
	local wasFxWindowClosed = false
	local numOfTracks = r.CountTracks(0)
	if numOfTracks > 0 then
		for i = 0, numOfTracks - 1 do
			local track = r.GetTrack(0, i)
			local trackFxCount = r.TrackFX_GetCount(track)
			if trackFxCount > 0 then
				local chain = r.TrackFX_GetChainVisible(track)
				if chain ~= -1 then
					r.TrackFX_Show(track, chain, 0)
					wasFxWindowClosed = true
				end
				for j = 0, trackFxCount - 1 do
					if r.TrackFX_GetFloatingWindow(track, j) then
						r.TrackFX_Show(track, j, 2)
						wasFxWindowClosed = true
					end
				end
			end
			local numOfItems = r.CountTrackMediaItems(track)
			if numOfItems > 0 then
				for k = 0, numOfItems - 1 do
					local item = r.GetTrackMediaItem(track, k)
					local take = r.GetActiveTake(item)
					if take == selTake then
						if r.TakeFX_GetChainVisible(selTake) ~= -1 then
							wasSelItemFxOpen = true
						end
					end
					local takeFxCount = r.TakeFX_GetCount(take)
					if takeFxCount > 0 then
						local chain = r.TakeFX_GetChainVisible(take)
						if chain ~= -1 then
							r.TakeFX_Show(take, chain, 0)
							wasFxWindowClosed = true
						end
						for m = 0, takeFxCount - 1 do
							if r.TakeFX_GetFloatingWindow(take, m) then
								r.TakeFX_Show(take, m, 2)
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
		local take = r.GetActiveTake(item)
		if take then
			if r.TakeFX_GetCount(take) > 0 then
				r.Main_OnCommand(40638, 0) --Calls action "Item: Show FX chain for item take"
			end
		end
	end
end

function MoveFxWindow(selItem)
	local take = r.GetActiveTake(selItem)
	local FX_win = r.CF_GetTakeFXChain(take)
	if not FX_win then return end
	local _, _, _, _, height, width = GetFxWindowDimensions(FX_win)
	local mLeft, mTop = GetFxWindowDimensions(r.GetMainHwnd())
	r.JS_Window_SetPosition(FX_win, mLeft + 50, mTop + 50, width, height)
end

function GetFxWindowDimensions(window)
	local retval, left, top, right, bottom = r.JS_Window_GetRect(window)
	if retval then
		local height = math.abs(bottom - top)
		local width = right - left
		return left, top, right, bottom, height, width
	end
end

function Main()
	if not mh.JsChecker() then return end
	local selItem = r.GetSelectedMediaItem(0, 0)
	local wasWindowClosed, wasSelItemFxOpen = CloseActiveFxWindows(selItem)
	if not wasSelItemFxOpen or not wasWindowClosed then
		OpenFxWindow(selItem)
		MoveFxWindow(selItem)
	end
end

----------------------------------------
--Main
----------------------------------------
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Remove FX From Track or Item Under Mouse
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
function SelectOnlyObjectUnderMouse()
	local screen_x, screen_y = reaper.GetMousePosition()
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

function RemoveFxFromObject(item, track)
	if item then
		local take = reaper.GetActiveTake(item)
		if take then
			local takeFxCount = reaper.TakeFX_GetCount(take)
			if takeFxCount > 0 then
				for i = 0, takeFxCount - 1 do
					reaper.TakeFX_Delete(take, 0) -- needs to be 0 because every time you delete a effect, the next effect gets moved into the 0 index
				end
			end
		end
	elseif track then
		local trackFxCount = reaper.TrackFX_GetCount(track)
		if trackFxCount > 0 then
			for i = 0, trackFxCount - 1 do
				reaper.TrackFX_Delete(track, 0) -- needs to be 0 because every time you delete a effect, the next effect gets moved into the 0 index
			end
		end
	end
end

function Main()
	local selItem, selTrack = SelectOnlyObjectUnderMouse()
	RemoveFxFromObject(selItem, selTrack)
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

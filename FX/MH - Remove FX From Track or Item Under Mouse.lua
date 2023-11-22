----------------------------------------
-- @description Remove FX From Track or Item Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
----------------------------------------
--Functions
----------------------------------------
function SelectOnlyObjectUnderMouse()
	local screen_x, screen_y = r.GetMousePosition()
	local trackInfo = r.GetTrackFromPoint(screen_x, screen_y)
	local itemInfo, takeInfo = r.GetItemFromPoint(screen_x, screen_y, true)
	if itemInfo then
		local SelItemCount = r.CountSelectedMediaItems(0)
		if SelItemCount > 0 then
			r.SelectAllMediaItems(0, false)
		end
		r.SetMediaItemSelected(itemInfo, true)
	elseif trackInfo then
		r.SetOnlyTrackSelected(trackInfo)
	end
	return itemInfo, trackInfo
end

function RemoveFxFromObject(item, track)
	if item then
		local take = r.GetActiveTake(item)
		if take then
			local takeFxCount = r.TakeFX_GetCount(take)
			if takeFxCount > 0 then
				for i = 0, takeFxCount - 1 do
					r.TakeFX_Delete(take, 0) -- needs to be 0 because every time you delete a effect, the next effect gets moved into the 0 index
				end
			end
		end
	elseif track then
		local trackFxCount = r.TrackFX_GetCount(track)
		if trackFxCount > 0 then
			for i = 0, trackFxCount - 1 do
				r.TrackFX_Delete(track, 0) -- needs to be 0 because every time you delete a effect, the next effect gets moved into the 0 index
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
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Select Only Items on Track Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @about Deselects all items except for the ones on the track you are mousing over. If no items on that track are selected yet it will select all items on it
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local track = reaper.BR_TrackAtMouseCursor()
    local trackItemCount = reaper.CountTrackMediaItems(track)
    if trackItemCount == 0 then return end
    local selItems = {}
    for i = 0, trackItemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        if reaper.IsMediaItemSelected(item) then
            selItems[#selItems+1] = item
        end
    end
    if #selItems > 0 then
        reaper.SelectAllMediaItems(0, false)
        for i = 1, #selItems do
            reaper.SetMediaItemSelected(selItems[i], true)
        end
    else
        reaper.SelectAllMediaItems(0, false)
        for i = 0, trackItemCount - 1 do
            reaper.SetMediaItemSelected(reaper.GetTrackMediaItem(track, i), true)
        end
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

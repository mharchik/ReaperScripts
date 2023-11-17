----------------------------------------
-- @description Select Only Items on Track Under Mouse
-- @author Max Harchik
-- @version 1.0
-- @about Deselects all items except for the ones on the track you are mousing over. If no items on that track are selected yet it will select all items on it
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWSChecker() then mh.noundo() return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local track = r.BR_TrackAtMouseCursor()
    local trackItemCount = r.CountTrackMediaItems(track)
    if trackItemCount == 0 then return end
    local selItems = {}
    for i = 0, trackItemCount - 1 do
        local item = r.GetTrackMediaItem(track, i)
        if r.IsMediaItemSelected(item) then
            selItems[#selItems+1] = item
        end
    end
    if #selItems > 0 then
        r.SelectAllMediaItems(0, false)
        for i = 1, #selItems do
            r.SetMediaItemSelected(selItems[i], true)
        end
    else
        r.SelectAllMediaItems(0, false)
        for i = 0, trackItemCount - 1 do
            r.SetMediaItemSelected(r.GetTrackMediaItem(track, i), true)
        end
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

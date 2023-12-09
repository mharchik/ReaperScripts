----------------------------------------
-- @description Toggle Mute for Selected Items to the Same Value
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
--mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
--if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selItemCount = r.CountSelectedMediaItems()
    if selItemCount == 0 then return mh.noundo() end
    local isUnmuted = false
    for i = 0, selItemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        if r.GetMediaItemInfo_Value(item, "B_MUTE") == 0 then
            isUnmuted = true
        end
    end
    local mute = 0
    if isUnmuted then
        mute = 1
    end
    for i = 0, selItemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        r.SetMediaItemInfo_Value(item, "B_MUTE", mute)
    end
end
----------------------------------------
--Main
----------------------------------------
--r.ClearConsole()
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @description Semi Normalize All Selected Items
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about Normalizes all items 50% of the way to 0dB Peak
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local strength = 0.5 --how much of the normalization is applied to selected items. 1 = 100% strength
----------------------------------------
--Functions
----------------------------------------

function Main()
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount == 0 then mh.noundo() return end
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVEALLSELITEMS1'),0) -- Calls Action: 'SWS: Save selected item(s)'
    for i = 0, selItemCount- 1 do
        local item = r.GetSelectedMediaItem(0, i)
        r.Main_OnCommand(r.NamedCommandLookup('40289'),0) -- Calls Action: 'Item: Unselect(clear selection of) all items'
        r.SetMediaItemSelected(item, true)
        local take = r.GetActiveTake(item)
        r.SetMediaItemInfo_Value(item, 'D_VOL', 1) -- reset item volume
        r.SetMediaItemTakeInfo_Value(take, 'D_VOL', 1)  -- reset take volume
        r.Main_OnCommand('40108',0) -- Calls Action: ' Item properties: Normalize items to +0dB peak'
        local vol = r.GetMediaItemTakeInfo_Value(take, 'D_VOL')
        if vol > 1 then -- only scale the normalization if the file is being turned up
            r.SetMediaItemTakeInfo_Value(take, 'D_VOL', 1 + (vol - 1) * strength) -- this is looking at how much the volume is changing and scaling that by the strength setting.
        end
        r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTALLSELITEMS1'),0) -- Calls Action: 'SWS: Restore saved selected item(s)'
    end
end

----------------------------------------
--Main
----------------------------------------
--r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

----------------------------------------
-- @noindex
-- @description default template
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about default template
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local TransientLength = 0.05
----------------------------------------
--Script Variables
----------------------------------------

----------------------------------------
--Functions
----------------------------------------

function Main()
    local selItemCount = r.CountSelectedMediaItems(0)
    if selItemCount == 0 then mh.noundo() return end
    for i = 0, selItemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        r.SetMediaItemLength(item, TransientLength, false)
        r.SetMediaItemTakeInfo_Value(take, 'D_VOL', 0)
        r.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', 0)
        r.SetMediaItemInfo_Value(item, 'D_FADEINLEN', 0)
    end
    r.Main_OnCommand(r.NamedCommandLookup('_RS1304a6b8861c3837b48bcd4466a34a24d7527989'), 0) -- Calls action: "mpl_Normalize selected items takes LUFS to -7dB.lua"
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

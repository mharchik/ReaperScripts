----------------------------------------
-- @description Toggle Take Volume Envelopes for Selected Items to the Same Value
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
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
local IgnoreFolderItems = true
----------------------------------------
--Functions
----------------------------------------
function Main()
    local itemCount = r.CountSelectedMediaItems(0)
    if itemCount == 0 then mh.noundo() return end
    local isVisible = false
    local folderItems = {}
    for i = 0, itemCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        if mh.IsFolderItem(item) and IgnoreFolderItems then
            folderItems[#folderItems+1] = item
        else
            local take = r.GetActiveTake(item)
            local env = reaper.GetTakeEnvelopeByName(take, 'Volume')
            if env then
                local brEnv = reaper.BR_EnvAlloc( env, false )
                if ({reaper.BR_EnvGetProperties(brEnv)})[2] then
                    isVisible = true
                end
            end
        end
    end

    if #folderItems > 0 and IgnoreFolderItems then
        for i = 1, #folderItems do
            r.SetMediaItemSelected(folderItems[i], false)
        end
    end
    if isVisible then
        r.Main_OnCommand(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW4'), 0) --Calls Action 'SWS/S&M: Hide take volume envelope'
    else
        r.Main_OnCommand(reaper.NamedCommandLookup('_S&M_TAKEENVSHOW1'), 0) --Calls Action 'SWS/S&M: Show take volume envelope'
    end
    if #folderItems > 0 and IgnoreFolderItems then
        for i = 1, #folderItems do
            r.SetMediaItemSelected(folderItems[i], true)
        end
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

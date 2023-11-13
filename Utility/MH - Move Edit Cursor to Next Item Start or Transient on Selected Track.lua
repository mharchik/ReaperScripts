----------------------------------------
-- @description Move Edit Cursor to Next Item Start or Transient on Selected Track
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
function MoveCursorForward(track, cursorPos)
    local itemCount = reaper.CountTrackMediaItems(track)
    if itemCount > 0 then
        reaper.SelectAllMediaItems(0, false)
        local didMove = false
        for i = 0, itemCount - 1 do
            local item = reaper.GetTrackMediaItem(track, i)
            local itemStart, itemEnd = mh.GetItemSize(item)
            if cursorPos >= itemStart and cursorPos < itemEnd and didMove == false then
                reaper.SetMediaItemSelected(item, true)
                reaper.Main_OnCommand("40375", 0) --Calls Action "Item navigation: Move cursor to next transient in items"
                didMove = true
            elseif cursorPos < itemStart and didMove == false then
                reaper.SetMediaItemSelected(item, true)
                reaper.SetEditCurPos(itemStart, true, false)
                didMove = true
            end
        end
    end
end

function Main()
    local track = reaper.GetLastTouchedTrack()
    local cursorPos = reaper.GetCursorPosition()
    MoveCursorForward(track, cursorPos)
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

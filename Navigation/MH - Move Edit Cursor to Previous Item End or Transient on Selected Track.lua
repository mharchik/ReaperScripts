----------------------------------------
-- @description Move Edit Cursor to Previous Item End or Transient on Selected Track
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
function MoveCursorBack(track, cursorPos)
    local itemCount = reaper.CountTrackMediaItems(track)
    if itemCount > 0 then
        reaper.SelectAllMediaItems(0, false)
        local didMove = false
        for i = itemCount - 1, 0, -1 do
            local item = reaper.GetTrackMediaItem(track, i)
            local itemStart, itemEnd = mh.GetItemSize(item)
            if cursorPos > itemStart and cursorPos <= itemEnd and didMove == false then
                reaper.SetMediaItemSelected(item, true)
                local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local take = reaper.GetActiveTake(item)
                local offSet = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                local source = reaper.GetMediaItemTake_Source(take)
                local sLength, isSeconds = reaper.GetMediaSourceLength(source)
                reaper.Main_OnCommand("40376", 0) --Calls Action "Item navigation: Move cursor to previous transient in items"
                --checking if we're passing by the start of the source. If so stop there first.
                if offSet < 0 then
                    if cursorPos > itemStart - offSet and reaper.GetCursorPosition() < itemStart - offSet then
                        reaper.SetEditCurPos(itemStart - offSet, true, false)
                    end
                end
                --checking if we're passing by the end of the source. If so stop there first.
                if length > sLength - offSet then
                    if cursorPos > itemStart + (sLength - offSet) and reaper.GetCursorPosition() < itemStart + (sLength - offSet) then
                        reaper.SetEditCurPos(itemStart + (sLength - offSet), true, false)
                    end
                end
                didMove = true
            elseif cursorPos > itemEnd and didMove == false then
                reaper.SetMediaItemSelected(item, true)
                reaper.SetEditCurPos(itemEnd, true, false)
                didMove = true
            end
        end
    end
end

function Main()
    local track = reaper.GetLastTouchedTrack()
    local cursorPos = reaper.GetCursorPosition()
    MoveCursorBack(track, cursorPos)
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

----------------------------------------
-- @description Move Edit Cursor to Next Item Edge or Transient on Selected Track
-- @author Max Harchik
-- @version 1.0

-- Requires SWS Extensions
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local ShouldSelectItem = true
local ShouldSelectFolderItem = false
----------------------------------------
--Functions
----------------------------------------
function MoveCursorForward(track, cursorPos)
    local itemCount = r.CountTrackMediaItems(track)
    if itemCount > 0 then
        r.SelectAllMediaItems(0, false)
        local didMove = false
        for i = 0, itemCount - 1 do
            local item = r.GetTrackMediaItem(track, i)
            local itemStart, itemEnd = mh.GetItemSize(item)
            if cursorPos >= itemStart and cursorPos < itemEnd and didMove == false then
                if not ShouldSelectItem and not mh.IsFolderItem(item) then
                    r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"), 0) -- Calls Action: "SWS: Save selected item(s)"
                elseif mh.IsFolderItem(item) and not ShouldSelectFolderItem then
                    r.Main_OnCommand(r.NamedCommandLookup("_SWS_SAVEALLSELITEMS1"), 0) -- Calls Action: "SWS: Save selected item(s)"
                end
                r.SetMediaItemSelected(item, true)
                local length = r.GetMediaItemInfo_Value(item, "D_LENGTH")
                local take = r.GetActiveTake(item)
                local offSet = r.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
                local source = r.GetMediaItemTake_Source(take)
                local sLength, isSeconds = r.GetMediaSourceLength(source)
                r.Main_OnCommand("40375", 0) --Calls Action "Item navigation: Move cursor to next transient in items"
                --checking if we're passing by the start of the source. If so stop there first.
                if offSet < 0 then
                    if cursorPos < itemStart - offSet and r.GetCursorPosition() > itemStart - offSet then
                        r.SetEditCurPos(itemStart - offSet, true, false)
                    end
                end
                --checking if we're passing by the end of the source. If so stop there first.
                if length > sLength - offSet then
                    if cursorPos < itemStart + (sLength - offSet) and r.GetCursorPosition() > itemStart + (sLength - offSet) then
                        r.SetEditCurPos(itemStart + (sLength - offSet), true, false)
                    end
                end
                didMove = true
                if not ShouldSelectItem and not mh.IsFolderItem(item) then
                    r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTALLSELITEMS1"), 0) -- Calls Action: "SWS: Restore saved selected item(s)"
                elseif mh.IsFolderItem(item) and not ShouldSelectFolderItem then
                    r.Main_OnCommand(r.NamedCommandLookup("_SWS_RESTALLSELITEMS1"), 0) -- Calls Action: "SWS: Restore saved selected item(s)"
                end
            elseif cursorPos < itemStart and didMove == false then
                if ShouldSelectItem and not mh.IsFolderItem(item) then
                    r.SetMediaItemSelected(item, true)
                elseif mh.IsFolderItem and ShouldSelectFolderItem then
                    r.SetMediaItemSelected(item, true)
                end
                r.SetEditCurPos(itemStart, true, false)
                didMove = true
            end
        end
    end
end



function Main()
    local track = r.GetLastTouchedTrack()
    local cursorPos = r.GetCursorPosition()
    MoveCursorForward(track, cursorPos)
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

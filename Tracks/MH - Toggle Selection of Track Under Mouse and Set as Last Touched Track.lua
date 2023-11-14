----------------------------------------
-- @description Toggle Selection of Track Under Mouse and Set as Last Touched Track
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--Script Variables
----------------------------------------
local selTracks = {}
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selTrackCount = reaper.CountSelectedTracks(0)
    if selTrackCount > 0 then
        for i = 0, selTrackCount - 1 do
            selTracks[#selTracks + 1] = reaper.GetSelectedTrack(0, i)
        end
    end
    local track = reaper.BR_TrackAtMouseCursor()
    if not track then return end
    reaper.SetOnlyTrackSelected(track) -- This sets track as last touched
    reaper.Main_OnCommand(40297, 0)    -- Track: Unselect all tracks
    for _, selTrack in ipairs(selTracks) do
        reaper.SetTrackSelected(selTrack, true)
    end
    if reaper.IsTrackSelected(track) then
        reaper.SetTrackSelected(track, false)
    else
        reaper.SetTrackSelected(track, true)
    end
end

----------------------------------------
--Utilities
----------------------------------------
function Msg(msg) reaper.ShowConsoleMsg(msg .. "\n") end

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

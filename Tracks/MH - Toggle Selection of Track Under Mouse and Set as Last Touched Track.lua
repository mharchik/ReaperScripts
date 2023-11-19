----------------------------------------
-- @description Toggle Selection of Track Under Mouse and Set as Last Touched Track
-- @provides /Functions/MH - Functions.lua
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local selTracks = {}
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selTrackCount = r.CountSelectedTracks(0)
    if selTrackCount > 0 then
        for i = 0, selTrackCount - 1 do
            selTracks[#selTracks + 1] = r.GetSelectedTrack(0, i)
        end
    end
    local track = r.BR_TrackAtMouseCursor()
    if not track then return end
    r.SetOnlyTrackSelected(track) -- This sets track as last touched
    r.Main_OnCommand(40297, 0)    -- Track: Unselect all tracks
    for _, selTrack in ipairs(selTracks) do
        r.SetTrackSelected(selTrack, true)
    end
    if r.IsTrackSelected(track) then
        r.SetTrackSelected(track, false)
    else
        r.SetTrackSelected(track, true)
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

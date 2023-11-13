----------------------------------------
-- @description Disable Track Height Lock For All Tracks
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
----------------------------------------
--Functions
----------------------------------------
function Main()
    local trackCount = reaper.CountTracks(0)
    if trackCount == 0 then return end
    for i = 0, trackCount - 1 do
        local track = reaper.GetTrack(0, i)
        if track then
            reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 0)
        end
    end
end

----------------------------------------
--Main
----------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock(scriptName, -1)
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

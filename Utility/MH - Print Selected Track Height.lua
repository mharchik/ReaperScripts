--@noindex
local track = reaper.GetSelectedTrack(0, 0)
reaper.ShowConsoleMsg(reaper.GetMediaTrackInfo_Value(track, "I_TCPH"))

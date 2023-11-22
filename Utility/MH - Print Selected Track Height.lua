----------------------------------------
--@noindex
----------------------------------------
local track = reaper.GetSelectedTrack(0, 0)
reaper.ShowConsoleMsg(r.GetMediaTrackInfo_Value(track, 'I_TCPH'))

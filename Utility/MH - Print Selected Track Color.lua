----------------------------------------
--@noindex
----------------------------------------
local track = reaper.GetSelectedTrack(0, 0)
local r, g, b = reaper.ColorFromNative(reaper.GetTrackColor(track))
reaper.ShowConsoleMsg(r .. " " .. g .. " " .. b)

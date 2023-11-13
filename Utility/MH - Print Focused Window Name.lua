----------------------------------------
--@noindex
----------------------------------------
local hwnd = reaper.JS_Window_GetForeground()
if hwnd then
  reaper.ShowConsoleMsg(reaper.JS_Window_GetTitle(hwnd))
else
  reaper.ShowConsoleMsg("No Window Found")
end

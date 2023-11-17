----------------------------------------
--@noindex
----------------------------------------
local hwnd = r.JS_Window_GetForeground()
if hwnd then
  reaper.ShowConsoleMsg(r.JS_Window_GetTitle(hwnd))
else
  reaper.ShowConsoleMsg("No Window Found")
end

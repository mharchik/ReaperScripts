----------------------------------------
--@noindex
----------------------------------------
r = reaper
r.ClearConsole()
local retval, list = r.JS_Window_ListAllTop()
for address in string.gmatch(list, '([^,]+)') do
  local win2 = reaper.JS_Window_HandleFromAddress( address )
  local win3 = r.JS_Window_GetTitle(win2)
  r.ShowConsoleMsg(win3 .. '\n')
end

local hwnd = r.JS_Window_GetForeground()
if hwnd then
  --r.ShowConsoleMsg(r.JS_Window_GetTitle(hwnd))
else
  r.ShowConsoleMsg('No Window Found')
end

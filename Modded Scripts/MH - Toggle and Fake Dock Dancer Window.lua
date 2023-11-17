----------------------------------------
-- @noindex
-- @about Moves Toggles the Pelo Dancer Window, and pins it to the top left of the main reaper window
-- @description Center Named Window
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
local _, _, section_ID, cmd_ID, _, _, _ = r.get_action_context()
r.SetToggleCommandState(section_ID, cmd_ID, 1)
r.RefreshToolbar2(section_ID, cmd_ID)
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--User Settings
----------------------------------------
local WINDOW_NAME = "DancerWindow" --Type the name of the window you'd like to center here
----------------------------------------
--Script Variables
----------------------------------------
local refreshRate = 0.01
local winCheckRefreshRate = 5
local lastActiveTime = r.time_precise()
local lastWinCheckTime = r.time_precise()

local win, mLeft, mTop, mRight, mBottom, left, top, right, bottom, width, height
----------------------------------------
--Functions
----------------------------------------

function Setup()
    local window = r.JS_Window_Find(WINDOW_NAME, false)
    if window then
        r.JS_Window_Destroy(win)
    else
        r.Main_OnCommand(r.NamedCommandLookup("_PELORI_DANCER_OPENWINDOW"), 0)
    window = r.JS_Window_Find(WINDOW_NAME, false)
    end
  return window
end

function Main()
    local currentTime = r.time_precise()
    if currentTime - lastActiveTime > refreshRate then
    if currentTime - lastWinCheckTime > winCheckRefreshRate then
      win = r.JS_Window_Find(WINDOW_NAME, false)
      if not win then return end
      lastWinCheckTime = currentTime
    end
    _, left, top, right, bottom = r.JS_Window_GetRect(win)
    _, mLeft, mTop, mRight, mBottom = r.JS_Window_GetRect(r.GetMainHwnd())
    height = math.abs(bottom - top)
    width = right - left
    r.JS_Window_SetPosition(win, mLeft + 5, mTop + 64, width, height)
    lastActiveTime = currentTime
  end
  if win then
    r.defer(Main)
  end
end

function Exit()
  if win then
    r.JS_Window_Destroy(win)
  end
  r.SetToggleCommandState(section_ID, cmd_ID, 0)
  r.RefreshToolbar2(section_ID, cmd_ID)
end

----------------------------------------
--Main
----------------------------------------
win = Setup()
Main()
r.atexit(Exit)

----------------------------------------
-- @noindex
-- @about Moves Toggles the Pelo Dancer Window, and pins it to the top left of the main reaper window
-- @description Center Named Window
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local _, _, section_ID, cmd_ID, _, _, _ = reaper.get_action_context()
reaper.SetToggleCommandState(section_ID, cmd_ID, 1)
reaper.RefreshToolbar2(section_ID, cmd_ID)
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit www.maxharchik.com/reaper for more information", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local WINDOW_NAME = "DancerWindow" --Type the name of the window you'd like to center here
----------------------------------------
--Script Variables
----------------------------------------
local refreshRate = 0.01
local winCheckRefreshRate = 5
local lastActiveTime = reaper.time_precise()
local lastWinCheckTime = reaper.time_precise()

local win, mLeft, mTop, mRight, mBottom, left, top, right, bottom, width, height
----------------------------------------
--Functions
----------------------------------------

function Setup()
    local window = reaper.JS_Window_Find(WINDOW_NAME, false)
    if window then
        reaper.JS_Window_Destroy(win)
    else
        reaper.Main_OnCommand(reaper.NamedCommandLookup("_PELORI_DANCER_OPENWINDOW"), 0)
    window = reaper.JS_Window_Find(WINDOW_NAME, false)
    end
  return window
end

function Main()
    local currentTime = reaper.time_precise()
    if currentTime - lastActiveTime > refreshRate then
    if currentTime - lastWinCheckTime > winCheckRefreshRate then
      win = reaper.JS_Window_Find(WINDOW_NAME, false)
      if not win then return end
      lastWinCheckTime = currentTime
    end
    _, left, top, right, bottom = reaper.JS_Window_GetRect(win)
    _, mLeft, mTop, mRight, mBottom = reaper.JS_Window_GetRect(reaper.GetMainHwnd())
    height = math.abs(bottom - top)
    width = right - left
    reaper.JS_Window_SetPosition(win, mLeft + 5, mTop + 64, width, height)
    lastActiveTime = currentTime
  end
  if win then
    reaper.defer(Main)
  end
end

function Exit()
  if win then
    reaper.JS_Window_Destroy(win)
  end
  reaper.SetToggleCommandState(section_ID, cmd_ID, 0)
  reaper.RefreshToolbar2(section_ID, cmd_ID)
end

----------------------------------------
--Main
----------------------------------------
win = Setup()
Main()
reaper.atexit(Exit)

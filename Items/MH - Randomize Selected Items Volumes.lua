----------------------------------------
-- @description Randomize Selected Items Volumes
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local RANDOM_AMOUNT = 1.5   --dB up and down
local DONT_PROMPT = false   --set value to true to bypass the input prompt. Script will default to dB value above
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selItemsCount = r.CountSelectedMediaItems(0)
    if selItemsCount == 0 then return end
    local randRange
    if DONT_PROMPT then
        randRange = RANDOM_AMOUNT
    else
        local retval, input = r.GetUserInputs(scriptName, 1, "Volume Random Range (+/- dB)", RANDOM_AMOUNT)
        if not retval then mh.noundo() return end
        randRange = input
    end
    randRange = math.abs(randRange)
    math.randomseed(os.clock() * 100)
    for i = 0, selItemsCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local curVol = r.GetMediaItemInfo_Value(item, "D_VOL")
        curVol = 20 * math.log(curVol, 10)
        local volChange = math.random(math.ceil(randRange * -100), math.floor(randRange * 100)) / 100
        local newVol = curVol + volChange
        if newVol <= -150 then newVol = -150 end
        if newVol >= 24 then newVol = 24 end
        local itemVol = 10 ^ (newVol / 20)
        r.SetMediaItemInfo_Value(item, "D_VOL", itemVol)
    end
end

----------------------------------------
--Main
----------------------------------------
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

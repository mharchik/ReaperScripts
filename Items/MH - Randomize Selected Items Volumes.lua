----------------------------------------
-- @description Randomize Selected Items Volumes
-- @author Max Harchik
-- @version 1.0
----------------------------------------
--Setup
----------------------------------------
local scriptName = ({ reaper.get_action_context() })[2]:match("([^/\\_]+)%.[Ll]ua$")
mh = reaper.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if reaper.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then reaper.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory. Please resync it from the menu above:\nExtensions > ReaPack > Synchronize Packages > 'MH Scripts'", "Error", 0); return end else reaper.ShowMessageBox("This script requires the full MH Scripts repository. Please install it from the menu above:\nExtensions > ReaPack > Browse Packages > 'MH Scripts'", "Error", 0); return end
----------------------------------------
--User Settings
----------------------------------------
local RANDOM_AMOUNT = 1.5   --dB up and down
local DONT_PROMPT = true    --set value to true to bypass the input prompt. Script will default to dB value above
----------------------------------------
--Functions
----------------------------------------
function Main()
    local selItemsCount = reaper.CountSelectedMediaItems(0)
    if selItemsCount == 0 then return end
    local randRange
    if DONT_PROMPT then
        randRange = RANDOM_AMOUNT
    else
        local retval, input = reaper.GetUserInputs(scriptName, 1, "Volume Random Range (+/- dB)", RANDOM_AMOUNT)
        if not retval then return end
        randRange = input
    end
    randRange = math.abs(randRange)
    math.randomseed(os.clock() * 100)
    for i = 0, selItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local curVol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
        curVol = 20 * math.log(curVol, 10)
        local volChange = math.random(math.ceil(randRange * -100), math.floor(randRange * 100)) / 100
        local newVol = curVol + volChange
        if newVol <= -150 then newVol = -150 end
        if newVol >= 24 then newVol = 24 end
        local itemVol = 10 ^ (newVol / 20)
        reaper.SetMediaItemInfo_Value(item, "D_VOL", itemVol)
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

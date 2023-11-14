----------------------------------------
-- @description Randomize Selected Items Pitch via Playrate
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
local RANDOM_AMOUNT = 150   --cents up and down
local DONT_PROMPT = true    --set value to true to bypass the input prompt. Script will default to pitch value above
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
        local retval, input = reaper.GetUserInputs(scriptName, 1, "Pitch Random Range (+/- Cents)", RANDOM_AMOUNT)
        if not retval then return end
        randRange = input
    end
    randRange = math.abs(randRange)
    math.randomseed(os.clock() * 100)
    for i = 0, selItemsCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        local curRate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local curLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local stretchAmount = 2 ^ ((math.random(math.ceil(randRange * -1), math.floor(randRange)) / 100) / 12)
        local newRate = curRate * stretchAmount
        if newRate < 0.125 then
            newRate = 0.125
        elseif newRate > 4 then
            newRate = 4
        end
        local newLength = curLength / (newRate / curRate)
        reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", 0)
        reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newRate)
        reaper.SetMediaItemLength(item, newLength, true)
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

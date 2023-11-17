----------------------------------------
-- @description Randomize Selected Items Pitch via Playrate
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
local RANDOM_AMOUNT = 150   --cents up and down
local DONT_PROMPT = false    --set value to true to bypass the input prompt. Script will default to pitch value above
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
        local retval, input = r.GetUserInputs(scriptName, 1, "Pitch Random Range (+/- Cents)", RANDOM_AMOUNT)
        if not retval then mh.noundo() return end
        randRange = input
    end
    randRange = math.abs(randRange)
    math.randomseed(os.clock() * 100)
    for i = 0, selItemsCount - 1 do
        local item = r.GetSelectedMediaItem(0, i)
        local take = r.GetActiveTake(item)
        local curRate = r.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
        local curLength = r.GetMediaItemInfo_Value(item, "D_LENGTH")
        local stretchAmount = 2 ^ ((math.random(math.ceil(randRange * -1), math.floor(randRange)) / 100) / 12)
        local newRate = curRate * stretchAmount
        if newRate < 0.125 then
            newRate = 0.125
        elseif newRate > 4 then
            newRate = 4
        end
        local newLength = curLength / (newRate / curRate)
        r.SetMediaItemTakeInfo_Value(take, "B_PPITCH", 0)
        r.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", newRate)
        r.SetMediaItemLength(item, newLength, true)
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

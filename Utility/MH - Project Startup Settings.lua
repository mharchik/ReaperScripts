---@diagnostic disable: param-type-mismatch
----------------------------------------
--@noindex
----------------------------------------
function CheckLocation()
    local file = io.open(('D:/PC_Location.txt'):gsub('\\', '/'), 'r')
    io.input(file)
    local s = io.read('l')
    io.close(file)
    return s
end

function Main()
    r=reaper
    r.GetSetRepeat(1)
    r.SNM_SetIntConfigVar( 'projfrbase', 60 )
    local str = CheckLocation()
    if str == 'Home' then
        r.Main_OnCommand(40455, 0) -- Calls action: 'Screenset: Load window set #02'
    elseif str == 'Work' then
        r.Main_OnCommand(40454, 0) -- Calls action: 'Screenset: Load window set #01'
    end
end

----------------------------------------
Main()
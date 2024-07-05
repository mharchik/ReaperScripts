----------------------------------------
-- @noindex
-- @description Insert Sub Track Template and Send Selected Tracks to It
-- @author Max Harchik
-- @version 1.0
-- @links GitHub Repo: https://github.com/mharchik/ReaperScripts

-- @about Creates a sub send track at the track at the top of the folder structure you have selected, and creates sends for any tracks that are selected and don't already have them
--        The sub send track template needs to be saved in SWS Track Template Slot 1 
----------------------------------------
--Setup
----------------------------------------
r = reaper
local scriptName = ({ r.get_action_context() })[2]:match('([^/\\_]+)%.[Ll]ua$')
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; 
if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local ParentTracks = {}
local NewTracks = {}

----------------------------------------
--Functions
----------------------------------------

function Main()
    --Find the top level parent track of each selected track. 
    local selTrackCount = r.CountSelectedTracks(0)
    if selTrackCount == 0 then mh.noundo() return end
    for i = 0, selTrackCount - 1 do
        local track = r.GetSelectedTrack(0, i)
        local retval, parent = mh.GetTopParentTrack(track)
        if retval  then
            local isNewParent = true
            for parentTrack, childTracks in pairs(ParentTracks) do
                if parent == parentTrack then
                    isNewParent = false
                    childTracks[#childTracks+1] = track --storing which top level parent each select track is associated with so we can setup sends from each track later
                end
            end
            if isNewParent then
                local tracks = {}
                tracks[1] = track
                ParentTracks[parent] = tracks --storing which top level parent each select track is associated with so we can setup sends from each track later
            end
        end
    end
    --Check if sub tracks exist for any of the top level parent tracks already
    for parentTrack, childTracks in pairs(ParentTracks) do
        local hasSub = false
        local retval, lastTrack = mh.GetLastChildTrack(parentTrack)
        local parentTrackNum = r.GetMediaTrackInfo_Value(parentTrack, 'IP_TRACKNUMBER')
        if retval == 1 then
            local lastTrackNum = r.GetMediaTrackInfo_Value(lastTrack, 'IP_TRACKNUMBER')
            for i = parentTrackNum, lastTrackNum - 1 do
                local track = r.GetTrack(0, i)
                local _, name = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '' , false)
                if string.match(name, 'SUB') then
                    hasSub = true
                end
            end
            if not hasSub then
                r.InsertTrackAtIndex(parentTrackNum, false)
                local subTrack = r.GetTrack(0, parentTrackNum)
                NewTracks[#NewTracks+1] = subTrack
            end
        end
    end

    --Create new tracks if any sub tracks are missing
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_SAVESEL'), 0) -- Calls Action 'SWS: Save current track selection'   
    r.Main_OnCommand(r.NamedCommandLookup('40297'), 0) -- Calls Action 'Track: Unselect (clear selection of) all tracks'
    for index, track in ipairs(NewTracks) do
        r.SetOnlyTrackSelected(track)
        r.Main_OnCommand(r.NamedCommandLookup('_S&M_APPLY_TRTEMPLATE1'), 0) -- Calls Action 'SWS/S&M: Resources - Apply track template to selected tracks, slot 1'   
    end
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_RESTORESEL'), 0) -- Calls Action 'SWS: Restore saved track selection'

    for parentTrack, childTracks in pairs(ParentTracks) do
        --First find the associated sub track with each top level parent track
        local subTrack
        local retval, lastTrack = mh.GetLastChildTrack(parentTrack)
        local parentTrackNum = r.GetMediaTrackInfo_Value(parentTrack, 'IP_TRACKNUMBER')
        if retval == 1 then
            local lastTrackNum = r.GetMediaTrackInfo_Value(lastTrack, 'IP_TRACKNUMBER')
            for i = parentTrackNum, lastTrackNum - 1 do
                local track = r.GetTrack(0, i)
                local _, name = r.GetSetMediaTrackInfo_String(track, 'P_NAME', '' , false)
                if string.match(name, 'SUB') then
                     subTrack = track
                end
            end
        end
        if subTrack then --create sends to the sub track, but only if they don't already exist
            for index, track in ipairs(childTracks) do
                local shouldSend = true
                local sendCount = r.GetTrackNumSends(track, 0)
                for i = 0, sendCount - 1 do
                    local recieveTrack = r.GetTrackSendInfo_Value( track, 0, i, 'P_DESTTRACK' )
                    if subTrack == recieveTrack then
                        shouldSend = false
                    end
                end
                if shouldSend then
                    r.CreateTrackSend( track, subTrack )
                end
            end
        end
    end
end

----------------------------------------
--Main
----------------------------------------
r.ClearConsole() -- comment out once script is complete
r.PreventUIRefresh(1)
r.Undo_BeginBlock()
Main()
r.Undo_EndBlock(scriptName, -1)
r.PreventUIRefresh(-1)
r.UpdateArrange()

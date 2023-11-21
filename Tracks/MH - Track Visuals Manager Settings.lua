----------------------------------------
-- @noindex
----------------------------------------
--Setup
----------------------------------------
r = reaper
tvm = r.GetResourcePath() .. '/Scripts/MH Scripts/Tracks/MH - Track Visuals Manager Globals.lua'; if r.file_exists(tvm) then dofile(tvm); if not tvm then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end; else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local ctx = r.ImGui_CreateContext('My script') --Storing values at the very start so we can cancel and not change anything
--Setting font
local verdana = r.ImGui_CreateFont('verdana', 14)
r.ImGui_Attach(ctx, verdana)

local WindowFlags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoResize() | r.ImGui_WindowFlags_AlwaysAutoResize()
local ColorFlags = r.ImGui_ColorEditFlags_InputRGB() | r.ImGui_ColorEditFlags_NoAlpha()

local confirm
local cancel
local reset
local update

local Layouts = {}
local Overrides = {}
local DividerSymbol
local prevValues
----------------------------------------
TrackType = {}

function TrackType:new()
    local t = {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function TrackType:GetCurrentSettings(name)
    self.layout = tvm.GetExtValue(self.name .. '_TrackLayout')
    self.color = tonumber(tvm.GetExtValue(self.name .. '_TrackColor'))
    self.recolor = mh.ToBool(tvm.GetExtValue(self.name .. '_TrackRecolor'))
    self.height = tvm.GetExtValue(self.name .. '_TrackHeight')
    self.idx = GetLayoutIndex(self.layout)
end

function TrackType:SaveCurrentSettings()
    tvm.SetExtValue(self.name .. '_TrackLayout', self.layout)
    tvm.SetExtValue(self.name .. '_TrackColor', self.color)
    tvm.SetExtValue(self.name .. '_TrackRecolor', self.recolor)
    tvm.SetExtValue(self.name .. '_TrackHeight', self.height)
    tvm.SetExtValue(self.name .. '_TrackHeight', self.height)
    self.idx = GetLayoutIndex(self.layout)
end

function TrackType:CreateTab()
    --Track Height Slider
    r.ImGui_PushID(ctx, self.name)
    local isSlider, val = r.ImGui_SliderInt(ctx, 'Track Height', self.height, 1, 100, '%d', 0)
    r.ImGui_PopID(ctx)
    if isSlider then
        self.height = val
        update = true
    end

    --Track Layout Combo Box
    r.ImGui_PushID(ctx, self.name)
    if r.ImGui_BeginCombo(ctx, 'TCP Layout', Layouts[self.idx], r.ImGui_ComboFlags_HeightLargest()) then
        for i, v in ipairs(Layouts) do
            local is_selected = self.selIdx == i
            if r.ImGui_Selectable(ctx, Layouts[i], is_selected) then
                self.layout = Layouts[i]
                update = true
            end
            if is_selected then
                r.ImGui_SetItemDefaultFocus(ctx)
            end
        end
        r.ImGui_EndCombo(ctx)
    end
    r.ImGui_PopID(ctx)

    -- Recolor Check Box
    r.ImGui_PushID(ctx, self.name)
    local isRecolor, rec = r.ImGui_Checkbox(ctx, 'Recolor Tracks', self.recolor)
    r.ImGui_PopID(ctx)
    if isRecolor then
        self.recolor = rec
        update = true
    end

    --Color Button
    r.ImGui_SameLine(ctx)
    r.ImGui_PushID(ctx, self.name)
    local pressed = r.ImGui_ColorButton(ctx, 'color', self.color, ColorFlags, 25, 25)
    r.ImGui_PopID(ctx)
    if pressed then
        r.ImGui_OpenPopup(ctx, 'my color picker')
    end
    --Color Picker
    r.ImGui_SameLine(ctx)
    r.ImGui_Text(ctx, 'Track Color')
    if r.ImGui_BeginPopup(ctx, 'my color picker') then
        r.ImGui_PushID(ctx, self.name)
        local isNewColor, color = r.ImGui_ColorPicker3(ctx, 'color picker', self.color, ColorFlags)
        r.ImGui_PopID(ctx)
        if isNewColor then
            self.color = color
            update = true
        end
        r.ImGui_EndPopup(ctx)
    end
end

----------------------------------------
Divider = TrackType:new()
Divider.name = 'Divider'
Folder = TrackType:new()
Folder.name = 'Folder'
Bus = TrackType:new()
Bus.name = 'Bus'
----------------------------------------
--Functions
----------------------------------------

function CreateOverrideTab(idx, name, color)
    r.ImGui_PushID(ctx, 'TrackNameOverride' .. idx)
    local isNewName, newName = r.ImGui_InputText(ctx, 'Color Override ', name, r.ImGui_InputTextFlags_None())
    r.ImGui_PopID(ctx)
    if isNewName then
        local newOverride = {}
        newOverride[newName] = color
        Overrides[idx] = newOverride
        update = true
    end
    r.ImGui_SameLine(ctx)
    r.ImGui_PushID(ctx, 'ColorButtonOverride' .. idx)
    local pressed = r.ImGui_ColorButton(ctx, 'Color Override ', color, ColorFlags, 25, 25)
    r.ImGui_PopID(ctx)
    if pressed then
        r.ImGui_OpenPopup(ctx, idx)
    end
    if r.ImGui_BeginPopup(ctx, idx) then
        r.ImGui_PushID(ctx, 'ColorPickerOverride' .. idx)
        local isNewColor, newColor = r.ImGui_ColorPicker3(ctx, 'Color Override ', color, ColorFlags)
        if isNewColor then
            Overrides[idx][name] = newColor
            update = true
        end
        r.ImGui_PopID(ctx)
        r.ImGui_EndPopup(ctx)
    end
    --Button to Delete Override
    r.ImGui_SameLine(ctx)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4.0, 4.0)
    r.ImGui_PushID(ctx, 'DeleteButton' .. idx)
    if r.ImGui_Button(ctx, 'x', 22.0, 22.0) then
        table.remove(Overrides, idx)
        update = true
    end
    r.ImGui_PopID(ctx)
    r.ImGui_PopStyleVar(ctx)
end

function GetLayouts()
    local layouts = {}
    layouts[1] = 'Global layout default'
    local i = 1
    repeat
        local retval, name = reaper.ThemeLayout_GetLayout('tcp', i)
        if retval then
            layouts[#layouts + 1] = name
        end
        i = i + 1
    until not retval
    return layouts
end

function GetLayoutIndex(name)
    local isValidLayout = false
    local selIdx
    for i, layout in ipairs(Layouts) do
        if name == layout then
            isValidLayout = true
            selIdx = i
            break
        end
    end
    --if saved layout is not part of your current theme then we'll default to the 'default' layout
    if not isValidLayout then
        selIdx = 1
    end
    return selIdx
end

function UndoValues()
    for name, value in pairs(prevValues) do
        r.SetExtState(tvm.ExtSection, name, value, true)
    end
end

--Main function for creating all of our UI
function DrawUI()
    r.ImGui_PushFont(ctx, verdana)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowRounding(), 5.0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(), 10.0, 10.0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 12.0, 5.0)
    local visible, open = r.ImGui_Begin(ctx, 'Track Visuals Manager - Settings', true, WindowFlags)
    if visible then
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 3.0)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 10.0, 4.0)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 1, 8)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_PopupRounding(), 10.0)
        if r.ImGui_BeginTabBar(ctx, 'TrackTypes', r.ImGui_TabBarFlags_Reorderable()) then
            --Divider Tab
            if r.ImGui_BeginTabItem(ctx, 'Divider') then
                Divider:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            --Folder Tab
            if r.ImGui_BeginTabItem(ctx, 'Folder Items') then
                Folder:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            --Bus Tab
            if r.ImGui_BeginTabItem(ctx, 'Folder Bus') then
                Bus:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            --Overrides Tab
            if r.ImGui_BeginTabItem(ctx, 'Overrides') then
                r.ImGui_Text(ctx, 'Track Name Color Overrides')
                r.ImGui_Separator(ctx)
                for index, override in ipairs(Overrides) do
                    for name, color in pairs(override) do
                        CreateOverrideTab(index, name, color)
                    end
                end
                --New Override Button
                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4.0, 4.0)
                if r.ImGui_Button(ctx, '+', 22.0, 22.0) then
                    local override = {}
                    override[' '] = 0
                    Overrides[#Overrides + 1] = override
                    update = true
                end
                r.ImGui_PopStyleVar(ctx)
                r.ImGui_EndTabItem(ctx)
            end
            --Options Tab
            if r.ImGui_BeginTabItem(ctx, 'Options') then
                --Divider Track Symbol
                local isNew, input = r.ImGui_InputText(ctx, 'Divider Track Symbol', DividerSymbol,
                    r.ImGui_InputTextFlags_CharsNoBlank())
                if isNew then
                    update = true
                    DividerSymbol = input
                end
                --Reset Defaults Button
                reset = r.ImGui_Button(ctx, 'Reset to Defaults', 150.0, 25.0)
                if reset then
                    update = true
                end
                r.ImGui_EndTabItem(ctx)
            end
            r.ImGui_EndTabBar(ctx)
        end

        --Confirm Button
        r.ImGui_Separator(ctx)
        confirm = r.ImGui_Button(ctx, 'Confirm', 150.0, 25.0)
        if confirm then
            update = true
        end


        --Cancel Button
        r.ImGui_SameLine(ctx)
        cancel = r.ImGui_Button(ctx, 'Cancel', 150.0, 25.0)
        if cancel then
            update = true
        end

        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_End(ctx)
    end
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_PopFont(ctx)
    return open
end

--Runs once at script startup. Reads and stores all the settings from disk that we'll need later.
function Setup()
    prevValues = tvm.GetAllExtValues()

    Layouts = GetLayouts()
    Overrides = tvm.GetOverrides()
    DividerSymbol = tvm.GetExtValue("DividerSymbol")
    Divider:GetCurrentSettings()
    Bus:GetCurrentSettings()
    Folder:GetCurrentSettings()
end

function Main()
    update = false
    local open = DrawUI()
    if reset then
        --Resets All Values to Default
        tvm.ResetAllExtValues()
        Divider:GetCurrentSettings()
        Folder:GetCurrentSettings()
        Bus:GetCurrentSettings()
        Overrides = tvm.GetOverrides()
        DividerSymbol = tvm.GetExtValue("DividerSymbol")
    else
        if update then
            --Updates all of our values
            Divider:SaveCurrentSettings()
            Folder:SaveCurrentSettings()
            Bus:SaveCurrentSettings()
            tvm.SetExtValue('DividerSymbol', DividerSymbol)
            tvm.SetOverrides(Overrides) 
        end
    end
    if cancel then
        UndoValues()
        open = false
    elseif confirm then
       open = false
    end
    if open then
        r.defer(Main)
    end
end

----------------------------------------
--Main
----------------------------------------
Setup()
Main()

----------------------------------------
-- @noindex
----------------------------------------
--Setup
----------------------------------------
r = reaper
mh = r.GetResourcePath() .. '/Scripts/MH Scripts/Functions/MH - Functions.lua'; if r.file_exists(mh) then dofile(mh); if not mh or mh.version() < 1.0 then r.ShowMessageBox('This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages', 'Error', 0); return end else r.ShowMessageBox('This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information', 'Error', 0); return end
if not mh.SWS() and not mh.ImGui() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local ctx = r.ImGui_CreateContext('My script') --Storing values at the very start so we can cancel and not change anything
--Setting font
local verdana = r.ImGui_CreateFont('verdana', 14)
r.ImGui_Attach(ctx, verdana)

local WindowFlags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoResize() |
r.ImGui_WindowFlags_AlwaysAutoResize()
local ColorFlags = r.ImGui_ColorEditFlags_InputRGB() | r.ImGui_ColorEditFlags_NoAlpha()
local DividerFlags =  r.ImGui_InputTextFlags_AlwaysOverwrite() |  r.ImGui_InputTextFlags_CharsNoBlank() |  reaper.ImGui_InputTextFlags_AutoSelectAll()

local confirm
local cancel
local reset
local update

local Layouts = {}
local Overrides = {}
local DividerSymbol
local prevValues
local defaultOverrideColor = 16711680
----------------------------------------
TrackType = {}

function TrackType:new()
    local t = {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function TrackType:GetCurrentSettings()
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
    r.ImGui_PushID(ctx, self.name .. ' slider')
    local isSlider, val = r.ImGui_SliderInt(ctx, 'Track Height', self.height, 1, 100, '%d', 0)
    r.ImGui_PopID(ctx)
    if isSlider then
        self.height = val
        update = true
    end

    --Track Layout Combo Box
    r.ImGui_PushID(ctx, self.name .. ' comboBox')
    if r.ImGui_BeginCombo(ctx, 'Track Layout', Layouts[self.idx], r.ImGui_ComboFlags_HeightLargest()) then
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

    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 70, 10)
    --Recolor Check Box
    r.ImGui_PushID(ctx, self.name .. 'checkbox')
    local isRecolor, rec = r.ImGui_Checkbox(ctx, ' Recolor Tracks   ', self.recolor)
    r.ImGui_PopID(ctx)
    if isRecolor then
        self.recolor = rec
        update = true
    end
    --Color Button
    r.ImGui_SameLine(ctx)
    r.ImGui_PushID(ctx, self.name .. 'button')
    local pressed = r.ImGui_ColorButton(ctx, 'color', self.color, ColorFlags, 22, 22)
    r.ImGui_PopID(ctx)
    if pressed then
        r.ImGui_OpenPopup(ctx, 'my color picker')
    end
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_SameLine(ctx)
    r.ImGui_Text(ctx, 'Track Color')
    --Color Picker
    if r.ImGui_BeginPopup(ctx, 'my color picker') then
        r.ImGui_PushID(ctx, self.name .. 'colorPicker')
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
    --Doing some string swapping to make sure we don't store an empty string
    if name == tvm.emptyOverrideName then
        name = ''
    end
    r.ImGui_PushID(ctx, 'TrackNameOverride' .. idx)
    local isNewName, newName = r.ImGui_InputText(ctx, '', name, r.ImGui_InputTextFlags_None())
    r.ImGui_PopID(ctx)
    if isNewName then
        --Doing some string swapping to make sure we don't store an empty string
        if newName == '' then
            newName = tvm.emptyOverrideName
        end
        local newOverride = {}
        newOverride[newName] = color
        Overrides[idx] = newOverride
        update = true
    end
    r.ImGui_SameLine(ctx)
    r.ImGui_PushID(ctx, 'ColorButtonOverride' .. idx)
    local pressed = r.ImGui_ColorButton(ctx, 'Color Override ', color, ColorFlags, 22, 22)
    r.ImGui_PopID(ctx)
    if pressed then
        r.ImGui_OpenPopup(ctx, idx)
    end
    if r.ImGui_BeginPopup(ctx, idx) then
        r.ImGui_PushID(ctx, 'ColorPickerOverride' .. idx)
        local isNewColor, newColor = r.ImGui_ColorPicker3(ctx, 'Color Override', color, ColorFlags)
        if isNewColor then
            --Doing some string swapping to make sure we don't store an empty string
            if name == '' then
                name = tvm.emptyOverrideName
            end
            Overrides[idx][name] = newColor
            update = true
        end
        r.ImGui_PopID(ctx)
        r.ImGui_EndPopup(ctx)
    end
    --Button to Delete Override
    r.ImGui_SameLine(ctx)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 1.0, 1.0)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.5, 0.4)
    reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(), 0x781616DC)
    reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(), 0xB40000FF)
    reaper.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0xFF1919CC)
    r.ImGui_PushID(ctx, 'DeleteButton' .. idx)
    if r.ImGui_Button(ctx, '×', 22.0, 22.0) then
        table.remove(Overrides, idx)
        update = true
    end
    r.ImGui_PopID(ctx)
    r.ImGui_PopStyleColor(ctx, 3)
    r.ImGui_PopStyleVar(ctx, 2)
end

function GetLayouts()
    local layouts = {}
    layouts[1] = 'Global layout default'
    local i = 1
    repeat
        local retval, name = r.ThemeLayout_GetLayout('tcp', i)
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
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 10.0, 5.0)
    local visible, open = r.ImGui_Begin(ctx, 'Track Visuals Manager - Settings', true, WindowFlags)
    if visible then
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 3.0)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 10.0, 4.0)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 10, 10)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_PopupRounding(), 5.0)
        --Tab Bar
        if r.ImGui_BeginTabBar(ctx, 'TrackTypes', r.ImGui_TabBarFlags_Reorderable()) then
            r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemInnerSpacing(), 9, 5)
            --Folder Tab
            r.ImGui_SetNextItemWidth(ctx, 100)
            if r.ImGui_BeginTabItem(ctx, 'Folder Parent') then
                Folder:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            --Bus Tab
            r.ImGui_SetNextItemWidth(ctx, 100)
            if r.ImGui_BeginTabItem(ctx, 'Folder Bus') then
                Bus:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            r.ImGui_SetNextItemWidth(ctx, 100)
            if r.ImGui_BeginTabItem(ctx, 'Dividers') then
                Divider:CreateTab()
                r.ImGui_EndTabItem(ctx)
            end
            r.ImGui_EndTabBar(ctx)
            r.ImGui_PopStyleVar(ctx)
        end
        --Overrides Section
        reaper.ImGui_Spacing(ctx)
        r.ImGui_Separator(ctx)
        reaper.ImGui_Spacing(ctx)
        r.ImGui_Text(ctx, 'Track Name Color Overrides')
        for index, override in ipairs(Overrides) do
            for name, color in pairs(override) do
                CreateOverrideTab(index, name, color)
            end
        end
        --New Override Button
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 1.0, 1.0)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ButtonTextAlign(), 0.6, 0.45)
        if r.ImGui_Button(ctx, '+', 22.0, 22.0) then
            local override = {}
            override[tvm.emptyOverrideName] = defaultOverrideColor
            Overrides[#Overrides + 1] = override
            update = true
        end
        r.ImGui_PopStyleVar(ctx, 2)
        reaper.ImGui_Spacing(ctx)
        --Options Section
        r.ImGui_Separator(ctx)
        --Divider Track Symbol
        r.ImGui_PushID(ctx, 'DividerSymbol')
        reaper.ImGui_SetNextItemWidth(ctx, 28)
        r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 9.0, 5.0)
        local isNew, input = r.ImGui_InputText(ctx, ' Divider Track Symbol ', DividerSymbol, DividerFlags)
        r.ImGui_PopStyleVar(ctx)
        r.ImGui_PopID(ctx)
        if isNew then
            input = input:sub(#input, #input)
            DividerSymbol = input
            update = true
        end
        --Reset Defaults Button
        r.ImGui_SameLine(ctx)
        reset = r.ImGui_Button(ctx, 'Reset all to Defaults', 140.0, 22.0)
        if reset then
            update = true
        end
        --Confirm Button
        r.ImGui_Separator(ctx)
        confirm = r.ImGui_Button(ctx, 'Confirm', 155.0, 30.0)
        if confirm then
            update = true
        end
        --Cancel Button
        r.ImGui_SameLine(ctx)
        cancel = r.ImGui_Button(ctx, 'Cancel', 155.0, 30.0)
        if cancel then
            update = true
        end
        r.ImGui_PopStyleVar(ctx, 4)
        r.ImGui_End(ctx)
    end
    r.ImGui_PopStyleVar(ctx, 3)
    r.ImGui_PopFont(ctx)
    return open
end

--Runs once at script startup. Reads and stores all the settings from disk that we'll need later.
function Setup()
    prevValues = tvm.GetAllExtValues()
    Layouts = GetLayouts()
    Overrides = tvm.GetOverrides()
    DividerSymbol = tvm.GetExtValue('DividerSymbol')
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
        DividerSymbol = tvm.GetExtValue('DividerSymbol')
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

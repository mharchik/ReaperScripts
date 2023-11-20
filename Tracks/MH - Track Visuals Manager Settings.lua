----------------------------------------
-- @noindex
----------------------------------------
--Setup
----------------------------------------
r = reaper
tvm = r.GetResourcePath() .. '/Scripts/MH Scripts/Tracks/MH - Track Visuals Manager Globals.lua'; if r.file_exists(tvm) then dofile(tvm); if not tvm then r.ShowMessageBox("This script requires a newer version of the MH Scripts repositiory!\n\n\nPlease resync from the above menu:\n\nExtensions > ReaPack > Synchronize Packages", "Error", 0); return end
else r.ShowMessageBox("This script requires the full MH Scripts repository!\n\nPlease visit github.com/mharchik/ReaperScripts for more information", "Error", 0); return end
if not mh.SWS() or not mh.JS() then mh.noundo() return end
----------------------------------------
--Script Variables
----------------------------------------
local prevValues =  tvm.GetAllExtValues()
local ctx = r.ImGui_CreateContext('My script')
--Setting font
local verdana = r.ImGui_CreateFont('verdana', 14)
r.ImGui_Attach(ctx, verdana)

local WindowFlags = r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoResize() | r.ImGui_WindowFlags_AlwaysAutoResize()
local Layouts
----------------------------------------
TrackType = {}

function TrackType:new(t)
    t = t or {}
    setmetatable(t, self)
    self.__index = self
    return t
end

function TrackType:GetCurrentSettings(name)
    self.layout = tvm.GetExtValue(name .. "_TrackLayout")
    self.color = tonumber(tvm.GetExtValue(name .. "_TrackColor"))
    self.recolor = mh.ToBool(tvm.GetExtValue(name .. "_TrackRecolor"))
    self.height = tvm.GetExtValue(name .. "_TrackHeight")
end

function TrackType:SaveCurrentSettings(name)
    tvm.SetExtValue(name .. "_TrackLayout", self.layout)
    tvm.SetExtValue(name .. "_TrackColor", self.color)
    tvm.SetExtValue(name .. "_TrackRecolor", self.recolor)
    tvm.SetExtValue(name .. "_TrackHeight", self.height)
end

function TrackType:TabSettings()
    local isSlider, val = r.ImGui_SliderInt(ctx, "Track Height", self.height, 1, 100, "%d", 0)
    if isSlider then
        self.height = val
    end
    local isValidLayout = false
    local selIdx
    for i, layout in ipairs(Layouts) do
        if self.layout == layout then
            isValidLayout = true
            selIdx = i
        end
    end
    --if saved layout is not part of your current theme then we'll default to the "default" layout
    if not isValidLayout then
        selIdx = 1
    end
    if r.ImGui_BeginCombo(ctx, 'TCP Layout', Layouts[selIdx], r.ImGui_ComboFlags_HeightLargest()) then
        for i, v in ipairs(Layouts) do
            local is_selected = self.selIdx == i
            if r.ImGui_Selectable(ctx, Layouts[i], is_selected) then
                self.layout = Layouts[i]
            end
            if is_selected then
                r.ImGui_SetItemDefaultFocus(ctx)
            end
        end
        r.ImGui_EndCombo(ctx)
    end
    local isRecolor, rec = r.ImGui_Checkbox(ctx, "Recolor Tracks", self.recolor)
    if isRecolor then
        self.recolor = rec
    end
    r.ImGui_SameLine(ctx)
    local pressed = r.ImGui_ColorButton(ctx, "color", self.color, 0, 25, 25)
    if pressed then
        r.ImGui_OpenPopup(ctx, 'my color picker')
    end
    r.ImGui_SameLine(ctx)
    r.ImGui_Text(ctx, "Track Color")
    if r.ImGui_BeginPopup(ctx, 'my color picker') then
        local isNewColor, color = r.ImGui_ColorPicker4(ctx, "color picker", self.color, r.ImGui_ColorEditFlags_InputRGB())
        if isNewColor then
            self.color = color
        end
        r.ImGui_EndPopup(ctx)
    end
end

----------------------------------------

Divider = TrackType:new()
Divider:GetCurrentSettings("Divider")
Bus = TrackType:new()
Bus:GetCurrentSettings("Bus")
Folder = TrackType:new()
Folder:GetCurrentSettings("Folder")

local confirm = false
local cancel = false
local reset = false
local dividerSymbol = tvm.GetExtValue("DividerTrackSymbol")

--color = 0x00000001
local o1 = {}
o1["video"] = 0x00000001
local o2 = {}
o2["source"] = 0x006666B5
local o3 = {}
o3["Mic In"] = 0x00FF0000
Overrides = { o1, o2, o3 }

----------------------------------------
--Functions
----------------------------------------
function GetLayouts()
    local layouts = {}
    layouts[1] = "Global layout default"
    local i = 1
    repeat
        local retval, name = reaper.ThemeLayout_GetLayout( "tcp", i)
        if retval then
            layouts[#layouts+1] = name
        end
        i = i + 1
    until not retval
    return layouts
end

function SetAllValues(table)
    for name, value in pairs(table) do
        tvm.SetExtValue(name, tostring(value))
    end
end

function OverrideSettings(idx, name, color)
    local isNewName, newName = r.ImGui_InputText(ctx, "Color Override " .. idx .. " ", name,
        r.ImGui_InputTextFlags_CharsNoBlank())
    if isNewName then
        local newOverride = {}
        newOverride[newName] = color
        Overrides[idx] = newOverride
    end
    r.ImGui_SameLine(ctx)
    local pressed = r.ImGui_ColorButton(ctx, "Color Override " .. idx, color, 0, 25, 25)
    if pressed then
        r.ImGui_OpenPopup(ctx, idx)
    end
    if r.ImGui_BeginPopup(ctx, idx) then
        local isNewColor, newColor = r.ImGui_ColorPicker4(ctx, "Color Override " .. idx .. " ", color, r.ImGui_ColorEditFlags_InputRGB())
        if isNewColor then
            reaper.ColorFromNative(newColor)
            Overrides[idx][name] = newColor
        end
        r.ImGui_EndPopup(ctx)
    end
end

function Main()
    Layouts = GetLayouts()
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
            if r.ImGui_BeginTabItem(ctx, 'Divider') then
                Divider:TabSettings()
                Divider:SaveCurrentSettings("Divider")
                r.ImGui_EndTabItem(ctx)
            end
            if r.ImGui_BeginTabItem(ctx, 'Folder Bus') then
                Bus:TabSettings()
                Bus:SaveCurrentSettings("Bus")
                r.ImGui_EndTabItem(ctx)
            end
            if r.ImGui_BeginTabItem(ctx, 'Folder Items') then
                Folder:TabSettings()
                Folder:SaveCurrentSettings("Folder")
                r.ImGui_EndTabItem(ctx)
            end
            if r.ImGui_BeginTabItem(ctx, 'Overrides') then
                r.ImGui_Text(ctx, "Track Name Color Overrides")
                r.ImGui_Separator(ctx)
                for index, override in ipairs(Overrides) do
                    for name, color in pairs(override) do
                        OverrideSettings(index, name, color)
                    end
                    r.ImGui_SameLine(ctx)
                    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4.0, 4.0)
                    r.ImGui_PushID(ctx, "Delete Override " .. index)
                    if r.ImGui_Button(ctx, "x", 22.0, 22.0) then
                        table.remove(Overrides, index)
                    end
                    r.ImGui_PopID(ctx)
                    r.ImGui_PopStyleVar(ctx)
                end
                r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(), 4.0, 4.0)
                if r.ImGui_Button(ctx, "+", 22.0, 22.0) then
                    local override = {}
                    override[" "] = 0x00000001
                    Overrides[#Overrides + 1] = override
                end
                r.ImGui_PopStyleVar(ctx)
                r.ImGui_EndTabItem(ctx)
            end
            if r.ImGui_BeginTabItem(ctx, 'Options') then
                local isNew, input = r.ImGui_InputText(ctx, 'Divider Track Symbol', dividerSymbol, r.ImGui_InputTextFlags_CharsNoBlank())
                if isNew then
                    dividerSymbol = input
                    tvm.SetExtValue("DividerTrackSymbol",input)
                end
                if r.ImGui_Button(ctx, "Reset to Defaults", 150.0, 25.0) then
                    tvm.ResetAllExtValues()
                    local vals = tvm.GetAllExtValues()
                    SetAllValues(vals)
                    Divider:GetCurrentSettings("Divider")
                    Folder:GetCurrentSettings("Folder")
                    Bus:GetCurrentSettings("Bus")
                    dividerSymbol = tvm.GetAllExtValues("DividerTrackSymbol")
                end
                r.ImGui_EndTabItem(ctx)
            end
            r.ImGui_EndTabBar(ctx)
        end
        r.ImGui_Separator(ctx)

        if r.ImGui_Button(ctx, "Confirm", 150.0, 25.0) then
            confirm = true
        end
        r.ImGui_SameLine(ctx)
        if r.ImGui_Button(ctx, "Cancel", 150.0, 25.0) then
            cancel = true
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
    if confirm then
        local vals = tvm.GetAllExtValues()
        SetAllValues(vals)
    elseif cancel then
        SetAllValues(prevValues)
    elseif open and not confirm and not cancel then
        r.defer(Main)
    end
end

----------------------------------------
--Main
----------------------------------------
Main()

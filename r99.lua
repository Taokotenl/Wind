--[[
    VTriP RayfieldAdapter - Advanced Edition v2.0
    Hỗ trợ:
    - Export cấu trúc UI ra JSON (clipboard)
    - Import JSON đã chỉnh sửa
    - Tự động sắp xếp, ẩn/hiện, đổi tên elements
    
    Sử dụng:
    local Rayfield = loadstring(game:HttpGet('YOUR_URL'))()
    
    -- Sau khi UI tạo xong, export:
    Rayfield:ExportConfig()
    
    -- Hoặc import config đã chỉnh sửa:
    Rayfield:ImportConfig('JSON_STRING_HERE')
]]

-- ==================== SERVICES ====================
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ==================== LOAD WINDUI ====================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ==================== CUSTOM THEME ====================
WindUI:AddTheme({
    Name = "VTriP Dark",
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#040040"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#473BE8"), Transparency = 0.42 },
    }, { Rotation = 104 }),
    Background = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#040040"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#473BE8"), Transparency = 0.42 },
    }, { Rotation = 104 }),
})

-- ==================== UTILITIES ====================
local function SafeJSONEncode(tbl)
    local success, result = pcall(function()
        return HttpService:JSONEncode(tbl)
    end)
    return success and result or nil
end

local function SafeJSONDecode(str)
    local success, result = pcall(function()
        return HttpService:JSONDecode(str)
    end)
    return success and result or nil
end

local function ConvertIcon(icon)
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle"
    end
    return icon or "circle"
end

local function DeepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ==================== DUMMY ELEMENT ====================
-- Dùng cho các element bị disable, tránh script lỗi
local DummyElement = {}
DummyElement.CurrentValue = nil
DummyElement.CurrentOption = nil
DummyElement.CurrentKeybind = nil

setmetatable(DummyElement, {
    __index = function(self, key)
        return function(...) 
            return DummyElement 
        end
    end,
    __newindex = function() end,
    __call = function() return DummyElement end
})

-- ==================== MAIN ADAPTER ====================
local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}
RayfieldAdapter.Windows = {}
RayfieldAdapter.UIStructure = {}  -- Lưu cấu trúc UI gốc
RayfieldAdapter.CustomConfig = nil -- Config đã import từ JSON
RayfieldAdapter.ElementRegistry = {} -- Registry tất cả elements đã tạo

-- ==================== CONFIG MANAGEMENT ====================

-- Export cấu trúc UI ra clipboard
function RayfieldAdapter:ExportConfig()
    local exportData = DeepCopy(self.UIStructure)
    local json = SafeJSONEncode(exportData)
    
    if json then
        if setclipboard then
            setclipboard(json)
            self:Notify({
                Title = "VTriP Config",
                Content = "Đã copy JSON config vào clipboard!\nHãy dán vào Web Tool để chỉnh sửa.",
                Duration = 5
            })
        else
            warn("[VTriP] setclipboard không khả dụng")
        end
        return json
    end
    return nil
end

-- Import config từ JSON string
function RayfieldAdapter:ImportConfig(jsonString)
    local config = SafeJSONDecode(jsonString)
    if config then
        self.CustomConfig = config
        self:Notify({
            Title = "VTriP Config",
            Content = "Đã import config thành công!",
            Duration = 3
        })
        return true
    else
        self:Notify({
            Title = "VTriP Config",
            Content = "Lỗi: JSON không hợp lệ!",
            Duration = 3
        })
        return false
    end
end

-- Load config từ file (nếu có)
function RayfieldAdapter:LoadConfigFromFile(fileName)
    if not isfolder or not isfile or not readfile then
        return false
    end
    
    local folderPath = "VTriP_Configs"
    local filePath = folderPath .. "/" .. fileName .. ".json"
    
    if isfolder(folderPath) and isfile(filePath) then
        local content = readfile(filePath)
        return self:ImportConfig(content)
    end
    return false
end

-- Save config ra file
function RayfieldAdapter:SaveConfigToFile(fileName)
    if not isfolder or not makefolder or not writefile then
        return false
    end
    
    local folderPath = "VTriP_Configs"
    local filePath = folderPath .. "/" .. fileName .. ".json"
    
    if not isfolder(folderPath) then
        makefolder(folderPath)
    end
    
    local json = SafeJSONEncode(self.UIStructure)
    if json then
        writefile(filePath, json)
        return true
    end
    return false
end

-- ==================== HELPER: CHECK ELEMENT CONFIG ====================
local function GetElementConfig(adapter, windowId, tabId, elementId)
    local config = adapter.CustomConfig
    if not config then return nil end
    
    -- Tìm trong config
    if config[windowId] and config[windowId].tabs then
        if config[windowId].tabs[tabId] and config[windowId].tabs[tabId].elements then
            return config[windowId].tabs[tabId].elements[elementId]
        end
    end
    
    return nil
end

local function IsElementEnabled(adapter, windowId, tabId, elementId)
    local elemConfig = GetElementConfig(adapter, windowId, tabId, elementId)
    if elemConfig then
        return elemConfig.enabled ~= false
    end
    return true -- Mặc định enabled nếu không có config
end

local function GetElementDisplayName(adapter, windowId, tabId, elementId, originalName)
    local elemConfig = GetElementConfig(adapter, windowId, tabId, elementId)
    if elemConfig and elemConfig.name then
        return elemConfig.name
    end
    return originalName
end

local function GetElementOrder(adapter, windowId, tabId, elementId)
    local elemConfig = GetElementConfig(adapter, windowId, tabId, elementId)
    if elemConfig and elemConfig.order then
        return elemConfig.order
    end
    return 9999
end

-- ==================== CREATE WINDOW ====================
function RayfieldAdapter:CreateWindow(config)
    local WindowAdapter = {}
    
    -- Xử lý tên Window
    local windowTitle = config.Name or "Window"
    local originalWindowName = windowTitle
    if windowTitle:find("Flash Hub") then
        windowTitle = windowTitle:gsub("Flash Hub", "VTriP")
    end
    
    local windowId = originalWindowName
    
    -- Khởi tạo UIStructure cho window này
    self.UIStructure[windowId] = {
        name = windowTitle,
        tabs = {}
    }
    
    -- Tạo WindUI Window
    local windConfig = {
        Title = windowTitle,
        Icon = ConvertIcon(config.Icon),
        Author = "Host By VTriP Official",
        Folder = (config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "VTriP_Data",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = "VTriP Dark",
        Resizable = true,
        SideBarWidth = 200,
    }
    
    -- Key System
    if config.KeySystem and config.KeySettings then
        windConfig.KeySystem = {
            Key = config.KeySettings.Key or {},
            Note = config.KeySettings.Note or "",
            SaveKey = config.KeySettings.SaveKey or false,
        }
    end
    
    local Window = WindUI:CreateWindow(windConfig)
    
    -- Open Button
    Window:EditOpenButton({
        Title = "Open VTriP",
        Icon = ConvertIcon(config.Icon),
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(
            Color3.fromHex("FF0F7B"),
            Color3.fromHex("F89B29")
        ),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    })
    
    -- Toggle Key
    if config.ToggleUIKeybind then
        local keyCode = config.ToggleUIKeybind
        if type(keyCode) == "string" then
            pcall(function()
                Window:SetToggleKey(Enum.KeyCode[keyCode])
            end)
        else
            pcall(function()
                Window:SetToggleKey(keyCode)
            end)
        end
    end
    
    -- Lưu references
    WindowAdapter._windWindow = Window
    WindowAdapter._windowId = windowId
    WindowAdapter._config = config
    WindowAdapter._tabs = {}
    WindowAdapter._tabOrder = 0
    
    -- Lưu vào registry
    self.Windows[windowId] = WindowAdapter
    
    -- ==================== CREATE TAB ====================
    function WindowAdapter:CreateTab(name, icon)
        local TabAdapter = {}
        local tabId = name
        local originalTabName = name
        
        WindowAdapter._tabOrder = WindowAdapter._tabOrder + 1
        
        -- Khởi tạo UIStructure cho tab
        RayfieldAdapter.UIStructure[windowId].tabs[tabId] = {
            name = name,
            icon = ConvertIcon(icon),
            order = WindowAdapter._tabOrder,
            elements = {}
        }
        
        -- Tạo Tab
        local Tab = Window:Tab({
            Title = name,
            Icon = ConvertIcon(icon),
        })
        
        TabAdapter._windTab = Tab
        TabAdapter._tabId = tabId
        TabAdapter._windowId = windowId
        TabAdapter._elementOrder = 0
        TabAdapter._pendingElements = {} -- Lưu elements để sort sau
        
        -- ==================== HELPER: REGISTER ELEMENT ====================
        local function RegisterElement(elementId, elementType, originalConfig)
            TabAdapter._elementOrder = TabAdapter._elementOrder + 1
            
            RayfieldAdapter.UIStructure[windowId].tabs[tabId].elements[elementId] = {
                type = elementType,
                name = originalConfig.Name or originalConfig.Title or elementId,
                enabled = true,
                order = TabAdapter._elementOrder,
                -- Lưu thêm config gốc để reference
                originalConfig = {
                    Flag = originalConfig.Flag,
                    CurrentValue = originalConfig.CurrentValue,
                    Range = originalConfig.Range,
                    Options = originalConfig.Options,
                }
            }
        end
        
        -- ==================== CREATE SECTION ====================
        function TabAdapter:CreateSection(name)
            local SectionAdapter = {}
            
            local Section = Tab:Section({
                Title = name,
                Box = false,
                TextSize = 18,
                Opened = true,
            })
            
            SectionAdapter._windSection = Section
            
            function SectionAdapter:Set(newName)
                pcall(function()
                    Section:SetTitle(newName)
                end)
            end
            
            return SectionAdapter
        end
        
        -- ==================== CREATE DIVIDER ====================
        function TabAdapter:CreateDivider()
            local DividerAdapter = {}
            
            Tab:Section({
                Title = "─────────────────",
                Box = false,
                Opened = true,
            })
            
            function DividerAdapter:Set(visible)
                -- WindUI không hỗ trợ ẩn/hiện section
            end
            
            return DividerAdapter
        end
        
        -- ==================== CREATE BUTTON ====================
        function TabAdapter:CreateButton(config)
            local elementId = config.Name
            RegisterElement(elementId, "Button", config)
            
            -- Kiểm tra enabled
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                return DummyElement
            end
            
            local ButtonAdapter = {}
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local Button = Tab:Button({
                Title = displayName,
                Desc = config.Desc or "",
                Callback = config.Callback or function() end
            })
            
            ButtonAdapter._windButton = Button
            ButtonAdapter._elementId = elementId
            
            function ButtonAdapter:Set(newName)
                pcall(function()
                    Button:SetTitle(newName)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = ButtonAdapter
            return ButtonAdapter
        end
        
        -- ==================== CREATE TOGGLE ====================
        function TabAdapter:CreateToggle(config)
            local elementId = config.Name
            RegisterElement(elementId, "Toggle", config)
            
            -- Kiểm tra enabled
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local ToggleAdapter = {}
            ToggleAdapter.CurrentValue = config.CurrentValue or false
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local description = config.Desc or ""
            if config.Plus then
                description = "[Plus] " .. description
            end
            
            local Toggle = Tab:Toggle({
                Title = displayName,
                Desc = description,
                Type = "Checkbox",
                Value = config.CurrentValue or false,
                Callback = function(state)
                    ToggleAdapter.CurrentValue = state
                    if config.Callback then
                        config.Callback(state)
                    end
                end
            })
            
            ToggleAdapter._windToggle = Toggle
            ToggleAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ToggleAdapter
            end
            
            function ToggleAdapter:Set(value)
                self.CurrentValue = value
                pcall(function()
                    Toggle:Set(value)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = ToggleAdapter
            return ToggleAdapter
        end
        
        -- ==================== CREATE SLIDER ====================
        function TabAdapter:CreateSlider(config)
            local elementId = config.Name
            RegisterElement(elementId, "Slider", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local SliderAdapter = {}
            SliderAdapter.CurrentValue = config.CurrentValue or config.Range[1]
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local Slider = Tab:Slider({
                Title = displayName,
                Desc = config.Suffix or "",
                Step = config.Increment or 1,
                Value = {
                    Min = config.Range[1],
                    Max = config.Range[2],
                    Default = config.CurrentValue or config.Range[1],
                },
                Callback = function(value)
                    SliderAdapter.CurrentValue = value
                    if config.Callback then
                        config.Callback(value)
                    end
                end
            })
            
            SliderAdapter._windSlider = Slider
            SliderAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                pcall(function()
                    Slider:Set(value)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = SliderAdapter
            return SliderAdapter
        end
        
        -- ==================== CREATE INPUT ====================
        function TabAdapter:CreateInput(config)
            local elementId = config.Name
            RegisterElement(elementId, "Input", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local InputAdapter = {}
            InputAdapter.CurrentValue = config.CurrentValue or ""
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local Input = Tab:Input({
                Title = displayName,
                Desc = config.Desc or "",
                Value = config.CurrentValue or "",
                Type = "Input",
                Placeholder = config.PlaceholderText or "",
                Callback = function(text)
                    InputAdapter.CurrentValue = text
                    if config.Callback then
                        config.Callback(text)
                    end
                end
            })
            
            InputAdapter._windInput = Input
            InputAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                pcall(function()
                    Input:Set(value)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = InputAdapter
            return InputAdapter
        end
        
        -- ==================== CREATE DROPDOWN ====================
        function TabAdapter:CreateDropdown(config)
            local elementId = config.Name
            RegisterElement(elementId, "Dropdown", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local DropdownAdapter = {}
            local isMulti = config.MultipleOptions or false
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            -- Xử lý default value
            local defaultValue
            if isMulti then
                if type(config.CurrentOption) == "table" then
                    defaultValue = config.CurrentOption
                elseif type(config.CurrentOption) == "string" then
                    defaultValue = {config.CurrentOption}
                else
                    defaultValue = {}
                end
            else
                if type(config.CurrentOption) == "table" and #config.CurrentOption > 0 then
                    defaultValue = config.CurrentOption[1]
                elseif type(config.CurrentOption) == "string" then
                    defaultValue = config.CurrentOption
                else
                    defaultValue = config.Options and config.Options[1] or ""
                end
            end
            
            DropdownAdapter.CurrentOption = defaultValue
            
            local Dropdown = Tab:Dropdown({
                Title = displayName,
                Desc = config.Desc or "",
                Values = config.Options or {},
                Value = defaultValue,
                Multi = isMulti,
                AllowNone = true,
                Callback = function(options)
                    DropdownAdapter.CurrentOption = options
                    if config.Callback then
                        if isMulti then
                            config.Callback(type(options) == "table" and options or {options})
                        else
                            config.Callback(type(options) == "string" and {options} or options)
                        end
                    end
                end
            })
            
            DropdownAdapter._windDropdown = Dropdown
            DropdownAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = DropdownAdapter
            end
            
            function DropdownAdapter:Set(options)
                if isMulti then
                    local value = type(options) == "table" and options or {options}
                    self.CurrentOption = value
                    pcall(function()
                        Dropdown:Select(value)
                    end)
                else
                    local value = type(options) == "table" and options[1] or options
                    self.CurrentOption = value
                    pcall(function()
                        Dropdown:Select(value)
                    end)
                end
            end
            
            function DropdownAdapter:Refresh(newOptions, keepSelected)
                pcall(function()
                    Dropdown:Refresh(newOptions)
                end)
                if keepSelected and self.CurrentOption then
                    self:Set(self.CurrentOption)
                end
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = DropdownAdapter
            return DropdownAdapter
        end
        
        -- ==================== CREATE COLORPICKER ====================
        function TabAdapter:CreateColorPicker(config)
            local elementId = config.Name
            RegisterElement(elementId, "ColorPicker", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local ColorPickerAdapter = {}
            ColorPickerAdapter.CurrentValue = config.Color or Color3.fromRGB(255, 255, 255)
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local ColorPicker = Tab:Colorpicker({
                Title = displayName,
                Desc = config.Desc or "",
                Default = config.Color or Color3.fromRGB(255, 255, 255),
                Transparency = 0,
                Callback = function(color)
                    ColorPickerAdapter.CurrentValue = color
                    if config.Callback then
                        config.Callback(color)
                    end
                end
            })
            
            ColorPickerAdapter._windColorPicker = ColorPicker
            ColorPickerAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ColorPickerAdapter
            end
            
            function ColorPickerAdapter:Set(color)
                self.CurrentValue = color
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = ColorPickerAdapter
            return ColorPickerAdapter
        end
        
        -- ==================== CREATE KEYBIND ====================
        function TabAdapter:CreateKeybind(config)
            local elementId = config.Name
            RegisterElement(elementId, "Keybind", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                if config.Flag then
                    RayfieldAdapter.Flags[config.Flag] = DummyElement
                end
                return DummyElement
            end
            
            local KeybindAdapter = {}
            KeybindAdapter.CurrentKeybind = config.CurrentKeybind or "None"
            
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Name)
            
            local Keybind = Tab:Keybind({
                Title = displayName,
                Desc = config.Desc or "",
                Value = config.CurrentKeybind or "None",
                Callback = function(key)
                    KeybindAdapter.CurrentKeybind = key
                    if config.Callback then
                        if config.HoldToInteract then
                            config.Callback(true)
                        else
                            config.Callback(key)
                        end
                    end
                end
            })
            
            KeybindAdapter._windKeybind = Keybind
            KeybindAdapter._elementId = elementId
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = KeybindAdapter
            end
            
            function KeybindAdapter:Set(key)
                self.CurrentKeybind = key
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = KeybindAdapter
            return KeybindAdapter
        end
        
        -- ==================== CREATE LABEL ====================
        function TabAdapter:CreateLabel(title, icon, color, ignoreTheme)
            local elementId = title
            RegisterElement(elementId, "Label", {Name = title})
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                return DummyElement
            end
            
            local LabelAdapter = {}
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, title)
            
            local Label = Tab:Paragraph({
                Title = displayName,
                Desc = "",
                Locked = false,
            })
            
            LabelAdapter._windLabel = Label
            LabelAdapter._elementId = elementId
            
            function LabelAdapter:Set(newTitle, newIcon, newColor, newIgnoreTheme)
                pcall(function()
                    Label:SetTitle(newTitle)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = LabelAdapter
            return LabelAdapter
        end
        
        -- ==================== CREATE PARAGRAPH ====================
        function TabAdapter:CreateParagraph(config)
            local elementId = config.Title
            RegisterElement(elementId, "Paragraph", config)
            
            if not IsElementEnabled(RayfieldAdapter, windowId, tabId, elementId) then
                return DummyElement
            end
            
            local ParagraphAdapter = {}
            local displayName = GetElementDisplayName(RayfieldAdapter, windowId, tabId, elementId, config.Title)
            
            local Paragraph = Tab:Paragraph({
                Title = displayName,
                Desc = config.Content or "",
                Locked = false,
            })
            
            ParagraphAdapter._windParagraph = Paragraph
            ParagraphAdapter._elementId = elementId
            
            function ParagraphAdapter:Set(newConfig)
                pcall(function()
                    Paragraph:SetTitle(newConfig.Title or config.Title)
                    Paragraph:SetDesc(newConfig.Content or config.Content)
                end)
            end
            
            RayfieldAdapter.ElementRegistry[elementId] = ParagraphAdapter
            return ParagraphAdapter
        end
        
        return TabAdapter
    end
    
    -- ==================== WINDOW METHODS ====================
    function WindowAdapter.ModifyTheme(theme)
        if type(theme) == "string" then
            pcall(function()
                WindUI:SetTheme(theme)
            end)
        else
            pcall(function()
                WindUI:AddTheme(theme)
            end)
        end
    end
    
    function WindowAdapter:SetVisibility(visible)
        -- WindUI toggle
    end
    
    function WindowAdapter:IsVisible()
        return true
    end
    
    function WindowAdapter:Destroy()
        -- Cleanup
    end
    
    return WindowAdapter
end

-- ==================== GLOBAL METHODS ====================

function RayfieldAdapter:Notify(config)
    WindUI:Notify({
        Title = config.Title or "Notification",
        Content = config.Content or "",
        Duration = config.Duration or 5,
        Icon = ConvertIcon(config.Image),
    })
end

function RayfieldAdapter:LoadConfiguration()
    -- Auto handled by WindUI
end

function RayfieldAdapter:SetVisibility(visible)
    -- Global visibility
end

function RayfieldAdapter:IsVisible()
    return true
end

function RayfieldAdapter:Destroy()
    -- Cleanup all
end

-- ==================== RETURN ====================
return RayfieldAdapter

--[[
    Rayfield to WindUI Adapter - Advanced Edition
    Cho phép tùy chỉnh, sắp xếp, xóa, chỉnh sửa elements
    Sử dụng: local Rayfield = loadstring(game:HttpGet('YOUR_SCRIPT_URL'))()
]]

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Tạo Rayfield Adapter
local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}
RayfieldAdapter.Elements = {} -- Lưu tất cả elements để quản lý
RayfieldAdapter.Tabs = {} -- Lưu tất cả tabs

-- Hàm chuyển đổi Icon từ Roblox ID sang Lucide
local function ConvertIcon(icon)
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle"
    end
    return icon or "circle"
end

-- Hàm chuyển đổi Theme
local ThemeMapping = {
    ["Default"] = "Dark",
    ["AmberGlow"] = "Dark",
    ["Amethyst"] = "Dark",
    ["Bloom"] = "Dark",
    ["DarkBlue"] = "Dark",
    ["Green"] = "Dark",
    ["Light"] = "Light",
    ["Ocean"] = "Dark",
    ["Serenity"] = "Dark",
}

-- CreateWindow
function RayfieldAdapter:CreateWindow(config)
    local WindowAdapter = {}
    
    -- Thay đổi tên nếu chứa "Flash Hub"
    local windowTitle = config.Name or "Window"
    if windowTitle:find("Flash Hub") then
        windowTitle = windowTitle:gsub("Flash Hub", "VTriP")
    end
    
    -- Chuyển đổi config Rayfield sang WindUI
    local windConfig = {
        Title = windowTitle,
        Icon = ConvertIcon(config.Icon),
        Author = config.LoadingSubtitle or "Script",
        Folder = (config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "RayfieldAdapter",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = ThemeMapping[config.Theme] or "Dark",
        Resizable = true,
        SideBarWidth = 200,
    }
    
    -- Key System
    if config.KeySystem then
        windConfig.KeySystem = {
            Key = config.KeySettings.Key or {},
            Note = config.KeySettings.Note or "No key note",
            SaveKey = config.KeySettings.SaveKey or false,
        }
    end
    
    -- Tạo WindUI Window
    local Window = WindUI:CreateWindow(windConfig)
    
    -- Tùy chỉnh nút mở menu (Open Button)
    local openButtonTitle = "Open VTriP"
    if config.ShowText and config.ShowText ~= "" then
        openButtonTitle = "Open " .. (config.ShowText:find("Flash Hub") and "VTriP" or config.ShowText)
    end
    
    Window:EditOpenButton({
        Title = openButtonTitle,
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
    
    -- Lưu config để dùng sau
    WindowAdapter._windWindow = Window
    WindowAdapter._config = config
    WindowAdapter._tabs = {}
    WindowAdapter._configFile = (config.ConfigurationSaving and config.ConfigurationSaving.FileName) or "Config"
    WindowAdapter._elementRegistry = {} -- Registry cho tất cả elements
    
    -- Set Toggle Key
    if config.ToggleUIKeybind then
        local keyCode = config.ToggleUIKeybind
        if type(keyCode) == "string" then
            Window:SetToggleKey(Enum.KeyCode[keyCode])
        else
            Window:SetToggleKey(keyCode)
        end
    end
    
    -- CreateTab
    function WindowAdapter:CreateTab(name, icon)
        local TabAdapter = {}
        
        -- Tạo Tab Section nếu chưa có
        if not self._mainSection then
            self._mainSection = Window:Section({
                Title = "Main",
                Icon = "folder",
                Opened = true,
            })
        end
        
        -- Tạo Tab
        local Tab = Window:Tab({
            Title = name,
            Icon = ConvertIcon(icon),
        })
        
        TabAdapter._windTab = Tab
        TabAdapter._elements = {}
        TabAdapter._elementOrder = {} -- Thứ tự elements
        TabAdapter._tabName = name
        
        -- Lưu tab vào registry
        table.insert(self._tabs, TabAdapter)
        RayfieldAdapter.Tabs[name] = TabAdapter
        
        -- Helper function để tạo element ID unique
        local function GenerateElementId(type, name)
            return type .. "_" .. name .. "_" .. tostring(os.clock())
        end
        
        -- Helper function để đăng ký element
        local function RegisterElement(elementId, elementAdapter, elementType, config)
            TabAdapter._elements[elementId] = {
                adapter = elementAdapter,
                type = elementType,
                config = config,
                order = #TabAdapter._elementOrder + 1,
                visible = true,
                tabName = TabAdapter._tabName
            }
            table.insert(TabAdapter._elementOrder, elementId)
            
            -- Lưu vào global registry
            WindowAdapter._elementRegistry[elementId] = TabAdapter._elements[elementId]
            RayfieldAdapter.Elements[elementId] = elementAdapter
            
            return elementId
        end
        
        -- CreateSection
        function TabAdapter:CreateSection(name)
            local SectionAdapter = {}
            local elementId = GenerateElementId("Section", name)
            
            local Section = Tab:Section({
                Title = name,
                Box = true,
                Opened = true,
            })
            
            SectionAdapter._windSection = Section
            SectionAdapter._elementId = elementId
            SectionAdapter._type = "Section"
            
            function SectionAdapter:Set(newName)
                Section:SetTitle(newName)
                self._config.Name = newName
            end
            
            function SectionAdapter:Remove()
                Section:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, SectionAdapter, "Section", {Name = name})
            
            return SectionAdapter
        end
        
        -- CreateDivider
        function TabAdapter:CreateDivider()
            local DividerAdapter = {}
            local elementId = GenerateElementId("Divider", "divider")
            
            local Section = Tab:Section({
                Title = "───────────────────",
                Box = false,
                Opened = true,
            })
            
            DividerAdapter._elementId = elementId
            DividerAdapter._type = "Divider"
            
            function DividerAdapter:Set(visible)
                if visible then
                    Section:SetTitle("───────────────────")
                else
                    Section:SetTitle("")
                end
            end
            
            function DividerAdapter:Remove()
                Section:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, DividerAdapter, "Divider", {})
            
            return DividerAdapter
        end
        
        -- CreateButton
        function TabAdapter:CreateButton(config)
            local ButtonAdapter = {}
            local elementId = GenerateElementId("Button", config.Name)
            
            local Button = Tab:Button({
                Title = config.Name,
                Desc = config.Desc or "",
                Callback = config.Callback or function() end
            })
            
            ButtonAdapter._windButton = Button
            ButtonAdapter._elementId = elementId
            ButtonAdapter._type = "Button"
            ButtonAdapter._config = config
            
            function ButtonAdapter:Set(newName)
                Button:SetTitle(newName)
                self._config.Name = newName
            end
            
            function ButtonAdapter:SetDesc(newDesc)
                Button:SetDesc(newDesc)
                self._config.Desc = newDesc
            end
            
            function ButtonAdapter:Lock()
                Button:Lock()
            end
            
            function ButtonAdapter:Unlock()
                Button:Unlock()
            end
            
            function ButtonAdapter:Remove()
                Button:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, ButtonAdapter, "Button", config)
            
            return ButtonAdapter
        end
        
        -- CreateToggle
        function TabAdapter:CreateToggle(config)
            local ToggleAdapter = {}
            local elementId = GenerateElementId("Toggle", config.Name)
            ToggleAdapter.CurrentValue = config.CurrentValue or false
            
            -- Xử lý tham số Plus
            local description = config.Desc or ""
            if config.Plus then
                description = "[Plus Feature] " .. description
            end
            
            local Toggle = Tab:Toggle({
                Title = config.Name,
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
            ToggleAdapter._type = "Toggle"
            ToggleAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ToggleAdapter
            end
            
            function ToggleAdapter:Set(value)
                self.CurrentValue = value
                Toggle:Set(value)
            end
            
            function ToggleAdapter:SetTitle(newTitle)
                Toggle:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function ToggleAdapter:SetDesc(newDesc)
                Toggle:SetDesc(newDesc)
                self._config.Desc = newDesc
            end
            
            function ToggleAdapter:Lock()
                Toggle:Lock()
            end
            
            function ToggleAdapter:Unlock()
                Toggle:Unlock()
            end
            
            function ToggleAdapter:Remove()
                Toggle:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, ToggleAdapter, "Toggle", config)
            
            return ToggleAdapter
        end
        
        -- CreateSlider
        function TabAdapter:CreateSlider(config)
            local SliderAdapter = {}
            local elementId = GenerateElementId("Slider", config.Name)
            SliderAdapter.CurrentValue = config.CurrentValue or config.Range[1]
            
            local Slider = Tab:Slider({
                Title = config.Name,
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
            SliderAdapter._type = "Slider"
            SliderAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                Slider:Set(value)
            end
            
            function SliderAdapter:SetTitle(newTitle)
                Slider:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function SliderAdapter:SetDesc(newDesc)
                Slider:SetDesc(newDesc)
                self._config.Suffix = newDesc
            end
            
            function SliderAdapter:SetMin(newMin)
                Slider:SetMin(newMin)
                self._config.Range[1] = newMin
            end
            
            function SliderAdapter:SetMax(newMax)
                Slider:SetMax(newMax)
                self._config.Range[2] = newMax
            end
            
            function SliderAdapter:Lock()
                Slider:Lock()
            end
            
            function SliderAdapter:Unlock()
                Slider:Unlock()
            end
            
            function SliderAdapter:Remove()
                Slider:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, SliderAdapter, "Slider", config)
            
            return SliderAdapter
        end
        
        -- CreateInput
        function TabAdapter:CreateInput(config)
            local InputAdapter = {}
            local elementId = GenerateElementId("Input", config.Name)
            InputAdapter.CurrentValue = config.CurrentValue or ""
            
            local Input = Tab:Input({
                Title = config.Name,
                Desc = "",
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
            InputAdapter._type = "Input"
            InputAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                Input:Set(value)
            end
            
            function InputAdapter:SetTitle(newTitle)
                Input:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function InputAdapter:SetPlaceholder(newPlaceholder)
                Input:SetPlaceholder(newPlaceholder)
                self._config.PlaceholderText = newPlaceholder
            end
            
            function InputAdapter:Lock()
                Input:Lock()
            end
            
            function InputAdapter:Unlock()
                Input:Unlock()
            end
            
            function InputAdapter:Remove()
                Input:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, InputAdapter, "Input", config)
            
            return InputAdapter
        end
        
        -- CreateDropdown
        function TabAdapter:CreateDropdown(config)
            local DropdownAdapter = {}
            local elementId = GenerateElementId("Dropdown", config.Name)
            DropdownAdapter.CurrentOption = config.CurrentOption or {}
            
            local Dropdown = Tab:Dropdown({
                Title = config.Name,
                Desc = "",
                Values = config.Options or {},
                Value = config.CurrentOption or {},
                Multi = config.MultipleOptions or false,
                AllowNone = true,
                Callback = function(options)
                    DropdownAdapter.CurrentOption = options
                    if config.Callback then
                        config.Callback(options)
                    end
                end
            })
            
            DropdownAdapter._windDropdown = Dropdown
            DropdownAdapter._elementId = elementId
            DropdownAdapter._type = "Dropdown"
            DropdownAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = DropdownAdapter
            end
            
            function DropdownAdapter:Set(options)
                self.CurrentOption = options
                Dropdown:Select(options)
            end
            
            function DropdownAdapter:Refresh(newOptions)
                Dropdown:Refresh(newOptions)
                self._config.Options = newOptions
            end
            
            function DropdownAdapter:SetTitle(newTitle)
                Dropdown:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function DropdownAdapter:Lock()
                Dropdown:Lock()
            end
            
            function DropdownAdapter:Unlock()
                Dropdown:Unlock()
            end
            
            function DropdownAdapter:Remove()
                Dropdown:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, DropdownAdapter, "Dropdown", config)
            
            return DropdownAdapter
        end
        
        -- CreateColorPicker
        function TabAdapter:CreateColorPicker(config)
            local ColorPickerAdapter = {}
            local elementId = GenerateElementId("ColorPicker", config.Name)
            ColorPickerAdapter.CurrentValue = config.Color or Color3.fromRGB(255, 255, 255)
            
            local ColorPicker = Tab:Colorpicker({
                Title = config.Name,
                Desc = "",
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
            ColorPickerAdapter._type = "ColorPicker"
            ColorPickerAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ColorPickerAdapter
            end
            
            function ColorPickerAdapter:Set(color)
                self.CurrentValue = color
            end
            
            function ColorPickerAdapter:SetTitle(newTitle)
                ColorPicker:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function ColorPickerAdapter:Lock()
                ColorPicker:Lock()
            end
            
            function ColorPickerAdapter:Unlock()
                ColorPicker:Unlock()
            end
            
            function ColorPickerAdapter:Remove()
                ColorPicker:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, ColorPickerAdapter, "ColorPicker", config)
            
            return ColorPickerAdapter
        end
        
        -- CreateKeybind
        function TabAdapter:CreateKeybind(config)
            local KeybindAdapter = {}
            local elementId = GenerateElementId("Keybind", config.Name)
            KeybindAdapter.CurrentKeybind = config.CurrentKeybind or "None"
            
            local Keybind = Tab:Keybind({
                Title = config.Name,
                Desc = "",
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
            KeybindAdapter._type = "Keybind"
            KeybindAdapter._config = config
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = KeybindAdapter
            end
            
            function KeybindAdapter:Set(key)
                self.CurrentKeybind = key
            end
            
            function KeybindAdapter:SetTitle(newTitle)
                Keybind:SetTitle(newTitle)
                self._config.Name = newTitle
            end
            
            function KeybindAdapter:Lock()
                Keybind:Lock()
            end
            
            function KeybindAdapter:Unlock()
                Keybind:Unlock()
            end
            
            function KeybindAdapter:Remove()
                Keybind:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, KeybindAdapter, "Keybind", config)
            
            return KeybindAdapter
        end
        
        -- CreateLabel
        function TabAdapter:CreateLabel(title, icon, color, ignoreTheme)
            local LabelAdapter = {}
            local elementId = GenerateElementId("Label", title)
            
            local Label = Tab:Paragraph({
                Title = title,
                Desc = "",
                Image = "",
                Locked = false,
            })
            
            LabelAdapter._windLabel = Label
            LabelAdapter._elementId = elementId
            LabelAdapter._type = "Label"
            LabelAdapter._config = {Title = title}
            
            function LabelAdapter:Set(newTitle, newIcon, newColor, newIgnoreTheme)
                Label:SetTitle(newTitle)
                self._config.Title = newTitle
            end
            
            function LabelAdapter:Remove()
                Label:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, LabelAdapter, "Label", {Title = title})
            
            return LabelAdapter
        end
        
        -- CreateParagraph
        function TabAdapter:CreateParagraph(config)
            local ParagraphAdapter = {}
            local elementId = GenerateElementId("Paragraph", config.Title)
            
            local Paragraph = Tab:Paragraph({
                Title = config.Title or "Paragraph",
                Desc = config.Content or "",
                Locked = false,
            })
            
            ParagraphAdapter._windParagraph = Paragraph
            ParagraphAdapter._elementId = elementId
            ParagraphAdapter._type = "Paragraph"
            ParagraphAdapter._config = config
            
            function ParagraphAdapter:Set(newConfig)
                Paragraph:SetTitle(newConfig.Title or config.Title)
                Paragraph:SetDesc(newConfig.Content or config.Content)
                self._config.Title = newConfig.Title or config.Title
                self._config.Content = newConfig.Content or config.Content
            end
            
            function ParagraphAdapter:Remove()
                Paragraph:Destroy()
                TabAdapter._elements[elementId].visible = false
            end
            
            RegisterElement(elementId, ParagraphAdapter, "Paragraph", config)
            
            return ParagraphAdapter
        end
        
        return TabAdapter
    end
    
    -- ModifyTheme
    function WindowAdapter.ModifyTheme(theme)
        if type(theme) == "string" then
            WindUI:SetTheme(ThemeMapping[theme] or theme)
        else
            WindUI:AddTheme(theme)
        end
    end
    
    -- SetVisibility
    function WindowAdapter:SetVisibility(visible)
        -- WindUI không có hàm này
    end
    
    -- IsVisible
    function WindowAdapter:IsVisible()
        return true
    end
    
    -- Destroy
    function WindowAdapter:Destroy()
        -- WindUI không có hàm destroy trực tiếp
    end
    
    return WindowAdapter
end

-- Notify
function RayfieldAdapter:Notify(config)
    WindUI:Notify({
        Title = config.Title or "Notification",
        Content = config.Content or "",
        Duration = config.Duration or 5,
        Icon = ConvertIcon(config.Image),
    })
end

-- LoadConfiguration
function RayfieldAdapter:LoadConfiguration()
    print("Configuration loaded automatically by WindUI")
end

-- SetVisibility
function RayfieldAdapter:SetVisibility(visible)
    -- Global function
end

-- IsVisible
function RayfieldAdapter:IsVisible()
    return true
end

-- Destroy
function RayfieldAdapter:Destroy()
    -- Destroy all
end

--[[ 
    ==========================================
    ADVANCED CUSTOMIZATION FUNCTIONS
    ==========================================
]]

-- Tìm element theo tên hoặc ID
function RayfieldAdapter:FindElement(identifier, tabName)
    if tabName then
        local tab = self.Tabs[tabName]
        if tab then
            for id, info in pairs(tab._elements) do
                if id == identifier or (info.config.Name == identifier) then
                    return info.adapter, id
                end
            end
        end
    else
        -- Tìm trong tất cả tabs
        for _, tab in pairs(self.Tabs) do
            for id, info in pairs(tab._elements) do
                if id == identifier or (info.config.Name == identifier) then
                    return info.adapter, id
                end
            end
        end
    end
    return nil, nil
end

-- Lấy danh sách tất cả elements trong tab
function RayfieldAdapter:GetElements(tabName)
    local tab = self.Tabs[tabName]
    if not tab then return {} end
    
    local elements = {}
    for _, elementId in ipairs(tab._elementOrder) do
        local info = tab._elements[elementId]
        if info.visible then
            table.insert(elements, {
                id = elementId,
                type = info.type,
                name = info.config.Name or "Unnamed",
                order = info.order,
                adapter = info.adapter
            })
        end
    end
    return elements
end

-- Xóa element
function RayfieldAdapter:RemoveElement(identifier, tabName)
    local element, id = self:FindElement(identifier, tabName)
    if element and element.Remove then
        element:Remove()
        return true
    end
    return false
end

-- Chỉnh sửa element
function RayfieldAdapter:EditElement(identifier, tabName, changes)
    local element, id = self:FindElement(identifier, tabName)
    if not element then return false end
    
    -- Áp dụng các thay đổi
    if changes.Title and element.SetTitle then
        element:SetTitle(changes.Title)
    end
    if changes.Desc and element.SetDesc then
        element:SetDesc(changes.Desc)
    end
    if changes.Value and element.Set then
        element:Set(changes.Value)
    end
    if changes.Min and element.SetMin then
        element:SetMin(changes.Min)
    end
    if changes.Max and element.SetMax then
        element:SetMax(changes.Max)
    end
    if changes.Placeholder and element.SetPlaceholder then
        element:SetPlaceholder(changes.Placeholder)
    end
    if changes.Lock ~= nil then
        if changes.Lock and element.Lock then
            element:Lock()
        elseif not changes.Lock and element.Unlock then
            element:Unlock()
        end
    end
    
    return true
end

-- Tạo bản sao tùy chỉnh của RayfieldAdapter cho script riêng
function RayfieldAdapter:CreateCustomAdapter(customizations)
    local CustomAdapter = {}
    
    -- Copy tất cả functions từ RayfieldAdapter
    for k, v in pairs(self) do
        CustomAdapter[k] = v
    end
    
    -- Áp dụng customizations
    if customizations then
        -- Xóa elements
        if customizations.Remove then
            for _, removal in ipairs(customizations.Remove) do
                self:RemoveElement(removal.Element, removal.Tab)
            end
        end
        
        -- Chỉnh sửa elements
        if customizations.Edit then
            for _, edit in ipairs(customizations.Edit) do
                self:EditElement(edit.Element, edit.Tab, edit.Changes)
            end
        end
        
        -- Thêm custom functions
        if customizations.CustomFunctions then
            for name, func in pairs(customizations.CustomFunctions) do
                CustomAdapter[name] = func
            end
        end
    end
    
    return CustomAdapter
end

-- Export configuration hiện tại
function RayfieldAdapter:ExportConfig()
    local config = {
        Tabs = {},
        Elements = {}
    }
    
    for tabName, tab in pairs(self.Tabs) do
        config.Tabs[tabName] = {
            Name = tabName,
            Elements = {}
        }
        
        for _, elementId in ipairs(tab._elementOrder) do
            local info = tab._elements[elementId]
            if info.visible then
                table.insert(config.Tabs[tabName].Elements, {
                    ID = elementId,
                    Type = info.type,
                    Config = info.config,
                    Order = info.order
                })
            end
        end
    end
    
    return game:GetService("HttpService"):JSONEncode(config)
end

-- In ra danh sách elements (debug)
function RayfieldAdapter:PrintElements(tabName)
    local elements = self:GetElements(tabName)
    print("=== Elements in Tab:", tabName, "===")
    for i, elem in ipairs(elements) do
        print(string.format("%d. [%s] %s (ID: %s)", elem.order, elem.type, elem.name, elem.id))
    end
    print("===========================")
end

return RayfieldAdapter

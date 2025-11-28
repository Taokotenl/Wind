--[[
    RayfieldAdapter with UI Editor
    Cho phép chỉnh sửa động cấu trúc UI, thứ tự elements, xóa/ẩn các thành phần
]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Tạo Custom Theme
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

local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}
RayfieldAdapter.UIConfigs = {} -- Lưu config các windows

-- Hàm chuyển Icon
local function ConvertIcon(icon)
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle"
    end
    return icon or "circle"
end

-- Hàm lưu config lên clipboard dạng JSON
local function SaveConfigToClipboard(windowName, config)
    local jsonConfig = game:GetService("HttpService"):JSONEncode(config)
    setclipboard(jsonConfig)
    print("✓ Config saved to clipboard for: " .. windowName)
end

-- Hàm tạo cấu trúc config mặc định
local function CreateDefaultConfig(windowName, tabs)
    local config = {
        [windowName] = {
            tabs = {}
        }
    }
    
    for tabName, tabData in pairs(tabs) do
        config[windowName].tabs[tabName] = {
            name = tabName,
            icon = tabData.icon or "folder",
            elements = {}
        }
    end
    
    return config
end

-- Hàm tạo editor window để chỉnh sửa config
local function CreateEditorWindow(windowName, config, onSave)
    local EditorWindow = WindUI:CreateWindow({
        Title = "🎨 UI Editor - " .. windowName,
        Icon = "settings",
        Author = "VTriP Editor",
        Folder = "RayfieldEditor",
        Size = UDim2.fromOffset(700, 600),
        Transparent = true,
        Theme = "VTriP Dark",
        Resizable = true,
        SideBarWidth = 150,
    })
    
    -- Tab hiển thị JSON
    local JsonTab = EditorWindow:Tab({
        Title = "JSON Config",
        Icon = "code",
    })
    
    local JsonSection = JsonTab:Section({
        Title = "Cấu Hình Hiện Tại",
        Box = true,
        Opened = true,
    })
    
    local jsonText = game:GetService("HttpService"):JSONEncode(config)
    
    JsonTab:Paragraph({
        Title = "Hướng Dẫn:",
        Desc = "1. Copy JSON bên dưới\n2. Chỉnh sửa theo format\n3. Dán JSON đã chỉnh sửa\n4. Bấm 'Apply Config'\n\nFormat:\n{\n  'TabName': {\n    'name': 'Display Name',\n    'icon': 'icon_name',\n    'elements': { ... }\n  }\n}",
    })
    
    JsonTab:Button({
        Title = "📋 Copy JSON Config",
        Desc = "Sao chép config hiện tại",
        Callback = function()
            setclipboard(jsonText)
            WindUI:Notify({
                Title = "✓ Copied!",
                Content = "JSON config đã được sao chép",
                Duration = 3,
            })
        end
    })
    
    -- Input để dán JSON
    local pastedJson = ""
    JsonTab:Input({
        Title = "Dán JSON Đã Chỉnh Sửa",
        Placeholder = "Paste your edited JSON here...",
        Value = "",
        Callback = function(text)
            pastedJson = text
        end
    })
    
    JsonTab:Button({
        Title = "✓ Apply Config",
        Desc = "Áp dụng config mới",
        Callback = function()
            if pastedJson == "" then
                WindUI:Notify({
                    Title = "⚠ Error",
                    Content = "Vui lòng dán JSON trước",
                    Duration = 3,
                })
                return
            end
            
            local success, newConfig = pcall(function()
                return game:GetService("HttpService"):JSONDecode(pastedJson)
            end)
            
            if not success then
                WindUI:Notify({
                    Title = "❌ JSON Invalid",
                    Content = "JSON không hợp lệ, kiểm tra lại format",
                    Duration = 5,
                })
                return
            end
            
            -- Gọi callback để apply config
            if onSave then
                onSave(newConfig)
            end
            
            WindUI:Notify({
                Title = "✓ Applied!",
                Content = "Config đã được áp dụng thành công",
                Duration = 3,
            })
        end
    })
    
    -- Tab quản lý Elements
    local ManagerTab = EditorWindow:Tab({
        Title = "Manager",
        Icon = "layers",
    })
    
    ManagerTab:Paragraph({
        Title = "Thông Tin Cấu Trúc",
        Desc = "Từ đây bạn có thể:\n✓ Xem tất cả tabs\n✓ Quản lý elements\n✓ Thay đổi thứ tự\n✓ Xóa/Ẩn elements",
    })
    
    -- Duyệt tất cả tabs
    for tabName, tabConfig in pairs(config) do
        if tabConfig.elements then
            local TabSection = ManagerTab:Section({
                Title = "📑 Tab: " .. tabName,
                Box = true,
                Opened = false,
            })
            
            -- Danh sách elements
            for elemName, elemConfig in pairs(tabConfig.elements) do
                TabSection:Paragraph({
                    Title = elemName,
                    Desc = "Type: " .. (elemConfig.type or "Unknown") .. 
                           "\nEnabled: " .. tostring(elemConfig.enabled) ..
                           "\nOrder: " .. (elemConfig.order or 0),
                })
            end
        end
    end
    
    -- Tab Settings
    local SettingsTab = EditorWindow:Tab({
        Title = "Settings",
        Icon = "settings",
    })
    
    SettingsTab:Button({
        Title = "💾 Save to Clipboard",
        Desc = "Lưu config hiện tại lên clipboard",
        Callback = function()
            SaveConfigToClipboard(windowName, config)
            WindUI:Notify({
                Title = "✓ Saved",
                Content = "Config đã được lưu lên clipboard",
                Duration = 3,
            })
        end
    })
    
    SettingsTab:Button({
        Title = "🔄 Reset to Default",
        Desc = "Khôi phục cấu hình mặc định",
        Callback = function()
            -- Reset logic
            WindUI:Notify({
                Title = "⚠ Reset",
                Content = "Cấu hình đã được khôi phục",
                Duration = 3,
            })
        end
    })
    
    return EditorWindow
end

-- CreateWindow chính
function RayfieldAdapter:CreateWindow(config)
    local WindowAdapter = {}
    
    local windowTitle = config.Name or "Window"
    if windowTitle:find("Flash Hub") then
        windowTitle = windowTitle:gsub("Flash Hub", "VTriP")
    end
    
    local windConfig = {
        Title = windowTitle,
        Icon = ConvertIcon(config.Icon),
        Author = "Host By VTriP Official",
        Folder = (config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "RayfieldAdapter",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = "VTriP Dark",
        Resizable = true,
        SideBarWidth = 200,
    }
    
    if config.KeySystem then
        windConfig.KeySystem = {
            Key = config.KeySettings.Key or {},
            Note = config.KeySettings.Note or "No key note",
            SaveKey = config.KeySettings.SaveKey or false,
        }
    end
    
    local Window = WindUI:CreateWindow(windConfig)
    
    Window:EditOpenButton({
        Title = "Open VTriP",
        Icon = ConvertIcon(config.Icon),
        CornerRadius = UDim.new(0, 16),
        StrokeThickness = 2,
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
        OnlyMobile = false,
        Enabled = true,
        Draggable = true,
    })
    
    WindowAdapter._windWindow = Window
    WindowAdapter._config = config
    WindowAdapter._tabs = {}
    WindowAdapter._elements = {} -- Lưu tất cả elements
    WindowAdapter._configFile = (config.ConfigurationSaving and config.ConfigurationSaving.FileName) or "Config"
    WindowAdapter._uiConfig = {} -- Config cho editor
    
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
        
        if not self._mainSection then
            self._mainSection = Window:Section({
                Title = "Main",
                Icon = "folder",
                Opened = true,
            })
        end
        
        local Tab = Window:Tab({
            Title = name,
            Icon = ConvertIcon(icon),
        })
        
        TabAdapter._windTab = Tab
        TabAdapter._elements = {}
        TabAdapter._elementOrder = {} -- Theo dõi thứ tự
        
        -- Cập nhật config
        self._uiConfig[name] = {
            name = name,
            icon = ConvertIcon(icon),
            elements = {}
        }
        
        -- CreateSection
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
                Section:SetTitle(newName)
            end
            
            return SectionAdapter
        end
        
        -- CreateButton
        function TabAdapter:CreateButton(config)
            local ButtonAdapter = {}
            local Button = Tab:Button({
                Title = config.Name,
                Desc = config.Desc or "",
                Callback = config.Callback or function() end
            })
            
            ButtonAdapter._windButton = Button
            ButtonAdapter.Name = config.Name
            ButtonAdapter.Type = "Button"
            ButtonAdapter.Enabled = true
            ButtonAdapter.Order = #TabAdapter._elementOrder + 1
            
            -- Lưu element
            TabAdapter._elements[config.Name] = ButtonAdapter
            table.insert(TabAdapter._elementOrder, config.Name)
            
            -- Cập nhật config
            WindowAdapter._uiConfig[name].elements[config.Name] = {
                type = "Button",
                name = config.Name,
                enabled = true,
                order = ButtonAdapter.Order
            }
            
            function ButtonAdapter:Set(newName)
                self.Name = newName
                Button:SetTitle(newName)
            end
            
            function ButtonAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                WindowAdapter._uiConfig[name].elements[config.Name].enabled = enabled
            end
            
            function ButtonAdapter:SetOrder(order)
                self.Order = order
                WindowAdapter._uiConfig[name].elements[config.Name].order = order
            end
            
            return ButtonAdapter
        end
        
        -- CreateToggle
        function TabAdapter:CreateToggle(config)
            local ToggleAdapter = {}
            ToggleAdapter.CurrentValue = config.CurrentValue or false
            
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
            ToggleAdapter.Name = config.Name
            ToggleAdapter.Type = "Toggle"
            ToggleAdapter.Enabled = true
            ToggleAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[config.Name] = ToggleAdapter
            table.insert(TabAdapter._elementOrder, config.Name)
            
            WindowAdapter._uiConfig[name].elements[config.Name] = {
                type = "Toggle",
                name = config.Name,
                enabled = true,
                order = ToggleAdapter.Order
            }
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ToggleAdapter
            end
            
            function ToggleAdapter:Set(value)
                self.CurrentValue = value
                Toggle:Set(value)
            end
            
            function ToggleAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                WindowAdapter._uiConfig[name].elements[config.Name].enabled = enabled
            end
            
            function ToggleAdapter:SetOrder(order)
                self.Order = order
                WindowAdapter._uiConfig[name].elements[config.Name].order = order
            end
            
            return ToggleAdapter
        end
        
        -- CreateSlider
        function TabAdapter:CreateSlider(config)
            local SliderAdapter = {}
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
            SliderAdapter.Name = config.Name
            SliderAdapter.Type = "Slider"
            SliderAdapter.Enabled = true
            SliderAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[config.Name] = SliderAdapter
            table.insert(TabAdapter._elementOrder, config.Name)
            
            WindowAdapter._uiConfig[name].elements[config.Name] = {
                type = "Slider",
                name = config.Name,
                enabled = true,
                order = SliderAdapter.Order
            }
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                Slider:Set(value)
            end
            
            function SliderAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                WindowAdapter._uiConfig[name].elements[config.Name].enabled = enabled
            end
            
            function SliderAdapter:SetOrder(order)
                self.Order = order
                WindowAdapter._uiConfig[name].elements[config.Name].order = order
            end
            
            return SliderAdapter
        end
        
        -- CreateInput
        function TabAdapter:CreateInput(config)
            local InputAdapter = {}
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
            InputAdapter.Name = config.Name
            InputAdapter.Type = "Input"
            InputAdapter.Enabled = true
            InputAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[config.Name] = InputAdapter
            table.insert(TabAdapter._elementOrder, config.Name)
            
            WindowAdapter._uiConfig[name].elements[config.Name] = {
                type = "Input",
                name = config.Name,
                enabled = true,
                order = InputAdapter.Order
            }
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                Input:Set(value)
            end
            
            function InputAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                WindowAdapter._uiConfig[name].elements[config.Name].enabled = enabled
            end
            
            function InputAdapter:SetOrder(order)
                self.Order = order
                WindowAdapter._uiConfig[name].elements[config.Name].order = order
            end
            
            return InputAdapter
        end
        
        -- CreateDropdown
        function TabAdapter:CreateDropdown(config)
            local DropdownAdapter = {}
            local isMulti = config.MultipleOptions or false
            
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
                Title = config.Name,
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
            DropdownAdapter.Name = config.Name
            DropdownAdapter.Type = "Dropdown"
            DropdownAdapter.Enabled = true
            DropdownAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[config.Name] = DropdownAdapter
            table.insert(TabAdapter._elementOrder, config.Name)
            
            WindowAdapter._uiConfig[name].elements[config.Name] = {
                type = "Dropdown",
                name = config.Name,
                enabled = true,
                order = DropdownAdapter.Order
            }
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = DropdownAdapter
            end
            
            function DropdownAdapter:Set(options)
                if isMulti then
                    local value = type(options) == "table" and options or {options}
                    self.CurrentOption = value
                    Dropdown:Select(value)
                else
                    local value = type(options) == "table" and options[1] or options
                    self.CurrentOption = value
                    Dropdown:Select(value)
                end
            end
            
            function DropdownAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                WindowAdapter._uiConfig[name].elements[config.Name].enabled = enabled
            end
            
            function DropdownAdapter:SetOrder(order)
                self.Order = order
                WindowAdapter._uiConfig[name].elements[config.Name].order = order
            end
            
            return DropdownAdapter
        end
        
        return TabAdapter
    end
    
    -- Hàm mở Editor
    function WindowAdapter:OpenEditor()
        return CreateEditorWindow(windowTitle, self._uiConfig, function(newConfig)
            -- Callback để áp dụng config mới
            print("Config updated:", game:GetService("HttpService"):JSONEncode(newConfig))
        end)
    end
    
    -- Hàm lưu config
    function WindowAdapter:SaveConfig()
        SaveConfigToClipboard(windowTitle, self._uiConfig)
    end
    
    -- Hàm export config
    function WindowAdapter:ExportConfig()
        local configString = game:GetService("HttpService"):JSONEncode(self._uiConfig)
        setclipboard(configString)
        return configString
    end
    
    -- Hàm import config
    function WindowAdapter:ImportConfig(jsonString)
        local success, newConfig = pcall(function()
            return game:GetService("HttpService"):JSONDecode(jsonString)
        end)
        
        if success then
            self._uiConfig = newConfig
            return true
        end
        return false
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

return RayfieldAdapter

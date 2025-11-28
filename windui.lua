--[[
    RayfieldAdapter with UI Editor - Fixed
    Cho phép chỉnh sửa động cấu trúc UI, thứ tự elements, xóa/ẩn các thành phần
]]

-- Kiểm tra và load WindUI
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    error("Failed to load WindUI library")
    return
end

-- Tạo Custom Theme
pcall(function()
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
end)

local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}
RayfieldAdapter.UIConfigs = {}

-- Hàm chuyển Icon
local function ConvertIcon(icon)
    if icon == nil then return "circle" end
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle"
    end
    return icon
end

-- Hàm lưu config
local function SaveConfigToClipboard(windowName, config)
    pcall(function()
        local HttpService = game:GetService("HttpService")
        if HttpService then
            local jsonConfig = HttpService:JSONEncode(config)
            setclipboard(jsonConfig)
            print("✓ Config saved to clipboard for: " .. windowName)
        end
    end)
end

-- Hàm tạo Section an toàn
local function SafeCreateSection(tab, title, opened)
    if not tab then return nil end
    
    local section = pcall(function()
        return tab:Section({
            Title = title or "Section",
            Box = false,
            TextSize = 18,
            Opened = opened or true,
        })
    end)
    
    if section then
        return section
    end
    return nil
end

-- CreateWindow chính
function RayfieldAdapter:CreateWindow(config)
    if not config then
        error("Config is required")
        return
    end
    
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
    
    if config.KeySystem and config.KeySettings then
        windConfig.KeySystem = {
            Key = config.KeySettings.Key or {},
            Note = config.KeySettings.Note or "No key note",
            SaveKey = config.KeySettings.SaveKey or false,
        }
    end
    
    local Window = WindUI:CreateWindow(windConfig)
    if not Window then
        error("Failed to create WindUI window")
        return
    end
    
    pcall(function()
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
    end)
    
    WindowAdapter._windWindow = Window
    WindowAdapter._config = config
    WindowAdapter._tabs = {}
    WindowAdapter._elements = {}
    WindowAdapter._configFile = (config.ConfigurationSaving and config.ConfigurationSaving.FileName) or "Config"
    WindowAdapter._uiConfig = {}
    
    if config.ToggleUIKeybind and Window then
        pcall(function()
            local keyCode = config.ToggleUIKeybind
            if type(keyCode) == "string" then
                Window:SetToggleKey(Enum.KeyCode[keyCode])
            else
                Window:SetToggleKey(keyCode)
            end
        end)
    end
    
    -- CreateTab
    function WindowAdapter:CreateTab(tabName, icon)
        if not self._windWindow then
            warn("Window is not initialized")
            return nil
        end
        
        local TabAdapter = {}
        
        local Tab = self._windWindow:Tab({
            Title = tabName or "Tab",
            Icon = ConvertIcon(icon),
        })
        
        if not Tab then
            warn("Failed to create tab: " .. tostring(tabName))
            return nil
        end
        
        TabAdapter._windTab = Tab
        TabAdapter._elements = {}
        TabAdapter._elementOrder = {}
        TabAdapter._tabName = tabName
        
        self._uiConfig[tabName] = {
            name = tabName,
            icon = ConvertIcon(icon),
            elements = {}
        }
        
        self._tabs[tabName] = TabAdapter
        
        -- CreateSection
        function TabAdapter:CreateSection(sectionName)
            if not self._windTab then return nil end
            
            local SectionAdapter = {}
            
            local Section = pcall(function()
                return self._windTab:Section({
                    Title = sectionName or "Section",
                    Box = false,
                    TextSize = 18,
                    Opened = true,
                })
            end)
            
            if not Section then
                warn("Failed to create section")
                return nil
            end
            
            SectionAdapter._windSection = Section
            
            function SectionAdapter:Set(newName)
                if self._windSection and self._windSection.SetTitle then
                    pcall(function()
                        self._windSection:SetTitle(newName)
                    end)
                end
            end
            
            return SectionAdapter
        end
        
        -- CreateButton
        function TabAdapter:CreateButton(buttonConfig)
            if not buttonConfig or not self._windTab then
                return nil
            end
            
            local ButtonAdapter = {}
            
            local Button = pcall(function()
                return self._windTab:Button({
                    Title = buttonConfig.Name or "Button",
                    Desc = buttonConfig.Desc or "",
                    Callback = buttonConfig.Callback or function() end
                })
            end)
            
            if not Button then
                warn("Failed to create button")
                return nil
            end
            
            ButtonAdapter._windButton = Button
            ButtonAdapter.Name = buttonConfig.Name
            ButtonAdapter.Type = "Button"
            ButtonAdapter.Enabled = true
            ButtonAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[buttonConfig.Name] = ButtonAdapter
            table.insert(TabAdapter._elementOrder, buttonConfig.Name)
            
            if WindowAdapter._uiConfig[self._tabName] then
                WindowAdapter._uiConfig[self._tabName].elements[buttonConfig.Name] = {
                    type = "Button",
                    name = buttonConfig.Name,
                    enabled = true,
                    order = ButtonAdapter.Order
                }
            end
            
            function ButtonAdapter:Set(newName)
                self.Name = newName
                if self._windButton and self._windButton.SetTitle then
                    pcall(function()
                        self._windButton:SetTitle(newName)
                    end)
                end
            end
            
            function ButtonAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                if WindowAdapter._uiConfig[self._tabName] and WindowAdapter._uiConfig[self._tabName].elements[buttonConfig.Name] then
                    WindowAdapter._uiConfig[self._tabName].elements[buttonConfig.Name].enabled = enabled
                end
            end
            
            function ButtonAdapter:SetOrder(order)
                self.Order = order
                if WindowAdapter._uiConfig[self._tabName] and WindowAdapter._uiConfig[self._tabName].elements[buttonConfig.Name] then
                    WindowAdapter._uiConfig[self._tabName].elements[buttonConfig.Name].order = order
                end
            end
            
            return ButtonAdapter
        end
        
        -- CreateToggle
        function TabAdapter:CreateToggle(toggleConfig)
            if not toggleConfig or not self._windTab then
                return nil
            end
            
            local ToggleAdapter = {}
            ToggleAdapter.CurrentValue = toggleConfig.CurrentValue or false
            
            local description = toggleConfig.Desc or ""
            if toggleConfig.Plus then
                description = "[Plus Feature] " .. description
            end
            
            local Toggle = pcall(function()
                return self._windTab:Toggle({
                    Title = toggleConfig.Name or "Toggle",
                    Desc = description,
                    Type = "Checkbox",
                    Value = toggleConfig.CurrentValue or false,
                    Callback = function(state)
                        ToggleAdapter.CurrentValue = state
                        if toggleConfig.Callback then
                            pcall(toggleConfig.Callback, state)
                        end
                    end
                })
            end)
            
            if not Toggle then
                warn("Failed to create toggle")
                return nil
            end
            
            ToggleAdapter._windToggle = Toggle
            ToggleAdapter.Name = toggleConfig.Name
            ToggleAdapter.Type = "Toggle"
            ToggleAdapter.Enabled = true
            ToggleAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[toggleConfig.Name] = ToggleAdapter
            table.insert(TabAdapter._elementOrder, toggleConfig.Name)
            
            if WindowAdapter._uiConfig[self._tabName] then
                WindowAdapter._uiConfig[self._tabName].elements[toggleConfig.Name] = {
                    type = "Toggle",
                    name = toggleConfig.Name,
                    enabled = true,
                    order = ToggleAdapter.Order
                }
            end
            
            if toggleConfig.Flag then
                RayfieldAdapter.Flags[toggleConfig.Flag] = ToggleAdapter
            end
            
            function ToggleAdapter:Set(value)
                self.CurrentValue = value
                if self._windToggle and self._windToggle.Set then
                    pcall(function()
                        self._windToggle:Set(value)
                    end)
                end
            end
            
            function ToggleAdapter:SetEnabled(enabled)
                self.Enabled = enabled
                if WindowAdapter._uiConfig[self._tabName] and WindowAdapter._uiConfig[self._tabName].elements[toggleConfig.Name] then
                    WindowAdapter._uiConfig[self._tabName].elements[toggleConfig.Name].enabled = enabled
                end
            end
            
            return ToggleAdapter
        end
        
        -- CreateSlider
        function TabAdapter:CreateSlider(sliderConfig)
            if not sliderConfig or not self._windTab or not sliderConfig.Range then
                return nil
            end
            
            local SliderAdapter = {}
            SliderAdapter.CurrentValue = sliderConfig.CurrentValue or sliderConfig.Range[1]
            
            local Slider = pcall(function()
                return self._windTab:Slider({
                    Title = sliderConfig.Name or "Slider",
                    Desc = sliderConfig.Suffix or "",
                    Step = sliderConfig.Increment or 1,
                    Value = {
                        Min = sliderConfig.Range[1],
                        Max = sliderConfig.Range[2],
                        Default = sliderConfig.CurrentValue or sliderConfig.Range[1],
                    },
                    Callback = function(value)
                        SliderAdapter.CurrentValue = value
                        if sliderConfig.Callback then
                            pcall(sliderConfig.Callback, value)
                        end
                    end
                })
            end)
            
            if not Slider then
                warn("Failed to create slider")
                return nil
            end
            
            SliderAdapter._windSlider = Slider
            SliderAdapter.Name = sliderConfig.Name
            SliderAdapter.Type = "Slider"
            SliderAdapter.Enabled = true
            SliderAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[sliderConfig.Name] = SliderAdapter
            table.insert(TabAdapter._elementOrder, sliderConfig.Name)
            
            if WindowAdapter._uiConfig[self._tabName] then
                WindowAdapter._uiConfig[self._tabName].elements[sliderConfig.Name] = {
                    type = "Slider",
                    name = sliderConfig.Name,
                    enabled = true,
                    order = SliderAdapter.Order
                }
            end
            
            if sliderConfig.Flag then
                RayfieldAdapter.Flags[sliderConfig.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                if self._windSlider and self._windSlider.Set then
                    pcall(function()
                        self._windSlider:Set(value)
                    end)
                end
            end
            
            return SliderAdapter
        end
        
        -- CreateInput
        function TabAdapter:CreateInput(inputConfig)
            if not inputConfig or not self._windTab then
                return nil
            end
            
            local InputAdapter = {}
            InputAdapter.CurrentValue = inputConfig.CurrentValue or ""
            
            local Input = pcall(function()
                return self._windTab:Input({
                    Title = inputConfig.Name or "Input",
                    Desc = "",
                    Value = inputConfig.CurrentValue or "",
                    Type = "Input",
                    Placeholder = inputConfig.PlaceholderText or "",
                    Callback = function(text)
                        InputAdapter.CurrentValue = text
                        if inputConfig.Callback then
                            pcall(inputConfig.Callback, text)
                        end
                    end
                })
            end)
            
            if not Input then
                warn("Failed to create input")
                return nil
            end
            
            InputAdapter._windInput = Input
            InputAdapter.Name = inputConfig.Name
            InputAdapter.Type = "Input"
            InputAdapter.Enabled = true
            InputAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[inputConfig.Name] = InputAdapter
            table.insert(TabAdapter._elementOrder, inputConfig.Name)
            
            if WindowAdapter._uiConfig[self._tabName] then
                WindowAdapter._uiConfig[self._tabName].elements[inputConfig.Name] = {
                    type = "Input",
                    name = inputConfig.Name,
                    enabled = true,
                    order = InputAdapter.Order
                }
            end
            
            if inputConfig.Flag then
                RayfieldAdapter.Flags[inputConfig.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                if self._windInput and self._windInput.Set then
                    pcall(function()
                        self._windInput:Set(value)
                    end)
                end
            end
            
            return InputAdapter
        end
        
        -- CreateDropdown
        function TabAdapter:CreateDropdown(dropdownConfig)
            if not dropdownConfig or not self._windTab then
                return nil
            end
            
            local DropdownAdapter = {}
            local isMulti = dropdownConfig.MultipleOptions or false
            
            local defaultValue
            if isMulti then
                if type(dropdownConfig.CurrentOption) == "table" then
                    defaultValue = dropdownConfig.CurrentOption
                elseif type(dropdownConfig.CurrentOption) == "string" then
                    defaultValue = {dropdownConfig.CurrentOption}
                else
                    defaultValue = {}
                end
            else
                if type(dropdownConfig.CurrentOption) == "table" and #dropdownConfig.CurrentOption > 0 then
                    defaultValue = dropdownConfig.CurrentOption[1]
                elseif type(dropdownConfig.CurrentOption) == "string" then
                    defaultValue = dropdownConfig.CurrentOption
                else
                    defaultValue = dropdownConfig.Options and dropdownConfig.Options[1] or ""
                end
            end
            
            DropdownAdapter.CurrentOption = defaultValue
            
            local Dropdown = pcall(function()
                return self._windTab:Dropdown({
                    Title = dropdownConfig.Name or "Dropdown",
                    Desc = dropdownConfig.Desc or "",
                    Values = dropdownConfig.Options or {},
                    Value = defaultValue,
                    Multi = isMulti,
                    AllowNone = true,
                    Callback = function(options)
                        DropdownAdapter.CurrentOption = options
                        if dropdownConfig.Callback then
                            pcall(dropdownConfig.Callback, options)
                        end
                    end
                })
            end)
            
            if not Dropdown then
                warn("Failed to create dropdown")
                return nil
            end
            
            DropdownAdapter._windDropdown = Dropdown
            DropdownAdapter.Name = dropdownConfig.Name
            DropdownAdapter.Type = "Dropdown"
            DropdownAdapter.Enabled = true
            DropdownAdapter.Order = #TabAdapter._elementOrder + 1
            
            TabAdapter._elements[dropdownConfig.Name] = DropdownAdapter
            table.insert(TabAdapter._elementOrder, dropdownConfig.Name)
            
            if WindowAdapter._uiConfig[self._tabName] then
                WindowAdapter._uiConfig[self._tabName].elements[dropdownConfig.Name] = {
                    type = "Dropdown",
                    name = dropdownConfig.Name,
                    enabled = true,
                    order = DropdownAdapter.Order
                }
            end
            
            if dropdownConfig.Flag then
                RayfieldAdapter.Flags[dropdownConfig.Flag] = DropdownAdapter
            end
            
            function DropdownAdapter:Set(options)
                if isMulti then
                    local value = type(options) == "table" and options or {options}
                    self.CurrentOption = value
                    if self._windDropdown and self._windDropdown.Select then
                        pcall(function()
                            self._windDropdown:Select(value)
                        end)
                    end
                else
                    local value = type(options) == "table" and options[1] or options
                    self.CurrentOption = value
                    if self._windDropdown and self._windDropdown.Select then
                        pcall(function()
                            self._windDropdown:Select(value)
                        end)
                    end
                end
            end
            
            return DropdownAdapter
        end
        
        return TabAdapter
    end
    
    -- Hàm lưu config
    function WindowAdapter:SaveConfig()
        SaveConfigToClipboard(windowTitle, self._uiConfig)
        print("✓ Config saved!")
    end
    
    -- Hàm export config
    function WindowAdapter:ExportConfig()
        pcall(function()
            local HttpService = game:GetService("HttpService")
            if HttpService then
                local configString = HttpService:JSONEncode(self._uiConfig)
                setclipboard(configString)
                return configString
            end
        end)
        return "{}"
    end
    
    -- Hàm import config
    function WindowAdapter:ImportConfig(jsonString)
        local success, newConfig = pcall(function()
            local HttpService = game:GetService("HttpService")
            if HttpService then
                return HttpService:JSONDecode(jsonString)
            end
        end)
        
        if success then
            self._uiConfig = newConfig
            return true
        end
        return false
    end
    
    -- Hàm Notify
    function WindowAdapter:Notify(title, content, duration)
        if self._windWindow and self._windWindow.Notify then
            pcall(function()
                self._windWindow:Notify({
                    Title = title or "Notification",
                    Content = content or "",
                    Duration = duration or 5,
                })
            end)
        end
    end
    
    return WindowAdapter
end

-- Notify global
function RayfieldAdapter:Notify(config)
    if not config then return end
    
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = config.Title or "Notification",
                Content = config.Content or "",
                Duration = config.Duration or 5,
                Icon = ConvertIcon(config.Image),
            })
        end
    end)
end

return RayfieldAdapter

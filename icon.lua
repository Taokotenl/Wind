--[[
    Rayfield to WindUI Adapter
    Chuyển đổi tự động các lệnh Rayfield sang WindUI
    Sử dụng: local Rayfield = loadstring(game:HttpGet('YOUR_SCRIPT_URL'))()
]]

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Tạo Rayfield Adapter
local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}

-- Hàm chuyển đổi Icon từ Roblox ID sang Lucide
local function ConvertIcon(icon)
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle" -- Default icon cho Roblox image IDs
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
        
        -- CreateSection
        function TabAdapter:CreateSection(name)
            local SectionAdapter = {}
            
            local Section = Tab:Section({
                Title = name,
                Box = true,
                Opened = true,
            })
            
            SectionAdapter._windSection = Section
            
            function SectionAdapter:Set(newName)
                Section:SetTitle(newName)
            end
            
            return SectionAdapter
        end
        
        -- CreateDivider
        function TabAdapter:CreateDivider()
            local DividerAdapter = {}
            
            -- WindUI không có divider riêng, dùng Section rỗng
            local Section = Tab:Section({
                Title = "───────────────────",
                Box = false,
                Opened = true,
            })
            
            function DividerAdapter:Set(visible)
                if visible then
                    Section:SetTitle("───────────────────")
                else
                    Section:SetTitle("")
                end
            end
            
            return DividerAdapter
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
            
            function ButtonAdapter:Set(newName)
                Button:SetTitle(newName)
            end
            
            return ButtonAdapter
        end
        
        -- CreateToggle
        function TabAdapter:CreateToggle(config)
            local ToggleAdapter = {}
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
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ToggleAdapter
            end
            
            function ToggleAdapter:Set(value)
                self.CurrentValue = value
                Toggle:Set(value)
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
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                Slider:Set(value)
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
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                Input:Set(value)
            end
            
            return InputAdapter
        end
        
        -- CreateDropdown
        function TabAdapter:CreateDropdown(config)
            local DropdownAdapter = {}
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
            end
            
            return DropdownAdapter
        end
        
        -- CreateColorPicker
        function TabAdapter:CreateColorPicker(config)
            local ColorPickerAdapter = {}
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
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ColorPickerAdapter
            end
            
            function ColorPickerAdapter:Set(color)
                self.CurrentValue = color
                -- WindUI không có hàm Set cho ColorPicker, phải tạo lại
            end
            
            return ColorPickerAdapter
        end
        
        -- CreateKeybind
        function TabAdapter:CreateKeybind(config)
            local KeybindAdapter = {}
            KeybindAdapter.CurrentKeybind = config.CurrentKeybind or "None"
            
            local Keybind = Tab:Keybind({
                Title = config.Name,
                Desc = "",
                Value = config.CurrentKeybind or "None",
                Callback = function(key)
                    KeybindAdapter.CurrentKeybind = key
                    if config.Callback then
                        -- Với HoldToInteract, cần xử lý khác
                        if config.HoldToInteract then
                            -- Trả về true khi giữ phím
                            config.Callback(true)
                        else
                            config.Callback(key)
                        end
                    end
                end
            })
            
            KeybindAdapter._windKeybind = Keybind
            
            -- Lưu vào Flags
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = KeybindAdapter
            end
            
            function KeybindAdapter:Set(key)
                self.CurrentKeybind = key
                -- WindUI không có hàm Set cho Keybind
            end
            
            return KeybindAdapter
        end
        
        -- CreateLabel
        function TabAdapter:CreateLabel(title, icon, color, ignoreTheme)
            local LabelAdapter = {}
            
            local Label = Tab:Paragraph({
                Title = title,
                Desc = "",
                Image = "",
                Locked = false,
            })
            
            LabelAdapter._windLabel = Label
            
            function LabelAdapter:Set(newTitle, newIcon, newColor, newIgnoreTheme)
                Label:SetTitle(newTitle)
            end
            
            return LabelAdapter
        end
        
        -- CreateParagraph
        function TabAdapter:CreateParagraph(config)
            local ParagraphAdapter = {}
            
            local Paragraph = Tab:Paragraph({
                Title = config.Title or "Paragraph",
                Desc = config.Content or "",
                Locked = false,
            })
            
            ParagraphAdapter._windParagraph = Paragraph
            
            function ParagraphAdapter:Set(newConfig)
                Paragraph:SetTitle(newConfig.Title or config.Title)
                Paragraph:SetDesc(newConfig.Content or config.Content)
            end
            
            return ParagraphAdapter
        end
        
        return TabAdapter
    end
    
    -- ModifyTheme
    function WindowAdapter.ModifyTheme(theme)
        if type(theme) == "string" then
            WindUI:SetTheme(ThemeMapping[theme] or theme)
        else
            -- Custom theme
            WindUI:AddTheme(theme)
        end
    end
    
    -- SetVisibility
    function WindowAdapter:SetVisibility(visible)
        -- WindUI không có hàm này, có thể dùng toggle key
    end
    
    -- IsVisible
    function WindowAdapter:IsVisible()
        return true -- Mặc định
    end
    
    -- Destroy
    function WindowAdapter:Destroy()
        -- WindUI không có hàm destroy trực tiếp
        if self._windWindow then
            -- Có thể ẩn UI
        end
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
    -- WindUI tự động load config, không cần gọi hàm này
    print("Configuration loaded automatically by WindUI")
end

-- SetVisibility
function RayfieldAdapter:SetVisibility(visible)
    -- Global function cho tất cả windows
end

-- IsVisible
function RayfieldAdapter:IsVisible()
    return true
end

-- Destroy
function RayfieldAdapter:Destroy()
    -- Destroy tất cả windows
end

return RayfieldAdapter

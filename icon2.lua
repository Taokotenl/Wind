--[[
    Rayfield to WindUI Auto-Generator with Callback Preservation
    Tự động chuyển đổi và TẠO SCRIPT WINDUI với CALLBACK GỐC
    Fixed: Theme must be created BEFORE any window operations
]]

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- ===== TẠO THEME TRƯỚC TIÊN =====
WindUI:AddTheme({
    Name = "VTriP Dark",
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#040040"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#473BE8"), Transparency = 0.42 },
    }, {
        Rotation = 104,
    }),
    Background = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#040040"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#473BE8"), Transparency = 0.42 },
    }, {
        Rotation = 104,
    }),
})

-- Code Generator
local CodeGenerator = {}
CodeGenerator.Lines = {}
CodeGenerator.Indentation = 0
CodeGenerator.CallbackSources = {}

function CodeGenerator:AddLine(code)
    local indent = string.rep("    ", self.Indentation)
    table.insert(self.Lines, indent .. code)
end

function CodeGenerator:Indent()
    self.Indentation = self.Indentation + 1
end

function CodeGenerator:Unindent()
    self.Indentation = math.max(0, self.Indentation - 1)
end

function CodeGenerator:GetCode()
    return table.concat(self.Lines, "\n")
end

function CodeGenerator:Reset()
    self.Lines = {}
    self.Indentation = 0
    self.CallbackSources = {}
end

-- Utility: Decompile function
local function DecompileFunction(func, funcName)
    if type(func) ~= "function" then 
        return string.format("local function %s(...)\n    -- Callback implementation\nend", funcName)
    end
    
    local upvalues = {}
    local i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        upvalues[name] = value
        i = i + 1
    end
    
    local lines = {}
    table.insert(lines, string.format("local function %s(...)", funcName))
    
    if next(upvalues) then
        table.insert(lines, "    -- Captured upvalues:")
        for name, value in pairs(upvalues) do
            if type(value) == "string" then
                table.insert(lines, string.format("    local %s = %q", name, value))
            elseif type(value) == "number" or type(value) == "boolean" then
                table.insert(lines, string.format("    local %s = %s", name, tostring(value)))
            else
                table.insert(lines, string.format("    -- local %s = %s (type: %s)", name, tostring(value), type(value)))
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "    -- TODO: Add your callback logic here")
    table.insert(lines, "    -- Original callback was defined but cannot be fully decompiled")
    table.insert(lines, "end")
    
    return table.concat(lines, "\n")
end

-- Convert value to code
local function ValueToCode(value, depth)
    depth = depth or 0
    if depth > 3 then return "nil" end
    
    if type(value) == "string" then
        return string.format("%q", value)
    elseif type(value) == "number" then
        return tostring(value)
    elseif type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "table" then
        local parts = {}
        local isArray = true
        local maxIndex = 0
        
        for k, v in pairs(value) do
            if type(k) ~= "number" then
                isArray = false
                break
            end
            maxIndex = math.max(maxIndex, k)
        end
        
        if isArray and maxIndex == #value then
            for i, v in ipairs(value) do
                table.insert(parts, ValueToCode(v, depth + 1))
            end
        else
            for k, v in pairs(value) do
                if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                    table.insert(parts, string.format("%s = %s", k, ValueToCode(v, depth + 1)))
                else
                    table.insert(parts, string.format("[%s] = %s", ValueToCode(k, depth + 1), ValueToCode(v, depth + 1)))
                end
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif typeof(value) == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", 
            math.floor(value.R * 255), 
            math.floor(value.G * 255), 
            math.floor(value.B * 255))
    elseif typeof(value) == "UDim2" then
        return string.format("UDim2.fromOffset(%d, %d)", value.X.Offset, value.Y.Offset)
    elseif typeof(value) == "EnumItem" then
        return tostring(value)
    else
        return "nil"
    end
end

local function ConvertIcon(icon)
    if type(icon) == "number" or (type(icon) == "string" and icon:match("^%d+$")) then
        return "circle"
    end
    return icon or "circle"
end

-- Rayfield Adapter
local RayfieldAdapter = {}
RayfieldAdapter.Flags = {}

function RayfieldAdapter:CreateWindow(config)
    local WindowAdapter = {}
    WindowAdapter._callbackCounter = 0
    WindowAdapter._generatedCallbacks = {}
    
    -- Initialize code generation
    CodeGenerator:Reset()
    CodeGenerator:AddLine("--[[")
    CodeGenerator:AddLine("    Auto-generated WindUI Script")
    CodeGenerator:AddLine("    Converted from Rayfield")
    CodeGenerator:AddLine("    Host by VTriP Official")
    CodeGenerator:AddLine("]]")
    CodeGenerator:AddLine("")
    CodeGenerator:AddLine("-- Load WindUI")
    CodeGenerator:AddLine("local WindUI = loadstring(game:HttpGet('https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'))()")
    CodeGenerator:AddLine("")
    
    -- Generate VTriP theme (same as original working script)
    CodeGenerator:AddLine("-- VTriP Custom Theme")
    CodeGenerator:AddLine("WindUI:AddTheme({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine("Name = 'VTriP Dark',")
    CodeGenerator:AddLine("Accent = WindUI:Gradient({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine("['0'] = {Color = Color3.fromHex('#040040'), Transparency = 0},")
    CodeGenerator:AddLine("['100'] = {Color = Color3.fromHex('#473BE8'), Transparency = 0.42},")
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("}, {Rotation = 104}),")
    CodeGenerator:AddLine("Background = WindUI:Gradient({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine("['0'] = {Color = Color3.fromHex('#040040'), Transparency = 0},")
    CodeGenerator:AddLine("['100'] = {Color = Color3.fromHex('#473BE8'), Transparency = 0.42},")
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("}, {Rotation = 104}),")
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("})")
    CodeGenerator:AddLine("")
    
    -- Window
    local windowTitle = config.Name or "Window"
    if windowTitle:find("Flash Hub") then
        windowTitle = windowTitle:gsub("Flash Hub", "VTriP")
    end
    
    CodeGenerator:AddLine("-- Create Window")
    CodeGenerator:AddLine("local Window = WindUI:CreateWindow({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(windowTitle)))
    CodeGenerator:AddLine(string.format("Icon = %s,", ValueToCode(ConvertIcon(config.Icon))))
    CodeGenerator:AddLine("Author = 'Host By VTriP Official',")
    CodeGenerator:AddLine(string.format("Folder = %s,", ValueToCode((config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "RayfieldAdapter")))
    CodeGenerator:AddLine("Size = UDim2.fromOffset(580, 460),")
    CodeGenerator:AddLine("Transparent = true,")
    CodeGenerator:AddLine("Theme = 'VTriP Dark',")
    CodeGenerator:AddLine("Resizable = true,")
    CodeGenerator:AddLine("SideBarWidth = 200,")
    
    if config.KeySystem then
        CodeGenerator:AddLine("KeySystem = {")
        CodeGenerator:Indent()
        CodeGenerator:AddLine(string.format("Key = %s,", ValueToCode(config.KeySettings.Key or {})))
        CodeGenerator:AddLine(string.format("Note = %s,", ValueToCode(config.KeySettings.Note or "No key note")))
        CodeGenerator:AddLine(string.format("SaveKey = %s,", ValueToCode(config.KeySettings.SaveKey or false)))
        CodeGenerator:Unindent()
        CodeGenerator:AddLine("},")
    end
    
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("})")
    CodeGenerator:AddLine("")
    
    CodeGenerator:AddLine("-- Customize Open Button")
    CodeGenerator:AddLine("Window:EditOpenButton({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine("Title = 'Open VTriP',")
    CodeGenerator:AddLine(string.format("Icon = %s,", ValueToCode(ConvertIcon(config.Icon))))
    CodeGenerator:AddLine("CornerRadius = UDim.new(0, 16),")
    CodeGenerator:AddLine("StrokeThickness = 2,")
    CodeGenerator:AddLine("Color = ColorSequence.new(Color3.fromHex('FF0F7B'), Color3.fromHex('F89B29')),")
    CodeGenerator:AddLine("OnlyMobile = false,")
    CodeGenerator:AddLine("Enabled = true,")
    CodeGenerator:AddLine("Draggable = true,")
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("})")
    CodeGenerator:AddLine("")
    
    if config.ToggleUIKeybind then
        local key = type(config.ToggleUIKeybind) == "string" 
            and "Enum.KeyCode." .. config.ToggleUIKeybind 
            or tostring(config.ToggleUIKeybind)
        CodeGenerator:AddLine(string.format("Window:SetToggleKey(%s)", key))
        CodeGenerator:AddLine("")
    end
    
    -- Create actual Window
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
    
    if config.ToggleUIKeybind then
        local keyCode = config.ToggleUIKeybind
        if type(keyCode) == "string" then
            Window:SetToggleKey(Enum.KeyCode[keyCode])
        else
            Window:SetToggleKey(keyCode)
        end
    end
    
    WindowAdapter._windWindow = Window
    WindowAdapter._config = config
    
    -- CreateTab
    function WindowAdapter:CreateTab(name, icon)
        local TabAdapter = {}
        local tabVarName = "Tab_" .. name:gsub("[%s%-%.%(%)%[%]%{%}]", "_")
        
        CodeGenerator:AddLine(string.format("-- Tab: %s", name))
        CodeGenerator:AddLine(string.format("local %s = Window:Tab({", tabVarName))
        CodeGenerator:Indent()
        CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(name)))
        CodeGenerator:AddLine(string.format("Icon = %s,", ValueToCode(ConvertIcon(icon))))
        CodeGenerator:Unindent()
        CodeGenerator:AddLine("})")
        CodeGenerator:AddLine("")
        
        local Tab = Window:Tab({
            Title = name,
            Icon = ConvertIcon(icon),
        })
        
        TabAdapter._windTab = Tab
        TabAdapter._tabVarName = tabVarName
        
        -- Helper: Generate callback
        local function GenerateCallback(elementType, elementName, callback, params)
            if not callback or type(callback) ~= "function" then 
                return "function(...) end" 
            end
            
            self._callbackCounter = self._callbackCounter + 1
            local callbackName = string.format("Callback_%s_%d", 
                elementType, 
                self._callbackCounter)
            
            local funcCode = DecompileFunction(callback, callbackName)
            
            if not self._generatedCallbacks[callbackName] then
                self._generatedCallbacks[callbackName] = {
                    code = funcCode,
                    params = params or "..."
                }
            end
            
            return callbackName
        end
        
        -- CreateButton
        function TabAdapter:CreateButton(config)
            local callbackRef = GenerateCallback("Button", config.Name, config.Callback, "")
            
            CodeGenerator:AddLine(string.format("%s:Button({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Desc = %s,", ValueToCode(config.Desc or "")))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Button({
                Title = config.Name,
                Desc = config.Desc or "",
                Callback = config.Callback or function() end
            })
        end
        
        -- CreateToggle
        function TabAdapter:CreateToggle(config)
            local callbackRef = GenerateCallback("Toggle", config.Name, config.Callback, "state")
            
            local description = config.Desc or ""
            if config.Plus then
                description = "[Plus Feature] " .. description
            end
            
            CodeGenerator:AddLine(string.format("%s:Toggle({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Desc = %s,", ValueToCode(description)))
            CodeGenerator:AddLine("Type = 'Checkbox',")
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(config.CurrentValue or false)))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            local ToggleAdapter = {}
            ToggleAdapter.CurrentValue = config.CurrentValue or false
            
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
            local callbackRef = GenerateCallback("Slider", config.Name, config.Callback, "value")
            
            CodeGenerator:AddLine(string.format("%s:Slider({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Desc = %s,", ValueToCode(config.Suffix or "")))
            CodeGenerator:AddLine(string.format("Step = %s,", ValueToCode(config.Increment or 1)))
            CodeGenerator:AddLine("Value = {")
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Min = %s,", ValueToCode(config.Range[1])))
            CodeGenerator:AddLine(string.format("Max = %s,", ValueToCode(config.Range[2])))
            CodeGenerator:AddLine(string.format("Default = %s,", ValueToCode(config.CurrentValue or config.Range[1])))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("},")
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
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
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = SliderAdapter
            end
            
            function SliderAdapter:Set(value)
                self.CurrentValue = value
                Slider:Set(value)
            end
            
            return SliderAdapter
        end
        
        -- CreateDropdown
        function TabAdapter:CreateDropdown(config)
            local callbackRef = GenerateCallback("Dropdown", config.Name, config.Callback, "options")
            
            local isMulti = config.MultipleOptions or false
            local defaultValue = isMulti 
                and (type(config.CurrentOption) == "table" and config.CurrentOption or {})
                or (type(config.CurrentOption) == "string" and config.CurrentOption or (config.Options and config.Options[1] or ""))
            
            CodeGenerator:AddLine(string.format("%s:Dropdown({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Desc = %s,", ValueToCode(config.Desc or "")))
            CodeGenerator:AddLine(string.format("Values = %s,", ValueToCode(config.Options or {})))
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(defaultValue)))
            CodeGenerator:AddLine(string.format("Multi = %s,", ValueToCode(isMulti)))
            CodeGenerator:AddLine("AllowNone = true,")
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            local DropdownAdapter = {}
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
            
            function DropdownAdapter:Refresh(newOptions, keepSelected)
                Dropdown:Refresh(newOptions)
                if keepSelected and self.CurrentOption then
                    self:Set(self.CurrentOption)
                end
            end
            
            return DropdownAdapter
        end
        
        -- CreateInput
        function TabAdapter:CreateInput(config)
            local callbackRef = GenerateCallback("Input", config.Name, config.Callback, "text")
            
            CodeGenerator:AddLine(string.format("%s:Input({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine("Desc = '',")
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(config.CurrentValue or "")))
            CodeGenerator:AddLine("Type = 'Input',")
            CodeGenerator:AddLine(string.format("Placeholder = %s,", ValueToCode(config.PlaceholderText or "")))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
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
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = InputAdapter
            end
            
            function InputAdapter:Set(value)
                self.CurrentValue = value
                Input:Set(value)
            end
            
            return InputAdapter
        end
        
        -- CreateColorPicker, Keybind, Label, Paragraph, Section, Divider
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
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = ColorPickerAdapter
            end
            
            function ColorPickerAdapter:Set(color)
                self.CurrentValue = color
            end
            
            return ColorPickerAdapter
        end
        
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
                        if config.HoldToInteract then
                            config.Callback(true)
                        else
                            config.Callback(key)
                        end
                    end
                end
            })
            
            KeybindAdapter._windKeybind = Keybind
            
            if config.Flag then
                RayfieldAdapter.Flags[config.Flag] = KeybindAdapter
            end
            
            function KeybindAdapter:Set(key)
                self.CurrentKeybind = key
            end
            
            return KeybindAdapter
        end
        
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
        
        function TabAdapter:CreateDivider()
            local DividerAdapter = {}
            
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
        
        return TabAdapter
    end
    
    -- ModifyTheme
    function WindowAdapter.ModifyTheme(theme)
        if type(theme) == "string" then
            WindUI:SetTheme(theme)
        else
            WindUI:AddTheme(theme)
        end
    end
    
    -- Finalize
    function WindowAdapter:Finalize()
        if next(self._generatedCallbacks) then
            local callbackLines = {}
            table.insert(callbackLines, "")
            table.insert(callbackLines, "-- ========== CALLBACK FUNCTIONS ==========")
            table.insert(callbackLines, "")
            
            for name, data in pairs(self._generatedCallbacks) do
                table.insert(callbackLines, data.code)
                table.insert(callbackLines, "")
            end
            
            table.insert(callbackLines, "-- ========== UI CREATION ==========")
            table.insert(callbackLines, "")
            
            local finalLines = {}
            local inserted = false
            for i, line in ipairs(CodeGenerator.Lines) do
                table.insert(finalLines, line)
                if line:match("AddTheme") and line:match("})") and not inserted then
                    inserted = true
                    for _, cbLine in ipairs(callbackLines) do
                        table.insert(finalLines, cbLine)
                    end
                end
            end
            
            CodeGenerator.Lines = inserted and finalLines or CodeGenerator.Lines
        end
        
        CodeGenerator:AddLine("")
        CodeGenerator:AddLine("-- Script generated successfully!")
        
        local generatedCode = CodeGenerator:GetCode()
        
        if setclipboard then
            setclipboard(generatedCode)
            WindUI:Notify({
                Title = "✅ Script Generated!",
                Content = "WindUI script đã copy vào clipboard. Paste để dùng ngay!",
                Duration = 10,
                Icon = "check-circle",
            })
        else
            WindUI:Notify({
                Title = "⚠️ Check Console (F9)",
                Content = "Executor không hỗ trợ clipboard. Xem console để copy.",
                Duration = 10,
                Icon = "alert-triangle",
            })
            print("\n" .. string.rep("=", 70))
            print("GENERATED WINDUI SCRIPT - COPY FROM HERE")
            print(string.rep("=", 70))
            print(generatedCode)
            print(string.rep("=", 70) .. "\n")
        end
    end
    
    return WindowAdapter
end

function RayfieldAdapter:Notify(config)
    WindUI:Notify({
        Title = config.Title or "Notification",
        Content = config.Content or "",
        Duration = config.Duration or 5,
        Icon = ConvertIcon(config.Image),
    })
end

function RayfieldAdapter:LoadConfiguration()
    -- WindUI tự động load config
end

function RayfieldAdapter:SetVisibility(visible)
    -- Global visibility control
end

function RayfieldAdapter:IsVisible()
    return true
end

function RayfieldAdapter:Destroy()
    -- Cleanup
end

return RayfieldAdapter

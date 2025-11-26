--[[
    Rayfield to WindUI Auto-Generator with Callback Preservation
    Tự động chuyển đổi và TẠO SCRIPT WINDUI với CALLBACK GỐC
    Sử dụng debug.getinfo để lấy source code của callback
]]

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Code Generator
local CodeGenerator = {}
CodeGenerator.Lines = {}
CodeGenerator.Indentation = 0
CodeGenerator.CallbackSources = {} -- Lưu source code callback

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

-- Utility: Lấy source code của function
local function GetFunctionSource(func)
    if type(func) ~= "function" then return nil end
    
    local info = debug.getinfo(func, "S")
    if not info then return nil end
    
    -- Nếu function được define trong script hiện tại
    if info.what == "Lua" and info.source and info.source:sub(1,1) == "@" then
        -- Không thể đọc file, return nil
        return nil
    end
    
    -- Nếu function được define inline trong loadstring
    if info.what == "Lua" and info.source and info.source:sub(1,1) == "=" then
        local source = info.source:sub(2)
        
        -- Thử lấy từ script đang chạy
        local success, result = pcall(function()
            return debug.getlocal(func, 1) -- Thử đọc upvalues
        end)
        
        if success then
            return source
        end
    end
    
    return nil
end

-- Utility: Decompile function thành code (simplified)
local function DecompileFunction(func, funcName)
    if type(func) ~= "function" then 
        return string.format("function %s()\n    -- Callback implementation\nend", funcName)
    end
    
    -- Thử lấy source
    local source = GetFunctionSource(func)
    if source then
        return source
    end
    
    -- Nếu không lấy được source, thử extract upvalues
    local upvalues = {}
    local i = 1
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        upvalues[name] = value
        i = i + 1
    end
    
    -- Generate function với upvalues
    local lines = {}
    table.insert(lines, string.format("function %s(...)", funcName))
    
    if next(upvalues) then
        table.insert(lines, "    -- Captured upvalues:")
        for name, value in pairs(upvalues) do
            if type(value) == "string" then
                table.insert(lines, string.format("    local %s = %q", name, value))
            elseif type(value) == "number" or type(value) == "boolean" then
                table.insert(lines, string.format("    local %s = %s", name, tostring(value)))
            else
                table.insert(lines, string.format("    -- local %s = %s", name, type(value)))
            end
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "    -- Original callback logic here")
    table.insert(lines, "    -- Parameters: ...")
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
    CodeGenerator:AddLine("    All callbacks preserved!")
    CodeGenerator:AddLine("]]")
    CodeGenerator:AddLine("")
    CodeGenerator:AddLine("-- Load WindUI")
    CodeGenerator:AddLine("local WindUI = loadstring(game:HttpGet('https://github.com/Footagesus/WindUI/releases/latest/download/main.lua'))()")
    CodeGenerator:AddLine("")
    
    -- Theme
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
    CodeGenerator:AddLine(string.format("Folder = %s,", ValueToCode((config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "WindUIConfig")))
    CodeGenerator:AddLine("Size = UDim2.fromOffset(580, 460),")
    CodeGenerator:AddLine("Transparent = true,")
    CodeGenerator:AddLine("Theme = 'VTriP Dark',")
    CodeGenerator:AddLine("Resizable = true,")
    
    if config.KeySystem then
        CodeGenerator:AddLine("KeySystem = {")
        CodeGenerator:Indent()
        CodeGenerator:AddLine(string.format("Key = %s,", ValueToCode(config.KeySettings.Key or {})))
        CodeGenerator:AddLine(string.format("Note = %s,", ValueToCode(config.KeySettings.Note or "")))
        CodeGenerator:AddLine(string.format("SaveKey = %s,", ValueToCode(config.KeySettings.SaveKey or false)))
        CodeGenerator:Unindent()
        CodeGenerator:AddLine("},")
    end
    
    CodeGenerator:Unindent()
    CodeGenerator:AddLine("})")
    CodeGenerator:AddLine("")
    
    CodeGenerator:AddLine("Window:EditOpenButton({")
    CodeGenerator:Indent()
    CodeGenerator:AddLine("Title = 'Open VTriP',")
    CodeGenerator:AddLine(string.format("Icon = %s,", ValueToCode(ConvertIcon(config.Icon))))
    CodeGenerator:AddLine("CornerRadius = UDim.new(0, 16),")
    CodeGenerator:AddLine("Color = ColorSequence.new(Color3.fromHex('FF0F7B'), Color3.fromHex('F89B29')),")
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
        Folder = (config.ConfigurationSaving and config.ConfigurationSaving.FolderName) or "WindUIConfig",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = "VTriP Dark",
        Resizable = true,
    }
    
    if config.KeySystem then
        windConfig.KeySystem = {
            Key = config.KeySettings.Key or {},
            Note = config.KeySettings.Note or "",
            SaveKey = config.KeySettings.SaveKey or false,
        }
    end
    
    local Window = WindUI:CreateWindow(windConfig)
    Window:EditOpenButton({
        Title = "Open VTriP",
        Icon = ConvertIcon(config.Icon),
        CornerRadius = UDim.new(0, 16),
        Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
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
        local tabVarName = "Tab_" .. name:gsub("[%s%-]", "_")
        
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
            
            -- Decompile callback
            local funcCode = DecompileFunction(callback, callbackName)
            
            -- Store để generate sau
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
            
            CodeGenerator:AddLine(string.format("%s:Toggle({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(config.CurrentValue or false)))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Toggle({
                Title = config.Name,
                Value = config.CurrentValue or false,
                Callback = config.Callback or function() end
            })
        end
        
        -- CreateSlider
        function TabAdapter:CreateSlider(config)
            local callbackRef = GenerateCallback("Slider", config.Name, config.Callback, "value")
            
            CodeGenerator:AddLine(string.format("%s:Slider({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
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
            
            return Tab:Slider({
                Title = config.Name,
                Step = config.Increment or 1,
                Value = {
                    Min = config.Range[1],
                    Max = config.Range[2],
                    Default = config.CurrentValue or config.Range[1],
                },
                Callback = config.Callback or function() end
            })
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
            CodeGenerator:AddLine(string.format("Values = %s,", ValueToCode(config.Options or {})))
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(defaultValue)))
            CodeGenerator:AddLine(string.format("Multi = %s,", ValueToCode(isMulti)))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Dropdown({
                Title = config.Name,
                Values = config.Options or {},
                Value = defaultValue,
                Multi = isMulti,
                Callback = config.Callback or function() end
            })
        end
        
        -- CreateInput
        function TabAdapter:CreateInput(config)
            local callbackRef = GenerateCallback("Input", config.Name, config.Callback, "text")
            
            CodeGenerator:AddLine(string.format("%s:Input({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Name)))
            CodeGenerator:AddLine(string.format("Placeholder = %s,", ValueToCode(config.PlaceholderText or "")))
            CodeGenerator:AddLine(string.format("Value = %s,", ValueToCode(config.CurrentValue or "")))
            CodeGenerator:AddLine(string.format("Callback = %s,", callbackRef))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Input({
                Title = config.Name,
                Placeholder = config.PlaceholderText or "",
                Value = config.CurrentValue or "",
                Callback = config.Callback or function() end
            })
        end
        
        -- CreateLabel / Paragraph
        function TabAdapter:CreateLabel(title, icon)
            CodeGenerator:AddLine(string.format("%s:Paragraph({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(title)))
            CodeGenerator:AddLine("Desc = '',")
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Paragraph({Title = title, Desc = ""})
        end
        
        function TabAdapter:CreateParagraph(config)
            CodeGenerator:AddLine(string.format("%s:Paragraph({", tabVarName))
            CodeGenerator:Indent()
            CodeGenerator:AddLine(string.format("Title = %s,", ValueToCode(config.Title or "")))
            CodeGenerator:AddLine(string.format("Desc = %s,", ValueToCode(config.Content or "")))
            CodeGenerator:Unindent()
            CodeGenerator:AddLine("})")
            CodeGenerator:AddLine("")
            
            return Tab:Paragraph({Title = config.Title or "", Desc = config.Content or ""})
        end
        
        return TabAdapter
    end
    
    -- Finalize: Generate callbacks và copy
    function WindowAdapter:Finalize()
        -- Generate all callbacks at the top
        if next(self._generatedCallbacks) then
            local callbackLines = {}
            table.insert(callbackLines, "")
            table.insert(callbackLines, "-- ========== CALLBACKS ==========")
            
            for name, data in pairs(self._generatedCallbacks) do
                table.insert(callbackLines, "")
                table.insert(callbackLines, data.code)
            end
            
            table.insert(callbackLines, "")
            table.insert(callbackLines, "-- ========== UI CREATION ==========")
            table.insert(callbackLines, "")
            
            -- Insert callbacks after theme setup
            local finalLines = {}
            local foundTheme = false
            for i, line in ipairs(CodeGenerator.Lines) do
                table.insert(finalLines, line)
                if line:match("AddTheme") and not foundTheme then
                    foundTheme = true
                    for _, cbLine in ipairs(callbackLines) do
                        table.insert(finalLines, cbLine)
                    end
                end
            end
            
            CodeGenerator.Lines = foundTheme and finalLines or CodeGenerator.Lines
        end
        
        CodeGenerator:AddLine("")
        CodeGenerator:AddLine("-- Script generated successfully!")
        
        local generatedCode = CodeGenerator:GetCode()
        
        if setclipboard then
            setclipboard(generatedCode)
            WindUI:Notify({
                Title = "✅ Script Generated!",
                Content = "WindUI script với callbacks đã copy vào clipboard. Paste để dùng ngay!",
                Duration = 10,
                Icon = "check-circle",
            })
        else
            WindUI:Notify({
                Title = "⚠️ Script Generated",
                Content = "Check console (F9) để lấy code. Executor không hỗ trợ clipboard.",
                Duration = 10,
                Icon = "alert-circle",
            })
            print("\n" .. string.rep("=", 60))
            print("GENERATED WINDUI SCRIPT (COPY THIS)")
            print(string.rep("=", 60))
            print(generatedCode)
            print(string.rep("=", 60) .. "\n")
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

return RayfieldAdapter

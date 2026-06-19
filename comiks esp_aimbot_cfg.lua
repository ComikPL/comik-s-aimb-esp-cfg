--[[
    comik's hub V14 - Poprawione wykrywanie configów po re-execucie
    Saves to: workspace/comik's e/a/c cfg/
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Stary UI cleanup, żeby się nie dublował przy re-execucie
if CoreGui:FindFirstChild("ComiksHubMobile") then
    CoreGui.ComiksHubMobile:Destroy()
end

--// Global Config
local Config = {
    Combat = { Aimbot = false, SilentAim = false, Triggerbot = false, FOV = 150, TargetPart = "Head", TeamCheck = true, WallCheck = false, SnapLevel = 5 },
    Visuals = { Box = false, Info = false, Tracers = false, FOV = false, Skeleton = false, Chams = false },
    Colors = {
        Main = {20, 20, 20}, Accent = {0, 255, 255},
        Box = {255, 0, 0}, Tracers = {0, 255, 0},
        Skeleton = {255, 255, 0}, Chams = {255, 0, 255},
        FOVCircle = {0, 255, 255}
    }
}

local SavedConfigsList = {}
local SelectedSlot = "brak_wyboru"
local FolderName = "comik's e/a/c cfg"

local function ToColor3(tbl) return Color3.fromRGB(tbl[1], tbl[2], tbl[3]) end

--=========================================
--// FIXED STORAGE MANAGEMENT
--=========================================
local function UpdateLocalFilesList()
    if isfile and listfiles then
        pcall(function()
            if not isfolder(FolderName) then makefolder(FolderName) end
            local files = listfiles(FolderName)
            local found = {}
            for _, file in ipairs(files) do
                if file:sub(-5) == ".json" then
                    -- Wyciąganie czystej nazwy pliku niezależnie od exploita
                    local name = file:gsub(FolderName .. "/", ""):gsub(".json", "")
                    name = name:match("[^/\\]+$") or name
                    table.insert(found, name)
                end
            end
            SavedConfigsList = found
            if #SavedConfigsList > 0 then
                if SelectedSlot == "brak_wyboru" or not table.find(SavedConfigsList, SelectedSlot) then
                    SelectedSlot = SavedConfigsList[1]
                end
            else
                SelectedSlot = "brak_wyboru"
            end
        end)
    end
end

local function SaveConfig(CustomName)
    if writefile and makefolder then
        makefolder(FolderName)
        local name = (CustomName and CustomName ~= "") and CustomName or (SelectedSlot ~= "brak_wyboru" and SelectedSlot or "my_config")
        name = name:gsub("%.json$", "") -- bezpieczeństwo rozszerzenia
        local success, encoded = pcall(function() return HttpService:JSONEncode(Config) end)
        if success then 
            writefile(FolderName .. "/" .. name .. ".json", encoded)
            SelectedSlot = name
            UpdateLocalFilesList()
        end
    end
end

local function LoadConfig()
    UpdateLocalFilesList() -- upewnij się, że lista jest aktualna przed ładowaniem
    if SelectedSlot == "brak_wyboru" then return end
    local path = FolderName .. "/" .. SelectedSlot .. ".json"
    if isfile and readfile and isfile(path) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if success then
            for k, v in pairs(decoded) do
                if type(v) == "table" then
                    for sk, sv in pairs(v) do Config[k][sk] = sv end
                end
            end
        end
    end
end

-- Wymuszenie skanowania folderu na starcie/re-execucie
pcall(function() if makefolder then makefolder(FolderName) end end)
UpdateLocalFilesList()
if SelectedSlot ~= "brak_wyboru" then LoadConfig() end

local Cache = {}
local SkeletonBones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

--=========================================
--// ENGINE UI CONFIGS
--=========================================
local MeowUI = Instance.new("ScreenGui", CoreGui)
MeowUI.Name = "ComiksHubMobile"
MeowUI.ResetOnSpawn = false

local ToggleBtn = Instance.new("TextButton", MeowUI)
ToggleBtn.Size = UDim2.new(0, 55, 0, 55); ToggleBtn.Position = UDim2.new(0, 10, 0, 10); ToggleBtn.BackgroundColor3 = ToColor3(Config.Colors.Main); ToggleBtn.TextColor3 = ToColor3(Config.Colors.Accent); ToggleBtn.Text = "cwol"; ToggleBtn.Font = Enum.Font.GothamBold; ToggleBtn.TextSize = 14
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0); Instance.new("UIStroke", ToggleBtn).Color = ToColor3(Config.Colors.Accent)

local MainFrame = Instance.new("Frame", MeowUI)
MainFrame.Size = UDim2.new(0, 250, 0, 420); MainFrame.Position = UDim2.new(0.5, -125, 0.5, -210); MainFrame.BackgroundColor3 = ToColor3(Config.Colors.Main); MainFrame.Visible = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10); Instance.new("UIStroke", MainFrame).Color = ToColor3(Config.Colors.Accent)

local function MakeDraggable(UIInstance)
    local dragging, dragInput, dragStart, startPos
    UIInstance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = UIInstance.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIInstance.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            UIInstance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(ToggleBtn); MakeDraggable(MainFrame)

local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, 0, 0, 35); TabBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local TabAimbotBtn = Instance.new("TextButton", TabBar)
TabAimbotBtn.Size = UDim2.new(0.33, 0, 1, 0); TabAimbotBtn.Text = "Aim"; TabAimbotBtn.TextColor3 = ToColor3(Config.Colors.Accent); TabAimbotBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40); TabAimbotBtn.Font = Enum.Font.GothamBold; TabAimbotBtn.TextSize = 12

local TabVisualsBtn = Instance.new("TextButton", TabBar)
TabVisualsBtn.Size = UDim2.new(0.33, 0, 1, 0); TabVisualsBtn.Position = UDim2.new(0.33, 0, 0, 0); TabVisualsBtn.Text = "Esp"; TabVisualsBtn.TextColor3 = Color3.fromRGB(200, 200, 200); TabVisualsBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TabVisualsBtn.Font = Enum.Font.GothamBold; TabVisualsBtn.TextSize = 12

local TabCfgBtn = Instance.new("TextButton", TabBar)
TabCfgBtn.Size = UDim2.new(0.34, 0, 1, 0); TabCfgBtn.Position = UDim2.new(0.66, 0, 0, 0); TabCfgBtn.Text = "Cfg"; TabCfgBtn.TextColor3 = Color3.fromRGB(200, 200, 200); TabCfgBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TabCfgBtn.Font = Enum.Font.GothamBold; TabCfgBtn.TextSize = 12

local AimbotFrame = Instance.new("ScrollingFrame", MainFrame)
AimbotFrame.Size = UDim2.new(1, -20, 1, -55); AimbotFrame.Position = UDim2.new(0, 10, 0, 45); AimbotFrame.BackgroundTransparency = 1; AimbotFrame.ScrollBarThickness = 2
local AimbotLayout = Instance.new("UIListLayout", AimbotFrame); AimbotLayout.Padding = UDim.new(0, 6)

local VisualsFrame = Instance.new("ScrollingFrame", MainFrame)
VisualsFrame.Size = AimbotFrame.Size; VisualsFrame.Position = AimbotFrame.Position; VisualsFrame.BackgroundTransparency = 1; VisualsFrame.ScrollBarThickness = 2; VisualsFrame.Visible = false
local VisualsLayout = Instance.new("UIListLayout", VisualsFrame); VisualsLayout.Padding = UDim.new(0, 6)

local CfgFrame = Instance.new("ScrollingFrame", MainFrame)
CfgFrame.Size = AimbotFrame.Size; CfgFrame.Position = AimbotFrame.Position; CfgFrame.BackgroundTransparency = 1; CfgFrame.ScrollBarThickness = 2; CfgFrame.Visible = false
local CfgLayout = Instance.new("UIListLayout", CfgFrame); CfgLayout.Padding = UDim.new(0, 6)

ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local function SwitchTab(Target)
    AimbotFrame.Visible = (Target == "Aimbot")
    VisualsFrame.Visible = (Target == "Visuals")
    CfgFrame.Visible = (Target == "Cfg")
    TabAimbotBtn.BackgroundColor3 = Target == "Aimbot" and Color3.fromRGB(40,40,40) or Color3.fromRGB(25,25,25)
    TabVisualsBtn.BackgroundColor3 = Target == "Visuals" and Color3.fromRGB(40,40,40) or Color3.fromRGB(25,25,25)
    TabCfgBtn.BackgroundColor3 = Target == "Cfg" and Color3.fromRGB(40,40,40) or Color3.fromRGB(25,25,25)
end
TabAimbotBtn.MouseButton1Click:Connect(function() SwitchTab("Aimbot") end)
TabVisualsBtn.MouseButton1Click:Connect(function() SwitchTab("Visuals") end)
TabCfgBtn.MouseButton1Click:Connect(function() SwitchTab("Cfg") end)

--=========================================
--// GENERATOR UTILITIES
--=========================================
local function CreateToggleButton(Name, Category, Setting, ParentFrame)
    local Btn = Instance.new("TextButton", ParentFrame)
    Btn.Size = UDim2.new(1, 0, 0, 32)
    local function UpdateBtnView()
        local state = Config[Category][Setting]
        Btn.BackgroundColor3 = state and ToColor3(Config.Colors.Accent) or Color3.fromRGB(35, 35, 35)
        Btn.TextColor3 = state and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
        Btn.Text = Name .. (state and " : ON" or " : OFF")
    end
    Btn.Font = Enum.Font.GothamSemibold; Btn.TextSize = 12
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    UpdateBtnView()
    Btn.MouseButton1Click:Connect(function() Config[Category][Setting] = not Config[Category][Setting]; UpdateBtnView() end)
    RunService.Heartbeat:Connect(UpdateBtnView) -- Odśwież widok przy załadowaniu pliku cfg
    return Btn
end

local function CreateColorCycleButton(Name, ColorKey, ParentFrame)
    local PresetColors = {
        {255, 0, 0}, {0, 255, 0}, {0, 0, 255}, 
        {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 255, 255}
    }
    local Btn = Instance.new("TextButton", ParentFrame)
    Btn.Size = UDim2.new(1, 0, 0, 26)
    Btn.Font = Enum.Font.Gotham; Btn.TextSize = 11
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    
    local function UpdateBtn()
        local current = Config.Colors[ColorKey]
        Btn.BackgroundColor3 = Color3.fromRGB(current[1], current[2], current[3])
        Btn.Text = Name .. " Color"
        Btn.TextColor3 = (current[1]+current[2]+current[3]) > 400 and Color3.new(0,0,0) or Color3.new(1,1,1)
    end
    
    Btn.MouseButton1Click:Connect(function()
        local current = Config.Colors[ColorKey]
        local nextIdx = 1
        for i, rgb in ipairs(PresetColors) do
            if rgb[1] == current[1] and rgb[2] == current[2] and rgb[3] == current[3] then
                nextIdx = (i % #PresetColors) + 1
                break
            end
        end
        Config.Colors[ColorKey] = PresetColors[nextIdx]
        UpdateBtn()
    end)
    RunService.Heartbeat:Connect(UpdateBtn)
end

local function CreateSlider(Name, Min, Max, Category, Setting, ParentFrame)
    local Container = Instance.new("Frame", ParentFrame)
    Container.Size = UDim2.new(1, 0, 0, 45); Container.BackgroundTransparency = 1
    local Label = Instance.new("TextLabel", Container)
    Label.Size = UDim2.new(0.7, 0, 0, 15); Label.Text = Name; Label.TextColor3 = Color3.new(1,1,1); Label.BackgroundTransparency = 1; Label.TextXAlignment = Enum.TextXAlignment.Left; Label.Font = Enum.Font.Gotham; Label.TextSize = 11
    local NumBox = Instance.new("TextLabel", Container)
    NumBox.Size = UDim2.new(0.3, 0, 0, 15); NumBox.Position = UDim2.new(0.7, 0, 0, 0); NumBox.TextColor3 = ToColor3(Config.Colors.Accent); NumBox.BackgroundTransparency = 1; NumBox.TextXAlignment = Enum.TextXAlignment.Right; NumBox.Font = Enum.Font.GothamBold; NumBox.TextSize = 11
    local SliderTrack = Instance.new("TextButton", Container)
    SliderTrack.Size = UDim2.new(1, 0, 0, 8); SliderTrack.Position = UDim2.new(0, 0, 0, 22); SliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 45); SliderTrack.Text = ""
    Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 4)
    local SliderFill = Instance.new("Frame", SliderTrack)
    SliderFill.Size = UDim2.new(0, 0, 1, 0); SliderFill.BackgroundColor3 = ToColor3(Config.Colors.Accent)
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

    local function UpdateSliderPosition(Value)
        local Percentage = math.clamp((Value - Min) / (Max - Min), 0, 1)
        SliderFill.Size = UDim2.new(Percentage, 0, 1, 0)
        NumBox.Text = tostring(math.floor(Value))
    end
    local function SnapToInput(input)
        local Percentage = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        local Value = Min + (Percentage * (Max - Min))
        Config[Category][Setting] = Value
        UpdateSliderPosition(Value)
    end
    local Sliding = false
    SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Sliding = true; SnapToInput(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if Sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then SnapToInput(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then Sliding = false end
    end)
    RunService.Heartbeat:Connect(function() UpdateSliderPosition(Config[Category][Setting]) end)
end

--=========================================
--// POPULATE INTERFACE MENU
--=========================================
CreateToggleButton("Aimbot Lock", "Combat", "Aimbot", AimbotFrame)
CreateToggleButton("Silent Aim", "Combat", "SilentAim", AimbotFrame)
CreateToggleButton("Triggerbot", "Combat", "Triggerbot", AimbotFrame)
CreateToggleButton("Team Check", "Combat", "TeamCheck", AimbotFrame)
CreateToggleButton("Wall Check", "Combat", "WallCheck", AimbotFrame)
CreateSlider("Snapping Speed", 0, 10, "Combat", "SnapLevel", AimbotFrame)
CreateSlider("FOV Radius Size", 100, 1000, "Combat", "FOV", AimbotFrame)

CreateToggleButton("Box ESP", "Visuals", "Box", VisualsFrame)
CreateColorCycleButton("Box", "Box", VisualsFrame)
CreateToggleButton("Tracers", "Visuals", "Tracers", VisualsFrame)
CreateColorCycleButton("Tracers", "Tracers", VisualsFrame)
CreateToggleButton("Skeleton ESP", "Visuals", "Skeleton", VisualsFrame)
CreateColorCycleButton("Skeleton", "Skeleton", VisualsFrame)
CreateToggleButton("Chams (Through Walls)", "Visuals", "Chams", VisualsFrame)
CreateColorCycleButton("Chams", "Chams", VisualsFrame)
CreateToggleButton("Show FOV Circle", "Visuals", "FOV", VisualsFrame)
CreateColorCycleButton("FOV Ring", "FOVCircle", VisualsFrame)
CreateToggleButton("Name/HP/Dist", "Visuals", "Info", VisualsFrame)

-- TAB 3: CONFIG MGR
local InputBox = Instance.new("TextBox", CfgFrame)
InputBox.Size = UDim2.new(1, 0, 0, 32); InputBox.BackgroundColor3 = Color3.fromRGB(30,30,30); InputBox.TextColor3 = Color3.new(1,1,1); InputBox.PlaceholderText = "Enter custom config name..."; InputBox.Text = ""; InputBox.Font = Enum.Font.Gotham; InputBox.TextSize = 12
Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

local DropdownMainBtn = Instance.new("TextButton", CfgFrame)
DropdownMainBtn.Size = UDim2.new(1, 0, 0, 35); DropdownMainBtn.BackgroundColor3 = Color3.fromRGB(45,45,45); DropdownMainBtn.TextColor3 = ToColor3(Config.Colors.Accent); DropdownMainBtn.Text = "Select Profile: " .. SelectedSlot; DropdownMainBtn.Font = Enum.Font.GothamBold; DropdownMainBtn.TextSize = 12
Instance.new("UICorner", DropdownMainBtn).CornerRadius = UDim.new(0, 6)

local DropdownItemsFrame = Instance.new("Frame", CfgFrame)
DropdownItemsFrame.Size = UDim2.new(1, 0, 0, 0); DropdownItemsFrame.BackgroundTransparency = 1; DropdownItemsFrame.Visible = false
local DropLayout = Instance.new("UIListLayout", DropdownItemsFrame); DropLayout.Padding = UDim.new(0, 4)

local function RedrawDropdownList()
    for _, item in ipairs(DropdownItemsFrame:GetChildren()) do if item:IsA("TextButton") then item:Destroy() end end
    UpdateLocalFilesList()
    if #SavedConfigsList == 0 then DropdownMainBtn.Text = "No Configs Found" return end
    
    for _, profileName in ipairs(SavedConfigsList) do
        local ItemBtn = Instance.new("TextButton", DropdownItemsFrame)
        ItemBtn.Size = UDim2.new(1, 0, 0, 28); ItemBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); ItemBtn.TextColor3 = Color3.new(1,1,1); ItemBtn.Text = profileName; ItemBtn.Font = Enum.Font.Gotham; ItemBtn.TextSize = 11
        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 4)
        ItemBtn.MouseButton1Click:Connect(function()
            SelectedSlot = profileName
            DropdownMainBtn.Text = "Select Profile: " .. SelectedSlot
            DropdownItemsFrame.Visible = false
            DropdownItemsFrame.Size = UDim2.new(1, 0, 0, 0)
        end)
    end
end

DropdownMainBtn.MouseButton1Click:Connect(function()
    local isVisible = not DropdownItemsFrame.Visible
    DropdownItemsFrame.Visible = isVisible
    if isVisible then
        RedrawDropdownList()
        DropdownItemsFrame.Size = UDim2.new(1, 0, 0, DropLayout.AbsoluteContentSize.Y)
    else DropdownItemsFrame.Size = UDim2.new(1, 0, 0, 0) end
end)

RunService.Heartbeat:Connect(function()
    if SelectedSlot == "brak_wyboru" then
        DropdownMainBtn.Text = "No Configs Found"
    else
        DropdownMainBtn.Text = "Select Profile: " .. SelectedSlot
    end
end)

local SaveBtn = Instance.new("TextButton", CfgFrame)
SaveBtn.Size = UDim2.new(1, 0, 0, 35); SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0); SaveBtn.TextColor3 = Color3.new(1,1,1); SaveBtn.Text = "SAVE PROFILE"; SaveBtn.Font = Enum.Font.GothamBold; SaveBtn.TextSize = 11
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)
SaveBtn.MouseButton1Click:Connect(function()
    SaveConfig(InputBox.Text)
    InputBox.Text = ""
end)

local LoadBtn = Instance.new("TextButton", CfgFrame)
LoadBtn.Size = UDim2.new(1, 0, 0, 35); LoadBtn.BackgroundColor3 = Color3.fromRGB(140, 90, 0); LoadBtn.TextColor3 = Color3.new(1,1,1); LoadBtn.Text = "LOAD PROFILE"; LoadBtn.Font = Enum.Font.GothamBold; LoadBtn.TextSize = 11
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 6); LoadBtn.MouseButton1Click:Connect(LoadConfig)

-- FOV Ring Setup
local FOVCircle = Instance.new("Frame", MeowUI)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5); FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0); FOVCircle.BackgroundTransparency = 1; FOVCircle.Visible = false
local FOVStroke = Instance.new("UIStroke", FOVCircle); FOVStroke.Thickness = 1.5
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)

--=========================================
--// ESP DATA PIPELINE
--=========================================
local function CreateVisuals(Player)
    if Cache[Player] then return end
    local Data = { Box = Drawing.new("Square"), Tracer = Drawing.new("Line"), Info = Drawing.new("Text"), Bones = {}, Chams = nil }
    Data.Box.Thickness = 1; Data.Box.Filled = false
    Data.Tracer.Thickness = 1
    Data.Info.Size = 14; Data.Info.Center = true; Data.Info.Outline = true; Data.Info.Color = Color3.new(1, 1, 1)
    for i = 1, #SkeletonBones do
        local Line = Drawing.new("Line"); Line.Thickness = 1
        table.insert(Data.Bones, Line)
    end
    Cache[Player] = Data
end

local function RemoveVisuals(Player)
    if Cache[Player] then
        Cache[Player].Box:Remove(); Cache[Player].Tracer:Remove(); Cache[Player].Info:Remove()
        for _, b in ipairs(Cache[Player].Bones) do b:Remove() end
        if Cache[Player].Chams then Cache[Player].Chams:Destroy() end
        Cache[Player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateVisuals(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateVisuals(p) end end)
Players.PlayerRemoving:Connect(RemoveVisuals)

local function GetTarget()
    local Target, Closest = nil, Config.Combat.FOV
    local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Config.Combat.TargetPart) then
            if Config.Combat.TeamCheck and v.Team == LocalPlayer.Team then continue end
            local Hum = v.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 then
                local Part = v.Character[Config.Combat.TargetPart]
                local Pos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                if OnScreen then
                    local Dist = (Vector2.new(Pos.X, Pos.Y) - Center).Magnitude
                    if Dist < Closest then
                        if Config.Combat.WallCheck then
                            local RayP = RaycastParams.new()
                            RayP.FilterType = Enum.RaycastFilterType.Exclude
                            RayP.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                            local Result = workspace:Raycast(Camera.CFrame.Position, (Part.Position - Camera.CFrame.Position), RayP)
                            if not Result or Result.Instance:IsDescendantOf(v.Character) then Target = v; Closest = Dist end
                        else Target = v; Closest = Dist end
                    end
                end
            end
        end
    end
    return Target
end

--=========================================
--// MAIN REPEATER LOOP
--=========================================
RunService.RenderStepped:Connect(function()
    local BoxColor = ToColor3(Config.Colors.Box)
    local TracerColor = ToColor3(Config.Colors.Tracers)
    local SkeletonColor = ToColor3(Config.Colors.Skeleton)
    local ChamsColor = ToColor3(Config.Colors.Chams)
    local RingColor = ToColor3(Config.Colors.FOVCircle)

    FOVCircle.Visible = Config.Visuals.FOV
    FOVCircle.Size = UDim2.new(0, Config.Combat.FOV * 2, 0, Config.Combat.FOV * 2)
    FOVStroke.Color = RingColor
    
    local Char = LocalPlayer.Character
    local MyRoot = Char and Char:FindFirstChild("HumanoidRootPart")
    
    -- Aimbot Lock
    if Config.Combat.Aimbot then
        local T = GetTarget()
        if T and T.Character and T.Character:FindFirstChild(Config.Combat.TargetPart) then
            local TargetPos = T.Character[Config.Combat.TargetPart].Position
            local RawSnap = Config.Combat.SnapLevel
            local Interpolation = RawSnap == 10 and 1.0 or (RawSnap * 0.09) + 0.01
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, TargetPos), Interpolation)
        end
    end

    -- Triggerbot Engine
    if Config.Combat.Triggerbot and Mouse.Target then
        local TargetPlayer = Players:GetPlayerFromCharacter(Mouse.Target.Parent) or Players:GetPlayerFromCharacter(Mouse.Target.Parent.Parent)
        if TargetPlayer and TargetPlayer ~= LocalPlayer then
            if not Config.Combat.TeamCheck or TargetPlayer.Team ~= LocalPlayer.Team then
                local Hum = TargetPlayer.Character and TargetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if Hum and Hum.Health > 0 then mouse1click() end
            end
        end
    end

    -- ESP Render Pipe
    for player, visual in pairs(Cache) do
        local pChar = player.Character
        local Root = pChar and pChar:FindFirstChild("HumanoidRootPart")
        local Hum = pChar and pChar:FindFirstChildOfClass("Humanoid")
        
        if Root and Hum and Hum.Health > 0 then
            local RootPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            
            -- Dynamic Chams Engine
            if Config.Visuals.Chams then
                if not visual.Chams then
                    visual.Chams = Instance.new("Highlight")
                    visual.Chams.FillTransparency = 0.5
                    visual.Chams.OutlineTransparency = 0
                end
                visual.Chams.FillColor = ChamsColor
                visual.Chams.OutlineColor = Color3.new(1,1,1)
                visual.Chams.Parent = pChar
            else
                if visual.Chams then visual.Chams.Parent = nil end
            end

            -- Render Boxes
            if OnScreen and (Config.Visuals.Box or Config.Visuals.Info) then
                local SizeX = 2000 / RootPos.Z; local SizeY = 3000 / RootPos.Z
                if Config.Visuals.Box then
                    visual.Box.Size = Vector2.new(SizeX, SizeY); visual.Box.Position = Vector2.new(RootPos.X - SizeX / 2, RootPos.Y - SizeY / 2); visual.Box.Color = BoxColor; visual.Box.Visible = true
                else visual.Box.Visible = false end

                if Config.Visuals.Info and MyRoot then
                    local Dist = math.floor((Root.Position - MyRoot.Position).Magnitude)
                    visual.Info.Text = string.format("%s\n%s HP | %sm", player.Name, math.floor(Hum.Health), Dist)
                    visual.Info.Position = Vector2.new(RootPos.X, RootPos.Y - (SizeY / 2) - 30); visual.Info.Visible = true
                else visual.Info.Visible = false end
            else visual.Box.Visible = false; visual.Info.Visible = false end

            -- Render Tracers
            if OnScreen and Config.Visuals.Tracers then
                visual.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); visual.Tracer.To = Vector2.new(RootPos.X, RootPos.Y); visual.Tracer.Color = TracerColor; visual.Tracer.Visible = true
            else visual.Tracer.Visible = false end

            -- Render Skeletons
            if Config.Visuals.Skeleton then
                for i, bone in ipairs(SkeletonBones) do
                    local p1, p2 = pChar:FindFirstChild(bone[1]), pChar:FindFirstChild(bone[2])
                    if p1 and p2 then
                        local pos1, v1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, v2 = Camera:WorldToViewportPoint(p2.Position)
                        if v1 and v2 then
                            visual.Bones[i].From = Vector2.new(pos1.X, pos1.Y); visual.Bones[i].To = Vector2.new(pos2.X, pos2.Y); visual.Bones[i].Color = SkeletonColor; visual.Bones[i].Visible = true
                        else visual.Bones[i].Visible = false end
                    else visual.Bones[i].Visible = false end
                end
            else for _, bone in ipairs(visual.Bones) do bone.Visible = false end end
        else
            visual.Box.Visible = false; visual.Tracer.Visible = false; visual.Info.Visible = false
            if visual.Chams then visual.Chams.Parent = nil end
            for _, b in ipairs(visual.Bones) do b.Visible = false end
        end
    end
end)

local OldIndex
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if Config.Combat.SilentAim and self == Mouse and (index == "Hit" or index == "Target") and not checkcaller() then
        local T = GetTarget()
        if T then
            local Part = T.Character[Config.Combat.TargetPart]
            return (index == "Hit" and Part.CFrame or Part)
        end
    end
    return OldIndex(self, index)
end))
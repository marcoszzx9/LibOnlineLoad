--// Load Fluent safely
local Fluent
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
        ))()
    end)

    if not ok or not lib then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Erro",
            Text = "Falha ao carregar Fluent UI",
            Duration = 5
        })
        return
    end

    Fluent = lib
end

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// CHAMS SETTINGS
getgenv().chams = {
    enabled = false, 
    outlineColor = Color3.fromRGB(255, 255, 255),
    fillColor = Color3.fromRGB(255, 0, 0), 
    fillTransparency = 0.5, 
    outlineTransparency = 0, 
    teamCheck = false 
}

--// FLAGS
local Flags = {
    -- Aimbot
    AimbotEnabled = false,
    TeamCheck = false,
    ShowFOV = false,
    Holding = false,
    
    -- ESP
    ESPEnabled = false,
    BoxESP = false,
    SkeletonESP = false,
    Tracers = false,
    Names = false,
    Health = false,
    Distance = false,
    
    -- Combat
    NoRecoil = false,
    Hitboxes = false
}

--// ESP VARIABLES
local Drawings = {}

--// AIMBOT VARIABLES
local FOVCircle
local AimPart = "Head"
local CircleRadius = 80
local CircleColor = Color3.fromRGB(255, 255, 255)
local CircleTransparency = 0.7

--// HITBOX VARIABLES
local HitboxExpander = {
    Enabled = false,
    Size = 10,
    Transparency = 0.5,
    TeamCheck = false,
    OriginalSizes = {},
    ActiveParts = {"Head", "HumanoidRootPart"}
}

--// WINDOW
local Window = Fluent:CreateWindow({
    Title = "Hypershoot Ultimate",
    SubTitle = "Combat Cheat Menu",
    TabWidth = 160,
    Size = UDim2.fromOffset(550, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

--// TABS
local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "target" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" })
}

------------------------------------------------
-- UTILITY FUNCTIONS
------------------------------------------------
local function GetClosestPlayer()
    if not Flags.AimbotEnabled then return nil end
    
    local MaximumDistance = CircleRadius
    local Target = nil

    for _, player in next, Players:GetPlayers() do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end
        
        -- Team check
        if Flags.TeamCheck and player.Team == LocalPlayer.Team then
            continue
        end
        
        local ScreenPoint = Camera:WorldToScreenPoint(rootPart.Position)
        local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
        
        if VectorDistance < MaximumDistance then
            Target = player
            MaximumDistance = VectorDistance
        end
    end

    return Target
end

local function isEnemy(player)
    if not LocalPlayer.Character then return true end
    if getgenv().chams.teamCheck or Flags.TeamCheck then
        return player.Team ~= LocalPlayer.Team
    end
    return true
end

------------------------------------------------
-- CHAMS SYSTEM
------------------------------------------------
do
    local activeHighlights = {}
    
    local function createHighlight(character)
        local highlight = Instance.new("Highlight")
        highlight.Adornee = character
        highlight.FillTransparency = getgenv().chams.fillTransparency
        highlight.FillColor = getgenv().chams.fillColor
        highlight.OutlineColor = getgenv().chams.outlineColor
        highlight.OutlineTransparency = getgenv().chams.outlineTransparency
        highlight.Parent = character
        return highlight
    end
    
    local function removeHighlight(character)
        local highlight = character:FindFirstChildOfClass("Highlight")
        if highlight then
            highlight:Destroy()
        end
    end
    
    local function applyHighlight(player)
        if player == LocalPlayer or (getgenv().chams.teamCheck and player.Team == LocalPlayer.Team) then 
            return 
        end

        local character = player.Character
        if character then
            removeHighlight(character)
            local highlight = createHighlight(character)
            activeHighlights[player] = highlight
        end
    end
    
    local function removeAllHighlights()
        for player, _ in pairs(activeHighlights) do
            if player.Character then
                removeHighlight(player.Character)
            end
        end
        activeHighlights = {}
    end
    
    local function monitorPlayers()
        if not getgenv().chams.enabled then
            removeAllHighlights()
            return
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            applyHighlight(player)
        end
    end
    
    -- Player events
    local function onPlayerAdded(player)
        player.CharacterAdded:Connect(function(character)
            if getgenv().chams.enabled then
                applyHighlight(player)
            end
        end)

        if player.Character and getgenv().chams.enabled then
            applyHighlight(player)
        end
    end
    
    local function onPlayerRemoving(player)
        if player.Character then
            removeHighlight(player.Character)
        end
        activeHighlights[player] = nil
    end
    
    -- Update loop
    task.spawn(function()
        while task.wait(0.2) do
            monitorPlayers()
        end
    end)
    
    -- Initialize
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
end

------------------------------------------------
-- AIMBOT SYSTEM
------------------------------------------------
do
    -- Create FOV Circle
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Radius = CircleRadius
    FOVCircle.Filled = false
    FOVCircle.Color = CircleColor
    FOVCircle.Visible = false
    FOVCircle.Transparency = CircleTransparency
    FOVCircle.NumSides = 64
    FOVCircle.Thickness = 1
    
    -- Mouse input handling
    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton2 then
            Flags.Holding = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton2 then
            Flags.Holding = false
        end
    end)
    
    -- Aimbot loop
    RunService.RenderStepped:Connect(function()
        -- Update FOV Circle
        FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
        FOVCircle.Visible = Flags.ShowFOV and Flags.AimbotEnabled
        FOVCircle.Radius = CircleRadius
        FOVCircle.Color = CircleColor
        
        -- Aimbot logic
        if Flags.Holding and Flags.AimbotEnabled then
            local target = GetClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild(AimPart) then
                local targetPart = target.Character[AimPart]
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end)
end

------------------------------------------------
-- NO RECOIL SYSTEM
------------------------------------------------
do
    local recoilConnection
    
    local function onRecoil(input, gameProcessedEvent)
        if not Flags.NoRecoil then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            input.UserInputDelta = input.UserInputDelta / 1.3 -- Reduce recoil by 30%
        end
    end
    
    -- Toggle no recoil
    local function updateNoRecoil()
        if recoilConnection then
            recoilConnection:Disconnect()
            recoilConnection = nil
        end
        
        if Flags.NoRecoil then
            recoilConnection = UserInputService.InputChanged:Connect(onRecoil)
        end
    end
    
    Flags.NoRecoilChanged = updateNoRecoil
end

------------------------------------------------
-- ESP SYSTEM (Complete)
------------------------------------------------
do
    -- Cleanup function
    local function ClearESP()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local drawings = Drawings[player]
                if drawings then
                    for _, drawing in pairs(drawings) do
                        if drawing.Remove then
                            drawing:Remove()
                        end
                    end
                    Drawings[player] = nil
                end
            end
        end
    end
    
    -- ESP Update function
    local function UpdateESP()
        if not Flags.ESPEnabled then
            ClearESP()
            return
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            
            local character = player.Character
            if not character then continue end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then continue end
            
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end
            
            -- Check if on screen
            local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if not onScreen then continue end
            
            -- Team check
            if Flags.TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            
            -- Skeleton ESP
            if Flags.SkeletonESP then
                local skeletonParts = {
                    Head = character:FindFirstChild("Head"),
                    UpperTorso = character:FindFirstChild("UpperTorso"),
                    LowerTorso = character:FindFirstChild("LowerTorso"),
                    LeftUpperArm = character:FindFirstChild("LeftUpperArm"),
                    LeftLowerArm = character:FindFirstChild("LeftLowerArm"),
                    RightUpperArm = character:FindFirstChild("RightUpperArm"),
                    RightLowerArm = character:FindFirstChild("RightLowerArm"),
                    LeftUpperLeg = character:FindFirstChild("LeftUpperLeg"),
                    LeftLowerLeg = character:FindFirstChild("LeftLowerLeg"),
                    RightUpperLeg = character:FindFirstChild("RightUpperLeg"),
                    RightLowerLeg = character:FindFirstChild("RightLowerLeg"),
                    HumanoidRootPart = rootPart
                }
                
                -- Initialize drawings if not exists
                if not Drawings[player] then
                    Drawings[player] = {}
                end
                
                -- Draw skeleton connections
                local connections = {
                    {"Head", "UpperTorso"},
                    {"UpperTorso", "LowerTorso"},
                    {"UpperTorso", "LeftUpperArm"},
                    {"LeftUpperArm", "LeftLowerArm"},
                    {"UpperTorso", "RightUpperArm"},
                    {"RightUpperArm", "RightLowerArm"},
                    {"LowerTorso", "LeftUpperLeg"},
                    {"LeftUpperLeg", "LeftLowerLeg"},
                    {"LowerTorso", "RightUpperLeg"},
                    {"RightUpperLeg", "RightLowerLeg"},
                    {"UpperTorso", "HumanoidRootPart"}
                }
                
                for _, connection in pairs(connections) do
                    local part1 = skeletonParts[connection[1]]
                    local part2 = skeletonParts[connection[2]]
                    
                    if part1 and part2 then
                        local fromPos = part1.Position
                        local toPos = part2.Position
                        
                        local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
                        local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)
                        
                        if fromVisible and toVisible then
                            local key = connection[1] .. "_" .. connection[2]
                            local line = Drawings[player][key]
                            
                            if not line then
                                line = Drawing.new("Line")
                                Drawings[player][key] = line
                            end
                            
                            line.From = Vector2.new(fromScreen.X, fromScreen.Y)
                            line.To = Vector2.new(toScreen.X, toScreen.Y)
                            line.Color = isEnemy(player) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                            line.Thickness = 2
                            line.Visible = true
                        else
                            local key = connection[1] .. "_" .. connection[2]
                            local line = Drawings[player][key]
                            if line then
                                line.Visible = false
                            end
                        end
                    end
                end
            else
                -- Hide skeleton drawings
                if Drawings[player] then
                    for key, drawing in pairs(Drawings[player]) do
                        if key:find("_") then -- Skeleton lines have underscores
                            drawing.Visible = false
                        end
                    end
                end
            end
            
            -- Box ESP
            if Flags.BoxESP then
                local size = character:GetExtentsSize()
                local head = character:FindFirstChild("Head")
                local feet = rootPart
                
                if head and feet then
                    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                    local feetPos, feetOnScreen = Camera:WorldToViewportPoint(feet.Position)
                    
                    if headOnScreen and feetOnScreen then
                        local height = feetPos.Y - headPos.Y
                        local width = height / 2
                        
                        -- Create box drawings
                        if not Drawings[player] then Drawings[player] = {} end
                        
                        local corners = {
                            topLeft = Vector2.new(headPos.X - width/2, headPos.Y),
                            topRight = Vector2.new(headPos.X + width/2, headPos.Y),
                            bottomLeft = Vector2.new(headPos.X - width/2, feetPos.Y),
                            bottomRight = Vector2.new(headPos.X + width/2, feetPos.Y)
                        }
                        
                        local boxLines = {
                            {"Top", corners.topLeft, corners.topRight},
                            {"Bottom", corners.bottomLeft, corners.bottomRight},
                            {"Left", corners.topLeft, corners.bottomLeft},
                            {"Right", corners.topRight, corners.bottomRight}
                        }
                        
                        for i, lineData in ipairs(boxLines) do
                            local key = "Box_" .. i
                            local line = Drawings[player][key]
                            
                            if not line then
                                line = Drawing.new("Line")
                                Drawings[player][key] = line
                            end
                            
                            line.From = lineData[2]
                            line.To = lineData[3]
                            line.Color = isEnemy(player) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                            line.Thickness = 2
                            line.Visible = true
                        end
                    end
                end
            else
                -- Hide box drawings
                if Drawings[player] then
                    for key, drawing in pairs(Drawings[player]) do
                        if key:find("Box_") then
                            drawing.Visible = false
                        end
                    end
                end
            end
            
            -- Name ESP
            if Flags.Names then
                local head = character:FindFirstChild("Head")
                if head then
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local key = "Name"
                        local text = Drawings[player] and Drawings[player][key]
                        
                        if not text then
                            text = Drawing.new("Text")
                            if not Drawings[player] then Drawings[player] = {} end
                            Drawings[player][key] = text
                        end
                        
                        text.Text = player.Name
                        text.Position = Vector2.new(headPos.X, headPos.Y - 30)
                        text.Size = 14
                        text.Color = isEnemy(player) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                        text.Visible = true
                    end
                end
            else
                if Drawings[player] and Drawings[player]["Name"] then
                    Drawings[player]["Name"].Visible = false
                end
            end
            
            -- Health ESP
            if Flags.Health then
                local head = character:FindFirstChild("Head")
                if head then
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local key = "Health"
                        local text = Drawings[player] and Drawings[player][key]
                        
                        if not text then
                            text = Drawing.new("Text")
                            if not Drawings[player] then Drawings[player] = {} end
                            Drawings[player][key] = text
                        end
                        
                        local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                        text.Text = tostring(math.floor(humanoid.Health)) .. " (" .. healthPercent .. "%)"
                        text.Position = Vector2.new(headPos.X, headPos.Y - 45)
                        text.Size = 12
                        text.Color = Color3.fromRGB(
                            255 - (255 * (humanoid.Health / humanoid.MaxHealth)),
                            255 * (humanoid.Health / humanoid.MaxHealth),
                            0
                        )
                        text.Visible = true
                    end
                end
            else
                if Drawings[player] and Drawings[player]["Health"] then
                    Drawings[player]["Health"].Visible = false
                end
            end
            
            -- Distance ESP
            if Flags.Distance then
                local head = character:FindFirstChild("Head")
                if head then
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local key = "Distance"
                        local text = Drawings[player] and Drawings[player][key]
                        
                        if not text then
                            text = Drawing.new("Text")
                            if not Drawings[player] then Drawings[player] = {} end
                            Drawings[player][key] = text
                        end
                        
                        local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude)
                        text.Text = tostring(distance) .. " studs"
                        text.Position = Vector2.new(headPos.X, headPos.Y - 60)
                        text.Size = 12
                        text.Color = Color3.fromRGB(200, 200, 200)
                        text.Visible = true
                    end
                end
            else
                if Drawings[player] and Drawings[player]["Distance"] then
                    Drawings[player]["Distance"].Visible = false
                end
            end
            
            -- Tracer ESP
            if Flags.Tracers then
                local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                if onScreen then
                    local key = "Tracer"
                    local line = Drawings[player] and Drawings[player][key]
                    
                    if not line then
                        line = Drawing.new("Line")
                        if not Drawings[player] then Drawings[player] = {} end
                        Drawings[player][key] = line
                    end
                    
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.From = screenCenter
                    line.To = Vector2.new(rootPos.X, rootPos.Y)
                    line.Color = isEnemy(player) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                    line.Thickness = 1
                    line.Visible = true
                end
            else
                if Drawings[player] and Drawings[player]["Tracer"] then
                    Drawings[player]["Tracer"].Visible = false
                end
            end
        end
    end
    
    -- ESP update loop
    RunService.RenderStepped:Connect(UpdateESP)
    
    -- Cleanup when player leaves
    Players.PlayerRemoving:Connect(function(player)
        if player ~= LocalPlayer then
            local drawings = Drawings[player]
            if drawings then
                for _, drawing in pairs(drawings) do
                    if drawing.Remove then
                        drawing:Remove()
                    end
                end
                Drawings[player] = nil
            end
        end
    end)
end

------------------------------------------------
-- HITBOX EXPANDER SYSTEM
------------------------------------------------
do
    local function expandHitboxes(player)
        if not HitboxExpander.Enabled then return end
        
        local character = player.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
        
        -- Check if enemy
        if HitboxExpander.TeamCheck and player.Team == LocalPlayer.Team then
            return
        end
        
        -- Save original sizes if not saved
        if not HitboxExpander.OriginalSizes[player] then
            HitboxExpander.OriginalSizes[player] = {}
        end
        
        for _, partName in pairs(HitboxExpander.ActiveParts) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                -- Save original size
                if not HitboxExpander.OriginalSizes[player][partName] then
                    HitboxExpander.OriginalSizes[player][partName] = {
                        Size = part.Size,
                        Transparency = part.Transparency
                    }
                end
                
                -- Expand hitbox
                part.Size = Vector3.new(HitboxExpander.Size, HitboxExpander.Size, HitboxExpander.Size)
                part.Transparency = HitboxExpander.Transparency
            end
        end
    end
    
    local function restoreHitboxes(player)
        if not HitboxExpander.OriginalSizes[player] then return end
        
        local character = player.Character
        if not character then return end
        
        for partName, originalData in pairs(HitboxExpander.OriginalSizes[player]) do
            local part = character:FindFirstChild(partName)
            if part and part:IsA("BasePart") then
                part.Size = originalData.Size
                part.Transparency = originalData.Transparency
            end
        end
    end
    
    -- Main update loop
    RunService.Heartbeat:Connect(function()
        if not HitboxExpander.Enabled then
            -- Restore all hitboxes when disabled
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    restoreHitboxes(player)
                end
            end
            return
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not (HitboxExpander.TeamCheck and player.Team == LocalPlayer.Team) then
                    expandHitboxes(player)
                else
                    restoreHitboxes(player)
                end
            end
        end
    end)
    
    -- Cleanup when player leaves
    Players.PlayerRemoving:Connect(function(player)
        if HitboxExpander.OriginalSizes[player] then
            HitboxExpander.OriginalSizes[player] = nil
        end
    end)
end

------------------------------------------------
-- UI - COMBAT TAB
------------------------------------------------
do
    local AimbotSection = Tabs.Combat:AddSection("Aimbot")
    
    -- Aimbot Toggle
    Tabs.Combat:AddToggle("AimbotEnabled", {
        Title = "Enable Aimbot",
        Default = false,
        Callback = function(value)
            Flags.AimbotEnabled = value
        end
    })
    
    -- Team Check
    Tabs.Combat:AddToggle("TeamCheck", {
        Title = "Team Check",
        Default = false,
        Callback = function(value)
            Flags.TeamCheck = value
        end
    })
    
    -- Show FOV Circle
    Tabs.Combat:AddToggle("ShowFOV", {
        Title = "Show FOV Circle",
        Default = false,
        Callback = function(value)
            Flags.ShowFOV = value
        end
    })
    
    -- FOV Radius
    Tabs.Combat:AddSlider("FOVRadius", {
        Title = "FOV Radius",
        Description = "Size of aimbot field of view",
        Default = 80,
        Min = 10,
        Max = 500,
        Rounding = 0,
        Callback = function(value)
            CircleRadius = value
        end
    })
    
    -- Aim Part
    Tabs.Combat:AddDropdown("AimPart", {
        Title = "Aim Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Head",
        Callback = function(value)
            AimPart = value
        end
    })
    
    local OtherCombatSection = Tabs.Combat:AddSection("Other Combat")
    
    -- No Recoil
    Tabs.Combat:AddToggle("NoRecoil", {
        Title = "No Recoil",
        Default = false,
        Callback = function(value)
            Flags.NoRecoil = value
            if Flags.NoRecoilChanged then
                Flags.NoRecoilChanged()
            end
        end
    })
    
    local HitboxSection = Tabs.Combat:AddSection("Hitbox Expander")
    
    -- Hitbox Toggle
    Tabs.Combat:AddToggle("HitboxEnabled", {
        Title = "Enable Hitbox Expander",
        Default = false,
        Callback = function(value)
            HitboxExpander.Enabled = value
            if not value then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        restoreHitboxes(player)
                    end
                end
            end
        end
    })
    
    -- Hitbox Size
    Tabs.Combat:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Description = "Size multiplier for hitboxes",
        Default = 10,
        Min = 2,
        Max = 30,
        Rounding = 0,
        Callback = function(value)
            HitboxExpander.Size = value
        end
    })
    
    -- Hitbox Transparency
    Tabs.Combat:AddSlider("HitboxTransparency", {
        Title = "Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            HitboxExpander.Transparency = value
        end
    })
    
    -- Hitbox Team Check
    Tabs.Combat:AddToggle("HitboxTeamCheck", {
        Title = "Team Check",
        Default = false,
        Callback = function(value)
            HitboxExpander.TeamCheck = value
        end
    })
    
    -- Parts selector
    Tabs.Combat:AddDropdown("HitboxParts", {
        Title = "Body Parts",
        Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "All Parts"},
        Default = "HumanoidRootPart",
        Multi = false,
        Callback = function(value)
            if value == "All Parts" then
                HitboxExpander.ActiveParts = {
                    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
                    "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"
                }
            else
                HitboxExpander.ActiveParts = {value}
            end
        end
    })
    
    -- Force Update Button
    Tabs.Combat:AddButton({
        Title = "Force Update Hitboxes",
        Description = "Manually update all hitboxes",
        Callback = function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    restoreHitboxes(player)
                    if HitboxExpander.Enabled and not (HitboxExpander.TeamCheck and player.Team == LocalPlayer.Team) then
                        expandHitboxes(player)
                    end
                end
            end
        end
    })
end

------------------------------------------------
-- UI - VISUAL TAB (ESP & CHAMS)
------------------------------------------------
do
    local ChamsSection = Tabs.Visual:AddSection("Chams")
    
    -- Chams Toggle
    Tabs.Visual:AddToggle("ChamsEnabled", {
        Title = "Enable Chams",
        Default = false,
        Callback = function(value)
            getgenv().chams.enabled = value
        end
    })
    
    -- Chams Team Check
    Tabs.Visual:AddToggle("ChamsTeamCheck", {
        Title = "Chams Team Check",
        Default = false,
        Callback = function(value)
            getgenv().chams.teamCheck = value
        end
    })
    
    -- Chams Fill Color
    Tabs.Visual:AddColorpicker("ChamsFillColor", {
        Title = "Fill Color",
        Description = "Color for visible parts",
        Default = getgenv().chams.fillColor,
        Callback = function(value)
            getgenv().chams.fillColor = value
        end
    })
    
    -- Chams Outline Color
    Tabs.Visual:AddColorpicker("ChamsOutlineColor", {
        Title = "Outline Color",
        Description = "Color for character outline",
        Default = getgenv().chams.outlineColor,
        Callback = function(value)
            getgenv().chams.outlineColor = value
        end
    })
    
    -- Chams Fill Transparency
    Tabs.Visual:AddSlider("ChamsFillTransparency", {
        Title = "Fill Transparency",
        Description = "Transparency of the fill color",
        Default = getgenv().chams.fillTransparency,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            getgenv().chams.fillTransparency = value
        end
    })
    
    local MainESPSection = Tabs.Visual:AddSection("ESP")
    
    -- ESP Master Toggle
    Tabs.Visual:AddToggle("ESPEnabled", {
        Title = "Enable ESP",
        Default = false,
        Callback = function(value)
            Flags.ESPEnabled = value
        end
    })
    
    -- Box ESP
    Tabs.Visual:AddToggle("BoxESP", {
        Title = "Box ESP",
        Default = false,
        Callback = function(value)
            Flags.BoxESP = value
        end
    })
    
    -- Skeleton ESP (Separate checkbox)
    Tabs.Visual:AddToggle("SkeletonESP", {
        Title = "Skeleton ESP",
        Default = false,
        Callback = function(value)
            Flags.SkeletonESP = value
        end
    })
    
    -- Tracers
    Tabs.Visual:AddToggle("Tracers", {
        Title = "Tracers",
        Default = false,
        Callback = function(value)
            Flags.Tracers = value
        end
    })
    
    local InfoESPSection = Tabs.Visual:AddSection("Info ESP")
    
    -- Names
    Tabs.Visual:AddToggle("Names", {
        Title = "Player Names",
        Default = false,
        Callback = function(value)
            Flags.Names = value
        end
    })
    
    -- Health
    Tabs.Visual:AddToggle("Health", {
        Title = "Health Display",
        Default = false,
        Callback = function(value)
            Flags.Health = value
        end
    })
    
    -- Distance
    Tabs.Visual:AddToggle("Distance", {
        Title = "Distance Display",
        Default = false,
        Callback = function(value)
            Flags.Distance = value
        end
    })
end

------------------------------------------------
-- INITIALIZATION
------------------------------------------------
Window:SelectTab(1)

Fluent:Notify({
    Title = "Hypershoot a Ultimate Test Script",
    Content = "Cheat menu loaded successfully!\nAll features available except Kill Aura.",
    Duration = 5
})

print("✅ Hypershoot Ultimate Loaded")
print("🎯 Features: Aimbot, ESP, Chams, NoRecoil, Hitbox Expander")
print("👁️ ESP Options: Box, Skeleton, Names, Health, Distance, Tracers")
print("🕹️ Controls: RMB for Aimbot, LeftControl for Menu")
print("⚠️ Removed: Kill Aura, Fly, Silent Aim, Teleport, WalkSpeed, JumpPower")

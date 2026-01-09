--[[
A Blind shoot script

credits to::

by Marco DEV King

rtUik22 Cheats
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- SETTINGS
local LASER_LENGTH = 50
local LOCK_SPEED = 10
local REVEAL_TIME = 0.25

-- STATES
local espEnabled, laserEnabled, revealOnShoot = true, true, true
local lockOnEnabled, lockedTarget = false, nil

-- STORAGE
local espObjects, laserParts = {}, {}

-- FUNCTIONS
local function createHighlight(player)
    if player == LocalPlayer then return end
    if espObjects[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255,0,0)
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = workspace
    espObjects[player] = highlight
end

local function removeHighlight(player)
    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

local function createLaser(player)
    if player == LocalPlayer then return end
    if laserParts[player] then return end
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(255,0,0)
    part.Size = Vector3.new(0.1,0.1,LASER_LENGTH)
    part.Parent = workspace
    laserParts[player] = part
end

local function removeLaser(player)
    if laserParts[player] then
        laserParts[player]:Destroy()
        laserParts[player] = nil
    end
end

local function getClosestEnemy()
    local closest, shortestDist = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X,screenPos.Y) -
                    Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function revealPlayer(player)
    if not player.Character then return end
    for _, part in pairs(player.Character:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 0
        end
    end
    task.delay(REVEAL_TIME, function()
        if player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
    end)
end

-- SAFE INIT
local function initPlayer(player)
    if player.Character then
        createHighlight(player)
        createLaser(player)
    end
    player.CharacterAdded:Connect(function()
        createHighlight(player)
        createLaser(player)
    end)
    player.CharacterRemoving:Connect(function()
        removeHighlight(player)
        removeLaser(player)
    end)
end

for _, p in pairs(Players:GetPlayers()) do
    initPlayer(p)
end
Players.PlayerAdded:Connect(initPlayer)

-- GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "rtUik22_Cheats_GUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(250,240)
frame.Position = UDim2.fromScale(0.05,0.1)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,15)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,-20,0,35)
title.Position = UDim2.new(0,10,0,5)
title.BackgroundTransparency = 1
title.Text = "rtUik22 Cheats"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Center

local function createToggleButton(text, yPos, stateFunc)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0,200,0,40)
    btn.Position = UDim2.new(0,25,0,yPos)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = text
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

    btn.BackgroundColor3 = stateFunc() and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

    local sound = Instance.new("Sound", btn)
    sound.SoundId = "rbxassetid://12222030"
    sound.Volume = 0.5

    btn.MouseButton1Click:Connect(function()
        sound:Play()
        local newState = not stateFunc()

        if text == "ESP" then
            espEnabled = newState
        elseif text == "Lasers" then
            laserEnabled = newState
        elseif text == "Reveal-On-Shot" then
            revealOnShoot = newState
        elseif text == "Lock-On" then
            lockOnEnabled = newState
            lockedTarget = newState and getClosestEnemy() or nil
        end

        btn.BackgroundColor3 = newState and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)

        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0,210,0,45)
        }):Play()
        task.wait(0.1)
        btn.Size = UDim2.new(0,200,0,40)
    end)
end

createToggleButton("ESP", 50, function() return espEnabled end)
createToggleButton("Lasers", 100, function() return laserEnabled end)
createToggleButton("Reveal-On-Shot", 150, function() return revealOnShoot end)
createToggleButton("Lock-On", 200, function() return lockOnEnabled end)

-- KEYBIND
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.R then
        lockOnEnabled = not lockOnEnabled
        lockedTarget = lockOnEnabled and getClosestEnemy() or nil
    end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function(dt)
    for player, h in pairs(espObjects) do
        if player.Character then
            h.Adornee = espEnabled and player.Character or nil
        end
    end

    for player, laser in pairs(laserParts) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and laserEnabled then
            local startPos = hrp.Position
            local forward = hrp.CFrame.LookVector
            local endPos = startPos + forward * LASER_LENGTH

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist

            local ray = workspace:Raycast(startPos, forward * LASER_LENGTH, rayParams)
            if ray then
                endPos = ray.Position
            end

            local length = (endPos - startPos).Magnitude
            laser.Size = Vector3.new(0.1,0.1,length)
            laser.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0,0,-length/2)
        else
            laser.Size = Vector3.zero
        end
    end

    if lockOnEnabled and lockedTarget and lockedTarget.Character
        and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = lockedTarget.Character.HumanoidRootPart.Position
        Camera.CFrame = Camera.CFrame:Lerp(
            CFrame.new(Camera.CFrame.Position, targetPos),
            dt * LOCK_SPEED
        )
    end
end)

--// RAYFIELD
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// EXECUTOR DETECT
local executor =
    identifyexecutor and identifyexecutor()
    or getexecutorname and getexecutorname()
    or "Unknown"

--// WINDOW
local Window = Rayfield:CreateWindow({
    Name = "Hypershoot | Private Test Panel",
    LoadingTitle = "Hypershoot",
    LoadingSubtitle = "Anti-Cheat Testing Build",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Hypershoot",
        FileName = "PrivatePanel"
    },
    Theme = "Dark"
})

--// TABS
local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualTab = Window:CreateTab("Visual", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local MiscTab   = Window:CreateTab("Misc",   4483362458)

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

--// INFO
CombatTab:CreateParagraph({
    Title = "Account Info",
    Content =
        "User: "..LP.Name..
        "\nUserId: "..LP.UserId..
        "\nExecutor: "..executor
})

--// FLAGS
local Flags = {
    Aimbot = false,
    AimSilent = false,
    Hitbox = false,
    ESP = false,
    KillAura = false,
    InfiniteAmmo = false,
    FastReload = false,
    SpeedShoot = false,
    NoRecoil = false,
    NoCooldown = false
}

------------------------------------------------
-- UTILS
------------------------------------------------
local function isEnemy(char)
    return char
        and char:FindFirstChild("Humanoid")
        and char:GetAttribute("Team") ~= LP.Character:GetAttribute("Team")
end

local function getClosestEnemy()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("Head") then
            if isEnemy(p.Character) then
                local pos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(pos.X,pos.Y) - UIS:GetMouseLocation()).Magnitude
                    if mag < dist and mag < 200 then
                        dist = mag
                        closest = p
                    end
                end
            end
        end
    end
    return closest
end

------------------------------------------------
-- AIMBOT
------------------------------------------------
RunService.RenderStepped:Connect(function()
    if Flags.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getClosestEnemy()
        if t and t.Character then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Character.Head.Position)
        end
    end
end)

------------------------------------------------
-- AIMSILENT
------------------------------------------------
local old
old = hookmetamethod(game, "__index", function(self, key)
    if Flags.AimSilent and self == Mouse and key == "Hit" then
        local t = getClosestEnemy()
        if t and t.Character then
            return t.Character.Head.CFrame
        end
    end
    return old(self, key)
end)

------------------------------------------------
-- HITBOX
------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not Flags.Hitbox then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isEnemy(p.Character) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(8,8,8)
                hrp.Transparency = 0.5
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            end
        end
    end
end)

------------------------------------------------
-- ESP
------------------------------------------------
local ESPCache = {}

local function applyESP(char)
    if ESPCache[char] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255,0,0)
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    ESPCache[char] = hl
end

local function clearESP()
    for _, v in pairs(ESPCache) do
        if v then v:Destroy() end
    end
    ESPCache = {}
end

------------------------------------------------
-- KILL AURA
------------------------------------------------
RunService.Heartbeat:Connect(function()
    if not Flags.KillAura then return end
    local lhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not lhrp then return end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isEnemy(p.Character) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if hrp and hum and (hrp.Position - lhrp.Position).Magnitude < 12 then
                hum.Health = 0
            end
        end
    end
end)

------------------------------------------------
-- AMMO / RECOIL / COOLDOWN
------------------------------------------------
local function applyGC()
    for _, v in next, getgc(true) do
        if typeof(v) == "table" then
            if Flags.InfiniteAmmo and rawget(v,"Ammo") then
                rawset(v,"Ammo", math.huge)
            end
            if Flags.FastReload and rawget(v,"ReloadTime") then
                rawset(v,"ReloadTime", 0.05)
            end
            if Flags.NoRecoil and rawget(v,"Spread") then
                rawset(v,"Spread",0)
                rawset(v,"BaseSpread",0)
            end
            if Flags.NoCooldown and rawget(v,"CD") then
                rawset(v,"CD",0)
            end
        end
    end
end

------------------------------------------------
-- SPEED ON SHOOT
------------------------------------------------
local function hookTool(tool)
    if tool:IsA("Tool") then
        tool.Activated:Connect(function()
            if Flags.SpeedShoot then
                local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
                if hum then
                    hum.WalkSpeed = 40
                    task.delay(0.25,function()
                        hum.WalkSpeed = 16
                    end)
                end
            end
        end)
    end
end

LP.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(hookTool)
end)

------------------------------------------------
-- RENDER LOOP
------------------------------------------------
RunService.RenderStepped:Connect(function()
    if Flags.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and isEnemy(p.Character) then
                applyESP(p.Character)
            end
        end
    else
        clearESP()
    end
    applyGC()
end)

------------------------------------------------
-- RAYFIELD TOGGLES
------------------------------------------------
CombatTab:CreateToggle({Name="Aimbot (RMB)", Callback=function(v) Flags.Aimbot=v end})
CombatTab:CreateToggle({Name="AimSilent", Callback=function(v) Flags.AimSilent=v end})
CombatTab:CreateToggle({Name="Hitbox Expander", Callback=function(v) Flags.Hitbox=v end})
CombatTab:CreateToggle({Name="Kill Aura", Callback=function(v) Flags.KillAura=v end})

VisualTab:CreateToggle({Name="ESP", Callback=function(v) Flags.ESP=v end})

PlayerTab:CreateToggle({Name="Infinite Ammo", Callback=function(v) Flags.InfiniteAmmo=v end})
PlayerTab:CreateToggle({Name="Fast Reload", Callback=function(v) Flags.FastReload=v end})
PlayerTab:CreateToggle({Name="Speed Boost on Shoot", Callback=function(v) Flags.SpeedShoot=v end})
PlayerTab:CreateToggle({Name="No Recoil", Callback=function(v) Flags.NoRecoil=v end})
PlayerTab:CreateToggle({Name="No Ability Cooldown", Callback=function(v) Flags.NoCooldown=v end})

MiscTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end
})

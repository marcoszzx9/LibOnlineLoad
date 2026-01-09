--// Load Fluent safely
local Fluent
do
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(
            "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
        ))()
    end)

    if not ok or not lib then
        warn("Failed to load Fluent UI")
        return
    end

    Fluent = lib
end

--// Addons
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()

local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

--// EXECUTOR
local executor = "Unknown"
if identifyexecutor then
    executor = identifyexecutor() or "Unknown"
elseif getexecutorname then
    executor = getexecutorname() or "Unknown"
end

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

--// FLAGS
local Flags = {
    Aimbot = false,
    AimSilent = false,
    ESP = false,
    Hitbox = false,
    KillAura = false
}

--// Window - CONFIGURAÇÃO SIMPLIFICADA
local Window = Fluent:CreateWindow({
    Title = "Hypershoot | Private",
    SubTitle = "Executor: " .. executor,
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460), -- Tamanho ligeiramente menor
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

print("✓ Janela Fluent criada")

--// Tabs
local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "" }), -- Removido ícone
    Visual = Window:AddTab({ Title = "Visual", Icon = "" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "" })
}

print("✓ Tabs criadas")

------------------------------------------------
-- INFO - MAIS SIMPLES
------------------------------------------------
local infoParagraph = Tabs.Combat:AddParagraph({
    Title = "Account Info",
    Content = "User: " .. LP.Name .. "\nUserId: " .. LP.UserId .. "\nExecutor: " .. executor
})

print("✓ Paragraph adicionado")

------------------------------------------------
-- TESTE SIMPLES PRIMEIRO
------------------------------------------------
local testToggle = Tabs.Combat:AddToggle("TestToggle", {
    Title = "Test Toggle",
    Default = false,
    Callback = function(v)
        print("Test Toggle:", v)
        Fluent:Notify({
            Title = "Toggle",
            Content = "Valor: " .. tostring(v),
            Duration = 2
        })
    end
})

print("✓ Test Toggle adicionado")

local testButton = Tabs.Combat:AddButton({
    Title = "Test Button",
    Description = "Clique para testar",
    Callback = function()
        print("Botão test clicado!")
        Fluent:Notify({
            Title = "Teste",
            Content = "Botão funcionando!",
            Duration = 3
        })
    end
})

print("✓ Test Button adicionado")

------------------------------------------------
-- UTILS
------------------------------------------------
local function isEnemy(char)
    if not LP.Character then return false end
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
                    local mag = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
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
-- BOTÕES REAIS DO CHEAT
------------------------------------------------

-- AIMBOT
local aimbotToggle = Tabs.Combat:AddToggle("AimbotToggle", {
    Title = "Aimbot (RMB)",
    Default = false,
    Callback = function(v)
        Flags.Aimbot = v
        print("Aimbot:", v)
        Fluent:Notify({
            Title = "Aimbot",
            Content = v and "Ativado" or "Desativado",
            Duration = 2
        })
    end
})

print("✓ Aimbot Toggle adicionado")

-- AIM SILENT
local aimSilentToggle = Tabs.Combat:AddToggle("AimSilentToggle", {
    Title = "Aim Silent",
    Default = false,
    Callback = function(v)
        Flags.AimSilent = v
        print("Aim Silent:", v)
    end
})

print("✓ Aim Silent Toggle adicionado")

-- KILL AURA
local killAuraToggle = Tabs.Combat:AddToggle("KillAuraToggle", {
    Title = "Kill Aura",
    Default = false,
    Callback = function(v)
        Flags.KillAura = v
        print("Kill Aura:", v)
    end
})

print("✓ Kill Aura Toggle adicionado")

-- ESP
local espToggle = Tabs.Visual:AddToggle("ESPToggle", {
    Title = "ESP",
    Default = false,
    Callback = function(v)
        Flags.ESP = v
        print("ESP:", v)
        Fluent:Notify({
            Title = "ESP",
            Content = v and "Ativado" or "Desativado",
            Duration = 2
        })
    end
})

print("✓ ESP Toggle adicionado")

-- HITBOX
local hitboxToggle = Tabs.Visual:AddToggle("HitboxToggle", {
    Title = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        Flags.Hitbox = v
        print("Hitbox:", v)
    end
})

print("✓ Hitbox Toggle adicionado")

-- SLIDER DE EXEMPLO
local exampleSlider = Tabs.Misc:AddSlider("ExampleSlider", {
    Title = "Example Slider",
    Description = "Apenas para teste visual",
    Min = 0,
    Max = 100,
    Default = 50,
    Rounding = 0,
    Callback = function(Value)
        print("Slider:", Value)
    end
})

print("✓ Example Slider adicionado")

-- DROPDOWN DE EXEMPLO
local exampleDropdown = Tabs.Misc:AddDropdown("ExampleDropdown", {
    Title = "Example Dropdown",
    Values = {"Option 1", "Option 2", "Option 3"},
    Default = 1,
    Callback = function(Value)
        print("Dropdown:", Value)
        Fluent:Notify({
            Title = "Dropdown",
            Content = "Selecionado: " .. Value,
            Duration = 2
        })
    end
})

print("✓ Example Dropdown adicionado")

------------------------------------------------
-- FUNÇÕES DO CHEAT
------------------------------------------------

-- AIMBOT
RunService.RenderStepped:Connect(function()
    if Flags.Aimbot and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = getClosestEnemy()
        if t and t.Character then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Character.Head.Position)
        end
    end
end)

-- AIMSILENT
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

-- HITBOX
RunService.Heartbeat:Connect(function()
    if not Flags.Hitbox then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isEnemy(p.Character) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(8,8,8)
                hrp.CanCollide = false
                hrp.Transparency = 0.5
            end
        end
    end
end)

-- ESP
local ESPCache = {}

local function clearESP()
    for _, v in pairs(ESPCache) do
        if v then v:Destroy() end
    end
    ESPCache = {}
end

RunService.RenderStepped:Connect(function()
    if not Flags.ESP then
        clearESP()
        return
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and isEnemy(p.Character) then
            if not ESPCache[p.Character] then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = p.Character
                ESPCache[p.Character] = hl
            end
        end
    end
end)

-- KILL AURA
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
-- OPTIONS
------------------------------------------------
local Options = Fluent.Options

------------------------------------------------
-- SETTINGS / SAVE
------------------------------------------------
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
InterfaceManager:SetFolder("HypershootFluent")
SaveManager:SetFolder("HypershootFluent/configs")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Forçar atualização da UI
task.spawn(function()
    task.wait(0.5)
    Window:SelectTab(1)
    
    Fluent:Notify({
        Title = "Hypershoot Loaded",
        Content = "UI carregada com sucesso!",
        Duration = 5
    })
    
    print("✅ Script completamente carregado")
    print("✅ Tabs disponíveis:", #Window.tabs)
    print("✅ Use LeftControl para minimizar")
    
    -- Verificar se os elementos estão visíveis
    for i, tab in pairs(Window.tabs) do
        print("Tab " .. i .. ": " .. tab.data.Title)
        print("  Elementos: " .. (tab.unloaded and "não carregados" or "carregados"))
    end
end)

-- Mostrar notificação inicial
Fluent:Notify({
    Title = "Carregando...",
    Content = "Inicializando Hypershoot",
    Duration = 2
})

print("🎮 Hypershoot Script Iniciado")
print("🎯 Executor: " .. executor)
print("👤 Player: " .. LP.Name)

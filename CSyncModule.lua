-- CSyncModule.lua

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Module
local CSyncModule = {
    Enabled = false,
    Speed = 5,
    Radius = 10,
    Height = 0,
    Mode = "Orbit", -- "Orbit", "Random", "Teleport", "Jitter"
    RandomRange = 15,
    JitterStrength = 3,
    TeleportDistance = 50,
    ShowTrail = false,
    TrailColor = Color3.fromRGB(255, 0, 0),
    DisableCollisions = true,
    HideMesh = false,
    Angle = 0,
    OriginalSubject = nil,
    CameraPart = nil,
    Trail = nil,
    ActiveConnections = {},
    DestroyOnReset = {},
    KeybindEnabled = false, -- État du toggle pour activer/désactiver le keybind
    SelectedKeybind = Enum.KeyCode.C -- Clé par défaut pour activer/désactiver
}

-- Nettoyage des objets précédents
local function cleanupOldObjects()
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "SimpleCSync" or obj.Name == "CSyncTrail" then
            obj:Destroy()
        end
    end
end

-- Création des objets
local function setupObjects()
    cleanupOldObjects()
    
    -- Création du CameraPart
    CSyncModule.CameraPart = Instance.new("Part")
    CSyncModule.CameraPart.Name = "SimpleCSync"
    CSyncModule.CameraPart.Size = Vector3.new(1, 1, 1)
    CSyncModule.CameraPart.CanCollide = false
    CSyncModule.CameraPart.Anchored = true
    CSyncModule.CameraPart.Transparency = 1
    CSyncModule.CameraPart.Parent = workspace
    table.insert(CSyncModule.DestroyOnReset, CSyncModule.CameraPart)
    
    -- Création du trail (optionnel)
    if CSyncModule.ShowTrail then
        local trail = Instance.new("Part")
        trail.Name = "CSyncTrail"
        trail.Size = Vector3.new(0.5, 0.5, 0.5)
        trail.CanCollide = false
        trail.Anchored = true
        trail.Material = Enum.Material.Neon
        trail.Color = CSyncModule.TrailColor
        trail.Transparency = 0.5
        trail.Shape = Enum.PartType.Ball
        trail.Parent = workspace
        CSyncModule.Trail = trail
        table.insert(CSyncModule.DestroyOnReset, trail)
    end
end

-- Gestion des notifications
local function notify(title, message, duration)
    print(title .. ": " .. message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 2
        })
    end)
end

-- Obtenir une position basée sur le mode
local function getModifiedPosition(originalCFrame)
    local newCFrame = originalCFrame
    
    if CSyncModule.Mode == "Orbit" then
        CSyncModule.Angle = CSyncModule.Angle + math.rad(CSyncModule.Speed)
        local x = math.cos(CSyncModule.Angle) * CSyncModule.Radius
        local z = math.sin(CSyncModule.Angle) * CSyncModule.Radius
        newCFrame = originalCFrame * CFrame.new(x, CSyncModule.Height, z)
    
    elseif CSyncModule.Mode == "Random" then
        local randomX = math.random(-CSyncModule.RandomRange, CSyncModule.RandomRange)
        local randomY = math.random(0, CSyncModule.RandomRange/2)
        local randomZ = math.random(-CSyncModule.RandomRange, CSyncModule.RandomRange)
        newCFrame = originalCFrame + Vector3.new(randomX, randomY, randomZ)
    
    elseif CSyncModule.Mode == "Teleport" then
        local direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)).Unit
        newCFrame = originalCFrame + (direction * CSyncModule.TeleportDistance)
    
    elseif CSyncModule.Mode == "Jitter" then
        local jitterX = (math.random() - 0.5) * CSyncModule.JitterStrength * 2
        local jitterY = (math.random() - 0.5) * CSyncModule.JitterStrength
        local jitterZ = (math.random() - 0.5) * CSyncModule.JitterStrength * 2
        newCFrame = originalCFrame * CFrame.new(jitterX, jitterY, jitterZ)
    end
    
    return newCFrame
end

-- Fonction principale du CSync
local function runCSync()
    if not CSyncModule.Enabled then return end
    
    -- Vérifications de sécurité
    if not LocalPlayer or not LocalPlayer.Character then return end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    -- Sauvegarde la position originale
    local originalCFrame = rootPart.CFrame
    
    -- Calcule et applique la nouvelle position
    local fakeCFrame = getModifiedPosition(originalCFrame)
    rootPart.CFrame = fakeCFrame
    
    -- Met à jour le trail si activé
    if CSyncModule.Trail and CSyncModule.ShowTrail then
        CSyncModule.Trail.Position = fakeCFrame.Position
    end
    
    -- Paramètres visuels
    if CSyncModule.HideMesh then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0.8
            end
        end
    end
    
    -- Met à jour la position de la caméra
    CSyncModule.CameraPart.Position = originalCFrame.Position + Vector3.new(0, 2, 0)
    Camera.CameraSubject = CSyncModule.CameraPart
    
    -- Attend un rendu
    RunService.RenderStepped:Wait()
    
    -- Restore la position originale
    rootPart.CFrame = originalCFrame
end

-- Fonction pour désactiver les collisions si nécessaire
local function setupCollisions()
    if not CSyncModule.DisableCollisions then return end
    
    local function disableCollisions(character)
        if not character then return end
        
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    local function onCharacterAdded(character)
        disableCollisions(character)
        character.DescendantAdded:Connect(function(part)
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end)
    end
    
    if LocalPlayer.Character then
        disableCollisions(LocalPlayer.Character)
    end
    
    local charConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    table.insert(CSyncModule.ActiveConnections, charConn)
end

-- Fonction pour activer ou désactiver le CSync
function CSyncModule:ToggleEnabled()
    self.Enabled = not self.Enabled
    
    if self.Enabled then
        setupObjects()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            self.OriginalSubject = Camera.CameraSubject
        end
        notify("CSync", "ACTIVÉ - Mode: " .. self.Mode, 2)
    else
        if self.OriginalSubject then
            Camera.CameraSubject = self.OriginalSubject
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
        
        if self.HideMesh and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
        
        notify("CSync", "DÉSACTIVÉ", 2)
    end
end

-- Fonction pour définir le mode
function CSyncModule:SetMode(mode)
    if table.find({"Orbit", "Random", "Teleport", "Jitter"}, mode) then
        self.Mode = mode
        self.ShowTrail = true -- Activer le trail par défaut lors du changement de mode
        setupObjects() -- Mettre à jour les objets pour refléter le trail
        notify("CSync", "Mode changé à: " .. mode, 2)
    else
        notify("CSync", "Mode invalide: " .. tostring(mode), 2)
    end
end

-- Gestion des touches (keybind)
function CSyncModule:SetupKeyBindings()
    if self.ActiveConnections["Keybind"] then
        self.ActiveConnections["Keybind"]:Disconnect()
    end
    
    local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.SelectedKeybind and self.KeybindEnabled then
            self:ToggleEnabled()
        end
    end)
    
    self.ActiveConnections["Keybind"] = keyConn
end

-- Fonction pour gérer le reset ou la déconnexion
local function setupResetHandler()
    local resetConn = LocalPlayer.CharacterRemoving:Connect(function()
        if CSyncModule.Enabled then
            CSyncModule.Enabled = false
            notify("CSync", "Désactivé temporairement - Personnage reset", 1)
        end
        
        for _, obj in pairs(CSyncModule.DestroyOnReset) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        CSyncModule.DestroyOnReset = {}
    end)
    
    local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if character then
            wait(1)
            setupObjects()
            setupCollisions()
        end
    end)
    
    table.insert(CSyncModule.ActiveConnections, resetConn)
    table.insert(CSyncModule.ActiveConnections, charAddedConn)
end

-- Fonction d'initialisation
function CSyncModule:Initialize()
    for _, conn in pairs(self.ActiveConnections) do
        conn:Disconnect()
    end
    self.ActiveConnections = {}
    
    setupObjects()
    setupCollisions()
    self:SetupKeyBindings()
    setupResetHandler()
    
    local mainConn = RunService.Heartbeat:Connect(runCSync)
    self.ActiveConnections["Main"] = mainConn
    
    notify("CSync", "Module initialisé!", 3)
end

-- Fonction pour définir l'état du toggle de keybind
function CSyncModule:SetKeybindEnabled(value)
    self.KeybindEnabled = value
    notify("CSync", "Keybind " .. (value and "activé" or "désactivé"), 2)
end

-- Fonction pour définir une nouvelle touche pour le keybind
function CSyncModule:SetKeybind(keyCode)
    self.SelectedKeybind = keyCode
    self:SetupKeyBindings()
    notify("CSync", "Keybind défini à: " .. tostring(keyCode), 2)
end

-- Fonction pour nettoyer le module
function CSyncModule:Cleanup()
    self.Enabled = false
    if self.OriginalSubject then
        Camera.CameraSubject = self.OriginalSubject
    end
    if self.HideMesh and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
    for _, obj in pairs(self.DestroyOnReset) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    for _, conn in pairs(self.ActiveConnections) do
        conn:Disconnect()
    end
    self.ActiveConnections = {}
    self.DestroyOnReset = {}
end

getgenv().CSyncModule = CSyncModule
return CSyncModule

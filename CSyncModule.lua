-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration avancée
local Config = {
    -- Paramètres de base
    Enabled = false,
    Speed = 5,
    Radius = 10,
    Height = 0,
    
    -- Modes disponibles
    Mode = "Orbit", -- "Orbit", "Random", "Teleport", "Jitter"
    
    -- Paramètres avancés
    RandomRange = 15,
    JitterStrength = 3,
    TeleportDistance = 50,
    
    -- Visuel
    ShowTrail = false,
    TrailColor = Color3.fromRGB(255, 0, 0),
    
    -- Anti-détection
    DisableCollisions = true,
    HideMesh = false
}

-- Variables
local Angle = 0
local OriginalSubject = nil
local CameraPart = nil
local Trail = nil
local ActiveConnections = {}
local DestroyOnReset = {}
local KeybindEnabled = false
local ToggleKey = Enum.KeyCode.C -- Touche par défaut

-- Nettoyage des objets précédents
local function cleanupOldObjects()
    for i, obj in pairs(workspace:GetChildren()) do
        if obj.Name == "SimpleCSync" or obj.Name == "CSyncTrail" then
            obj:Destroy()
        end
    end
end

-- Création des objets
local function setupObjects()
    cleanupOldObjects()
    
    -- Création du CameraPart
    CameraPart = Instance.new("Part")
    CameraPart.Name = "SimpleCSync"
    CameraPart.Size = Vector3.new(1, 1, 1)
    CameraPart.CanCollide = false
    CameraPart.Anchored = true
    CameraPart.Transparency = 1
    CameraPart.Parent = workspace
    table.insert(DestroyOnReset, CameraPart)
    
    -- Création du trail (optionnel)
    if Config.ShowTrail then
        local trail = Instance.new("Part")
        trail.Name = "CSyncTrail"
        trail.Size = Vector3.new(0.5, 0.5, 0.5)
        trail.CanCollide = false
        trail.Anchored = true
        trail.Material = Enum.Material.Neon
        trail.Color = Config.TrailColor
        trail.Transparency = 0.5
        trail.Shape = Enum.PartType.Ball
        trail.Parent = workspace
        Trail = trail
        table.insert(DestroyOnReset, Trail)
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
    
    if Config.Mode == "Orbit" then
        Angle = Angle + math.rad(Config.Speed)
        local x = math.cos(Angle) * Config.Radius
        local z = math.sin(Angle) * Config.Radius
        newCFrame = originalCFrame * CFrame.new(x, Config.Height, z)
    
    elseif Config.Mode == "Random" then
        local randomX = math.random(-Config.RandomRange, Config.RandomRange)
        local randomY = math.random(0, Config.RandomRange/2)
        local randomZ = math.random(-Config.RandomRange, Config.RandomRange)
        newCFrame = originalCFrame + Vector3.new(randomX, randomY, randomZ)
    
    elseif Config.Mode == "Teleport" then
        local direction = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)).Unit
        newCFrame = originalCFrame + (direction * Config.TeleportDistance)
    
    elseif Config.Mode == "Jitter" then
        local jitterX = (math.random() - 0.5) * Config.JitterStrength * 2
        local jitterY = (math.random() - 0.5) * Config.JitterStrength
        local jitterZ = (math.random() - 0.5) * Config.JitterStrength * 2
        newCFrame = originalCFrame * CFrame.new(jitterX, jitterY, jitterZ)
    end
    
    return newCFrame
end

-- Fonction du CSync
local function runCSync()
    if not Config.Enabled then return end
    
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
    if Trail and Config.ShowTrail then
        Trail.Position = fakeCFrame.Position
    end
    
    -- Paramètres visuels
    if Config.HideMesh then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.LocalTransparencyModifier = 0.8
            end
        end
    end
    
    -- Met à jour la position de la caméra
    CameraPart.Position = originalCFrame.Position + Vector3.new(0, 2, 0)
    Camera.CameraSubject = CameraPart
    
    -- Attend un rendu
    RunService.RenderStepped:Wait()
    
    -- Restore la position originale
    rootPart.CFrame = originalCFrame
end

-- Fonction pour désactiver les collisions si nécessaire
local function setupCollisions()
    if not Config.DisableCollisions then return end
    
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
    
    -- Connection pour les futurs caractères
    local charConn = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    table.insert(ActiveConnections, charConn)
end

-- Fonction pour activer ou désactiver le CSync
local function toggleCSync()
    Config.Enabled = not Config.Enabled
    
    if Config.Enabled then
        -- Réinitialise et crée les objets nécessaires
        setupObjects()
        
        -- Enregistre le sujet de caméra original
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            OriginalSubject = Camera.CameraSubject
        end
        
        notify("CSync", "ACTIVÉ - Mode: " .. Config.Mode, 2)
    else
        -- Restaure la caméra
        if OriginalSubject then
            Camera.CameraSubject = OriginalSubject
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
        
        -- Restaure les propriétés visuelles
        if Config.HideMesh and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0
                end
            end
        end
        
        notify("CSync", "DÉSACTIVÉ", 2)
    end
end

-- Fonction pour changer le mode
local function setMode(mode)
    Config.Mode = mode
    notify("CSync", "Mode changé à: " .. Config.Mode, 2)
end

-- Fonction pour activer/désactiver les keybinds
local function setKeybindEnabled(enabled)
    KeybindEnabled = enabled
    if enabled then
        notify("CSync", "Keybinds activés", 1)
    else
        notify("CSync", "Keybinds désactivés", 1)
    end
end

-- Fonction pour définir la touche de toggle
local function setKeybind(keyCode)
    ToggleKey = keyCode
    notify("CSync", "Touche de toggle définie sur: " .. keyCode.Name, 1) -- Correction ici
end

-- Gestion des touches
local function setupKeyBindings()
    local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not KeybindEnabled then return end
        
        if input.KeyCode == ToggleKey then
            toggleCSync()
        elseif input.KeyCode == Enum.KeyCode.V then
            local modes = {"Orbit", "Random", "Teleport", "Jitter"}
            local currentIndex = table.find(modes, Config.Mode) or 1
            currentIndex = (currentIndex % #modes) + 1
            Config.Mode = modes[currentIndex]
            notify("CSync", "Mode changé à: " .. Config.Mode, 2)
        elseif input.KeyCode == Enum.KeyCode.B then
            Config.ShowTrail = not Config.ShowTrail
            notify("CSync", "Trail " .. (Config.ShowTrail and "activé" or "désactivé"), 1)
            setupObjects()
        end
    end)
    
    table.insert(ActiveConnections, keyConn)
end

-- Gérer le reset ou la déconnexion
local function setupResetHandler()
    local resetConn = LocalPlayer.CharacterRemoving:Connect(function()
        -- Désactiver temporairement
        if Config.Enabled then
            Config.Enabled = false
            notify("CSync", "Désactivé temporairement - Personnage reset", 1)
        end
        
        -- Nettoyer les objets
        for _, obj in pairs(DestroyOnReset) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
        DestroyOnReset = {}
    end)
    
    local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if character then
            wait(1) -- Attendre que le personnage soit complètement chargé
            setupObjects()
            setupCollisions()
        end
    end)
    
    table.insert(ActiveConnections, resetConn)
    table.insert(ActiveConnections, charAddedConn)
end

-- Fonction principale
local function initialize()
    -- Nettoyage des anciennes connexions
    for _, conn in pairs(ActiveConnections) do
        conn:Disconnect()
    end
    ActiveConnections = {}
    
    -- Configuration initiale
    setupCollisions()
    setupKeyBindings()
    setupResetHandler()
    
    -- Connexion principale
    local mainConn = RunService.Heartbeat:Connect(runCSync)
    table.insert(ActiveConnections, mainConn)
    
    -- Message d'initialisation
    notify("CSync", "Initialisé! Utilisez l'UI pour configurer.", 3)
end

-- Interface pour l'UI
return {
    Initialize = initialize,
    SetMode = setMode,
    SetKeybindEnabled = setKeybindEnabled,
    SetKeybind = setKeybind,
    ToggleCSync = toggleCSync
}

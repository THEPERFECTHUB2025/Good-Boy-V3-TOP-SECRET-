-- ForceHitModule.lua

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Pour les animations
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- Variables
local ForceHitModule = {
    Enabled = false, -- État effectif (peut être modifié par la logique des HP, de la distance ou du wall check)
    ManuallyEnabled = false, -- État défini par l'utilisateur via le keybind ou l'UI
    AutoTargetAll = false, -- Option pour cibler automatiquement une nouvelle personne
    UIMobileSupportEnabled = false, -- Option pour activer le bouton draggable dans l'UI
    WallCheckEnabled = true, -- Option pour activer/désactiver le Wall Check
    KillAllEnabled = false, -- Option pour Kill All
    AutoStompEnabled = false, -- Option pour Auto Stomp
    TargetStrafeEnabled = false, -- Option pour Target Strafe
    BlankShots = true,
    HitPart = "Head",
    SelectedTarget = nil, -- Partie ciblée (HitPart)
    TargetPlayer = nil, -- Joueur ciblé (pour persistance après respawn)
    Connections = {}, -- Stockage des connexions pour nettoyage
    ForceHitButton = nil, -- Référence au bouton draggable dans l'UI
    ButtonPosition = UDim2.new(0.5, -50, 0.5, -25), -- Position initiale du bouton (sauvegardée)
    LastKillAllTime = 0, -- Dernière fois que Kill All a été exécuté
    StrafeAngle = 0, -- Angle actuel pour le Target Strafe
    Tracer = nil, -- Référence au Beam (Tracer)
    Attachment0 = nil, -- Attachment pour le joueur local
    Attachment1 = nil, -- Attachment pour la cible
    TargetInfoUI = nil, -- Référence à l'UI d'informations sur la cible
    HitSound = nil -- Référence au son de hit
}

-- Highlight pour la cible
local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

-- Création du son pour le hit
local hitSound = Instance.new("Sound")
hitSound.SoundId = "rbxassetid://110168723447153" -- ID du son fourni
hitSound.Volume = 1
hitSound.Parent = LocalPlayer
ForceHitModule.HitSound = hitSound

-- Liste des armes possibles
local WEAPON_LIST = {
    "[DoubleBarrel]",
    "[Revolver]",
    "[SMG]",
    "[Shotgun]",
    "[Silencer]",
    "[TacticalShotgun]"
}

-- Créer l'UI pour le bouton draggable
local function CreateForceHitButton()
    -- Créer un ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForceHitUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false -- Persiste après un respawn/reset

    -- Créer un Frame pour le bouton (draggable)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 60) -- Légèrement plus grand pour une meilleure visibilité
    frame.Position = ForceHitModule.ButtonPosition -- Utiliser la position sauvegardée
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255) -- Ajouter une bordure blanche
    frame.Active = true -- Permet de rendre le Frame draggable
    frame.Draggable = true -- Permet de déplacer le Frame (solution principale)
    frame.Parent = screenGui

    -- Ajouter un coin arrondi au Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    -- Ajouter une ombre au Frame
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Transparency = 0.5
    stroke.Parent = frame

    -- Créer un TextButton à l'intérieur du Frame
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = "ForceHit: OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Parent = frame

    -- Mettre à jour le texte et la couleur du bouton en fonction de l'état de ForceHit
    local function UpdateButtonText()
        button.Text = "ForceHit: " .. (ForceHitModule.ManuallyEnabled and "ON" or "OFF")
        frame.BackgroundColor3 = ForceHitModule.ManuallyEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
    end

    -- Connecter l'événement de clic sur le bouton
    button.MouseButton1Click:Connect(function()
        if not getgenv().Rake.Settings.Misc.ForceHitEnabled then
            -- sendNotification("ForceHit", "Toggle must be enabled to use this button", 2)
            return
        end

        local newValue = ForceHitModule:Toggle()
        UpdateButtonText()
        if newValue then
            -- sendNotification("ForceHit", "Enabled", 2)
        else
            -- sendNotification("ForceHit", "Disabled", 2)
        end
    end)

    -- Logique de drag manuelle avec UserInputService (solution de secours)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                local newPos = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
                frame.Position = newPos
            end
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            -- Sauvegarder la nouvelle position
            ForceHitModule.ButtonPosition = frame.Position
        end
    end)

    -- Mettre à jour le texte initial
    UpdateButtonText()

    ForceHitModule.ForceHitButton = screenGui
end

-- Créer l'UI pour les informations sur la cible (design futuriste encore plus amélioré)
local function CreateTargetInfoUI()
    -- Créer un ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TargetInfoUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false -- Persiste après un respawn/reset

    -- Créer un Frame principal (style futuriste)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 180) -- Augmenté pour accueillir le nouveau label
    -- Position sera définie dynamiquement dans UpdateTargetInfoUI
    frame.BackgroundColor3 = Color3.fromRGB(5, 5, 15) -- Fond très sombre
    frame.BackgroundTransparency = 0.5 -- Semi-transparent (effet de verre)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    -- Ajouter un coin arrondi au Frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Ajouter un gradient de fond vibrant avec des couleurs changeantes
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 50, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 150))
    })
    gradient.Rotation = 45
    gradient.Parent = frame

    -- Animation de rotation du gradient pour un effet dynamique
    local function rotateGradient()
        while true do
            local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(gradient, tweenInfo, {Rotation = gradient.Rotation + 360})
            tween:Play()
            tween.Completed:Wait()
        end
    end
    spawn(rotateGradient)

    -- Ajouter une bordure néon avec scintillement et gradient
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.fromRGB(0, 255, 255) -- Cyan néon
    stroke.Transparency = 0
    stroke.Parent = frame

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255))
    })
    strokeGradient.Rotation = 0
    strokeGradient.Parent = stroke

    -- Animation de rotation du gradient de la bordure
    local function rotateStrokeGradient()
        while true do
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(strokeGradient, tweenInfo, {Rotation = strokeGradient.Rotation + 360})
            tween:Play()
            tween.Completed:Wait()
        end
    end
    spawn(rotateStrokeGradient)

    -- Animation de scintillement pour la bordure
    local function flickerBorder()
        while true do
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween1 = TweenService:Create(stroke, tweenInfo, {Transparency = 0.2})
            local tween2 = TweenService:Create(stroke, tweenInfo, {Transparency = 0})
            tween1:Play()
            tween1.Completed:Wait()
            tween2:Play()
            tween2.Completed:Wait()
            wait(0.4)
        end
    end
    spawn(flickerBorder)

    -- Ajouter un effet de glow
    local shadow = Instance.new("UIStroke")
    shadow.Thickness = 8
    shadow.Color = Color3.fromRGB(0, 255, 255)
    shadow.Transparency = 0.3
    shadow.Parent = frame

    -- Ajouter un effet d'hologramme (variation de transparence)
    local function hologramEffect()
        while true do
            local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween1 = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0.6})
            local tween2 = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 0.4})
            tween1:Play()
            tween1.Completed:Wait()
            tween2:Play()
            tween2.Completed:Wait()
        end
    end
    spawn(hologramEffect)

    -- Ajouter des particules subtiles (effet de "poussière" futuriste)
    local particleFrame = Instance.new("Frame")
    particleFrame.Size = UDim2.new(1, 0, 1, 0)
    particleFrame.BackgroundTransparency = 1
    particleFrame.Parent = frame

    local function createParticle()
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 4, 0, 4)
        particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        particle.BackgroundTransparency = 0.4
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.Parent = particleFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle

        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(particle, tweenInfo, {
            Position = UDim2.new(math.random(), 0, math.random(), 0),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            particle:Destroy()
        end)
    end

    local function spawnParticles()
        while true do
            createParticle()
            wait(0.15)
        end
    end
    spawn(spawnParticles)

    -- Ajouter un effet de "vague" (lignes horizontales qui se déplacent)
    local waveFrame = Instance.new("Frame")
    waveFrame.Size = UDim2.new(1, 0, 1, 0)
    waveFrame.BackgroundTransparency = 1
    waveFrame.Parent = frame

    local function createWave()
        local wave = Instance.new("Frame")
        wave.Size = UDim2.new(1, 0, 0, 1)
        wave.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        wave.BackgroundTransparency = 0.7
        wave.Position = UDim2.new(0, 0, 0, 0)
        wave.Parent = waveFrame

        local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(wave, tweenInfo, {
            Position = UDim2.new(0, 0, 1, 0),
            BackgroundTransparency = 0.9
        })
        tween:Play()
        tween.Completed:Connect(function()
            wave:Destroy()
        end)
    end

    local function spawnWaves()
        while true do
            createWave()
            wait(0.8)
        end
    end
    spawn(spawnWaves)

    -- Ajouter un effet de "scan radial" (cercles qui s'étendent depuis l'icône)
    local radialFrame = Instance.new("Frame")
    radialFrame.Size = UDim2.new(1, 0, 1, 0)
    radialFrame.BackgroundTransparency = 1
    radialFrame.Parent = frame

    local function createRadialScan()
        local radial = Instance.new("Frame")
        radial.Size = UDim2.new(0, 0, 0, 0)
        radial.Position = UDim2.new(0, 22, 0, 72) -- Centré sur l'icône
        radial.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        radial.BackgroundTransparency = 0.5
        radial.Parent = radialFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = radial

        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(radial, tweenInfo, {
            Size = UDim2.new(0, 100, 0, 100),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            radial:Destroy()
        end)
    end

    local function spawnRadialScans()
        while true do
            createRadialScan()
            wait(2)
        end
    end
    spawn(spawnRadialScans)

    -- Ajouter un effet de "connexion" (remplacé par des particules sous forme de points)
    local connectionFrame = Instance.new("Frame")
    connectionFrame.Size = UDim2.new(1, 0, 1, 0)
    connectionFrame.BackgroundTransparency = 1
    connectionFrame.Parent = frame

    local function createConnectionParticle()
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 3, 0, 3) -- Petits points
        particle.Position = UDim2.new(0, 35, 0, 75) -- Part de l'icône
        particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        particle.BackgroundTransparency = 0.5
        particle.Parent = connectionFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0) -- Cercle
        corner.Parent = particle

        local angle = math.random() * 2 * math.pi
        local endX = 35 + math.cos(angle) * 150
        local endY = 75 + math.sin(angle) * 150

        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(particle, tweenInfo, {
            Position = UDim2.new(0, endX, 0, endY),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            particle:Destroy()
        end)
    end

    local function spawnConnectionParticles()
        while true do
            createConnectionParticle()
            wait(0.3) -- Plus fréquent pour un effet plus fluide
        end
    end
    spawn(spawnConnectionParticles)

    -- Ajouter un effet de distorsion holographique (1a)
    local glitchFrame = Instance.new("Frame")
    glitchFrame.Size = UDim2.new(1, 0, 1, 0)
    glitchFrame.BackgroundTransparency = 1
    glitchFrame.Parent = frame

    local function createGlitchLine()
        local glitchLine = Instance.new("Frame")
        glitchLine.Size = UDim2.new(1, 0, 0, 2)
        glitchLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        glitchLine.BackgroundTransparency = 0.7
        glitchLine.Position = UDim2.new(0, 0, math.random(), 0)
        glitchLine.Parent = glitchFrame

        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(glitchLine, tweenInfo, {BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Connect(function()
            glitchLine:Destroy()
        end)
    end

    local function spawnGlitchLines()
        while true do
            createGlitchLine()
            wait(math.random(1, 3)) -- Apparition sporadique
        end
    end
    spawn(spawnGlitchLines)

    -- Ajouter un effet de tremblement holographique
    local function shakeEffect()
        while true do
            local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            local offsetX = math.random(-2, 2)
            local offsetY = math.random(-2, 2)
            local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0, 10 + offsetX, 0, 10 + offsetY)})
            tween:Play()
            wait(math.random(2, 4)) -- Tremblement toutes les 2-4 secondes
        end
    end
    spawn(shakeEffect)

    -- Ajouter un titre "Indicator"
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Indicator"
    titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cyan néon
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SciFi -- Police futuriste
    titleLabel.Parent = frame

    -- Ajouter un effet de glitch sur le titre
    local function glitchEffect()
        while true do
            titleLabel.TextTransparency = 0.2
            titleLabel.Position = UDim2.new(0, math.random(-2, 2), 0, 0)
            wait(0.05)
            titleLabel.TextTransparency = 0
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
            wait(0.05)
            titleLabel.TextTransparency = 0.3
            titleLabel.Position = UDim2.new(0, math.random(-2, 2), 0, 0)
            wait(0.05)
            titleLabel.TextTransparency = 0
            titleLabel.Position = UDim2.new(0, 0, 0, 0)
            wait(math.random(1, 3))
        end
    end
    spawn(glitchEffect)

    -- Ajouter un label "INFO"
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 20)
    infoLabel.Position = UDim2.new(0, 0, 0, 30)
    infoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    infoLabel.BackgroundTransparency = 0.5
    infoLabel.Text = "INFO"
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.Code -- Police moderne
    infoLabel.Parent = frame

    -- Ajouter une ligne de scan
    local scanLine = Instance.new("Frame")
    scanLine.Size = UDim2.new(1, 0, 0, 2)
    scanLine.Position = UDim2.new(0, 0, 0, 30)
    scanLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    scanLine.BackgroundTransparency = 0.5
    scanLine.Parent = frame

    -- Animation de la ligne de scan
    local function animateScanLine()
        while true do
            scanLine.Position = UDim2.new(0, 0, 0, 30)
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(scanLine, tweenInfo, {Position = UDim2.new(0, 0, 1, -2)})
            tween:Play()
            tween.Completed:Wait()
            wait(0.8)
        end
    end
    spawn(animateScanLine)

    -- Ajouter une icône (ImageLabel) avec un cadre circulaire
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, 10, 0, 50)
    iconFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    iconFrame.BackgroundTransparency = 0.6
    iconFrame.Parent = frame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0) -- Cercle
    iconCorner.Parent = iconFrame

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 46, 0, 46)
    icon.Position = UDim2.new(0, 2, 0, 2)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png" -- Placeholder, sera mis à jour avec l'avatar
    icon.Parent = iconFrame

    local iconInnerCorner = Instance.new("UICorner")
    iconInnerCorner.CornerRadius = UDim.new(1, 0) -- Cercle
    iconInnerCorner.Parent = icon

    -- Ajouter un effet de pulsation sur l'icône
    local function pulseIcon()
        while true do
            local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween1 = TweenService:Create(iconFrame, tweenInfo, {BackgroundTransparency = 0.8})
            local tween2 = TweenService:Create(iconFrame, tweenInfo, {BackgroundTransparency = 0.6})
            tween1:Play()
            tween1.Completed:Wait()
            tween2:Play()
            tween2.Completed:Wait()
        end
    end
    spawn(pulseIcon)

    -- Ajouter un label pour le nom de la cible
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 220, 0, 25)
    nameLabel.Position = UDim2.new(0, 70, 0, 50)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "No Target"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.Code
    nameLabel.Parent = frame

    -- Ajouter un effet de glitch sur le nom
    local function glitchNameEffect()
        while true do
            nameLabel.TextTransparency = 0.2
            nameLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 50)
            wait(0.05)
            nameLabel.TextTransparency = 0
            nameLabel.Position = UDim2.new(0, 70, 0, 50)
            wait(0.05)
            nameLabel.TextTransparency = 0.3
            nameLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 50)
            wait(0.05)
            nameLabel.TextTransparency = 0
            nameLabel.Position = UDim2.new(0, 70, 0, 50)
            wait(math.random(2, 4))
        end
    end
    spawn(glitchNameEffect)

    -- Ajouter un label pour la santé
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(0, 110, 0, 25)
    healthLabel.Position = UDim2.new(0, 70, 0, 75)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "0/0"
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextScaled = true
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthLabel.Font = Enum.Font.Code
    healthLabel.Parent = frame

    -- Ajouter un effet de glitch sur la santé
    local function glitchHealthEffect()
        while true do
            healthLabel.TextTransparency = 0.2
            healthLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 75)
            wait(0.05)
            healthLabel.TextTransparency = 0
            healthLabel.Position = UDim2.new(0, 70, 0, 75)
            wait(0.05)
            healthLabel.TextTransparency = 0.3
            healthLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 75)
            wait(0.05)
            healthLabel.TextTransparency = 0
            healthLabel.Position = UDim2.new(0, 70, 0, 75)
            wait(math.random(2, 4))
        end
    end
    spawn(glitchHealthEffect)

    -- Ajouter un label pour la distance
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(0, 100, 0, 25)
    distanceLabel.Position = UDim2.new(0, 190, 0, 75)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0 studs"
    distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    distanceLabel.TextScaled = true
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Font = Enum.Font.Code
    distanceLabel.Parent = frame

    -- Ajouter un effet de glitch sur la distance
    local function glitchDistanceEffect()
        while true do
            distanceLabel.TextTransparency = 0.2
            distanceLabel.Position = UDim2.new(0, 190 + math.random(-1, 1), 0, 75)
            wait(0.05)
            distanceLabel.TextTransparency = 0
            distanceLabel.Position = UDim2.new(0, 190, 0, 75)
            wait(0.05)
            distanceLabel.TextTransparency = 0.3
            distanceLabel.Position = UDim2.new(0, 190 + math.random(-1, 1), 0, 75)
            wait(0.05)
            distanceLabel.TextTransparency = 0
            distanceLabel.Position = UDim2.new(0, 190, 0, 75)
            wait(math.random(2, 4))
        end
    end
    spawn(glitchDistanceEffect)

    -- Ajouter un label pour l'arme équipée
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(0, 220, 0, 30)
    weaponLabel.Position = UDim2.new(0, 70, 0, 110)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = "nil"
    weaponLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange pour se démarquer
    weaponLabel.TextScaled = true
    weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
    weaponLabel.Font = Enum.Font.Code
    weaponLabel.Parent = frame

    -- Ajouter un effet de glitch sur l'arme
    local function glitchWeaponEffect()
        while true do
            weaponLabel.TextTransparency = 0.2
            weaponLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 110)
            wait(0.05)
            weaponLabel.TextTransparency = 0
            weaponLabel.Position = UDim2.new(0, 70, 0, 110)
            wait(0.05)
            weaponLabel.TextTransparency = 0.3
            weaponLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 110)
            wait(0.05)
            weaponLabel.TextTransparency = 0
            weaponLabel.Position = UDim2.new(0, 70, 0, 110)
            wait(math.random(2, 4))
        end
    end
    spawn(glitchWeaponEffect)

    -- Stocker les références pour mise à jour
    ForceHitModule.TargetInfoUI = {
        ScreenGui = screenGui,
        Frame = frame,
        Icon = icon,
        NameLabel = nameLabel,
        HealthLabel = healthLabel,
        DistanceLabel = distanceLabel,
        WeaponLabel = weaponLabel -- Ajout de la référence au label de l'arme
    }

    -- Cacher l'UI par défaut
    frame.Visible = false
end

-- Mettre à jour l'UI des informations sur la cible
local function UpdateTargetInfoUI()
    if not ForceHitModule.TargetInfoUI then
        CreateTargetInfoUI()
    end

    local ui = ForceHitModule.TargetInfoUI

    -- Positionner l'UI juste en dessous de la barre de HP
    local hpFrame = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Main Screen") and
                    game:GetService("Players").LocalPlayer.PlayerGui["Main Screen"]:FindFirstChild("Bar") and
                    game:GetService("Players").LocalPlayer.PlayerGui["Main Screen"].Bar:FindFirstChild("HP")
    if hpFrame then
        local hpAbsolutePosition = hpFrame.AbsolutePosition
        local hpAbsoluteSize = hpFrame.AbsoluteSize
        -- Positionner l'UI juste en dessous de la barre de HP
        ui.Frame.Position = UDim2.new(
            0, hpAbsolutePosition.X,
            0, hpAbsolutePosition.Y + hpAbsoluteSize.Y + 10 -- 10 pixels de marge en dessous
        )
    end

    if not ForceHitModule.ManuallyEnabled or not ForceHitModule.TargetPlayer then
        if ui.Frame.Visible then
            -- Animation de disparition spectaculaire (5b)
            ui.Frame.Visible = true
            local particleFrame = Instance.new("Frame")
            particleFrame.Size = UDim2.new(1, 0, 1, 0)
            particleFrame.BackgroundTransparency = 1
            particleFrame.Parent = ui.Frame

            local function createExplosionParticle()
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, 5, 0, 5)
                particle.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centre de l'UI
                particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
                particle.BackgroundTransparency = 0.3
                particle.Parent = particleFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = particle

                local angle = math.random() * 2 * math.pi
                local endX = math.cos(angle) * 200
                local endY = math.sin(angle) * 200

                local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(particle, tweenInfo, {
                    Position = UDim2.new(0.5, endX, 0.5, endY),
                    BackgroundTransparency = 1
                })
                tween:Play()
                tween.Completed:Connect(function()
                    particle:Destroy()
                end)
            end

            for i = 1, 20 do
                createExplosionParticle()
            end

            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(ui.Frame, tweenInfo, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                ui.Frame.Visible = false
                ui.Frame.BackgroundTransparency = 0.5
                ui.Frame.Size = UDim2.new(0, 300, 0, 180)
                particleFrame:Destroy()
            end)
        end
        return
    end

    local targetPlayer = ForceHitModule.TargetPlayer
    local character = targetPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local targetRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    if not humanoid or not targetRootPart or not localRootPart then
        if ui.Frame.Visible then
            -- Animation de disparition spectaculaire (5b)
            ui.Frame.Visible = true
            local particleFrame = Instance.new("Frame")
            particleFrame.Size = UDim2.new(1, 0, 1, 0)
            particleFrame.BackgroundTransparency = 1
            particleFrame.Parent = ui.Frame

            local function createExplosionParticle()
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, 5, 0, 5)
                particle.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centre de l'UI
                particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
                particle.BackgroundTransparency = 0.3
                particle.Parent = particleFrame

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = particle

                local angle = math.random() * 2 * math.pi
                local endX = math.cos(angle) * 200
                local endY = math.sin(angle) * 200

                local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(particle, tweenInfo, {
                    Position = UDim2.new(0.5, endX, 0.5, endY),
                    BackgroundTransparency = 1
                })
                tween:Play()
                tween.Completed:Connect(function()
                    particle:Destroy()
                end)
            end

            for i = 1, 20 do
                createExplosionParticle()
            end

            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local tween = TweenService:Create(ui.Frame, tweenInfo, {BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0)})
            tween:Play()
            tween.Completed:Connect(function()
                ui.Frame.Visible = false
                ui.Frame.BackgroundTransparency = 0.5
                ui.Frame.Size = UDim2.new(0, 300, 0, 180)
                particleFrame:Destroy()
            end)
        end
        return
    end

    -- Mettre à jour l'icône avec l'avatar du joueur
    local userId = targetPlayer.UserId
    ui.Icon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=48&h=48"

    -- Mettre à jour le nom
    ui.NameLabel.Text = targetPlayer.Name .. " (@" .. targetPlayer.DisplayName .. ")"

    -- Mettre à jour la santé
    local health = math.floor(humanoid.Health)
    local maxHealth = math.floor(humanoid.MaxHealth)
    ui.HealthLabel.Text = health .. "/" .. maxHealth
    -- Changer la couleur en fonction de la santé
    if health > maxHealth * 0.5 then
        ui.HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Vert
    elseif health > maxHealth * 0.25 then
        ui.HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Jaune
    else
        ui.HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rouge
    end

    -- Mettre à jour la distance
    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    ui.DistanceLabel.Text = math.floor(distance) .. " studs"
    -- Changer la couleur en fonction de la distance
    if distance <= 50 then
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Vert (proche)
    elseif distance <= 100 then
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Jaune (moyen)
    else
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rouge (loin)
    end

    -- Mettre à jour l'arme équipée
    local equippedWeapon = "nil"
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        for _, weapon in pairs(WEAPON_LIST) do
            if tool.Name == weapon then
                equippedWeapon = weapon
                break
            end
        end
    end
    ui.WeaponLabel.Text = equippedWeapon

    -- UI réactive à la santé (2b) : Battement de cœur et glitch intensifié si santé ≤ 25%
    if health <= maxHealth * 0.25 and ui.Frame.Visible then
        -- Effet de battement de cœur
        local pulseSpeed = 0.3 -- Vitesse rapide pour simuler un battement de cœur
        local tweenInfo = TweenInfo.new(pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween1 = TweenService:Create(ui.Frame, tweenInfo, {Size = UDim2.new(0, 310, 0, 185)})
        local tween2 = TweenService:Create(ui.Frame, tweenInfo, {Size = UDim2.new(0, 300, 0, 180)})
        tween1:Play()
        tween1.Completed:Connect(function()
            tween2:Play()
        end)

        -- Glitch intensifié
        local glitchFrame = ui.Frame:FindFirstChild("GlitchFrame") or Instance.new("Frame")
        glitchFrame.Name = "GlitchFrame"
        glitchFrame.Size = UDim2.new(1, 0, 1, 0)
        glitchFrame.BackgroundTransparency = 1
        glitchFrame.Parent = ui.Frame

        local function createIntenseGlitchLine()
            local glitchLine = Instance.new("Frame")
            glitchLine.Size = UDim2.new(1, 0, 0, 2)
            glitchLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Rouge pour indiquer un danger
            glitchLine.BackgroundTransparency = 0.5
            glitchLine.Position = UDim2.new(0, 0, math.random(), 0)
            glitchLine.Parent = glitchFrame

            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            local tween = TweenService:Create(glitchLine, tweenInfo, {BackgroundTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function()
                glitchLine:Destroy()
            end)
        end

        for i = 1, 3 do
            createIntenseGlitchLine()
        end
    end

    -- Afficher l'UI avec une animation spectaculaire si elle n'est pas déjà visible (5b)
    if not ui.Frame.Visible then
        ui.Frame.Visible = true
        ui.Frame.BackgroundTransparency = 1
        ui.Frame.Size = UDim2.new(0, 0, 0, 0)

        local particleFrame = Instance.new("Frame")
        particleFrame.Size = UDim2.new(1, 0, 1, 0)
        particleFrame.BackgroundTransparency = 1
        particleFrame.Parent = ui.Frame

        local function createConvergingParticle()
            local particle = Instance.new("Frame")
            particle.Size = UDim2.new(0, 5, 0, 5)
            local angle = math.random() * 2 * math.pi
            local startX = math.cos(angle) * 200
            local startY = math.sin(angle) * 200
            particle.Position = UDim2.new(0.5, startX, 0.5, startY)
            particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
            particle.BackgroundTransparency = 0.3
            particle.Parent = particleFrame

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = particle

            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tween = TweenService:Create(particle, tweenInfo, {
                Position = UDim2.new(0.5, 0, 0.5, 0),
                BackgroundTransparency = 1
            })
            tween:Play()
            tween.Completed:Connect(function()
                particle:Destroy()
            end)
        end

        for i = 1, 20 do
            createConvergingParticle()
        end

        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(ui.Frame, tweenInfo, {BackgroundTransparency = 0.5, Size = UDim2.new(0, 300, 0, 180)})
        tween:Play()
        tween.Completed:Connect(function()
            particleFrame:Destroy()
        end)
    end
end

-- Gestion de l'UI après un respawn/reset
local function SetupUIMobileSupport()
    if not ForceHitModule.UIMobileSupportEnabled then
        if ForceHitModule.ForceHitButton then
            ForceHitModule.ForceHitButton:Destroy()
            ForceHitModule.ForceHitButton = nil
        end
        return
    end

    -- Créer le bouton au démarrage
    if LocalPlayer.Character and not ForceHitModule.ForceHitButton then
        CreateForceHitButton()
    end

    -- Recréer le bouton après un respawn/reset
    LocalPlayer.CharacterAdded:Connect(function()
        if ForceHitModule.UIMobileSupportEnabled and not ForceHitModule.ForceHitButton then
            print("Player respawned, recreating ForceHit UI button")
            CreateForceHitButton()
        end
    end)
end

-- Fonction pour trouver la cible la plus proche (sans limite de distance, basée sur la souris)
local function GetClosestPlayer()
    local MouseLocation = UserInputService:GetMouseLocation()
    local ClosestToMouse = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(ForceHitModule.HitPart)
                local ForceField = Character:FindFirstChildOfClass("ForceField")
                if Part and not ForceField then
                    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local MouseDistance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MouseLocation).Magnitude
                        local Score = MouseDistance
                        
                        if Score < ClosestToMouse then
                            ClosestToMouse = Score
                            ClosestPlayer = Player
                            ClosestPart = Part
                            ClosestCharacter = Character
                        end
                    end
                end
            end
        end
    end
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

-- Fonction pour trouver la cible la plus proche en termes de distance physique (pour AutoTargetAll et Kill All)
local function GetClosestPlayerByDistance(minHealth)
    local ClosestDistance = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil
    local LocalCharacter = LocalPlayer.Character
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position

    if not LocalPosition then return nil, nil, nil end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(ForceHitModule.HitPart)
                local ForceField = Character:FindFirstChildOfClass("ForceField")
                if Part and not ForceField then
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if Humanoid and (not minHealth or Humanoid.Health >= minHealth) then
                        local Distance = (LocalPosition - Part.Position).Magnitude
                        if Distance < ClosestDistance then
                            ClosestDistance = Distance
                            ClosestPlayer = Player
                            ClosestPart = Part
                            ClosestCharacter = Character
                        end
                    end
                end
            end
        end
    end
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

-- Fonction pour vérifier si la cible est derrière un mur
local function IsTargetBehindWall(localPosition, targetPosition)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, ForceHitModule.TargetPlayer and ForceHitModule.TargetPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local direction = (targetPosition - localPosition).Unit * (targetPosition - localPosition).Magnitude
    local raycastResult = workspace:Raycast(localPosition, direction, raycastParams)

    return raycastResult ~= nil -- Retourne true si un obstacle est détecté
end

-- Fonction pour vérifier si la cible est dans le void (position Y très basse)
local function IsTargetInVoid(targetPosition)
    -- Supposons que Y < -500 est considéré comme le void (ajuste selon ton jeu)
    return targetPosition.Y < -500
end

-- Fonction pour créer ou mettre à jour le Tracer (du joueur local à la cible)
local function UpdateTracer()
    -- Vérifier si ForceHit est activé manuellement et s'il y a une cible
    if not ForceHitModule.ManuallyEnabled or not ForceHitModule.TargetPlayer then
        -- Supprimer le Tracer s'il existe
        if ForceHitModule.Tracer then
            print("Tracer: Suppression du Tracer (ForceHit désactivé ou pas de cible)")
            ForceHitModule.Tracer:Destroy()
            ForceHitModule.Tracer = nil
        end
        if ForceHitModule.Attachment0 then
            ForceHitModule.Attachment0:Destroy()
            ForceHitModule.Attachment0 = nil
        end
        if ForceHitModule.Attachment1 then
            ForceHitModule.Attachment1:Destroy()
            ForceHitModule.Attachment1 = nil
        end
        return
    end

    -- Vérifier que le joueur local a un HumanoidRootPart
    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then
        print("Tracer: Joueur local non valide - LocalRootPart:", localRootPart)
        -- Supprimer le Tracer s'il existe
        if ForceHitModule.Tracer then
            ForceHitModule.Tracer:Destroy()
            ForceHitModule.Tracer = nil
        end
        if ForceHitModule.Attachment0 then
            ForceHitModule.Attachment0:Destroy()
            ForceHitModule.Attachment0 = nil
        end
        if ForceHitModule.Attachment1 then
            ForceHitModule.Attachment1:Destroy()
            ForceHitModule.Attachment1 = nil
        end
        return
    end

    -- Vérifier que la cible a un HitPart
    local targetCharacter = ForceHitModule.TargetPlayer.Character
    local targetHitPart = targetCharacter and targetCharacter:FindFirstChild(ForceHitModule.HitPart)
    if not targetHitPart then
        print("Tracer: Cible non valide - TargetHitPart:", targetHitPart)
        -- Supprimer le Tracer s'il existe
        if ForceHitModule.Tracer then
            ForceHitModule.Tracer:Destroy()
            ForceHitModule.Tracer = nil
        end
        if ForceHitModule.Attachment0 then
            ForceHitModule.Attachment0:Destroy()
            ForceHitModule.Attachment0 = nil
        end
        if ForceHitModule.Attachment1 then
            ForceHitModule.Attachment1:Destroy()
            ForceHitModule.Attachment1 = nil
        end
        return
    end

    -- Si le Tracer n'existe pas, le créer
    if not ForceHitModule.Tracer then
        print("Tracer: Création d'un nouveau Tracer")
        local tracer = Instance.new("Beam")
        tracer.Name = "ForceHitTracer"
        tracer.Parent = workspace -- Placer le Beam dans le workspace pour qu'il soit visible dans le monde 3D
        tracer.Enabled = true
        tracer.Color = ColorSequence.new(Color3.new(1, 0, 0)) -- Rouge (tu peux changer la couleur)
        tracer.Transparency = NumberSequence.new(0) -- Complètement opaque
        tracer.Width0 = 0.2 -- Largeur au début
        tracer.Width1 = 0.2 -- Largeur à la fin
        tracer.LightEmission = 1 -- Émission de lumière pour le rendre plus visible
        tracer.LightInfluence = 0 -- Pas d'influence de la lumière ambiante

        -- Créer les Attachments
        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = localRootPart
        ForceHitModule.Attachment0 = attachment0

        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = targetHitPart
        ForceHitModule.Attachment1 = attachment1

        -- Connecter le Beam aux Attachments
        tracer.Attachment0 = attachment0
        tracer.Attachment1 = attachment1

        ForceHitModule.Tracer = tracer
        print("Tracer: Créé de " .. LocalPlayer.Name .. " à " .. ForceHitModule.TargetPlayer.Name)
    end

    -- Mettre à jour l'Attachment0 si nécessaire
    if ForceHitModule.Attachment0 and ForceHitModule.Attachment0.Parent ~= localRootPart then
        print("Tracer: Mise à jour de Attachment0")
        ForceHitModule.Attachment0:Destroy()
        local newAttachment0 = Instance.new("Attachment")
        newAttachment0.Parent = localRootPart
        ForceHitModule.Attachment0 = newAttachment0
        ForceHitModule.Tracer.Attachment0 = newAttachment0
    end

    -- Mettre à jour l'Attachment1 si nécessaire
    if ForceHitModule.Attachment1 and ForceHitModule.Attachment1.Parent ~= targetHitPart then
        print("Tracer: Mise à jour de Attachment1")
        ForceHitModule.Attachment1:Destroy()
        local newAttachment1 = Instance.new("Attachment")
        newAttachment1.Parent = targetHitPart
        ForceHitModule.Attachment1 = newAttachment1
        ForceHitModule.Tracer.Attachment1 = newAttachment1
    end
end

-- Gestion du Highlight, du Tracer et mise à jour de la cible
local function UpdateTargetAndHighlight()
    -- Si l'utilisateur a désactivé manuellement, ne rien faire
    if not ForceHitModule.ManuallyEnabled then
        ForceHitModule.Enabled = false
        Highlight.Enabled = false
        ForceHitModule.SelectedTarget = nil
        -- Désactiver le Tracer et l'UI
        UpdateTracer()
        UpdateTargetInfoUI()
        return
    end

    -- Si on a un joueur ciblé, essayer de mettre à jour SelectedTarget
    if ForceHitModule.TargetPlayer then
        local character = ForceHitModule.TargetPlayer.Character
        if character then
            local hitPart = character:FindFirstChild(ForceHitModule.HitPart)
            local humanoid = character:FindFirstChild("Humanoid")
            local forceField = character:FindFirstChildOfClass("ForceField")
            if hitPart and humanoid and humanoid.Health > 0 and not forceField then
                ForceHitModule.SelectedTarget = hitPart

                -- Vérifier les HP pour activer/désactiver ForceHit ou changer de cible
                local health = humanoid.Health
                if health >= 0.5 and health <= 2.5 then -- Nouvelle plage de HP (0.5 à 2.5)
                    if ForceHitModule.Enabled then
                        ForceHitModule.Enabled = false
                    end
                elseif health > 2.5 then
                    if not ForceHitModule.Enabled then
                        ForceHitModule.Enabled = true
                    end
                end

                -- Vérifier si AutoTargetAll est activé et si les HP sont <= 0.5
                if ForceHitModule.AutoTargetAll and health <= 0.5 then
                    -- Sélectionner une nouvelle cible
                    local newPart, newCharacter, newPlayer = GetClosestPlayerByDistance()
                    if newPlayer then
                        ForceHitModule.TargetPlayer = newPlayer
                        ForceHitModule.SelectedTarget = newPart
                    else
                        ForceHitModule.TargetPlayer = nil
                        ForceHitModule.SelectedTarget = nil
                    end
                end

                -- Vérifier la distance entre le joueur local et la cible
                local localCharacter = LocalPlayer.Character
                local localPosition = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position
                if localPosition and hitPart then
                    local distance = (localPosition - hitPart.Position).Magnitude
                    if distance > 200 then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    elseif distance <= 200 then
                        if not ForceHitModule.Enabled and health > 2.5 then
                            ForceHitModule.Enabled = true
                        end
                    end

                    -- Vérifier si la cible est derrière un mur (seulement si WallCheckEnabled est true)
                    local targetPosition = hitPart.Position
                    if ForceHitModule.WallCheckEnabled and IsTargetBehindWall(localPosition, targetPosition) then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                            -- Optionnel : Ajouter une notification pour indiquer que ForceHit est désactivé
                            -- sendNotification("ForceHit", "Disabled (Target behind wall)", 2)
                        end
                    else
                        if not ForceHitModule.Enabled and health > 2.5 and distance <= 200 then
                            ForceHitModule.Enabled = true
                            -- Optionnel : Ajouter une notification pour indiquer que ForceHit est réactivé
                            -- sendNotification("ForceHit", "Enabled (Target in line of sight)", 2)
                        end
                    end

                    -- Vérifier si la cible est dans le void
                    if IsTargetInVoid(targetPosition) then
                        print("ForceHit: Cible dans le void, désactivation")
                        ForceHitModule.Enabled = false
                        ForceHitModule.ManuallyEnabled = false
                        ForceHitModule.SelectedTarget = nil
                        ForceHitModule.TargetPlayer = nil
                        Highlight.Enabled = false
                        -- Désactiver le Tracer et l'UI
                        UpdateTracer()
                        UpdateTargetInfoUI()
                        return
                    end
                end
            else
                ForceHitModule.SelectedTarget = nil
            end
        else
            ForceHitModule.SelectedTarget = nil
        end
    end

    -- Si ForceHit est désactivé (par la logique des HP, de la distance, du wall check ou autre), désactiver le Highlight
    if not ForceHitModule.Enabled then
        Highlight.Enabled = false
    end

    -- Mettre à jour le Highlight
    local target, character = ForceHitModule.SelectedTarget, nil
    if target and target.Parent then
        character = target.Parent
    end
    if character then
        Highlight.Adornee = character
        Highlight.Enabled = true
    else
        Highlight.Enabled = false
    end

    -- Mettre à jour le Tracer et l'UI (même si ForceHit est désactivé par le wall check)
    UpdateTracer()
    UpdateTargetInfoUI()
end

-- Vérification de la cible après un respawn/reset
local function CheckTargetAfterRespawn()
    if not ForceHitModule.TargetPlayer then return end

    local player = ForceHitModule.TargetPlayer
    player.CharacterAdded:Connect(function(newCharacter)
        if not ForceHitModule.Enabled or not ForceHitModule.TargetPlayer then return end
        -- Pas besoin de faire quoi que ce soit ici, UpdateTargetAndHighlight s'en chargera
    end)
end

-- Logique pour Kill All (téléportation et activation de ForceHit)
local function ExecuteKillAll()
    if not ForceHitModule.KillAllEnabled then return end

    -- Vérifier le cooldown pour éviter les abus
    local currentTime = tick()
    if currentTime - ForceHitModule.LastKillAllTime < 1 then -- Cooldown de 1 seconde
        -- sendNotification("Kill All", "Please wait before using Kill All again", 2)
        return
    end
    ForceHitModule.LastKillAllTime = currentTime

    -- Vérifier que le joueur local est valide
    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then
        -- sendNotification("Kill All", "Local player not ready", 2)
        return
    end

    -- Activer ForceHit manuellement si ce n'est pas déjà fait
    if not ForceHitModule.ManuallyEnabled then
        ForceHitModule:Toggle()
    end

    -- Trouver tous les joueurs valides et les trier par distance
    local targets = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local forceField = character:FindFirstChildOfClass("ForceField")
                if rootPart and not forceField then
                    local distance = (localRootPart.Position - rootPart.Position).Magnitude
                    table.insert(targets, {Player = player, Distance = distance, RootPart = rootPart})
                end
            end
        end
    end

    -- Trier les cibles par distance (de la plus proche à la plus éloignée)
    table.sort(targets, function(a, b)
        return a.Distance < b.Distance
    end)

    -- Téléporter le joueur local vers chaque cible et activer ForceHit
    for _, target in ipairs(targets) do
        local targetPlayer = target.Player
        local targetRootPart = target.RootPart

        -- Vérifier que la cible est toujours valide
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") and targetPlayer.Character.Humanoid.Health > 0 then
            -- Téléporter le joueur local près de la cible
            local offset = Vector3.new(5, 0, 5) -- Décalage pour ne pas être trop près
            local newPosition = targetRootPart.Position + offset
            localRootPart.CFrame = CFrame.new(newPosition)

            -- Définir la cible pour ForceHit
            ForceHitModule.TargetPlayer = targetPlayer
            local hitPart = targetPlayer.Character:FindFirstChild(ForceHitModule.HitPart)
            if hitPart then
                ForceHitModule.SelectedTarget = hitPart
                ForceHitModule.Enabled = true
            end

            -- Attendre un court instant pour permettre à ForceHit de fonctionner
            wait(0.5)

            -- Vérifier si la cible est toujours en vie
            local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                -- sendNotification("Kill All", "Eliminated " .. targetPlayer.Name, 1)
            end
        end
    end

    -- sendNotification("Kill All", "Finished targeting all players", 2)
end

-- Logique pour Auto Stomp
local function ExecuteAutoStomp()
    if not ForceHitModule.AutoStompEnabled then return end

    -- Vérifier que le joueur local est valide
    local localCharacter = LocalPlayer.Character
    local localHumanoid = localCharacter and localCharacter:FindFirstChild("Humanoid")
    if not localHumanoid or localHumanoid.Health <= 0 then return end

    -- Rechercher les joueurs à proximité pour stomper
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                if humanoid.Health <= 0 then -- Vérifier si le joueur est KO
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
                    if rootPart and localRootPart then
                        local distance = (localRootPart.Position - rootPart.Position).Magnitude
                        if distance <= 10 then -- Distance maximale pour stomper
                            -- Exécuter l'action de stomp via l'événement MainEvent
                            if MainEvent then
                                MainEvent:FireServer("Stomp")
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Logique pour Target Strafe
local function ExecuteTargetStrafe()
    if not ForceHitModule.TargetStrafeEnabled or not ForceHitModule.TargetPlayer then return end

    -- Vérifier que le joueur local est valide
    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then return end

    -- Vérifier que la cible est valide
    local targetCharacter = ForceHitModule.TargetPlayer.Character
    local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
    if not targetRootPart then return end

    -- Calculer la position pour le strafe (cercle autour de la cible)
    local radius = 10 -- Rayon du cercle de strafe
    local speed = 10 -- Vitesse de rotation (degrés par seconde)
    ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle + (speed * RunService.Heartbeat:Wait())
    if ForceHitModule.StrafeAngle >= 360 then
        ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle - 360
    end

    local angle = math.rad(ForceHitModule.StrafeAngle)
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local newPosition = targetRootPart.Position + offset

    -- Téléporter le joueur local à la nouvelle position
    localRootPart.CFrame = CFrame.new(newPosition, targetRootPart.Position)
end

-- Fonction pour jouer le son de hit
local function PlayHitSound()
    if ForceHitModule.HitSound then
        ForceHitModule.HitSound:Play()
    end
end

-- Fonction principale pour gérer ForceHit
local function ForceHit()
    if not ForceHitModule.Enabled or not ForceHitModule.SelectedTarget then return end

    -- Vérifier que le joueur local a un outil équipé
    local localCharacter = LocalPlayer.Character
    local tool = localCharacter and localCharacter:FindFirstChildOfClass("Tool")
    if not tool then return end

    -- Vérifier que MainEvent existe
    if not MainEvent then return end

    -- Vérifier que la cible est valide
    local target = ForceHitModule.SelectedTarget
    if not target or not target.Parent then return end

    -- Vérifier que la cible a un Humanoid
    local character = target.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    -- Vérifier que le joueur local a un Humanoid
    local localHumanoid = localCharacter:FindFirstChild("Humanoid")
    if not localHumanoid or localHumanoid.Health <= 0 then return end

    -- Exécuter ForceHit via MainEvent
    if ForceHitModule.BlankShots then
        MainEvent:FireServer("Update", {ForceHitModule.SelectedTarget})
    else
        MainEvent:FireServer("Fire", {ForceHitModule.SelectedTarget})
    end

    -- Jouer le son de hit
    PlayHitSound()
end

-- Toggle pour activer/désactiver ForceHit
function ForceHitModule:Toggle()
    self.ManuallyEnabled = not self.ManuallyEnabled
    if not self.ManuallyEnabled then
        self.Enabled = false
        self.SelectedTarget = nil
        self.TargetPlayer = nil
        Highlight.Enabled = false
        -- Désactiver le Tracer et l'UI
        UpdateTracer()
        UpdateTargetInfoUI()
    end
    return self.ManuallyEnabled
end

-- Fonction pour définir une nouvelle cible
function ForceHitModule:SetTarget(player)
    self.TargetPlayer = player
    if player and player.Character then
        local hitPart = player.Character:FindFirstChild(self.HitPart)
        if hitPart then
            self.SelectedTarget = hitPart
            CheckTargetAfterRespawn()
        else
            self.SelectedTarget = nil
        end
    else
        self.SelectedTarget = nil
    end
end

-- Fonction pour nettoyer toutes les ressources
function ForceHitModule:Destroy()
    -- Désactiver tout
    self.Enabled = false
    self.ManuallyEnabled = false
    self.AutoTargetAll = false
    self.UIMobileSupportEnabled = false
    self.WallCheckEnabled = true
    self.KillAllEnabled = false
    self.AutoStompEnabled = false
    self.TargetStrafeEnabled = false
    self.SelectedTarget = nil
    self.TargetPlayer = nil

    -- Déconnecter toutes les connexions
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}

    -- Supprimer le Highlight
    if Highlight then
        Highlight:Destroy()
    end

    -- Supprimer le Tracer et les Attachments
    if self.Tracer then
        self.Tracer:Destroy()
        self.Tracer = nil
    end
    if self.Attachment0 then
        self.Attachment0:Destroy()
        self.Attachment0 = nil
    end
    if self.Attachment1 then
        self.Attachment1:Destroy()
        self.Attachment1 = nil
    end

    -- Supprimer l'UI
    if self.ForceHitButton then
        self.ForceHitButton:Destroy()
        self.ForceHitButton = nil
    end
    if self.TargetInfoUI then
        self.TargetInfoUI.ScreenGui:Destroy()
        self.TargetInfoUI = nil
    end

    -- Supprimer le son
    if self.HitSound then
        self.HitSound:Destroy()
        self.HitSound = nil
    end
end

-- Initialisation du module
local function Initialize()
    -- Créer l'UI pour le support mobile
    SetupUIMobileSupport()

    -- Connecter les événements principaux
    table.insert(ForceHitModule.Connections, RunService.Heartbeat:Connect(function()
        -- Mettre à jour la cible et le Highlight
        UpdateTargetAndHighlight()

        -- Exécuter ForceHit si activé
        ForceHit()

        -- Exécuter Kill All si activé
        ExecuteKillAll()

        -- Exécuter Auto Stomp si activé
        ExecuteAutoStomp()

        -- Exécuter Target Strafe si activé
        ExecuteTargetStrafe()
    end))

    -- Connecter l'événement de clic pour sélectionner une cible
    table.insert(ForceHitModule.Connections, Mouse.Button1Down:Connect(function()
        if not ForceHitModule.ManuallyEnabled then return end
        local targetPart, targetCharacter, targetPlayer = GetClosestPlayer()
        if targetPlayer then
            ForceHitModule:SetTarget(targetPlayer)
            -- sendNotification("ForceHit", "Target set to " .. targetPlayer.Name, 2)
        end
    end))

    -- Connecter l'événement de respawn/reset du joueur local
    table.insert(ForceHitModule.Connections, LocalPlayer.CharacterAdded:Connect(function()
        -- Réinitialiser certaines variables si nécessaire
        ForceHitModule.SelectedTarget = nil
        UpdateTracer()
        UpdateTargetInfoUI()
    end))
end

-- Appeler l'initialisation
Initialize()

-- Retourner le module
return ForceHitModule

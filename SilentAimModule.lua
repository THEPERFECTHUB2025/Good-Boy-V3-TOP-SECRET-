-- SilentAimModule.lua
local SilentAimModule = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables internes (rendues publiques pour SilentAimTarget)
SilentAimModule.SilentAimTarget = nil -- Cible actuelle du Silent Aim
local SilentAimEnabled = false
local SilentAimClosestPart = nil
local SilentAimLockedTarget = nil
local characterAddedConnections = {}
local originalIndex = nil -- Pour stocker la méthode originale
local lastHookTime = 0 -- Suivi du dernier appel du hook pour limiter la fréquence
local hookCooldown = 0.01 -- Délai minimum entre les appels du hook (en secondes)

-- Fonction pour trouver l'ennemi le plus proche en fonction de la position de la souris (rendue publique)
function SilentAimModule:findNearestEnemyForSilentAim()
    if SilentAimLockedTarget and SilentAimLockedTarget.Character and SilentAimLockedTarget.Character:FindFirstChild("Humanoid") then
        local humanoid = SilentAimLockedTarget.Character.Humanoid
        if humanoid.Health > 0 then
            return SilentAimLockedTarget, SilentAimLockedTarget.Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
        else
            print("Silent Aim: Cible", SilentAimLockedTarget.Name, "morte - Recherche d'une nouvelle cible")
            SilentAimLockedTarget = nil
        end
    end

    local MouseLocation = UserInputService:GetMouseLocation()
    local ClosestToMouse = math.huge
    local ClosestPlayer, ClosestPart = nil, nil

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
                if Part then
                    local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                    if OnScreen then
                        local MouseDistance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MouseLocation).Magnitude
                        local Score = MouseDistance
                        
                        if Score < ClosestToMouse then
                            ClosestToMouse = Score
                            ClosestPlayer = Player
                            ClosestPart = Part
                        end
                    end
                end
            end
        end
    end

    if ClosestPlayer then
        SilentAimLockedTarget = ClosestPlayer
        print("Silent Aim: Cible trouvée:", ClosestPlayer.Name)
    end

    return ClosestPlayer, ClosestPart
end

-- Fonction pour nettoyer les highlights et tracers existants
local function cleanHighlightsAndTracers(plr)
    if plr and plr.Character then
        for _, obj in pairs(plr.Character:GetChildren()) do
            if obj:IsA("Highlight") or obj:IsA("Beam") then
                obj:Destroy()
            end
        end
    end
end

-- Fonction pour ajouter un highlight à la cible
local function highlightSilentAimTarget(plr)
    if plr and plr.Character then
        cleanHighlightsAndTracers(plr)
        local highlight = Instance.new("Highlight")
        highlight.Parent = plr.Character
        highlight.FillColor = Color3.new(1, 1, 1)
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
    end
end

-- Fonction pour créer un tracer vers la cible
local function createTracerSilentAimTarget(plr)
    if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
        print("Silent Aim: Impossible de créer un tracer - Cible invalide ou sans HumanoidRootPart")
        return
    end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("Silent Aim: Impossible de créer un tracer - LocalPlayer invalide ou sans HumanoidRootPart")
        return
    end

    cleanHighlightsAndTracers(plr)
    local tracer = Instance.new("Beam")
    tracer.Parent = plr.Character
    tracer.FaceCamera = true
    tracer.Color = ColorSequence.new(Color3.new(1, 1, 1))
    tracer.Width0 = 0.1
    tracer.Width1 = 0.1
    local attachment0 = Instance.new("Attachment", LocalPlayer.Character.HumanoidRootPart)
    local attachment1 = Instance.new("Attachment", plr.Character.HumanoidRootPart)
    tracer.Attachment0 = attachment0
    tracer.Attachment1 = attachment1
    print("Silent Aim: Tracer créé pour " .. plr.Name)
end

-- Fonction pour activer le Silent Aim
function SilentAimModule:Enable()
    if SilentAimEnabled then
        print("Silent Aim: Déjà activé")
        return
    end

    SilentAimEnabled = true
    print("Silent Aim activé")

    -- Hook pour rediriger les tirs
    local mt = getrawmetatable(game)
    originalIndex = mt.__index
    setreadonly(mt, false)

    local PredictionValue = getgenv().Rake.Settings.Prediction or 0.04

    originalIndex = hookmetamethod(game, "__index", function(self, key)
        -- Garde-fou : limiter la fréquence des appels pour éviter les stack overflows
        local currentTime = tick()
        if currentTime - lastHookTime < hookCooldown then
            return originalIndex(self, key)
        end
        lastHookTime = currentTime

        -- Vérifications pour rediriger les tirs
        if not checkcaller() and SilentAimEnabled and SilentAimModule.SilentAimTarget and self:IsA("Mouse") and key == "Hit" then
            if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character and SilentAimModule.SilentAimTarget.Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head") then
                local target = SilentAimModule.SilentAimTarget.Character[getgenv().Rake.Settings.AimPart or "Head"]
                local Position = target.Position + (SilentAimModule.SilentAimTarget.Character.Head.Velocity * PredictionValue)
                return CFrame.new(Position)
            end
        end
        return originalIndex(self, key)
    end)
end

-- Fonction pour désactiver le Silent Aim
function SilentAimModule:Disable()
    if not SilentAimEnabled then
        print("Silent Aim: Déjà désactivé")
        return
    end

    SilentAimEnabled = false
    print("Silent Aim désactivé")

    -- Restaurer le hook original
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    if originalIndex then
        mt.__index = originalIndex
        originalIndex = nil
    end
    setreadonly(mt, true)

    -- Nettoyer les highlights et tracers
    if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character then
        cleanHighlightsAndTracers(SilentAimModule.SilentAimTarget)
    end

    -- Nettoyer les connexions CharacterAdded
    for _, connection in pairs(characterAddedConnections) do
        connection:Disconnect()
    end
    characterAddedConnections = {}
    SilentAimModule.SilentAimTarget = nil
    SilentAimClosestPart = nil
    SilentAimLockedTarget = nil
end

-- Fonction pour toggle le ciblage (appelée par le keybind)
function SilentAimModule:ToggleTarget()
    if not SilentAimEnabled then
        print("Silent Aim: Veuillez activer le Silent Aim avant de sélectionner une cible")
        return
    end

    if SilentAimModule.SilentAimTarget then
        print("Silent Aim: Ciblage désactivé")
        if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character then
            cleanHighlightsAndTracers(SilentAimModule.SilentAimTarget)
        end
        if characterAddedConnections[SilentAimModule.SilentAimTarget] then
            characterAddedConnections[SilentAimModule.SilentAimTarget]:Disconnect()
            characterAddedConnections[SilentAimModule.SilentAimTarget] = nil
        end
        SilentAimModule.SilentAimTarget = nil
        SilentAimClosestPart = nil
        SilentAimLockedTarget = nil
    else
        SilentAimModule.SilentAimTarget, SilentAimClosestPart = SilentAimModule:findNearestEnemyForSilentAim()
        if SilentAimModule.SilentAimTarget then
            print("Silent Aim: Cible sélectionnée - " .. SilentAimModule.SilentAimTarget.Name)
            highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
            createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)

            -- Gérer le respawn/reset de la cible
            local characterAddedConnection = SilentAimModule.SilentAimTarget.CharacterAdded:Connect(function(newCharacter)
                print("Silent Aim: Cible " .. SilentAimModule.SilentAimTarget.Name .. " a respawné/reset")
                task.wait(0.1)
                if SilentAimModule.SilentAimTarget == SilentAimLockedTarget and SilentAimEnabled then
                    SilentAimModule.SilentAimTarget, SilentAimClosestPart = SilentAimLockedTarget, newCharacter:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
                    if SilentAimModule.SilentAimTarget and SilentAimClosestPart then
                        print("Silent Aim: Reprise du ciblage pour " .. SilentAimModule.SilentAimTarget.Name .. " après respawn/reset")
                        highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
                        createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)
                    end
                end
            end)
            characterAddedConnections[SilentAimModule.SilentAimTarget] = characterAddedConnection
        else
            print("Silent Aim: Aucune cible trouvée")
        end
    end
end

return SilentAimModule

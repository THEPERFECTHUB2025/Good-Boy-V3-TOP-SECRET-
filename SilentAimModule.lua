-- SilentAimModule.lua
local SilentAimModule = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables internes
local SilentAimEnabled = false
local SilentAimTarget = nil
local SilentAimClosestPart = nil
local SilentAimLockedTarget = nil
local characterAddedConnections = {}
local getForceHit = nil
local originalIndex = nil -- Pour stocker la méthode originale

-- Fonction pour trouver l'ennemi le plus proche en fonction de la position de la souris
local function findNearestEnemyForSilentAim()
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
function SilentAimModule:Enable(getForceHitFunc)
    if SilentAimEnabled then
        print("Silent Aim: Déjà activé")
        return
    end

    if not getForceHitFunc then
        error("SilentAimModule:Enable requires getForceHitFunc as an argument")
    end
    getForceHit = getForceHitFunc

    SilentAimEnabled = true
    getgenv().Rake.Settings.Misc.ForceHit = false
    print("Silent Aim activé, ForceHit désactivé")

    -- Hook pour rediriger les tirs
    local mt = getrawmetatable(game)
    originalIndex = mt.__index
    setreadonly(mt, false)

    local PredictionValue = getgenv().Rake.Settings.Prediction or 0.04

    originalIndex = hookmetamethod(game, "__index", function(self, key)
        if not checkcaller() and SilentAimEnabled and SilentAimTarget and self:IsA("Mouse") and key == "Hit" then
            if SilentAimTarget and SilentAimTarget.Character and SilentAimTarget.Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head") then
                local target = SilentAimTarget.Character[getgenv().Rake.Settings.AimPart or "Head"]
                local Position = target.Position + (SilentAimTarget.Character.Head.Velocity * PredictionValue)
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
    if getForceHit and getForceHit() then
        getgenv().Rake.Settings.Misc.ForceHit = true
        print("Silent Aim désactivé, ForceHit réactivé")
    else
        print("Silent Aim désactivé, ForceHit reste désactivé (toggle ForceHit non activé)")
    end

    -- Restaurer le hook original
    local mt = getrawmetatable(game)
    if originalIndex then
        mt.__index = originalIndex
        setreadonly(mt, true)
        originalIndex = nil
    end

    -- Nettoyer les highlights et tracers
    if SilentAimTarget and SilentAimTarget.Character then
        cleanHighlightsAndTracers(SilentAimTarget)
    end
    -- Nettoyer les connexions CharacterAdded
    for _, connection in pairs(characterAddedConnections) do
        connection:Disconnect()
    end
    characterAddedConnections = {}
    SilentAimTarget = nil
    SilentAimClosestPart = nil
    SilentAimLockedTarget = nil
end

-- Fonction pour toggle le ciblage (appelée par le keybind)
function SilentAimModule:ToggleTarget()
    if not SilentAimEnabled then
        print("Silent Aim: Veuillez activer le Silent Aim avant de sélectionner une cible")
        return
    end

    if SilentAimTarget then
        print("Silent Aim: Ciblage désactivé")
        if SilentAimTarget and SilentAimTarget.Character then
            cleanHighlightsAndTracers(SilentAimTarget)
        end
        if characterAddedConnections[SilentAimTarget] then
            characterAddedConnections[SilentAimTarget]:Disconnect()
            characterAddedConnections[SilentAimTarget] = nil
        end
        SilentAimTarget = nil
        SilentAimClosestPart = nil
        SilentAimLockedTarget = nil
    else
        SilentAimTarget, SilentAimClosestPart = findNearestEnemyForSilentAim()
        if SilentAimTarget then
            print("Silent Aim: Cible sélectionnée - " .. SilentAimTarget.Name)
            highlightSilentAimTarget(SilentAimTarget)
            createTracerSilentAimTarget(SilentAimTarget)

            -- Gérer le respawn/reset de la cible
            local characterAddedConnection = SilentAimTarget.CharacterAdded:Connect(function(newCharacter)
                print("Silent Aim: Cible " .. SilentAimTarget.Name .. " a respawné/reset")
                task.wait(0.1)
                if SilentAimTarget == SilentAimLockedTarget and SilentAimEnabled then
                    SilentAimTarget, SilentAimClosestPart = SilentAimLockedTarget, newCharacter:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
                    if SilentAimTarget and SilentAimClosestPart then
                        print("Silent Aim: Reprise du ciblage pour " .. SilentAimTarget.Name .. " après respawn/reset")
                        highlightSilentAimTarget(SilentAimTarget)
                        createTracerSilentAimTarget(SilentAimTarget)
                    end
                end
            end)
            characterAddedConnections[SilentAimTarget] = characterAddedConnection
        else
            print("Silent Aim: Aucune cible trouvée")
        end
    end
end

return SilentAimModule

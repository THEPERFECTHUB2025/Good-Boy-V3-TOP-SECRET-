-- ForceHitModule.lua

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
    AutoToxicEnabled = false, -- Option pour Auto Toxic
    BlankShots = true,
    HitPart = "Head",
    SelectedTarget = nil, -- Partie ciblée (HitPart)
    TargetPlayer = nil, -- Joueur ciblé (pour persistance après respawn)
    Connections = {}, -- Stockage des connexions pour nettoyage
    ForceHitButton = nil, -- Référence au bouton draggable dans l'UI
    ButtonPosition = UDim2.new(0.5, -50, 0.5, -25) -- Position initiale du bouton (sauvegardée)
}

-- Highlight pour la cible
local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

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
    local shadow = Instance.new("UIStroke")
    shadow.Thickness = 2
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Transparency = 0.5
    shadow.Parent = frame

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

-- Fonction pour trouver la cible la plus proche en termes de distance physique (pour AutoTargetAll)
local function GetClosestPlayerByDistance()
    local ClosestDistance = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil
    local LocalCharacter = LocalPlayer.Character
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position

    if not LocalPosition then return nil, nil, nil end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player ~= ForceHitModule.TargetPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(ForceHitModule.HitPart)
                local ForceField = Character:FindFirstChildOfClass("ForceField")
                if Part and not ForceField then
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
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

-- Fonction pour vérifier si la cible est derrière un mur
local function IsTargetBehindWall(localPosition, targetPosition)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, ForceHitModule.TargetPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local direction = (targetPosition - localPosition).Unit * (targetPosition - localPosition).Magnitude
    local raycastResult = workspace:Raycast(localPosition, direction, raycastParams)

    return raycastResult ~= nil -- Retourne true si un obstacle est détecté
end

-- Gestion du Highlight et mise à jour de la cible
local function UpdateTargetAndHighlight()
    -- Si l'utilisateur a désactivé manuellement, ne rien faire
    if not ForceHitModule.ManuallyEnabled then
        ForceHitModule.Enabled = false
        Highlight.Enabled = false
        ForceHitModule.SelectedTarget = nil
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
                if health >= 0.5 and health <= 1.5 then
                    if ForceHitModule.Enabled then
                        ForceHitModule.Enabled = false
                    end
                elseif health > 1.5 then
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
                        if not ForceHitModule.Enabled and health > 1.5 then
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
                        if not ForceHitModule.Enabled and health > 1.5 and distance <= 200 then
                            ForceHitModule.Enabled = true
                            -- Optionnel : Ajouter une notification pour indiquer que ForceHit est réactivé
                            -- sendNotification("ForceHit", "Enabled (Target in line of sight)", 2)
                        end
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
        return
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

-- Auto Toxic (envoie des messages toxiques à la cible)
ForceHitModule.Connections["AutoToxic"] = RunService.Heartbeat:Connect(function()
    if not ForceHitModule.AutoToxicEnabled or not ForceHitModule.Enabled then return end

    local targetPlayer = ForceHitModule.TargetPlayer
    if not targetPlayer then return end

    -- Vérifier si le Wall Check est activé et si la cible est derrière un mur
    local localCharacter = LocalPlayer.Character
    local localPosition = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position
    local targetPosition = targetPlayer.Character and targetPlayer.Character:FindFirstChild(ForceHitModule.HitPart) and targetPlayer.Character[ForceHitModule.HitPart].Position

    if ForceHitModule.WallCheckEnabled and localPosition and targetPosition and IsTargetBehindWall(localPosition, targetPosition) then
        return -- Ne pas envoyer de message si la cible est derrière un mur et que le Wall Check est activé
    end

    -- Liste de messages tox Wiques
    local toxicMessages = {
        "You're trash, " .. targetPlayer.Name .. "!",
        "Get good, " .. targetPlayer.Name .. "!",
        "Lol, " .. targetPlayer.Name .. ", you suck!",
        "EZ clap, " .. targetPlayer.Name .. "!"
    }

    -- Envoyer un message toxique aléatoire toutes les 5 secondes
    if not ForceHitModule.LastToxicMessage then
        ForceHitModule.LastToxicMessage = 0
    end

    if os.clock() - ForceHitModule.LastToxicMessage >= 5 then
        local message = toxicMessages[math.random(1, #toxicMessages)]
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
        ForceHitModule.LastToxicMessage = os.clock()
    end
end)

-- Connexion pour mettre à jour la cible et le Highlight
ForceHitModule.Connections["UpdateTargetAndHighlight"] = RunService.RenderStepped:Connect(UpdateTargetAndHighlight)

-- Hook pour intercepter les tirs
local OriginalNameCall
OriginalNameCall = hookmetamethod(game, "__namecall", function(Object, ...)
    local Arguments = {...}
    local NameCallMethod = getnamecallmethod()

    if not ForceHitModule.Enabled then
        return OriginalNameCall(Object, ...)
    end

    if NameCallMethod == "InvokeServer" and Object.Name == "MainFunction" and #Arguments > 0 and Arguments[1] == "GunCheck" then
        return nil
    end

    if NameCallMethod == "FireServer" and Object.Name == "MainEvent" and #Arguments > 0 and Arguments[1] == "Shoot" then
        local AimPart = ForceHitModule.SelectedTarget
        if AimPart then
            if Arguments[2] and #Arguments[2] > 0 then
                for _, Table in pairs(Arguments[2][1]) do
                    Table["Instance"] = AimPart
                end
                for _, Table in pairs(Arguments[2][2]) do
                    Table["thePart"] = AimPart
                    Table["theOffset"] = CFrame.new()
                end
            end
            return OriginalNameCall(Object, unpack(Arguments))
        end
    end
    
    return OriginalNameCall(Object, ...)
end)

-- Blank Shots
ForceHitModule.Connections["BlankShots"] = RunService.Heartbeat:Connect(function()
    if not ForceHitModule.Enabled or not ForceHitModule.BlankShots then return end

    local HasTool = false
    for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            HasTool = true
            break
        end
    end

    if not HasTool then return end

    local AimPart = ForceHitModule.SelectedTarget
    local AimChar = AimPart and AimPart.Parent
    if AimChar then
        local ForceField = AimChar:FindFirstChildOfClass("ForceField")
        if not ForceField then
            if AimPart and MainEvent then
                local args = {
                    "Shoot",
                    {
                        {
                            [1] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.78562927246094, 33.89368438720703, -365.6424865722656)
                            },
                            [2] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.78562927246094, 33.89368438720703, -365.6424865722656)
                            },
                            [3] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937343597412109, 0.10944879800081253, -0.022651422768831253),
                                ["Position"] = AimPart.Position
                            },
                            [4] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = AimPart.Position
                            },
                            [5] = {
                                ["Instance"] = AimPart,
                                ["Normal"] = Vector3.new(0.9937344193458557, 0.10944880545139313, -0.022651424631476402),
                                ["Position"] = Vector3.new(-141.79481506347656, 34.033607482910156, -365.369384765625)
                            }
                        },
                        {
                            [1] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [2] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [3] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [4] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            },
                            [5] = {
                                ["thePart"] = AimPart,
                                ["theOffset"] = CFrame.new(0, 0, 0)
                            }
                        },
                        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position or Vector3.new(),
                        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position or Vector3.new(),
                        workspace:GetServerTimeNow()
                    }
                }

                MainEvent:FireServer(unpack(args))
            end
        end
    end
end)

-- Fonctions du module
function ForceHitModule:Enable()
    if self.ManuallyEnabled then return end
    self.ManuallyEnabled = true
    self.Enabled = true
    -- Sélectionner une cible si aucune n'est verrouillée
    if not self.TargetPlayer then
        local ClosestPart, ClosestCharacter, ClosestPlayer = GetClosestPlayer()
        self.SelectedTarget = ClosestPart
        self.TargetPlayer = ClosestPlayer
        CheckTargetAfterRespawn()
    end
end

function ForceHitModule:Disable()
    if not self.ManuallyEnabled then return end
    self.ManuallyEnabled = false
    self.Enabled = false
    self.SelectedTarget = nil -- Réinitialiser la cible verrouillée
    self.TargetPlayer = nil -- Réinitialiser le joueur ciblé
    Highlight.Enabled = false
end

function ForceHitModule:Toggle()
    if self.ManuallyEnabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.ManuallyEnabled
end

function ForceHitModule:IsEnabled()
    return self.ManuallyEnabled
end

function ForceHitModule:SetAutoTargetAll(value)
    self.AutoTargetAll = value
end

function ForceHitModule:GetAutoTargetAll()
    return self.AutoTargetAll
end

function ForceHitModule:SetUIMobileSupport(value)
    self.UIMobileSupportEnabled = value
    if value then
        SetupUIMobileSupport()
    else
        if self.ForceHitButton then
            self.ForceHitButton:Destroy()
            self.ForceHitButton = nil
        end
    end
end

function ForceHitModule:GetUIMobileSupport()
    return self.UIMobileSupportEnabled
end

function ForceHitModule:SetWallCheckEnabled(value)
    self.WallCheckEnabled = value
end

function ForceHitModule:GetWallCheckEnabled()
    return self.WallCheckEnabled
end

function ForceHitModule:SetAutoToxic(value)
    self.AutoToxicEnabled = value
end

function ForceHitModule:GetAutoToxic()
    return self.AutoToxicEnabled
end

function ForceHitModule:Cleanup()
    self:Disable()
    if self.ForceHitButton then
        self.ForceHitButton:Destroy()
        self.ForceHitButton = nil
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    Highlight:Destroy()
end

return ForceHitModule

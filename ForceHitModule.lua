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
    ManuallyEnabled = false, -- État défini par l'utilisateur via le keybind ou l'outil
    AutoTargetAll = false, -- Option pour cibler automatiquement une nouvelle personne
    ToolSupportEnabled = false, -- Option pour activer le support de l'outil
    BlankShots = true,
    HitPart = "Head",
    SelectedTarget = nil, -- Partie ciblée (HitPart)
    TargetPlayer = nil, -- Joueur ciblé (pour persistance après respawn)
    Connections = {}, -- Stockage des connexions pour nettoyage
    Tool = nil -- Référence à l'outil créé
}

-- Highlight pour la cible
local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

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
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position

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

                    -- Vérifier si la cible est derrière un mur
                    local targetPosition = hitPart.Position
                    if IsTargetBehindWall(localPosition, targetPosition) then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    else
                        if not ForceHitModule.Enabled and health > 1.5 and distance <= 200 then
                            ForceHitModule.Enabled = true
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

-- Fonction pour trier les outils dans le Backpack et placer "ForceHit Toggle" à la 4ème position
local function SortBackpack()
    local backpack = LocalPlayer.Backpack
    local tools = backpack:GetChildren()
    local forceHitTool = nil
    local otherTools = {}

    -- Séparer "ForceHit Toggle" des autres outils
    for _, tool in pairs(tools) do
        if tool.Name == "ForceHit Toggle" then
            forceHitTool = tool
        else
            table.insert(otherTools, tool)
        end
    end

    -- S'assurer qu'il y a assez d'outils pour avoir une 4ème position
    if not forceHitTool then return end

    -- Réorganiser les outils
    for _, tool in pairs(tools) do
        tool.Parent = nil -- Détacher temporairement tous les outils
    end

    -- Ajouter les 3 premiers outils (ou moins si moins de 3 outils)
    for i = 1, math.min(3, #otherTools) do
        otherTools[i].Parent = backpack
    end

    -- Ajouter "ForceHit Toggle" à la 4ème position
    forceHitTool.Parent = backpack

    -- Ajouter les outils restants
    for i = 4, #otherTools do
        otherTools[i].Parent = backpack
    end

    print("Backpack sorted, ForceHit Toggle placed at position 4")
end

-- Fonction pour créer l'outil ForceHit
local function CreateForceHitTool()
    if ForceHitModule.Tool then
        ForceHitModule.Tool:Destroy()
    end

    local tool = Instance.new("Tool")
    tool.Name = "ForceHit Toggle"
    tool.RequiresHandle = false
    tool.Parent = LocalPlayer.Backpack
    print("ForceHit Toggle tool created")

    tool.Activated:Connect(function()
        print("ForceHit Toggle tool activated")
        if not getgenv().Rake.Settings.Misc.ForceHitEnabled then
            -- sendNotification("ForceHit", "Toggle must be enabled to use this tool", 2)
            return
        end

        local newValue = ForceHitModule:Toggle()
        if newValue then
            -- sendNotification("ForceHit", "Enabled", 2)
        else
            -- sendNotification("ForceHit", "Disabled", 2)
        end
    end)

    ForceHitModule.Tool = tool

    -- Trier le Backpack pour placer l'outil à la 4ème position
    SortBackpack()
end

-- Gestion de l'outil après un respawn/reset
local function SetupToolOnRespawn()
    if not ForceHitModule.ToolSupportEnabled then return end

    -- Créer l'outil au démarrage
    if LocalPlayer.Character then
        CreateForceHitTool()
    end

    -- Recréer l'outil après un respawn/reset
    LocalPlayer.CharacterAdded:Connect(function()
        if ForceHitModule.ToolSupportEnabled then
            print("Player respawned, recreating ForceHit Toggle tool")
            CreateForceHitTool()
        end
    end)
end

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

function ForceHitModule:SetToolSupport(value)
    self.ToolSupportEnabled = value
    if value then
        SetupToolOnRespawn()
    else
        if self.Tool then
            self.Tool:Destroy()
            self.Tool = nil
        end
    end
end

function ForceHitModule:GetToolSupport()
    return self.ToolSupportEnabled
end

function ForceHitModule:Cleanup()
    self:Disable()
    if self.Tool then
        self.Tool:Destroy()
        self.Tool = nil
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    Highlight:Destroy()
end

return ForceHitModule

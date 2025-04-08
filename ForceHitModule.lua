-- ForceHitModule.lua

-- Services
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- Variables
local ForceHitModule = {
    Enabled = false,
    BlankShots = true,
    HitPart = "Head",
    MaxDistance = 200, -- Distance maximale de 200 studs
    SelectedPlayer = nil, -- Joueur verrouillé (au lieu de SelectedTarget)
    SelectedTarget = nil, -- Partie cible actuelle (mise à jour dynamiquement)
    CachedClosestPlayer = nil, -- Utilisé pour trouver une nouvelle cible si aucune n'est verrouillée
    Connections = {} -- Stockage des connexions pour nettoyage
}

-- Highlight pour la cible
local Highlight = Instance.new("Highlight")
Highlight.Parent = game.CoreGui
Highlight.FillColor = Color3.fromRGB(0, 255, 0)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.Enabled = false

-- Fonction pour trouver la cible la plus proche
local function GetClosestPlayer()
    local ClosestDistance, ClosestPart, ClosestCharacter = nil, nil, nil
    local MousePosition = UserInput:GetMouseLocation()
    local LocalCharacter = LocalPlayer.Character
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position

    if not LocalPosition then return nil, nil end -- Si le joueur local n'a pas de position, on arrête

    for _, Player in next, Players:GetPlayers() do
        if Player ~= LocalPlayer and Player.Character then
            local Character = Player.Character
            local HitPart = Character:FindFirstChild(ForceHitModule.HitPart)
            local Humanoid = Character:FindFirstChild("Humanoid")
            local ForceField = Character:FindFirstChildOfClass("ForceField")

            if HitPart and Humanoid and Humanoid.Health > 0 and not ForceField then
                local TargetPosition = HitPart.Position
                local DistanceToTarget = (LocalPosition - TargetPosition).Magnitude

                -- Vérifier si la cible est à moins de 200 studs
                if DistanceToTarget <= ForceHitModule.MaxDistance then
                    local ScreenPosition, Visible = workspace.CurrentCamera:WorldToScreenPoint(HitPart.Position)
                    if Visible then
                        local Distance = (MousePosition - Vector2.new(ScreenPosition.X, ScreenPosition.Y)).Magnitude
                        if Distance <= 400 and (not ClosestDistance or Distance < ClosestDistance) then
                            ClosestDistance, ClosestPart, ClosestCharacter = Distance, HitPart, Character
                        end
                    end
                end
            end
        end
    end
    return ClosestPart, ClosestCharacter
end

-- Gestion du Highlight
local function UpdateHighlight()
    if not ForceHitModule.Enabled then
        Highlight.Enabled = false
        return
    end

    local character = ForceHitModule.SelectedPlayer and ForceHitModule.SelectedPlayer.Character
    if character then
        Highlight.Adornee = character
        Highlight.Enabled = true
    else
        Highlight.Enabled = false
    end
end

-- Mettre à jour la cible (HitPart) après un respawn/reset
local function UpdateTargetAfterRespawn()
    if not ForceHitModule.SelectedPlayer then return end

    local player = ForceHitModule.SelectedPlayer
    if player.Character then
        local newHitPart = player.Character:FindFirstChild(ForceHitModule.HitPart)
        if newHitPart then
            ForceHitModule.SelectedTarget = newHitPart
            UpdateHighlight()
        end
    end

    -- Surveiller les futurs respawns
    ForceHitModule.Connections["CharacterAdded_" .. player.Name] = player.CharacterAdded:Connect(function(newCharacter)
        if not ForceHitModule.Enabled or not ForceHitModule.SelectedPlayer then return end
        local newHitPart = newCharacter:WaitForChild(ForceHitModule.HitPart, 5)
        if newHitPart then
            ForceHitModule.SelectedTarget = newHitPart
            UpdateHighlight()
        end
    end)
end

-- Connexion pour mettre à jour la cible si elle n'est pas verrouillée
ForceHitModule.Connections["FindTarget"] = RunService.Heartbeat:Connect(function()
    if not ForceHitModule.Enabled or ForceHitModule.SelectedPlayer then return end
    local ClosestPart, ClosestCharacter = GetClosestPlayer()
    ForceHitModule.CachedClosestPlayer = ClosestPart
end)

-- Connexion pour mettre à jour le Highlight
ForceHitModule.Connections["UpdateHighlight"] = RunService.RenderStepped:Connect(UpdateHighlight)

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
        local AimPart = ForceHitModule.SelectedTarget or ForceHitModule.CachedClosestPlayer
        if AimPart then
            -- Vérifier la distance entre le joueur local et la cible
            local LocalCharacter = LocalPlayer.Character
            local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position
            local TargetPosition = AimPart.Position
            local DistanceToTarget = LocalPosition and TargetPosition and (LocalPosition - TargetPosition).Magnitude or math.huge

            if DistanceToTarget <= ForceHitModule.MaxDistance then
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

    local AimPart = ForceHitModule.SelectedTarget or ForceHitModule.CachedClosestPlayer
    local AimChar = AimPart and AimPart.Parent
    if AimChar then
        local ForceField = AimChar:FindFirstChildOfClass("ForceField")
        if not ForceField then
            -- Vérifier la distance pour BlankShots
            local LocalCharacter = LocalPlayer.Character
            local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position
            local TargetPosition = AimPart.Position
            local DistanceToTarget = LocalPosition and TargetPosition and (LocalPosition - TargetPosition).Magnitude or math.huge

            if DistanceToTarget <= ForceHitModule.MaxDistance then
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
    end
end)

-- Fonctions du module
function ForceHitModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    -- Sélectionner une cible si aucun joueur n'est verrouillé
    if not self.SelectedPlayer then
        local ClosestPart, ClosestCharacter = GetClosestPlayer()
        if ClosestCharacter then
            self.SelectedPlayer = Players:GetPlayerFromCharacter(ClosestCharacter)
            self.SelectedTarget = ClosestPart
            UpdateTargetAfterRespawn()
        end
    elseif self.SelectedPlayer and self.SelectedPlayer.Character then
        -- Si le joueur est déjà sélectionné, mettre à jour la cible
        local newHitPart = self.SelectedPlayer.Character:FindFirstChild(self.HitPart)
        if newHitPart then
            self.SelectedTarget = newHitPart
            UpdateTargetAfterRespawn()
        end
    end
end

function ForceHitModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    self.SelectedPlayer = nil -- Réinitialiser le joueur verrouillé
    self.SelectedTarget = nil -- Réinitialiser la cible
    self.CachedClosestPlayer = nil
    Highlight.Enabled = false
end

function ForceHitModule:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
    return self.Enabled
end

function ForceHitModule:IsEnabled()
    return self.Enabled
end

function ForceHitModule:Cleanup()
    self:Disable()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    Highlight:Destroy()
end

return ForceHitModule

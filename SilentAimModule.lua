local SilentAimModule = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

SilentAimModule.SilentAimTarget = nil 
local SilentAimEnabled = false
local SilentAimClosestPart = nil
local SilentAimLockedTarget = nil
local characterAddedConnections = {}
local originalIndex = nil 

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

local function cleanHighlightsAndTracers(plr)
    if plr and plr.Character then
        for _, obj in pairs(plr.Character:GetChildren()) do
            if obj:IsA("Highlight") or obj:IsA("Beam") then
                obj:Destroy()
            end
        end
    end
end

local function highlightSilentAimTarget(plr)
    if plr and plr.Character then
        cleanHighlightsAndTracers(plr)
        local highlight = Instance.new("Highlight")
        highlight.Parent = plr.Character
        highlight.FillColor = Color3.new(255, 0, 0)
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
    end
end

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
    tracer.Color = ColorSequence.new(Color3.new(255, 0, 0))
    tracer.Width0 = 0.1
    tracer.Width1 = 0.1
    local attachment0 = Instance.new("Attachment", LocalPlayer.Character.HumanoidRootPart)
    local attachment1 = Instance.new("Attachment", plr.Character.HumanoidRootPart)
    tracer.Attachment0 = attachment0
    tracer.Attachment1 = attachment1
    print("Silent Aim: Tracer créé pour " .. plr.Name)
end

function SilentAimModule:Enable()
    if SilentAimEnabled then
        print("Silent Aim: Déjà activé")
        return
    end

    SilentAimEnabled = true
    print("Silent Aim activé")

    local mt = getrawmetatable(game)
    originalIndex = mt.__index
    setreadonly(mt, false)

    local PredictionValue = getgenv().Rake.Settings.Prediction or 0.04

    originalIndex = hookmetamethod(game, "__index", function(self, key)
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

function SilentAimModule:Disable()
    if not SilentAimEnabled then
        print("Silent Aim: Déjà désactivé")
        return
    end

    SilentAimEnabled = false
    print("Silent Aim désactivé")

    local mt = getrawmetatable(game)
    if originalIndex then
        mt.__index = originalIndex
        setreadonly(mt, true)
        originalIndex = nil
    end

    if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character then
        cleanHighlightsAndTracers(SilentAimModule.SilentAimTarget)
    end
    for _, connection in pairs(characterAddedConnections) do
        connection:Disconnect()
    end
    characterAddedConnections = {}
    SilentAimModule.SilentAimTarget = nil
    SilentAimClosestPart = nil
    SilentAimLockedTarget = nil
end

function SilentAimModule:ToggleTarget()
    if not SilentAimEnabled then
        print("Silent Aim: Turn on the silent aim on an target 🥀")
        return
    end

    if SilentAimModule.SilentAimTarget then
        print("Silent Aim: Target disabled")
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
            print("Silent Aim: Target Selected - " .. SilentAimModule.SilentAimTarget.Name)
            highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
            createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)
      
            local characterAddedConnection = SilentAimModule.SilentAimTarget.CharacterAdded:Connect(function(newCharacter)
                print("Silent Aim: Target " .. SilentAimModule.SilentAimTarget.Name .. " a respawné/reset")
                task.wait(0.1)
                if SilentAimModule.SilentAimTarget == SilentAimLockedTarget and SilentAimEnabled then
                    SilentAimModule.SilentAimTarget, SilentAimClosestPart = SilentAimLockedTarget, newCharacter:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
                    if SilentAimModule.SilentAimTarget and SilentAimClosestPart then
                        print("Silent Aim: Reprise du ciblage pour " .. SilentAimModule.SilentAimTarget.Name .. " After respawn/reset")
                        highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
                        createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)
                    end
                end
            end)
            characterAddedConnections[SilentAimModule.SilentAimTarget] = characterAddedConnection
        else
            print("Silent Aim: No Target Fund")
        end
    end
end

return SilentAimModule

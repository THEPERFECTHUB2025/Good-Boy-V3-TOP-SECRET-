local SilentAimModule = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables internes (rendues publiques pour SilentAimTarget)
SilentAimModule.SilentAimTarget = nil -- Current Silent Aim target
local SilentAimEnabled = false
local SilentAimClosestPart = nil
local SilentAimLockedTarget = nil
local characterAddedConnections = {}
local localPlayerCharacterAddedConnection = nil -- To handle LocalPlayer respawn
local originalIndex = nil -- To store the original method
local lastHookTime = 0 -- Track the last hook call to limit frequency
local hookCooldown = 0.01 -- Minimum delay between hook calls (in seconds)

-- Function to find the nearest enemy based on mouse position (made public)
function SilentAimModule:findNearestEnemyForSilentAim()
    if SilentAimLockedTarget and SilentAimLockedTarget.Character and SilentAimLockedTarget.Character:FindFirstChild("Humanoid") then
        local humanoid = SilentAimLockedTarget.Character.Humanoid
        if humanoid.Health > 0 then
            return SilentAimLockedTarget, SilentAimLockedTarget.Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
        else
            print("Silent Aim: Target", SilentAimLockedTarget.Name, "is dead - Searching for a new target")
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
        print("Silent Aim: Target found:", ClosestPlayer.Name)
    end

    return ClosestPlayer, ClosestPart
end

-- Function to clean up existing highlights and tracers
local function cleanHighlightsAndTracers(plr)
    if plr and plr.Character then
        for _, obj in pairs(plr.Character:GetChildren()) do
            if obj:IsA("Highlight") or obj:IsA("Beam") then
                obj:Destroy()
            end
        end
    end
end

-- Function to add a highlight to the target
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

-- Function to create a tracer to the target
local function createTracerSilentAimTarget(plr)
    if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
        print("Silent Aim: Cannot create tracer - Invalid target or missing HumanoidRootPart")
        return
    end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("Silent Aim: Cannot create tracer - LocalPlayer invalid or missing HumanoidRootPart")
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
    print("Silent Aim: Tracer created for " .. plr.Name)
end

-- Function to enable Silent Aim
function SilentAimModule:Enable()
    if SilentAimEnabled then
        print("Silent Aim: Already enabled")
        return
    end

    SilentAimEnabled = true
    print("Silent Aim enabled")

    -- Hook to redirect shots
    local mt = getrawmetatable(game)
    originalIndex = mt.__index
    setreadonly(mt, false)

    local PredictionValue = getgenv().Rake.Settings.Prediction or 0.04

    originalIndex = hookmetamethod(game, "__index", function(self, key)
        -- Safeguard: limit the frequency of calls to avoid stack overflows
        local currentTime = tick()
        if currentTime - lastHookTime < hookCooldown then
            return originalIndex(self, key)
        end
        lastHookTime = currentTime

        -- Check to redirect shots
        if not checkcaller() and SilentAimEnabled and SilentAimModule.SilentAimTarget and self:IsA("Mouse") and key == "Hit" then
            if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character and SilentAimModule.SilentAimTarget.Character:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head") then
                local target = SilentAimModule.SilentAimTarget.Character[getgenv().Rake.Settings.AimPart or "Head"]
                local Position = target.Position + (SilentAimModule.SilentAimTarget.Character.Head.Velocity * PredictionValue)
                return CFrame.new(Position)
            end
        end
        return originalIndex(self, key)
    end)

    -- Handle LocalPlayer respawn to recreate the tracer
    if localPlayerCharacterAddedConnection then
        localPlayerCharacterAddedConnection:Disconnect()
    end
    localPlayerCharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        print("Silent Aim: LocalPlayer respawned/reset")
        task.wait(0.1) -- Wait for the new character to fully load
        if SilentAimEnabled and SilentAimModule.SilentAimTarget then
            print("Silent Aim: Recreating tracer for " .. SilentAimModule.SilentAimTarget.Name .. " after LocalPlayer respawn")
            highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
            createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)
        end
    end)
end

-- Function to disable Silent Aim
function SilentAimModule:Disable()
    if not SilentAimEnabled then
        print("Silent Aim: Already disabled")
        return
    end

    SilentAimEnabled = false
    print("Silent Aim disabled")

    -- Restore the original hook
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    if originalIndex then
        mt.__index = originalIndex
        originalIndex = nil
    end
    setreadonly(mt, true)

    -- Clean up highlights and tracers
    if SilentAimModule.SilentAimTarget and SilentAimModule.SilentAimTarget.Character then
        cleanHighlightsAndTracers(SilentAimModule.SilentAimTarget)
    end

    -- Clean up CharacterAdded connections
    for _, connection in pairs(characterAddedConnections) do
        connection:Disconnect()
    end
    characterAddedConnections = {}

    -- Clean up LocalPlayer CharacterAdded connection
    if localPlayerCharacterAddedConnection then
        localPlayerCharacterAddedConnection:Disconnect()
        localPlayerCharacterAddedConnection = nil
    end

    SilentAimModule.SilentAimTarget = nil
    SilentAimClosestPart = nil
    SilentAimLockedTarget = nil
end

-- Function to toggle targeting (called by the keybind)
function SilentAimModule:ToggleTarget()
    if not SilentAimEnabled then
        print("Silent Aim: Please enable Silent Aim before selecting a target")
        return
    end

    if SilentAimModule.SilentAimTarget then
        print("Silent Aim: Targeting disabled")
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
            print("Silent Aim: Target selected - " .. SilentAimModule.SilentAimTarget.Name)
            highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
            createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)

            -- Handle target respawn/reset
            if characterAddedConnections[SilentAimModule.SilentAimTarget] then
                characterAddedConnections[SilentAimModule.SilentAimTarget]:Disconnect()
            end
            local characterAddedConnection = SilentAimModule.SilentAimTarget.CharacterAdded:Connect(function(newCharacter)
                print("Silent Aim: Target " .. SilentAimModule.SilentAimTarget.Name .. " respawned/reset")
                task.wait(0.1) -- Wait for the new character to fully load
                if SilentAimModule.SilentAimTarget and SilentAimEnabled then
                    -- Update the closest part after respawn
                    SilentAimClosestPart = newCharacter:FindFirstChild(getgenv().Rake.Settings.AimPart or "Head")
                    if SilentAimClosestPart then
                        print("Silent Aim: Resuming targeting for " .. SilentAimModule.SilentAimTarget.Name .. " after respawn/reset")
                        highlightSilentAimTarget(SilentAimModule.SilentAimTarget)
                        createTracerSilentAimTarget(SilentAimModule.SilentAimTarget)
                    else
                        print("Silent Aim: Could not find aim part for " .. SilentAimModule.SilentAimTarget.Name .. " after respawn/reset")
                    end
                end
            end)
            characterAddedConnections[SilentAimModule.SilentAimTarget] = characterAddedConnection
        else
            print("Silent Aim: No target found")
        end
    end
end

return SilentAimModule

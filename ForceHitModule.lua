-- ForceHitModule.lua

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera
local MainEvent = ReplicatedStorage:FindFirstChild("MainEvent")

-- Variables
-- ForceHitModule.lua

-- Add Whitelist to the ForceHitModule table
local ForceHitModule = {
    Enabled = false,
    ManuallyEnabled = false,
    AutoTargetAll = false,
    UIMobileSupportEnabled = false,
    WallCheckEnabled = true,
    KillAllEnabled = false,
    AutoStompEnabled = false,
    TargetStrafeEnabled = false,
    BlankShots = true,
    HitPart = "Head",
    SelectedTarget = nil,
    TargetPlayer = nil,
    Connections = {},
    ForceHitButton = nil,
    ButtonPosition = UDim2.new(0.5, -50, 0.5, -25),
    LastKillAllTime = 0,
    LastTargetSwitchTime = 0,
    StrafeAngle = 0,
    Tracer = nil,
    Attachment0 = nil,
    Attachment1 = nil,
    TargetInfoUI = nil,
    HitSound = nil,
    SavedPosition = nil,
    LastAmmoValue = nil,
    Whitelist = {}, -- Add Whitelist table to store whitelisted players
}

-- Helper function to check if a player is whitelisted
local function IsPlayerWhitelisted(player)
    if not ForceHitModule.Whitelist then return false end
    for _, whitelistedPlayer in ipairs(ForceHitModule.Whitelist) do
        if whitelistedPlayer == player then
            return true
        end
    end
    return false
end

-- Modify GetClosestPlayer to exclude whitelisted players
local function GetClosestPlayerByDistance(minHealth, maxRadius, checkVisibility)
    local ClosestDistance = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil
    local LocalCharacter = LocalPlayer.Character
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position

    if not LocalPosition then return nil, nil, nil end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and not IsPlayerWhitelisted(Player) then -- Exclude whitelisted players
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(ForceHitModule.HitPart)
                local ForceField = Character:FindFirstChildOfClass("ForceField")
                if Part and not ForceField then
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if Humanoid and (not minHealth or Humanoid.Health >= minHealth) then
                        local Distance = (LocalPosition - Part.Position).Magnitude
                        if (not maxRadius or Distance <= maxRadius) and Distance < ClosestDistance then
                            if checkVisibility then
                                if not IsTargetBehindWall(LocalPosition, Part.Position) then
                                    ClosestDistance = Distance
                                    ClosestPlayer = Player
                                    ClosestPart = Part
                                    ClosestCharacter = Character
                                end
                            else
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
    end
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

-- Modify GetClosestPlayerByDistance to exclude whitelisted players
local function GetClosestPlayerByDistance(minHealth, maxRadius, checkVisibility)
    local ClosestDistance = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil
    local LocalCharacter = LocalPlayer.Character
    local LocalPosition = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart") and LocalCharacter.HumanoidRootPart.Position

    if not LocalPosition then return nil, nil, nil end

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and not IsPlayerWhitelisted(Player) then -- Exclude whitelisted players
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(ForceHitModule.HitPart)
                local ForceField = Character:FindFirstChildOfClass("ForceField")
                if Part and not ForceField then
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    if Humanoid and (not minHealth or Humanoid.Health >= minHealth) then
                        local Distance = (LocalPosition - Part.Position).Magnitude
                        if (not maxRadius or Distance <= maxRadius) and Distance < ClosestDistance then
                            if checkVisibility then
                                if not IsTargetBehindWall(LocalPosition, Part.Position) then
                                    ClosestDistance = Distance
                                    ClosestPlayer = Player
                                    ClosestPart = Part
                                    ClosestCharacter = Character
                                end
                            else
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
    end
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

-- Modify UpdateTargetAndHighlight to respect the whitelist
local function UpdateTargetAndHighlight()
    if not ForceHitModule.ManuallyEnabled then
        ForceHitModule.Enabled = false
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
        ForceHitModule.SelectedTarget = nil
        UpdateTracer()
        ForceHitModule:UpdateTargetInfoUI()
        return
    end

    if ForceHitModule.TargetPlayer then
        -- Check if the current target is whitelisted
        if IsPlayerWhitelisted(ForceHitModule.TargetPlayer) then
            ForceHitModule.TargetPlayer = nil
            ForceHitModule.SelectedTarget = nil
            -- Find a new non-whitelisted target
            local ClosestPart, ClosestCharacter, ClosestPlayer = GetClosestPlayer()
            ForceHitModule.SelectedTarget = ClosestPart
            ForceHitModule.TargetPlayer = ClosestPlayer
        end

        local character = ForceHitModule.TargetPlayer and ForceHitModule.TargetPlayer.Character
        if character then
            local hitPart = character:FindFirstChild(ForceHitModule.HitPart)
            local humanoid = character:FindFirstChild("Humanoid")
            local forceField = character:FindFirstChildOfClass("ForceField")
            if hitPart and humanoid and humanoid.Health > 0 and not forceField then
                ForceHitModule.SelectedTarget = hitPart

                local health = humanoid.Health
                if health >= 0.5 and health <= 20 then
                    if ForceHitModule.Enabled then
                        ForceHitModule.Enabled = false
                    end
                elseif health > 20 then
                    if not ForceHitModule.Enabled then
                        ForceHitModule.Enabled = true
                    end
                end

                -- AutoTargetAll logic: Switch target every 0.5 seconds, exclude whitelisted players
                if ForceHitModule.AutoTargetAll then
                    local currentTime = os.clock()
                    if currentTime - ForceHitModule.LastTargetSwitchTime >= 0.5 then
                        ForceHitModule.LastTargetSwitchTime = currentTime
                        local maxRadius = 714.2 -- 200 meters ≈ 714.2 studs
                        local newPart, newCharacter, newPlayer = GetClosestPlayerByDistance(20, maxRadius, true)
                        if newPlayer and newPlayer ~= ForceHitModule.TargetPlayer then
                            ForceHitModule.TargetPlayer = newPlayer
                            ForceHitModule.SelectedTarget = newPart
                        end
                    end
                end

                local localCharacter = LocalPlayer.Character
                local localPosition = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position
                if localPosition and hitPart then
                    local distance = (localPosition - hitPart.Position).Magnitude
                    if distance > 200 then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    elseif distance <= 200 then
                        if not ForceHitModule.Enabled and health > 20 then
                            ForceHitModule.Enabled = true
                        end
                    end

                    local targetPosition = hitPart.Position
                    if ForceHitModule.WallCheckEnabled and IsTargetBehindWall(localPosition, targetPosition) then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    else
                        if not ForceHitModule.Enabled and health > 20 and distance <= 200 then
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

    if not ForceHitModule.Enabled then
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
    end

    local target, character = ForceHitModule.SelectedTarget, nil
    if target and target.Parent then
        character = target.Parent
    end
    if character and ForceHitModule.Highlight then
        ForceHitModule.Highlight.Adornee = character
        ForceHitModule.Highlight.Enabled = true
    else
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
    end

    UpdateTracer()
    ForceHitModule:UpdateTargetInfoUI()
end

-- Modify KillAll to exclude whitelisted players (already handled by GetClosestPlayerByDistance)

-- Modify TargetStrafe to exclude whitelisted players
ForceHitModule.Connections["TargetStrafe"] = RunService.Heartbeat:Connect(function(deltaTime)
    if not ForceHitModule.TargetStrafeEnabled or not ForceHitModule.Enabled or not ForceHitModule.TargetPlayer then return end

    -- Check if the target is whitelisted
    if IsPlayerWhitelisted(ForceHitModule.TargetPlayer) then
        ForceHitModule.TargetStrafeEnabled = false
        ForceHitModule.TargetPlayer = nil
        ForceHitModule.SelectedTarget = nil
        return
    end

    local targetCharacter = ForceHitModule.TargetPlayer.Character
    local humanoid = targetCharacter and targetCharacter:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health < 20 then return end

    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

    if not localRootPart or not targetRootPart then return end

    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    if distance > 100000 then
        return
    end

    if IsTargetInVoid(targetRootPart.Position) then return end

    local radius = 5
    local speed = 5
    ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle + (speed * deltaTime)
    if ForceHitModule.StrafeAngle > 2 * math.pi then
        ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle - 2 * math.pi
    end

    local offset = Vector3.new(math.cos(ForceHitModule.StrafeAngle) * radius, 0, math.sin(ForceHitModule.StrafeAngle) * radius)
    local newPosition = targetRootPart.Position + offset

    localRootPart.CFrame = CFrame.new(newPosition, targetRootPart.Position)
    localRootPart.CFrame = localRootPart.CFrame + Vector3.new(0, targetRootPart.Position.Y - localRootPart.Position.Y, 0)
end)

-- Modify AutoStomp to exclude whitelisted players
ForceHitModule.Connections["AutoStomp"] = RunService.Stepped:Connect(function(time, step)
    if not ForceHitModule.AutoStompEnabled then return end
    -- Only stomp if the target is not whitelisted
    if ForceHitModule.TargetPlayer and not IsPlayerWhitelisted(ForceHitModule.TargetPlayer) then
        ReplicatedStorage.MainEvent:FireServer("Stomp")
    end
end)

-- Modify BlankShots to exclude whitelisted players
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
        local targetPlayer = Players:GetPlayerFromCharacter(AimChar)
        if targetPlayer and IsPlayerWhitelisted(targetPlayer) then return end -- Skip if whitelisted

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

-- Update the Cleanup function to clear the whitelist
function ForceHitModule:Cleanup()
    self:Disable()
    if self.ForceHitButton then
        self.ForceHitButton:Destroy()
        self.ForceHitButton = nil
    end
    if self.TargetInfoUI then
        self.TargetInfoUI.ScreenGui:Destroy()
        self.TargetInfoUI = nil
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    if self.Highlight then
        self.Highlight:Destroy()
        self.Highlight = nil
    end
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
    if self.HitSound then
        self.HitSound:Destroy()
        self.HitSound = nil
    end
    self.SavedPosition = nil
    self.Whitelist = {} -- Clear the whitelist on cleanup
end
-- Helper function to check if a player is whitelisted
local function IsPlayerWhitelisted(player)
    if not ForceHitModule.Whitelist then return false end
    for _, whitelistedPlayer in ipairs(ForceHitModule.Whitelist) do
        if whitelistedPlayer == player then
            return true
        end
    end
    return false
end
-- The rest of the ForceHitModule.lua remains unchanged

-- Liste des armes
local WeaponsList = {
    "[DoubleBarrel]",
    "[Revolver]",
    "[SMG]",
    "[Shotgun]",
    "[Silencer]",
    "[TacticalShotgun]"
}

-- Default ammo values for each weapon
local DefaultAmmoValues = {
    ["[Revolver]"] = 6,
    ["[DoubleBarrel]"] = 2,
    ["[SMG]"] = 20,
    ["[Shotgun]"] = 2,
    ["[Silencer]"] = 12,
    ["[TacticalShotgun]"] = 5
}

-- Initialize Highlight for the target
local function InitializeHighlight()
    if not ForceHitModule.Highlight or not ForceHitModule.Highlight.Parent then
        local highlight = Instance.new("Highlight")
        highlight.Parent = game.CoreGui
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.Enabled = false
        ForceHitModule.Highlight = highlight
    end
end

-- Call InitializeHighlight at the start
InitializeHighlight()

-- Création du son pour le hit
local hitSound = Instance.new("Sound")
hitSound.SoundId = "rbxassetid://110168723447153"
hitSound.Volume = 1
hitSound.Parent = LocalPlayer
ForceHitModule.HitSound = hitSound

-- Créer l'UI pour le bouton draggable
local function CreateForceHitButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ForceHitUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 120, 0, 60)
    frame.Position = ForceHitModule.ButtonPosition
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.Transparency = 0.5
    stroke.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = "ForceHit: OFF"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.SourceSansBold
    button.Parent = frame

    local function UpdateButtonText()
        button.Text = "ForceHit: " .. (ForceHitModule.ManuallyEnabled and "ON" or "OFF")
        frame.BackgroundColor3 = ForceHitModule.ManuallyEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(50, 50, 50)
    end

    button.MouseButton1Click:Connect(function()
        if not getgenv().Rake.Settings.Misc.ForceHitEnabled then
            return
        end

        local newValue = ForceHitModule:Toggle()
        UpdateButtonText()
    end)

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
            ForceHitModule.ButtonPosition = frame.Position
        end
    end)

    UpdateButtonText()
    ForceHitModule.ForceHitButton = screenGui
end

-- Créer l'UI pour les informations sur la cible
local function CreateTargetInfoUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TargetInfoUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 180)
    frame.Position = UDim2.new(0, 10, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local function adjustPositionForScreen()
        local viewportSize = Camera.ViewportSize
        if viewportSize.X < 600 then
            frame.Size = UDim2.new(0, 250, 0, 150)
            frame.Position = UDim2.new(0, 5, 0.5, -75)
        else
            frame.Size = UDim2.new(0, 300, 0, 180)
            frame.Position = UDim2.new(0, 10, 0.5, -90)
        end
    end
    adjustPositionForScreen()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustPositionForScreen)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 50, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 150))
    })
    gradient.Rotation = 45
    gradient.Parent = frame

    local function rotateGradient()
        while true do
            local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(gradient, tweenInfo, {Rotation = gradient.Rotation + 360})
            tween:Play()
            tween.Completed:Wait()
        end
    end
    spawn(rotateGradient)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 4
    stroke.Color = Color3.fromRGB(0, 255, 255)
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

    local function rotateStrokeGradient()
        while true do
            local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(strokeGradient, tweenInfo, {Rotation = strokeGradient.Rotation + 360})
            tween:Play()
            tween.Completed:Wait()
        end
    end
    spawn(rotateStrokeGradient)

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

    local shadow = Instance.new("UIStroke")
    shadow.Thickness = 8
    shadow.Color = Color3.fromRGB(0, 255, 255)
    shadow.Transparency = 0.3
    shadow.Parent = frame

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

    local radialFrame = Instance.new("Frame")
    radialFrame.Size = UDim2.new(1, 0, 1, 0)
    radialFrame.BackgroundTransparency = 1
    radialFrame.Parent = frame

    local function createRadialScan()
        local radial = Instance.new("Frame")
        radial.Size = UDim2.new(0, 0, 0, 0)
        radial.Position = UDim2.new(0, 22, 0, 72)
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

    local connectionFrame = Instance.new("Frame")
    connectionFrame.Size = UDim2.new(1, 0, 1, 0)
    connectionFrame.BackgroundTransparency = 1
    connectionFrame.Parent = frame

    local function createConnectionParticle()
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, 3, 0, 3)
        particle.Position = UDim2.new(0, 35, 0, 75)
        particle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        particle.BackgroundTransparency = 0.5
        particle.Parent = connectionFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
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
            wait(0.3)
        end
    end
    spawn(spawnConnectionParticles)

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
            wait(math.random(1, 3))
        end
    end
    spawn(spawnGlitchLines)

    local function shakeEffect()
        while true do
            local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            local offsetX = math.random(-2, 2)
            local offsetY = math.random(-2, 2)
            local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0, 10 + offsetX, 0.5, -90 + offsetY)})
            tween:Play()
            wait(math.random(2, 4))
        end
    end
    spawn(shakeEffect)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Indicator"
    titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.SciFi
    titleLabel.Parent = frame

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

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(1, 0, 0, 20)
    infoLabel.Position = UDim2.new(0, 0, 0, 30)
    infoLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    infoLabel.BackgroundTransparency = 0.5
    infoLabel.Text = "INFO"
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextScaled = true
    infoLabel.Font = Enum.Font.Code
    infoLabel.Parent = frame

    local scanLine = Instance.new("Frame")
    scanLine.Size = UDim2.new(1, 0, 0, 2)
    scanLine.Position = UDim2.new(0, 0, 0, 30)
    scanLine.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    scanLine.BackgroundTransparency = 0.5
    scanLine.Parent = frame

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

    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, 10, 0, 50)
    iconFrame.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    iconFrame.BackgroundTransparency = 0.6
    iconFrame.Parent = frame

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = iconFrame

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 46, 0, 46)
    icon.Position = UDim2.new(0, 2, 0, 2)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    icon.Parent = iconFrame

    local iconInnerCorner = Instance.new("UICorner")
    iconInnerCorner.CornerRadius = UDim.new(1, 0)
    iconInnerCorner.Parent = icon

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

    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(0, 220, 0, 25)
    weaponLabel.Position = UDim2.new(0, 70, 0, 100)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = ""
    weaponLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    weaponLabel.TextScaled = true
    weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
    weaponLabel.Font = Enum.Font.Code
    weaponLabel.Parent = frame

    local function glitchWeaponEffect()
        while true do
            weaponLabel.TextTransparency = 0.2
            weaponLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 100)
            wait(0.05)
            weaponLabel.TextTransparency = 0
            weaponLabel.Position = UDim2.new(0, 70, 0, 100)
            wait(0.05)
            weaponLabel.TextTransparency = 0.3
            weaponLabel.Position = UDim2.new(0, 70 + math.random(-1, 1), 0, 100)
            wait(0.05)
            weaponLabel.TextTransparency = 0
            weaponLabel.Position = UDim2.new(0, 70, 0, 100)
            wait(math.random(2, 4))
        end
    end
    spawn(glitchWeaponEffect)

    ForceHitModule.TargetInfoUI = {
        ScreenGui = screenGui,
        Frame = frame,
        Icon = icon,
        NameLabel = nameLabel,
        HealthLabel = healthLabel,
        DistanceLabel = distanceLabel,
        WeaponLabel = weaponLabel
    }

    frame.Visible = false
end

local function GetEquippedWeapon(character)
    if not character then return nil end
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            for _, weapon in pairs(WeaponsList) do
                if child.Name == weapon then
                    return weapon
                end
            end
        end
    end
    return nil
end

-- Function to get the ammo count for the equipped weapon
local function GetEquippedWeaponAmmo(targetPlayer, equippedWeapon)
    if not targetPlayer or not equippedWeapon then return nil end

    -- Check if the weapon is equipped in the character's hands
    local character = targetPlayer.Character
    local equippedTool = character and character:FindFirstChild(equippedWeapon)
    if equippedTool then
        local script = equippedTool:FindFirstChild("Script")
        local ammo = script and script:FindFirstChild("Ammo")
        if ammo and ammo:IsA("IntValue") then
            return ammo.Value
        end
    end

    -- If not equipped, check in the backpack
    local backpack = targetPlayer:FindFirstChild("Backpack")
    if backpack then
        local weapon = backpack:FindFirstChild(equippedWeapon)
        if weapon then
            local script = weapon:FindFirstChild("Script")
            local ammo = script and script:FindFirstChild("Ammo")
            if ammo and ammo:IsA("IntValue") then
                return ammo.Value
            end
        end
    end

    -- Fallback to default ammo value if not found
    return DefaultAmmoValues[equippedWeapon]
end

function ForceHitModule:UpdateTargetInfoUI()
    if not self.TargetInfoUI then
        CreateTargetInfoUI()
    end

    local ui = self.TargetInfoUI
    if not getgenv().Rake.Settings.Misc.TargetInfoEnabled or not self.ManuallyEnabled or not self.TargetPlayer then
        if ui.Frame.Visible then
            ui.Frame.Visible = true
            local particleFrame = Instance.new("Frame")
            particleFrame.Size = UDim2.new(1, 0, 1, 0)
            particleFrame.BackgroundTransparency = 1
            particleFrame.Parent = ui.Frame

            local function createExplosionParticle()
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, 5, 0, 5)
                particle.Position = UDim2.new(0.5, 0, 0.5, 0)
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
                ui.Frame.Size = Camera.ViewportSize.X < 600 and UDim2.new(0, 250, 0, 150) or UDim2.new(0, 300, 0, 180)
                particleFrame:Destroy()
            end)
        end
        return
    end

    local targetPlayer = self.TargetPlayer
    local character = targetPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local targetRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

    if not humanoid or not targetRootPart or not localRootPart then
        if ui.Frame.Visible then
            ui.Frame.Visible = true
            local particleFrame = Instance.new("Frame")
            particleFrame.Size = UDim2.new(1, 0, 1, 0)
            particleFrame.BackgroundTransparency = 1
            particleFrame.Parent = ui.Frame

            local function createExplosionParticle()
                local particle = Instance.new("Frame")
                particle.Size = UDim2.new(0, 5, 0, 5)
                particle.Position = UDim2.new(0.5, 0, 0.5, 0)
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
                ui.Frame.Size = Camera.ViewportSize.X < 600 and UDim2.new(0, 250, 0, 150) or UDim2.new(0, 300, 0, 180)
                particleFrame:Destroy()
            end)
        end
        return
    end

    local userId = targetPlayer.UserId
    ui.Icon.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=48&h=48"

    ui.NameLabel.Text = targetPlayer.Name .. " (@" .. targetPlayer.DisplayName .. ")"

    local health = math.floor(humanoid.Health)
    local maxHealth = math.floor(humanoid.MaxHealth)
    ui.HealthLabel.Text = health .. "/" .. maxHealth
    if health > maxHealth * 0.5 then
        ui.HealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif health > maxHealth * 0.25 then
        ui.HealthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        ui.HealthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    ui.DistanceLabel.Text = math.floor(distance) .. " studs"
    if distance <= 50 then
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    elseif distance <= 100 then
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    else
        ui.DistanceLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    end

    -- Update weapon and ammo display (this will be updated in the loop as well)
    local equippedWeapon = GetEquippedWeapon(character)
    local ammoCount = equippedWeapon and GetEquippedWeaponAmmo(targetPlayer, equippedWeapon) or nil
    if equippedWeapon and ammoCount then
        ui.WeaponLabel.Text = equippedWeapon .. " - Ammo: " .. ammoCount
    else
        ui.WeaponLabel.Text = equippedWeapon or "None"
    end

    if health <= maxHealth * 0.25 and ui.Frame.Visible then
        local pulseSpeed = 0.3
        local tweenInfo = TweenInfo.new(pulseSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween1 = TweenService:Create(ui.Frame, tweenInfo, {Size = Camera.ViewportSize.X < 600 and UDim2.new(0, 260, 0, 155) or UDim2.new(0, 310, 0, 185)})
        local tween2 = TweenService:Create(ui.Frame, tweenInfo, {Size = Camera.ViewportSize.X < 600 and UDim2.new(0, 250, 0, 150) or UDim2.new(0, 300, 0, 180)})
        tween1:Play()
        tween1.Completed:Connect(function()
            tween2:Play()
        end)

        local glitchFrame = ui.Frame:FindFirstChild("GlitchFrame") or Instance.new("Frame")
        glitchFrame.Name = "GlitchFrame"
        glitchFrame.Size = UDim2.new(1, 0, 1, 0)
        glitchFrame.BackgroundTransparency = 1
        glitchFrame.Parent = ui.Frame

        local function createIntenseGlitchLine()
            local glitchLine = Instance.new("Frame")
            glitchLine.Size = UDim2.new(1, 0, 0, 2)
            glitchLine.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
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
        local tween = TweenService:Create(ui.Frame, tweenInfo, {BackgroundTransparency = 0.5, Size = Camera.ViewportSize.X < 600 and UDim2.new(0, 250, 0, 150) or UDim2.new(0, 300, 0, 180)})
        tween:Play()
        tween.Completed:Connect(function()
            particleFrame:Destroy()
        end)
    end
end

-- New function to continuously monitor the ammo value of the equipped weapon
local function MonitorTargetAmmo()
    ForceHitModule.Connections["MonitorAmmo"] = RunService.Heartbeat:Connect(function()
        if not ForceHitModule.ManuallyEnabled or not ForceHitModule.TargetPlayer or not ForceHitModule.TargetInfoUI then
            ForceHitModule.LastAmmoValue = nil
            return
        end

        local targetPlayer = ForceHitModule.TargetPlayer
        local character = targetPlayer.Character
        if not character then
            ForceHitModule.LastAmmoValue = nil
            return
        end

        local equippedWeapon = GetEquippedWeapon(character)
        if not equippedWeapon then
            ForceHitModule.LastAmmoValue = nil
            if ForceHitModule.TargetInfoUI.WeaponLabel.Text ~= "None" then
                ForceHitModule.TargetInfoUI.WeaponLabel.Text = "None"
            end
            return
        end

        local currentAmmo = GetEquippedWeaponAmmo(targetPlayer, equippedWeapon)
        if currentAmmo == nil then
            currentAmmo = DefaultAmmoValues[equippedWeapon]
        end

        -- Check if the ammo value has changed
        if ForceHitModule.LastAmmoValue ~= currentAmmo then
            ForceHitModule.LastAmmoValue = currentAmmo
            ForceHitModule.TargetInfoUI.WeaponLabel.Text = equippedWeapon .. " - Ammo: " .. currentAmmo
        end

        -- Update the weapon label if the equipped weapon changes
        local currentWeaponText = equippedWeapon .. " - Ammo: " .. currentAmmo
        if ForceHitModule.TargetInfoUI.WeaponLabel.Text ~= currentWeaponText then
            ForceHitModule.TargetInfoUI.WeaponLabel.Text = currentWeaponText
        end
    end)
end

local function SetupUIMobileSupport()
    if not ForceHitModule.UIMobileSupportEnabled then
        if ForceHitModule.ForceHitButton then
            ForceHitModule.ForceHitButton:Destroy()
            ForceHitModule.ForceHitButton = nil
        end
        return
    end

    if LocalPlayer.Character and not ForceHitModule.ForceHitButton then
        CreateForceHitButton()
    end

    LocalPlayer.CharacterAdded:Connect(function()
        if ForceHitModule.UIMobileSupportEnabled and not ForceHitModule.ForceHitButton then
            print("Player respawned, recreating ForceHit UI button")
            CreateForceHitButton()
        end
    end)
end

local function GetClosestPlayer()
    local MouseLocation = UserInputService:GetMouseLocation()
    local ClosestToMouse = math.huge
    local ClosestPlayer, ClosestPart, ClosestCharacter = nil, nil, nil

    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and not IsPlayerWhitelisted(Player) then -- Exclude whitelisted players
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

local function GetClosestPlayerByDistance(minHealth, maxRadius, checkVisibility)
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
                        if (not maxRadius or Distance <= maxRadius) and Distance < ClosestDistance then
                            if checkVisibility then
                                if not IsTargetBehindWall(LocalPosition, Part.Position) then
                                    ClosestDistance = Distance
                                    ClosestPlayer = Player
                                    ClosestPart = Part
                                    ClosestCharacter = Character
                                end
                            else
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
    end
    return ClosestPart, ClosestCharacter, ClosestPlayer
end

local function IsTargetBehindWall(localPosition, targetPosition)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, ForceHitModule.TargetPlayer and ForceHitModule.TargetPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local direction = (targetPosition - localPosition).Unit * (targetPosition - localPosition).Magnitude
    local raycastResult = workspace:Raycast(localPosition, direction, raycastParams)

    return raycastResult ~= nil
end

local function IsTargetInVoid(targetPosition)
    return targetPosition.Y < -500
end

local function UpdateTracer()
    if not ForceHitModule.ManuallyEnabled or not ForceHitModule.TargetPlayer then
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

    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then
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

    local targetCharacter = ForceHitModule.TargetPlayer.Character
    local targetHitPart = targetCharacter and targetCharacter:FindFirstChild(ForceHitModule.HitPart)
    if not targetHitPart then
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

    if not ForceHitModule.Tracer then
        local tracer = Instance.new("Beam")
        tracer.Name = "ForceHitTracer"
        tracer.Parent = workspace
        tracer.Enabled = true
        tracer.Color = ColorSequence.new(Color3.new(1, 0, 0))
        tracer.Transparency = NumberSequence.new(0)
        tracer.Width0 = 0.2
        tracer.Width1 = 0.2
        tracer.LightEmission = 1
        tracer.LightInfluence = 0

        local attachment0 = Instance.new("Attachment")
        attachment0.Parent = localRootPart
        ForceHitModule.Attachment0 = attachment0

        local attachment1 = Instance.new("Attachment")
        attachment1.Parent = targetHitPart
        ForceHitModule.Attachment1 = attachment1

        tracer.Attachment0 = attachment0
        tracer.Attachment1 = attachment1

        ForceHitModule.Tracer = tracer
    end

    if ForceHitModule.Attachment0 and ForceHitModule.Attachment0.Parent ~= localRootPart then
        ForceHitModule.Attachment0:Destroy()
        local newAttachment0 = Instance.new("Attachment")
        newAttachment0.Parent = localRootPart
        ForceHitModule.Attachment0 = newAttachment0
        ForceHitModule.Tracer.Attachment0 = newAttachment0
    end

    if ForceHitModule.Attachment1 and ForceHitModule.Attachment1.Parent ~= targetHitPart then
        ForceHitModule.Attachment1:Destroy()
        local newAttachment1 = Instance.new("Attachment")
        newAttachment1.Parent = targetHitPart
        ForceHitModule.Attachment1 = newAttachment1
        ForceHitModule.Tracer.Attachment1 = newAttachment1
    end
end

local function UpdateTargetAndHighlight()
    if not ForceHitModule.ManuallyEnabled then
        ForceHitModule.Enabled = false
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
        ForceHitModule.SelectedTarget = nil
        UpdateTracer()
        ForceHitModule:UpdateTargetInfoUI()
        return
    end

    if ForceHitModule.TargetPlayer then
        local character = ForceHitModule.TargetPlayer.Character
        if character then
            local hitPart = character:FindFirstChild(ForceHitModule.HitPart)
            local humanoid = character:FindFirstChild("Humanoid")
            local forceField = character:FindFirstChildOfClass("ForceField")
            if hitPart and humanoid and humanoid.Health > 0 and not forceField then
                ForceHitModule.SelectedTarget = hitPart

                local health = humanoid.Health
                if health >= 0.5 and health <= 20 then
                    if ForceHitModule.Enabled then
                        ForceHitModule.Enabled = false
                    end
                elseif health > 20 then
                    if not ForceHitModule.Enabled then
                        ForceHitModule.Enabled = true
                    end
                end

                -- AutoTargetAll logic: Switch target every 0.5 seconds
                if ForceHitModule.AutoTargetAll then
                    local currentTime = os.clock()
                    if currentTime - ForceHitModule.LastTargetSwitchTime >= 0.5 then
                        ForceHitModule.LastTargetSwitchTime = currentTime
                        local maxRadius = 714.2 -- 200 meters ≈ 714.2 studs
                        local newPart, newCharacter, newPlayer = GetClosestPlayerByDistance(20, maxRadius, true) -- Min 20 HP, 200m radius, check visibility
                        if newPlayer and newPlayer ~= ForceHitModule.TargetPlayer then -- Ensure we switch to a different player
                            ForceHitModule.TargetPlayer = newPlayer
                            ForceHitModule.SelectedTarget = newPart
                        end
                    end
                end

                local localCharacter = LocalPlayer.Character
                local localPosition = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position
                if localPosition and hitPart then
                    local distance = (localPosition - hitPart.Position).Magnitude
                    if distance > 200 then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    elseif distance <= 200 then
                        if not ForceHitModule.Enabled and health > 20 then
                            ForceHitModule.Enabled = true
                        end
                    end

                    local targetPosition = hitPart.Position
                    if ForceHitModule.WallCheckEnabled and IsTargetBehindWall(localPosition, targetPosition) then
                        if ForceHitModule.Enabled then
                            ForceHitModule.Enabled = false
                        end
                    else
                        if not ForceHitModule.Enabled and health > 20 and distance <= 200 then
                            ForceHitModule.Enabled = true
                        end
                    end

                    if IsTargetInVoid(targetPosition) then
                        ForceHitModule.Enabled = false
                        ForceHitModule.ManuallyEnabled = false
                        ForceHitModule.SelectedTarget = nil
                        ForceHitModule.TargetPlayer = nil
                        if ForceHitModule.Highlight then
                            ForceHitModule.Highlight.Enabled = false
                        end
                        UpdateTracer()
                        ForceHitModule:UpdateTargetInfoUI()
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

    if not ForceHitModule.Enabled then
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
    end

    local target, character = ForceHitModule.SelectedTarget, nil
    if target and target.Parent then
        character = target.Parent
    end
    if character and ForceHitModule.Highlight then
        ForceHitModule.Highlight.Adornee = character
        ForceHitModule.Highlight.Enabled = true
    else
        if ForceHitModule.Highlight then
            ForceHitModule.Highlight.Enabled = false
        end
    end

    UpdateTracer()
    ForceHitModule:UpdateTargetInfoUI()
end

local function CheckTargetAfterRespawn()
    if not ForceHitModule.TargetPlayer then return end

    local player = ForceHitModule.TargetPlayer
    player.CharacterAdded:Connect(function(newCharacter)
        if not ForceHitModule.Enabled or not ForceHitModule.TargetPlayer then return end
    end)
end

ForceHitModule.Connections["KillAll"] = RunService.Heartbeat:Connect(function()
    if not ForceHitModule.KillAllEnabled then return end

    local currentTime = os.clock()
    if currentTime - ForceHitModule.LastKillAllTime < 0.5 then return end
    ForceHitModule.LastKillAllTime = currentTime

    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRootPart then return end

    local maxRadius = 1785.5 -- 500 meters ≈ 1785.5 studs
    local closestPart, closestCharacter, closestPlayer = GetClosestPlayerByDistance(20, maxRadius, false) -- Min 20 HP, 500m radius, no visibility check
    if not closestPlayer then return end

    local targetRootPart = closestCharacter and closestCharacter:FindFirstChild("HumanoidRootPart")
    if targetRootPart and IsTargetInVoid(targetRootPart.Position) then return end

    if localRootPart and targetRootPart then
        localRootPart.CFrame = targetRootPart.CFrame * CFrame.new(0, 0, -2)
        ForceHitModule.TargetPlayer = closestPlayer
        ForceHitModule.SelectedTarget = closestPart
        ForceHitModule.ManuallyEnabled = true
        ForceHitModule.Enabled = true
        CheckTargetAfterRespawn()
    end
end)

ForceHitModule.Connections["TargetStrafe"] = RunService.Heartbeat:Connect(function(deltaTime)
    if not ForceHitModule.TargetStrafeEnabled or not ForceHitModule.Enabled or not ForceHitModule.TargetPlayer then return end

    local targetCharacter = ForceHitModule.TargetPlayer.Character
    local humanoid = targetCharacter and targetCharacter:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health < 20 then return end -- Stop if HP is less than 20

    local localCharacter = LocalPlayer.Character
    local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")

    if not localRootPart or not targetRootPart then return end

    local distance = (localRootPart.Position - targetRootPart.Position).Magnitude
    if distance > 100000 then -- Maximum distance of 100,000 studs
        return
    end

    if IsTargetInVoid(targetRootPart.Position) then return end

    local radius = 0
    local speed = 0
    ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle + (speed * deltaTime)
    if ForceHitModule.StrafeAngle > 2 * math.pi then
        ForceHitModule.StrafeAngle = ForceHitModule.StrafeAngle - 2 * math.pi
    end

    local offset = Vector3.new(math.cos(ForceHitModule.StrafeAngle) * radius, 0, math.sin(ForceHitModule.StrafeAngle) * radius)
    local newPosition = targetRootPart.Position + offset

    localRootPart.CFrame = CFrame.new(newPosition, targetRootPart.Position)
    localRootPart.CFrame = localRootPart.CFrame + Vector3.new(0, targetRootPart.Position.Y - localRootPart.Position.Y, 0)
end)

ForceHitModule.Connections["AutoStomp"] = RunService.Stepped:Connect(function(time, step)
    if not ForceHitModule.AutoStompEnabled then return end
    ReplicatedStorage.MainEvent:FireServer("Stomp")
end)

ForceHitModule.Connections["UpdateTargetAndHighlight"] = RunService.RenderStepped:Connect(UpdateTargetAndHighlight)

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

local lastHealth = nil
ForceHitModule.Connections["HitSound"] = RunService.Heartbeat:Connect(function()
    if not ForceHitModule.Enabled or not ForceHitModule.TargetPlayer then
        lastHealth = nil
        return
    end

    local targetChar = ForceHitModule.TargetPlayer and ForceHitModule.TargetPlayer.Character
    if not (targetChar and targetChar:FindFirstChild("Humanoid")) then
        lastHealth = nil
        return
    end

    local humanoid = targetChar.Humanoid
    local currentHealth = humanoid.Health

    if lastHealth == nil then
        lastHealth = currentHealth
        return
    end

    if currentHealth < lastHealth and currentHealth > 0 then
        ForceHitModule.HitSound:Play()
    end

    lastHealth = currentHealth
end)

function ForceHitModule:Enable()
    if self.ManuallyEnabled then return end
    self.ManuallyEnabled = true
    self.Enabled = true
    if not self.TargetPlayer then
        local ClosestPart, ClosestCharacter, ClosestPlayer = GetClosestPlayer()
        self.SelectedTarget = ClosestPart
        self.TargetPlayer = ClosestPlayer
        CheckTargetAfterRespawn()
    end
    -- Start monitoring ammo when enabling
    MonitorTargetAmmo()
end

function ForceHitModule:Disable()
    if not self.ManuallyEnabled then return end
    self.ManuallyEnabled = false
    self.Enabled = false
    self.SelectedTarget = nil
    self.TargetPlayer = nil
    if self.Highlight then
        self.Highlight.Enabled = false
    end
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
    if self.TargetInfoUI then
        self.TargetInfoUI.Frame.Visible = false
    end
    lastHealth = nil
    self.LastAmmoValue = nil -- Reset the last ammo value when disabling
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

function ForceHitModule:SetKillAll(value)
    self.KillAllEnabled = value
    if value then
        self.LastKillAllTime = 0
    end
end

function ForceHitModule:GetKillAll()
    return self.KillAllEnabled
end

function ForceHitModule:SetAutoStomp(value)
    self.AutoStompEnabled = value
end

function ForceHitModule:GetAutoStomp()
    return self.AutoStompEnabled
end

function ForceHitModule:SetTargetStrafe(value)
    self.TargetStrafeEnabled = value
    if value then
        -- Save the player's current position when enabling Target Strafe
        local localCharacter = LocalPlayer.Character
        local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        if localRootPart then
            self.SavedPosition = localRootPart.CFrame
        end
        self.StrafeAngle = 0
    else
        -- Teleport the player back to the saved position when disabling Target Strafe
        if self.SavedPosition then
            local localCharacter = LocalPlayer.Character
            local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
            if localRootPart then
                localRootPart.CFrame = self.SavedPosition
            end
            self.SavedPosition = nil
        end
    end
end

function ForceHitModule:GetTargetStrafe()
    return self.TargetStrafeEnabled
end

function ForceHitModule:Cleanup()
    self:Disable()
    if self.ForceHitButton then
        self.ForceHitButton:Destroy()
        self.ForceHitButton = nil
    end
    if self.TargetInfoUI then
        self.TargetInfoUI.ScreenGui:Destroy()
        self.TargetInfoUI = nil
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    if self.Highlight then
        self.Highlight:Destroy()
        self.Highlight = nil
    end
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
    if self.HitSound then
        self.HitSound:Destroy()
        self.HitSound = nil
    end
    self.SavedPosition = nil
end

-- Initialisation des paramètres
if not getgenv().Rake then
    getgenv().Rake = {}
end
if not getgenv().Rake.Settings then
    getgenv().Rake.Settings = {}
end
if not getgenv().Rake.Settings.Misc then
    getgenv().Rake.Settings.Misc = {}
end
getgenv().Rake.Settings.Misc.TargetInfoEnabled = true

return ForceHitModule

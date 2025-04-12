-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables pour Camera Destroyer
getgenv().DC = false

local CameraDestroyerModule = {}

-- Tracer variables
local tracer = nil
local attachment0 = nil -- Attachment on the character's HumanoidRootPart
local attachment1 = nil -- Attachment at the stored Position

function CameraDestroyerModule:Enable()
    getgenv().DC = true
end

function CameraDestroyerModule:Disable()
    getgenv().DC = false
    -- Disable the tracer when Camera Destroyer is disabled
    if tracer then
        tracer:Destroy()
        tracer = nil
    end
    if attachment0 then
        attachment0:Destroy()
        attachment0 = nil
    end
    if attachment1 then
        attachment1:Destroy()
        attachment1 = nil
    end
end

function CameraDestroyerModule:Toggle()
    getgenv().DC = not getgenv().DC
    if not getgenv().DC then
        -- If disabling, clean up the tracer
        if tracer then
            tracer:Destroy()
            tracer = nil
        end
        if attachment0 then
            attachment0:Destroy()
            attachment0 = nil
        end
        if attachment1 then
            attachment1:Destroy()
            attachment1 = nil
        end
    end
    return getgenv().DC
end

function CameraDestroyerModule:IsEnabled()
    return getgenv().DC
end

function CameraDestroyerModule:Cleanup()
    self:Disable()
end

-- New Camera Destroyer Logic
local Position = nil
local renderstepped = RunService.RenderStepped

RunService.Heartbeat:Connect(function()
    if getgenv().DC == true then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            Position = LocalPlayer.Character.HumanoidRootPart.CFrame
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(math.random(-9e9, 9e9), math.random(-9e9, 9e9), math.random(-9e9, 9e9))
            renderstepped:Wait()
            LocalPlayer.Character.HumanoidRootPart.CFrame = Position

            -- Update the tracer
            if not tracer then
                -- Create the tracer beam
                tracer = Instance.new("Beam")
                tracer.Name = "CameraDestroyerTracer"
                tracer.Parent = workspace
                tracer.Enabled = true
                tracer.Color = ColorSequence.new(Color3.new(0, 1, 0)) -- Green color
                tracer.Transparency = NumberSequence.new(0)
                tracer.Width0 = 0.2
                tracer.Width1 = 0.2
                tracer.LightEmission = 1
                tracer.LightInfluence = 0

                -- Create attachment0 (on the character's HumanoidRootPart)
                attachment0 = Instance.new("Attachment")
                attachment0.Parent = LocalPlayer.Character.HumanoidRootPart
                tracer.Attachment0 = attachment0

                -- Create attachment1 (at the stored Position)
                attachment1 = Instance.new("Attachment")
                attachment1.Parent = workspace.Terrain -- Parent to Terrain to keep it in the world
                tracer.Attachment1 = attachment1
            end

            -- Update attachment positions
            if attachment0 and attachment0.Parent ~= LocalPlayer.Character.HumanoidRootPart then
                attachment0:Destroy()
                attachment0 = Instance.new("Attachment")
                attachment0.Parent = LocalPlayer.Character.HumanoidRootPart
                tracer.Attachment0 = attachment0
            end
            if attachment1 then
                attachment1.WorldCFrame = Position -- Set attachment1 to the stored Position
            end
        end
    end
end)

local HookMetamethod
HookMetamethod = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and key == "CFrame" then
        if getgenv().DC == true and Position and self == LocalPlayer.Character.HumanoidRootPart then
            return Position
        end
    end
    return HookMetamethod(self, key)
end)

-- Keep the forceHitActive logic
RunService.Heartbeat:Connect(function()
    if getgenv().DC then
        forceHitActive = false
    end
end)

return CameraDestroyerModule

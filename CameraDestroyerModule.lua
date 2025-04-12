-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables pour Camera Destroyer
getgenv().DC = false

local CameraDestroyerModule = {}

function CameraDestroyerModule:Enable()
    getgenv().DC = true
end

function CameraDestroyerModule:Disable()
    getgenv().DC = false
end

function CameraDestroyerModule:Toggle()
    getgenv().DC = not getgenv().DC
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

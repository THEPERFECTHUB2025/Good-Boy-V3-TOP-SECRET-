-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables
getgenv().Finobe1 = false
local Position = nil
local renderstepped = RunService.RenderStepped

-- Module Definition
local CameraDestroyerModule = {}

function CameraDestroyerModule:Enable()
    getgenv().Finobe1 = true
    print("[CameraDestroyerModule] Enabled - Finobe1 set to true")
end

function CameraDestroyerModule:Disable()
    getgenv().Finobe1 = false
    print("[CameraDestroyerModule] Disabled - Finobe1 set to false")

    -- Reset camera properties to default
    if Camera then
        print("[CameraDestroyerModule] Resetting camera properties")
        Camera.CameraType = Enum.CameraType.Custom
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
            print("[CameraDestroyerModule] CameraSubject set to player's Humanoid")
        else
            print("[CameraDestroyerModule] No Humanoid found, cannot set CameraSubject")
        end
        -- Clear CFrame and Focus to force the camera to update
        Camera.CFrame = Camera.CFrame -- This forces a refresh
        Camera.Focus = CFrame.new(Camera.CFrame.Position) -- Reset Focus
    else
        print("[CameraDestroyerModule] Camera not found")
    end

    -- Ensure the character's position is valid
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Position then
        LocalPlayer.Character.HumanoidRootPart.CFrame = Position
        print("[CameraDestroyerModule] HumanoidRootPart CFrame reset to: " .. tostring(Position))
    else
        print("[CameraDestroyerModule] Could not reset HumanoidRootPart CFrame - missing character or Position")
    end
end

function CameraDestroyerModule:Toggle()
    if getgenv().Finobe1 then
        self:Disable()
    else
        self:Enable()
    end
    return getgenv().Finobe1
end

function CameraDestroyerModule:IsEnabled()
    return getgenv().Finobe1
end

function CameraDestroyerModule:Cleanup()
    self:Disable()
end

-- Integrated Teleportation Logic
RunService.Heartbeat:Connect(function()
    if not getgenv().Finobe1 then return end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Position = LocalPlayer.Character.HumanoidRootPart.CFrame
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(9999999999999e999999995, 9e99999995, 9e9999999995)
        renderstepped:Wait()
        LocalPlayer.Character.HumanoidRootPart.CFrame = Position
    end
end)

-- Hook for CFrame to Mask Position
local HookMetamethod
HookMetamethod = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and key == "CFrame" then
        if Position and self == LocalPlayer.Character.HumanoidRootPart then
            return Position
        end
    end
    return HookMetamethod(self, key)
end)

-- Keep the forceHitActive Toggle
RunService.Heartbeat:Connect(function()
    if getgenv().Finobe1 then
        forceHitActive = false
    end
end)

return CameraDestroyerModule

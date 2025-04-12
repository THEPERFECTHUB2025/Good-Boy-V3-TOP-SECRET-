-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables pour Camera Destroyer
getgenv().DC = false

local CameraDestroyerModule = {}

-- Highlight setup
local highlight = Instance.new("Highlight")
highlight.Name = "CameraDestroyerHighlight"
highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green fill
highlight.OutlineColor = Color3.fromRGB(0, 255, 0) -- Green outline
highlight.FillTransparency = 0.5 -- Semi-transparent fill
highlight.OutlineTransparency = 0 -- Fully visible outline
highlight.Parent = game.CoreGui -- Parent to CoreGui to ensure visibility
highlight.Enabled = false -- Initially disabled

function CameraDestroyerModule:Enable()
    getgenv().DC = true
    -- Enable the highlight on the LocalPlayer's character
    if LocalPlayer.Character then
        highlight.Adornee = LocalPlayer.Character
        highlight.Enabled = true
    end
end

function CameraDestroyerModule:Disable()
    getgenv().DC = false
    -- Disable the highlight
    highlight.Enabled = false
    highlight.Adornee = nil
end

function CameraDestroyerModule:Toggle()
    getgenv().DC = not getgenv().DC
    -- Toggle the highlight based on the new state
    if getgenv().DC then
        if LocalPlayer.Character then
            highlight.Adornee = LocalPlayer.Character
            highlight.Enabled = true
        end
    else
        highlight.Enabled = false
        highlight.Adornee = nil
    end
    return getgenv().DC
end

function CameraDestroyerModule:IsEnabled()
    return getgenv().DC
end

function CameraDestroyerModule:Cleanup()
    self:Disable()
    -- Clean up the highlight
    highlight:Destroy()
end

-- New Camera Destroyer Logic
local Position = nil
local renderstepped = RunService.RenderStepped

-- Handle character respawn to reapply the highlight if Camera Destroyer is active
LocalPlayer.CharacterAdded:Connect(function(character)
    if getgenv().DC then
        highlight.Adornee = character
        highlight.Enabled = true
    end
end)

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

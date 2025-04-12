-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variables pour Camera Destroyer
getgenv().DC = false

local CameraDestroyerModule = {}
CameraDestroyerModule.Highlight = nil -- Store the Highlight object

-- Function to initialize the Highlight
local function InitializeHighlight()
    if not CameraDestroyerModule.Highlight then
        local highlight = Instance.new("Highlight")
        highlight.Name = "CameraDestroyerHighlight"
        highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green fill
        highlight.OutlineColor = Color3.fromRGB(0, 255, 0) -- Green outline
        highlight.FillTransparency = 0.5 -- Semi-transparent fill
        highlight.OutlineTransparency = 0 -- Fully visible outline
        highlight.Parent = game.CoreGui -- Parent to CoreGui to ensure visibility
        CameraDestroyerModule.Highlight = highlight
    end
end

-- Function to update the Highlight based on DC state
local function UpdateHighlight()
    if not CameraDestroyerModule.Highlight then
        InitializeHighlight()
    end

    if getgenv().DC and LocalPlayer.Character then
        CameraDestroyerModule.Highlight.Adornee = LocalPlayer.Character
        CameraDestroyerModule.Highlight.Enabled = true
    else
        CameraDestroyerModule.Highlight.Enabled = false
        CameraDestroyerModule.Highlight.Adornee = nil
    end
end

function CameraDestroyerModule:Enable()
    getgenv().DC = true
    UpdateHighlight() -- Update the highlight when enabling
end

function CameraDestroyerModule:Disable()
    getgenv().DC = false
    UpdateHighlight() -- Update the highlight when disabling
end

function CameraDestroyerModule:Toggle()
    getgenv().DC = not getgenv().DC
    UpdateHighlight() -- Update the highlight when toggling
    return getgenv().DC
end

function CameraDestroyerModule:IsEnabled()
    return getgenv().DC
end

function CameraDestroyerModule:Cleanup()
    self:Disable()
    if CameraDestroyerModule.Highlight then
        CameraDestroyerModule.Highlight:Destroy()
        CameraDestroyerModule.Highlight = nil
    end
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

-- Handle character respawns to reapply the highlight
LocalPlayer.CharacterAdded:Connect(function(character)
    UpdateHighlight() -- Reapply the highlight if DC is enabled
end)

-- Initial highlight update in case the character already exists
if LocalPlayer.Character then
    UpdateHighlight()
end

return CameraDestroyerModule

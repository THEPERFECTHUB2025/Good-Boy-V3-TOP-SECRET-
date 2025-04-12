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

-- BillboardGui setup for the text above the head
local billboardGui = Instance.new("BillboardGui")
billboardGui.Name = "CameraDestroyerState"
billboardGui.Size = UDim2.new(4, 0, 1, 0) -- Size of the GUI
billboardGui.StudsOffset = Vector3.new(0, 3, 0) -- Position above the head
billboardGui.AlwaysOnTop = true -- Ensure it’s always visible
billboardGui.Parent = game.CoreGui -- Parent to CoreGui
billboardGui.Enabled = false -- Initially disabled

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(1, 0, 1, 0)
stateLabel.BackgroundTransparency = 1 -- Transparent background
stateLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
stateLabel.TextScaled = true
stateLabel.Font = Enum.Font.SourceSansBold
stateLabel.Text = "CD : OFF 😢" -- Default text
stateLabel.Parent = billboardGui

-- Function to update the BillboardGui state
function CameraDestroyerModule:UpdateBillboardState()
    if getgenv().Rake.Settings.Misc.CameraDestroyer then
        -- Toggle is enabled, show the BillboardGui
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
            billboardGui.Adornee = LocalPlayer.Character.Head
            billboardGui.Enabled = true
            -- Update the text based on getgenv().DC
            stateLabel.Text = getgenv().DC and "CD : ON 😈" or "CD : OFF 😢"
            -- Change text color based on state
            stateLabel.TextColor3 = getgenv().DC and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        end
    else
        -- Toggle is disabled, hide the BillboardGui
        billboardGui.Enabled = false
        billboardGui.Adornee = nil
    end
end

function CameraDestroyerModule:Enable()
    getgenv().DC = true
    -- Enable the highlight on the LocalPlayer's character
    if LocalPlayer.Character then
        highlight.Adornee = LocalPlayer.Character
        highlight.Enabled = true
    end
    -- Update the BillboardGui
    self:UpdateBillboardState()
end

function CameraDestroyerModule:Disable()
    getgenv().DC = false
    -- Disable the highlight
    highlight.Enabled = false
    highlight.Adornee = nil
    -- Update the BillboardGui
    self:UpdateBillboardState()
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
    -- Update the BillboardGui
    self:UpdateBillboardState()
    return getgenv().DC
end

function CameraDestroyerModule:IsEnabled()
    return getgenv().DC
end

function CameraDestroyerModule:Cleanup()
    self:Disable()
    -- Clean up the highlight and BillboardGui
    highlight:Destroy()
    billboardGui:Destroy()
end

-- Handle toggle changes
function CameraDestroyerModule:OnToggleChanged(value)
    getgenv().Rake.Settings.Misc.CameraDestroyer = value
    if not value then
        -- If the toggle is disabled, force disable the Camera Destroyer
        self:Disable()
    end
    self:UpdateBillboardState()
end

-- New Camera Destroyer Logic
local Position = nil
local renderstepped = RunService.RenderStepped

-- Handle character respawn to reapply the highlight and BillboardGui
LocalPlayer.CharacterAdded:Connect(function(character)
    if getgenv().DC then
        highlight.Adornee = character
        highlight.Enabled = true
    end
    CameraDestroyerModule:UpdateBillboardState()
end)

-- Ensure the BillboardGui updates if the character exists when the script loads
if LocalPlayer.Character then
    CameraDestroyerModule:UpdateBillboardState()
end

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

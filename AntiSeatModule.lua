-- AntiSeatModule.lua
local AntiSeatModule = {}
AntiSeatModule.Enabled = false
AntiSeatModule.Connection = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Function to enable the anti-seat feature
function AntiSeatModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("[AntiSeatModule] Enabled - Preventing sitting")

    -- Ensure the character exists
    local character = LocalPlayer.Character
    if not character then
        LocalPlayer.CharacterAdded:Wait()
        character = LocalPlayer.Character
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        warn("[AntiSeatModule] Humanoid not found")
        self.Enabled = false
        return
    end

    -- Connect to monitor sitting
    self.Connection = humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
        if self.Enabled and humanoid.Sit then
            humanoid.Sit = false -- Eject the character from the seat
            print("[AntiSeatModule] Prevented sitting")
        end
    end)

    -- Handle character respawn
    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if not self.Enabled then return end
        local newHumanoid = newCharacter:WaitForChild("Humanoid", 5)
        if newHumanoid then
            if self.Connection then
                self.Connection:Disconnect()
            end
            self.Connection = newHumanoid:GetPropertyChangedSignal("Sit"):Connect(function()
                if self.Enabled and newHumanoid.Sit then
                    newHumanoid.Sit = false
                    print("[AntiSeatModule] Prevented sitting")
                end
            end)
        end
    end)
end

-- Function to disable the anti-seat feature
function AntiSeatModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    print("[AntiSeatModule] Disabled - Allowing sitting")

    -- Disconnect the monitoring connection
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

-- Function to initialize the module
function AntiSeatModule:Init()
    self:Disable()
end

-- Initialize the module
AntiSeatModule:Init()

return AntiSeatModule

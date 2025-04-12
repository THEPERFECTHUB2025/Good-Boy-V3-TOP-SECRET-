-- Alternative AntiSeatModule.lua
local AntiSeatModule = {}
AntiSeatModule.Enabled = false
AntiSeatModule.Connection = nil

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

function AntiSeatModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("[AntiSeatModule] Enabled - Preventing sitting")

    local function monitorSeats(obj)
        if obj:IsA("Seat") then
            self.Connection = obj:GetPropertyChangedSignal("Occupant"):Connect(function()
                if self.Enabled and obj.Occupant == LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Sit = false
                        print("[AntiSeatModule] Prevented sitting on seat: " .. obj:GetFullName())
                    end
                end
            end)
        end
        for _, child in pairs(obj:GetChildren()) do
            monitorSeats(child)
        end
    end

    monitorSeats(Workspace)
    Workspace.DescendantAdded:Connect(function(descendant)
        if self.Enabled and descendant:IsA("Seat") then
            self.Connection = descendant:GetPropertyChangedSignal("Occupant"):Connect(function()
                if self.Enabled and descendant.Occupant == LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Sit = false
                        print("[AntiSeatModule] Prevented sitting on seat: " .. descendant:GetFullName())
                    end
                end
            end)
        end
    end)
end

function AntiSeatModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    print("[AntiSeatModule] Disabled - Allowing sitting")
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

AntiSeatModule:Disable()
return AntiSeatModule

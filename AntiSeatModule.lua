-- AntiSeatModule.lua with Heartbeat Loop
local AntiSeatModule = {}
AntiSeatModule.Enabled = false
AntiSeatModule.Connections = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function getPlayerHumanoid()
    local character = LocalPlayer.Character
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function monitorSeat(seat)
    if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then return end

    local connection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if not AntiSeatModule.Enabled then return end

        local humanoid = getPlayerHumanoid()
        if humanoid and seat.Occupant == humanoid then
            humanoid.Sit = false
            print("[AntiSeatModule] Prevented sitting on seat: " .. seat:GetFullName())
        end
    end)

    table.insert(AntiSeatModule.Connections, connection)
end

local function monitorSeats(obj)
    if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
        monitorSeat(obj)
    end
    for _, child in pairs(obj:GetChildren()) do
        monitorSeats(child)
    end
end

function AntiSeatModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("[AntiSeatModule] Enabled - Preventing sitting")

    -- Monitor existing seats
    monitorSeats(Workspace)

    -- Monitor new seats
    table.insert(self.Connections, Workspace.DescendantAdded:Connect(function(descendant)
        if self.Enabled and (descendant:IsA("Seat") or descendant:IsA("VehicleSeat")) then
            monitorSeat(descendant)
        end
    end))

    -- Handle character respawns
    table.insert(self.Connections, LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if self.Enabled and humanoid then
            for _, seat in pairs(Workspace:GetDescendants()) do
                if (seat:IsA("Seat") or seat:IsA("VehicleSeat")) and seat.Occupant == humanoid then
                    humanoid.Sit = false
                    print("[AntiSeatModule] Prevented sitting on seat after respawn: " .. seat:GetFullName())
                end
            end
        end
    end))

    -- Continuously force Humanoid.Sit to false while enabled
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        local humanoid = getPlayerHumanoid()
        if humanoid and humanoid.Sit then
            humanoid.Sit = false
            print("[AntiSeatModule] Forced Humanoid.Sit to false")
        end
    end))
end

function AntiSeatModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    print("[AntiSeatModule] Disabled - Allowing sitting")

    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}
end

AntiSeatModule:Disable()
return AntiSeatModule

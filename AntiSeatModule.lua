-- AntiSeatModule.lua
local AntiSeatModule = {}
AntiSeatModule.Enabled = false
AntiSeatModule.SeatData = {} -- Table to store seat data for restoration

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Function to find and delete seats
function AntiSeatModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    print("[AntiSeatModule] Enabled - Deleting seats")

    -- Clear previous seat data
    self.SeatData = {}

    -- Navigate to the specific map folder: workspace.FFA_MAP.Map:GetChildren()[225]:GetChildren()[17]
    local mapFolder
    local success, err = pcall(function()
        local ffaMap = Workspace:FindFirstChild("FFA_MAP")
        if not ffaMap then error("FFA_MAP not found") end
        local map = ffaMap:FindFirstChild("Map")
        if not map then error("Map not found") end
        local mapChildren = map:GetChildren()
        if not mapChildren[225] then error("Map:GetChildren()[225] not found") end
        local subChildren = mapChildren[225]:GetChildren()
        if not subChildren[17] then error("Map:GetChildren()[225]:GetChildren()[17] not found") end
        mapFolder = subChildren[17]
    end)

    if not success then
        warn("[AntiSeatModule] Failed to find map folder: " .. tostring(err))
        self.Enabled = false
        return
    end

    -- Find all Seat objects in the map folder
    local function findSeats(obj)
        if obj:IsA("Seat") then
            -- Store seat data before deleting
            local seatData = {
                Parent = obj.Parent,
                CFrame = obj.CFrame,
                Size = obj.Size,
                Color = obj.Color,
                Material = obj.Material,
                Transparency = obj.Transparency,
                CanCollide = obj.CanCollide,
                Anchored = obj.Anchored,
                Name = obj.Name
            }
            table.insert(self.SeatData, seatData)
            print("[AntiSeatModule] Found and deleted seat: " .. obj:GetFullName())
            obj:Destroy()
        end
        for _, child in pairs(obj:GetChildren()) do
            findSeats(child)
        end
    end

    -- Run the seat deletion
    findSeats(mapFolder)
    print("[AntiSeatModule] Finished deleting seats. Total seats deleted: " .. #self.SeatData)
end

-- Function to restore seats
function AntiSeatModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    print("[AntiSeatModule] Disabled - Restoring seats")

    -- Restore all seats from stored data
    for _, seatData in pairs(self.SeatData) do
        local newSeat = Instance.new("Seat")
        newSeat.CFrame = seatData.CFrame
        newSeat.Size = seatData.Size
        newSeat.Color = seatData.Color
        newSeat.Material = seatData.Material
        newSeat.Transparency = seatData.Transparency
        newSeat.CanCollide = seatData.CanCollide
        newSeat.Anchored = seatData.Anchored
        newSeat.Name = seatData.Name
        newSeat.Parent = seatData.Parent
        print("[AntiSeatModule] Restored seat: " .. newSeat:GetFullName())
    end

    -- Clear seat data
    self.SeatData = {}
    print("[AntiSeatModule] Finished restoring seats")
end

-- Function to initialize the module
function AntiSeatModule:Init()
    -- Ensure the module starts in a disabled state
    self:Disable()
end

-- Initialize the module
AntiSeatModule:Init()

return AntiSeatModule

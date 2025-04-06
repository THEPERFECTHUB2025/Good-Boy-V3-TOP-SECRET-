-- Variables pour Camera Destroyer
getgenv().Finobe1 = false
local NewCFrame = CFrame.new
local LocalFinobe = game.Players.LocalPlayer
local Finobe2

-- Code pour Camera Destroyer
local pi = math.pi
local abs = math.abs
local clamp = math.clamp
local exp = math.exp
local rad = math.rad
local sign = math.sign
local sqrt = math.sqrt
local tan = math.tan

local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")

local Spring = {}
Spring.__index = Spring

function Spring.new(freq, pos)
    local self = setmetatable({}, Spring)
    self.f = freq
    self.p = pos
    self.v = pos*0
    return self
end

function Spring:Update(dt, goal)
    local f = self.f*2*pi
    local p0 = self.p
    local v0 = self.v
    local offset = goal - p0
    local decay = exp(-f*dt)
    local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
    local v1 = (f*dt*(offset*f - v0) + v0)*decay
    self.p = p1
    self.v = v1
    return p1
end

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 70
local velSpring = Spring.new(1.5, Vector3.new())
local panSpring = Spring.new(1.0, Vector2.new())
local NAV_GAIN = Vector3.new(1, 1, 1)*64
local PAN_GAIN = Vector2.new(0.75, 1)*8
local PITCH_LIMIT = rad(90)

local PlayerState = {
    enabled = false,
    originalCFrame = nil,
    originalFov = nil,
    originalType = nil,
    originalSubject = nil
}

local function StartFreecam()
    PlayerState.enabled = true
    PlayerState.originalCFrame = Camera.CFrame
    PlayerState.originalFov = Camera.FieldOfView
    PlayerState.originalType = Camera.CameraType
    PlayerState.originalSubject = Camera.CameraSubject
    
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = nil
    
    cameraPos = Camera.CFrame.p
    cameraRot = Vector2.new(Camera.CFrame:toEulerAnglesYXZ())
end

local function StopFreecam()
    PlayerState.enabled = false
    Camera.CFrame = PlayerState.originalCFrame
    Camera.FieldOfView = PlayerState.originalFov
    Camera.CameraType = PlayerState.originalType
    Camera.CameraSubject = PlayerState.originalSubject
end

local function UpdateFreecam(dt)
    if not PlayerState.enabled then return end
    
    local cameraCFrame = CFrame.new(cameraPos) * 
                        CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)
    
    Camera.CFrame = cameraCFrame
    Camera.Focus = cameraCFrame * CFrame.new(0, 0, -15)
end

RunService.Heartbeat:Connect(function()
    if LocalFinobe.Character then
        local FinobeChar = LocalFinobe.Character.HumanoidRootPart
        local Offset = FinobeChar.CFrame * NewCFrame(math.random(-999e9, 999e9), math.random(-999e9, 999e9), math.random(-999e9, 999e9))

        if getgenv().Finobe1 then
            Finobe2 = FinobeChar.CFrame
            FinobeChar.CFrame = Offset
            RunService.RenderStepped:Wait()
            FinobeChar.CFrame = Finobe2
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if PlayerState.enabled then
        UpdateFreecam(dt)
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().Finobe1 then
        forceHitActive = false
    end
end)

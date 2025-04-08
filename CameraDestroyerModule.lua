-- CameraDestroyerModule.lua

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Variables globales pour Camera Destroyer
local Finobe1 = false
local LocalFinobe = LocalPlayer
local Finobe2

-- État du joueur pour la gestion du freecam
local PlayerState = {
    enabled = false,
    originalCFrame = nil,
    originalFov = nil,
    originalType = nil,
    originalSubject = nil
}

-- Variables pour le freecam
local pi = math.pi
local abs = math.abs
local clamp = math.clamp
local exp = math.exp
local rad = math.rad
local sign = math.sign
local sqrt = math.sqrt
local tan = math.tan

local NewCFrame = CFrame.new
local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 70
local velSpring = { f = 1.5, p = Vector3.new(), v = Vector3.new() }
local panSpring = { f = 1.0, p = Vector2.new(), v = Vector2.new() }
local NAV_GAIN = Vector3.new(1, 1, 1) * 64
local PITCH_LIMIT = rad(90)

-- Définition de la classe Spring pour le freecam
local Spring = {}
Spring.__index = Spring

function Spring.new(freq, pos)
    local self = setmetatable({}, Spring)
    self.f = freq
    self.p = pos
    self.v = pos * 0
    return self
end

function Spring:Update(dt, goal)
    local f = self.f * 2 * pi
    local p0 = self.p
    local v0 = self.v
    local offset = goal - p0
    local decay = exp(-f * dt)
    local p1 = goal + (v0 * dt - offset * (f * dt + 1)) * decay
    local v1 = (f * dt * (offset * f - v0) + v0) * decay
    self.p = p1
    self.v = v1
    return p1
end

-- Initialisation des springs
velSpring = Spring.new(1.5, Vector3.new())
panSpring = Spring.new(1.0, Vector2.new())

-- Fonction pour démarrer le freecam
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

-- Fonction pour arrêter le freecam
local function StopFreecam()
    PlayerState.enabled = false
    Camera.CFrame = PlayerState.originalCFrame
    Camera.FieldOfView = PlayerState.originalFov
    Camera.CameraType = PlayerState.originalType
    Camera.CameraSubject = PlayerState.originalSubject
end

-- Fonction pour mettre à jour le freecam
local function UpdateFreecam(dt)
    if not PlayerState.enabled then return end
    
    local cameraCFrame = CFrame.new(cameraPos) * 
                        CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)
    
    Camera.CFrame = cameraCFrame
    Camera.Focus = cameraCFrame * CFrame.new(0, 0, -15)
end

-- Fonction pour désactiver le Hide
local function DisableHide()
    if getgenv().Rake and getgenv().Rake.Settings and getgenv().Rake.Settings.Misc then
        if getgenv().Rake.Settings.Misc.Hide then
            getgenv().Rake.Settings.Misc.Hide = false
            local character = LocalPlayer.Character
            if character then
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.Transparency = 0
                    elseif v:IsA("Decal") then
                        v.Transparency = 0
                    end
                end
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    end
end

-- Connexion pour gérer le déplacement du personnage (Finobe1)
local heartbeatConnection
local renderSteppedConnection

local function StartConnections()
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    if renderSteppedConnection then renderSteppedConnection:Disconnect() end

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if LocalFinobe.Character then
            local FinobeChar = LocalFinobe.Character:FindFirstChild("HumanoidRootPart")
            if FinobeChar then
                local Offset = FinobeChar.CFrame * NewCFrame(math.random(-999e9, 999e9), math.random(-999e9, 999e9), math.random(-999e9, 999e9))
                if Finobe1 then
                    Finobe2 = FinobeChar.CFrame
                    FinobeChar.CFrame = Offset
                    RunService.RenderStepped:Wait()
                    FinobeChar.CFrame = Finobe2
                end
            end
        end
    end)

    renderSteppedConnection = RunService.RenderStepped:Connect(function(dt)
        if PlayerState.enabled then
            UpdateFreecam(dt)
        end
    end)
end

-- Module CameraDestroyer
local CameraDestroyerModule = {}

-- Fonction pour activer le Camera Destroyer
function CameraDestroyerModule:Enable()
    -- Désactiver le Hide avant d'activer le Camera Destroyer
    DisableHide()
    
    Finobe1 = true
    getgenv().Finobe1 = Finobe1
    StartFreecam()
    StartConnections()
end

-- Fonction pour désactiver le Camera Destroyer
function CameraDestroyerModule:Disable()
    Finobe1 = false
    getgenv().Finobe1 = Finobe1
    StopFreecam()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = Finobe2 or LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end

-- Fonction pour basculer l'état du Camera Destroyer
function CameraDestroyerModule:Toggle()
    if Finobe1 then
        self:Disable()
    else
        self:Enable()
    end
    return Finobe1
end

-- Fonction pour nettoyer les connexions lors de la déconnexion
function CameraDestroyerModule:Cleanup()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    if renderSteppedConnection then
        renderSteppedConnection:Disconnect()
        renderSteppedConnection = nil
    end
    self:Disable()
end

-- Initialisation du module
StartConnections()

-- Nettoyage à la déconnexion du joueur
LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        CameraDestroyerModule:Cleanup()
    end
end)

return CameraDestroyerModule

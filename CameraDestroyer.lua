-- CameraDestroyer.lua
local pi = math.pi
local abs = math.abs
local clamp = math.clamp
local exp = math.exp
local rad = math.rad
local sign = math.sign
local sqrt = math.sqrt
local tan = math.tan

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Liste des armes qui désactivent le Camera Destroyer
local restrictedWeapons = {
    "[DoubleBarrel]",
    "[Revolver]",
    "[SMG]",
    "[Shotgun]",
    "[Silencer]",
    "[TacticalShotgun]"
}

-- État du Camera Destroyer
local CameraDestroyer = {
    enabled = false, -- État global du toggle
    active = false, -- État effectif (dépend des outils équipés)
    connections = {} -- Pour stocker les connexions
}

-- Spring pour la gestion de la caméra
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

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()
local cameraFov = 70
local velSpring = Spring.new(1.5, Vector3.new())
local panSpring = Spring.new(1.0, Vector2.new())
local NAV_GAIN = Vector3.new(1, 1, 1) * 64
local PAN_GAIN = Vector2.new(0.75, 1) * 8
local PITCH_LIMIT = rad(90)

local PlayerState = {
    originalCFrame = nil,
    originalFov = nil,
    originalType = nil,
    originalSubject = nil
}

-- Fonction pour démarrer le Camera Destroyer
local function StartCameraDestroyer()
    PlayerState.originalCFrame = Camera.CFrame
    PlayerState.originalFov = Camera.FieldOfView
    PlayerState.originalType = Camera.CameraType
    PlayerState.originalSubject = Camera.CameraSubject
    
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = nil
    
    cameraPos = Camera.CFrame.p
    cameraRot = Vector2.new(Camera.CFrame:toEulerAnglesYXZ())
end

-- Fonction pour arrêter le Camera Destroyer
local function StopCameraDestroyer()
    Camera.CFrame = PlayerState.originalCFrame
    Camera.FieldOfView = PlayerState.originalFov
    Camera.CameraType = PlayerState.originalType
    Camera.CameraSubject = PlayerState.originalSubject
end

-- Fonction pour mettre à jour la caméra
local function UpdateCameraDestroyer(dt)
    if not CameraDestroyer.active then return end
    
    local cameraCFrame = CFrame.new(cameraPos) * 
                        CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)
    
    Camera.CFrame = cameraCFrame
    Camera.Focus = cameraCFrame * CFrame.new(0, 0, -15)
end

-- Fonction pour vérifier si une arme équipée est dans la liste des armes restreintes
local function IsRestrictedWeapon(tool)
    if not tool then return false end
    for _, weapon in pairs(restrictedWeapons) do
        if tool.Name == weapon then
            return true
        end
    end
    return false
end

-- Fonction pour gérer l'état du Camera Destroyer en fonction des outils équipés
local function UpdateCameraDestroyerState()
    if not CameraDestroyer.enabled then
        CameraDestroyer.active = false
        if PlayerState.originalCFrame then
            StopCameraDestroyer()
        end
        return
    end

    local character = LocalPlayer.Character
    local equippedTool = character and character:FindFirstChildOfClass("Tool")

    if equippedTool and IsRestrictedWeapon(equippedTool) then
        -- Une arme restreinte est équipée, désactiver le Camera Destroyer
        CameraDestroyer.active = false
        if PlayerState.originalCFrame then
            StopCameraDestroyer()
        end
        print("Camera Destroyer: Désactivé (arme restreinte équipée - " .. equippedTool.Name .. ")")
    else
        -- Aucune arme restreinte n'est équipée, activer le Camera Destroyer
        CameraDestroyer.active = true
        if not PlayerState.originalCFrame then
            StartCameraDestroyer()
        end
        print("Camera Destroyer: Activé (aucune arme restreinte équipée)")
    end
end

-- Fonction pour activer le Camera Destroyer (appelée par le toggle)
function CameraDestroyer:Enable()
    if CameraDestroyer.enabled then
        print("Camera Destroyer: Déjà activé")
        return
    end

    CameraDestroyer.enabled = true
    print("Camera Destroyer: Toggle activé")

    -- Surveiller les changements de personnage
    local characterConnection
    characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        UpdateCameraDestroyerState()

        -- Surveiller les outils équipés
        local toolEquippedConnection = character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                UpdateCameraDestroyerState()
            end
        end)

        -- Surveiller les outils déséquipés
        local toolUnequippedConnection = character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                UpdateCameraDestroyerState()
            end
        end)

        table.insert(CameraDestroyer.connections, toolEquippedConnection)
        table.insert(CameraDestroyer.connections, toolUnequippedConnection)
    end)

    -- Vérifier le personnage actuel
    if LocalPlayer.Character then
        UpdateCameraDestroyerState()
    end

    table.insert(CameraDestroyer.connections, characterConnection)
end

-- Fonction pour désactiver le Camera Destroyer (appelée par le toggle)
function CameraDestroyer:Disable()
    if not CameraDestroyer.enabled then
        print("Camera Destroyer: Déjà désactivé")
        return
    end

    CameraDestroyer.enabled = false
    CameraDestroyer.active = false
    print("Camera Destroyer: Toggle désactivé")

    -- Nettoyer toutes les connexions
    for _, connection in pairs(CameraDestroyer.connections) do
        connection:Disconnect()
    end
    CameraDestroyer.connections = {}

    -- Restaurer la caméra
    if PlayerState.originalCFrame then
        StopCameraDestroyer()
    end
end

-- Connexion pour mettre à jour la caméra
RunService.RenderStepped:Connect(function(dt)
    UpdateCameraDestroyer(dt)
end)

-- Gestion de Finobe (partie existante de ton code)
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local FinobeChar = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if FinobeChar then
            local Offset = FinobeChar.CFrame * CFrame.new(math.random(-999e9, 999e9), math.random(-999e9, 999e9), math.random(-999e9, 999e9))

            if getgenv().Finobe1 then
                local Finobe2 = FinobeChar.CFrame
                FinobeChar.CFrame = Offset
                RunService.RenderStepped:Wait()
                FinobeChar.CFrame = Finobe2
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().Finobe1 then
        forceHitActive = false
    end
end)

return CameraDestroyer

-- Services
local Players = game:GetService("Players")

-- Variables
local LocalPlayer = Players.LocalPlayer
local NoJumpCooldownModule = {
    Enabled = false,
    Connections = {}
}

-- Fonction pour mettre à jour UseJumpPower
local function UpdateJumpCooldown()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    humanoid.UseJumpPower = not NoJumpCooldownModule.Enabled -- false si activé, true si désactivé
end

-- Fonction pour activer le No Jump Cooldown
function NoJumpCooldownModule:Enable()
    if self.Enabled then return end
    self.Enabled = true
    UpdateJumpCooldown()
end

-- Fonction pour désactiver le No Jump Cooldown
function NoJumpCooldownModule:Disable()
    if not self.Enabled then return end
    self.Enabled = false
    UpdateJumpCooldown()
end

-- Fonction pour basculer l'état
function NoJumpCooldownModule:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

-- Gérer le respawn du joueur pour appliquer l'état actuel
NoJumpCooldownModule.Connections["CharacterAdded"] = LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        UpdateJumpCooldown()
    end
end)

-- Nettoyage du module
function NoJumpCooldownModule:Cleanup()
    self:Disable()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}
end

-- Initialisation : appliquer l'état actuel si le personnage existe déjà
if LocalPlayer.Character then
    UpdateJumpCooldown()
end

return NoJumpCooldownModule

-- AutoToxic.lua
local AutoToxic = {}
AutoToxic.__index = AutoToxic

-- Dépendances
local RunService = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- Liste des messages toxiques
local words = {
    "Get Perfect.vip",
    "Perfect.vip On Top",
    "Nobody can stop me anymore",
    "How it feels losing?",
    "Better luck next year",
}

-- Fonction pour vérifier si le chat legacy est activé
local function isLegacyChatEnabled()
    return RunService:FindFirstChild("DefaultChatSystemChatEvents") ~= nil
end

-- Fonction pour envoyer un message via le chat legacy
local function sendLegacyMessage(message)
    local event = RunService.DefaultChatSystemChatEvents.SayMessageRequest
    event:FireServer(message, "All")
end

-- Fonction pour envoyer un message via le chat moderne
local function sendModernMessage(message)
    TextChatService.TextChannels.RBXGeneral:SendAsync(message)
end

-- Fonction pour envoyer un message aléatoire
local function sendRandomMessage()
    local randomMessage = words[math.random(1, #words)]
    if isLegacyChatEnabled() then
        sendLegacyMessage(randomMessage)
    else
        sendModernMessage(randomMessage)
    end
    print("Auto Toxic: Message envoyé - " .. randomMessage)
end

-- Constructeur du module
function AutoToxic.new()
    local self = setmetatable({}, AutoToxic)
    self.connections = {}
    self.monitoredTargets = {}
    self.messageSentForLowHP = {}
    self.isActive = false
    return self
end

-- Fonction pour surveiller les HP de la cible
function AutoToxic:MonitorTargetHealth(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        print("Auto Toxic: Cible invalide pour surveillance")
        return
    end

    local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        print("Auto Toxic: Humanoid non trouvé pour " .. targetPlayer.Name)
        return
    end

    -- Marquer la cible comme surveillée
    self.monitoredTargets[targetPlayer] = true
    print("Auto Toxic: Surveillance des HP activée pour " .. targetPlayer.Name)

    -- Surveiller les HP en boucle avec RunService.Heartbeat (délai ~0)
    local healthMonitorConnection
    healthMonitorConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- Vérifier si AutoToxic est activé
        if not self.isActive then
            print("Auto Toxic: Désactivé, arrêt de la surveillance pour " .. targetPlayer.Name)
            healthMonitorConnection:Disconnect()
            self.monitoredTargets[targetPlayer] = nil
            self.messageSentForLowHP[targetPlayer] = nil
            return
        end

        -- Vérifier si le ForceHit et l'aimbot sont activés
        if not enabled or not getgenv().Rake.Settings.Misc.ForceHit then
            print("Auto Toxic: ForceHit ou aimbot désactivé, pas de message envoyé pour " .. targetPlayer.Name)
            return
        end

        -- Vérifier si la cible est bien celle visée par l'aimbot
        if targetPlayer ~= Plr then
            print("Auto Toxic: Cible " .. targetPlayer.Name .. " n'est pas la cible actuelle de l'aimbot (" .. (Plr and Plr.Name or "aucune") .. ")")
            return
        end

        -- Vérifier si le personnage ou le humanoid a changé (par exemple, après un respawn/reset)
        if not targetPlayer.Character or targetPlayer.Character ~= humanoid.Parent then
            print("Auto Toxic: Personnage de " .. targetPlayer.Name .. " a changé, arrêt de la surveillance")
            healthMonitorConnection:Disconnect()
            self.monitoredTargets[targetPlayer] = nil
            self.messageSentForLowHP[targetPlayer] = nil
            return
        end

        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then
            print("Auto Toxic: Humanoid non trouvé pour " .. targetPlayer.Name .. ", arrêt de la surveillance")
            healthMonitorConnection:Disconnect()
            self.monitoredTargets[targetPlayer] = nil
            self.messageSentForLowHP[targetPlayer] = nil
            return
        end

        local currentHealth = humanoid.Health

        -- Vérifier si les HP sont entre 0.5 et 1
        if currentHealth >= 0.5 and currentHealth <= 1 then
            -- Vérifier si un message a déjà été envoyé pour cette instance de HP bas
            if not self.messageSentForLowHP[targetPlayer] then
                print("Auto Toxic: HP de " .. targetPlayer.Name .. " tombés à " .. currentHealth .. " - Envoi d'un message")
                sendRandomMessage()
                self.messageSentForLowHP[targetPlayer] = true
            end
        else
            -- Réinitialiser l'état si les HP sortent de la plage 0.5-1
            self.messageSentForLowHP[targetPlayer] = nil
        end
    end)

    -- Gérer le respawn/reset
    local characterAddedConnection
    characterAddedConnection = targetPlayer.CharacterAdded:Connect(function(newCharacter)
        print("Auto Toxic: Cible " .. targetPlayer.Name .. " a respawné/reset, réinitialisation de la surveillance")
        -- Nettoyer les anciennes connexions
        healthMonitorConnection:Disconnect()
        characterAddedConnection:Disconnect()
        -- Réinitialiser l'état
        self.monitoredTargets[targetPlayer] = nil
        self.messageSentForLowHP[targetPlayer] = nil
        -- Reprendre la surveillance si la cible est toujours sélectionnée
        if self.isActive and targetPlayer == Plr and enabled and getgenv().Rake.Settings.Misc.ForceHit then
            print("Auto Toxic: Reprise de la surveillance pour " .. targetPlayer.Name .. " après respawn/reset")
            self:MonitorTargetHealth(targetPlayer)
        end
    end)

    -- Stocker les connexions pour les nettoyer plus tard
    table.insert(self.connections, healthMonitorConnection)
    table.insert(self.connections, characterAddedConnection)
end

-- Fonction pour activer le module
function AutoToxic:Enable()
    if self.isActive then
        print("Auto Toxic: Déjà activé")
        return
    end

    self.isActive = true
    print("Auto Toxic activé")

    -- Surveiller les changements de cible dans Plr
    local plrMonitorConnection
    plrMonitorConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not self.isActive then
            plrMonitorConnection:Disconnect()
            return
        end

        -- Vérifier si une cible est sélectionnée et si l'aimbot et ForceHit sont activés
        if Plr and enabled and getgenv().Rake.Settings.Misc.ForceHit then
            -- Vérifier si nous surveillons déjà cette cible
            if not self.monitoredTargets[Plr] then
                print("Auto Toxic: Début de la surveillance des HP pour " .. Plr.Name)
                self:MonitorTargetHealth(Plr)
            end
        else
            -- Si les conditions ne sont plus remplies, nettoyer les cibles surveillées
            for target, _ in pairs(self.monitoredTargets) do
                if Plr ~= target or not enabled or not getgenv().Rake.Settings.Misc.ForceHit then
                    print("Auto Toxic: Arrêt de la surveillance pour " .. target.Name .. " (conditions non remplies)")
                    self.monitoredTargets[target] = nil
                    self.messageSentForLowHP[target] = nil
                end
            end
        end
    end)

    table.insert(self.connections, plrMonitorConnection)
end

-- Fonction pour désactiver le module
function AutoToxic:Disable()
    if not self.isActive then
        print("Auto Toxic: Déjà désactivé")
        return
    end

    self.isActive = false
    print("Auto Toxic désactivé")

    -- Nettoyer toutes les connexions
    for _, connection in pairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}
    -- Réinitialiser les tables
    self.monitoredTargets = {}
    self.messageSentForLowHP = {}
end

return AutoToxic

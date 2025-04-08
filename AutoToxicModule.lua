-- AutoToxicModule.lua
local AutoToxicModule = {}

-- Liste des messages toxiques
local words = {
    "Get Perfect.vip",
    "Perfect.vip On Top",
    "Nobody can stop me anymore",
    "How it feels losing?",
    "Better luck next year",
}

-- Variables pour stocker l'état
local isEnabled = false
local connections = {}
local monitoredTargets = {}
local messageSentForLowHP = {}

-- Fonction pour vérifier si le chat legacy est activé
local function isLegacyChatEnabled()
    return game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") ~= nil
end

-- Fonction pour envoyer un message via le chat legacy
local function sendLegacyMessage(message)
    local event = game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest
    event:FireServer(message, "All")
end

-- Fonction pour envoyer un message via le chat moderne
local function sendModernMessage(message)
    game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(message)
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

-- Fonction pour vérifier si la cible est derrière un mur (utilise la logique de ForceHitModule)
local function IsTargetBehindWall(localPosition, targetPosition, forceHitModule)
    -- Vérifier si le Wall Check est activé dans ForceHitModule
    if forceHitModule and forceHitModule.WallCheckEnabled then
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character, forceHitModule.TargetPlayer.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.IgnoreWater = true

        local direction = (targetPosition - localPosition).Unit * (targetPosition - localPosition).Magnitude
        local raycastResult = workspace:Raycast(localPosition, direction, raycastParams)
        return raycastResult ~= nil -- Retourne true si un obstacle est détecté
    end
    return false -- Si le Wall Check est désactivé, ignorer les murs
end

-- Fonction pour surveiller les HP de la cible
local function monitorTargetHealth(targetPlayer, getPlr, getEnabled, getForceHit, getSilentAimTarget, forceHitModule)
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
    monitoredTargets[targetPlayer] = true
    print("Auto Toxic: Surveillance des HP activée pour " .. targetPlayer.Name)

    -- Surveiller les HP en boucle avec RunService.Heartbeat (délai ~0)
    local healthMonitorConnection
    healthMonitorConnection = game:GetService("RunService").Heartbeat:Connect(function()
        -- Vérifier si le module est activé
        if not isEnabled then
            print("Auto Toxic: Désactivé, arrêt de la surveillance pour " .. targetPlayer.Name)
            healthMonitorConnection:Disconnect()
            monitoredTargets[targetPlayer] = nil
            messageSentForLowHP[targetPlayer] = nil
            return
        end

        -- Récupérer les valeurs actuelles de Plr, enabled, ForceHit et SilentAimTarget
        local Plr = getPlr()
        local enabled = getEnabled()
        local ForceHit = getForceHit()
        local SilentAimTarget = getSilentAimTarget()

        -- Vérifier si la cible est bien celle visée par l'aimbot ou le Silent Aim
        local isTargetValid = false
        if enabled and ForceHit and Plr and targetPlayer == Plr then
            isTargetValid = true
        elseif SilentAimTarget and targetPlayer == SilentAimTarget then
            isTargetValid = true
        end

        if not isTargetValid then
            print("Auto Toxic: Cible " .. targetPlayer.Name .. " n'est pas la cible actuelle (Plr: " .. (Plr and Plr.Name or "nil") .. ", SilentAimTarget: " .. (SilentAimTarget and SilentAimTarget.Name or "nil") .. ")")
            return
        end

        -- Vérifier si le personnage ou le humanoid a changé (par exemple, après un respawn/reset)
        if not targetPlayer.Character or targetPlayer.Character ~= humanoid.Parent then
            print("Auto Toxic: Personnage de " .. targetPlayer.Name .. " a changé, arrêt de la surveillance")
            healthMonitorConnection:Disconnect()
            monitoredTargets[targetPlayer] = nil
            messageSentForLowHP[targetPlayer] = nil
            return
        end

        local humanoid = targetPlayer.Character:FindFirstChild("Humanoid")
        if not humanoid then
            print("Auto Toxic: Humanoid non trouvé pour " .. targetPlayer.Name .. ", arrêt de la surveillance")
            healthMonitorConnection:Disconnect()
            monitoredTargets[targetPlayer] = nil
            messageSentForLowHP[targetPlayer] = nil
            return
        end

        -- Vérifier le Wall Check avant d'envoyer un message
        local localCharacter = game.Players.LocalPlayer.Character
        local localPosition = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart") and localCharacter.HumanoidRootPart.Position
        local targetPosition = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character.Head.Position

        if localPosition and targetPosition and IsTargetBehindWall(localPosition, targetPosition, forceHitModule) then
            print("Auto Toxic: Cible " .. targetPlayer.Name .. " derrière un mur, message non envoyé")
            return
        end

        local currentHealth = humanoid.Health

        -- Vérifier si les HP sont entre 0.5 et 1
        if currentHealth >= 0.5 and currentHealth <= 1 then
            -- Vérifier si un message a déjà été envoyé pour cette instance de HP bas
            if not messageSentForLowHP[targetPlayer] then
                print("Auto Toxic: HP de " .. targetPlayer.Name .. " tombés à " .. currentHealth .. " - Envoi d'un message")
                sendRandomMessage()
                messageSentForLowHP[targetPlayer] = true
            end
        else
            -- Réinitialiser l'état si les HP sortent de la plage 0.5-1
            messageSentForLowHP[targetPlayer] = nil
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
        monitoredTargets[targetPlayer] = nil
        messageSentForLowHP[targetPlayer] = nil
        -- Reprendre la surveillance si la cible est toujours sélectionnée
        local Plr = getPlr()
        local enabled = getEnabled()
        local ForceHit = getForceHit()
        local SilentAimTarget = getSilentAimTarget()
        if isEnabled and (targetPlayer == Plr or targetPlayer == SilentAimTarget) then
            print("Auto Toxic: Reprise de la surveillance pour " .. targetPlayer.Name .. " après respawn/reset")
            monitorTargetHealth(targetPlayer, getPlr, getEnabled, getForceHit, getSilentAimTarget, forceHitModule)
        end
    end)

    -- Stocker les connexions pour les nettoyer plus tard
    table.insert(connections, healthMonitorConnection)
    table.insert(connections, characterAddedConnection)
end

-- Fonction pour activer le module
function AutoToxicModule:Enable(getPlr, getEnabled, getForceHit, getSilentAimTarget, forceHitModule)
    if isEnabled then
        print("Auto Toxic: Déjà activé")
        return
    end

    -- Vérifier que les fonctions de récupération des variables sont fournies
    if not getPlr or not getEnabled or not getForceHit or not getSilentAimTarget or not forceHitModule then
        error("AutoToxicModule:Enable requires getPlr, getEnabled, getForceHit, getSilentAimTarget, and forceHitModule as arguments")
    end

    isEnabled = true
    print("Auto Toxic activé")

    -- Surveiller les changements de cible dans Plr et SilentAimTarget
    local targetMonitorConnection
    targetMonitorConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not isEnabled then
            targetMonitorConnection:Disconnect()
            return
        end

        -- Récupérer les valeurs actuelles de Plr, enabled, ForceHit et SilentAimTarget
        local Plr = getPlr()
        local enabled = getEnabled()
        local ForceHit = getForceHit()
        local SilentAimTarget = getSilentAimTarget()

        -- Vérifier si une cible est sélectionnée (soit par l'aimbot, soit par le Silent Aim)
        local currentTarget = nil
        if enabled and ForceHit and Plr then
            currentTarget = Plr
        elseif SilentAimTarget then
            currentTarget = SilentAimTarget
        end

        if currentTarget and not monitoredTargets[currentTarget] then
            print("Auto Toxic: Début de la surveillance des HP pour " .. currentTarget.Name)
            monitorTargetHealth(currentTarget, getPlr, getEnabled, getForceHit, getSilentAimTarget, forceHitModule)
        else
            -- Si les conditions ne sont plus remplies, nettoyer les cibles surveillées
            for target, _ in pairs(monitoredTargets) do
                if target ~= Plr and target ~= SilentAimTarget then
                    print("Auto Toxic: Arrêt de la surveillance pour " .. target.Name .. " (conditions non remplies)")
                    monitoredTargets[target] = nil
                    messageSentForLowHP[target] = nil
                end
            end
        end
    end)

    table.insert(connections, targetMonitorConnection)
end

-- Fonction pour désactiver le module
function AutoToxicModule:Disable()
    if not isEnabled then
        print("Auto Toxic: Déjà désactivé")
        return
    end

    isEnabled = false
    print("Auto Toxic désactivé")

    -- Nettoyer toutes les connexions
    for _, connection in pairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    -- Réinitialiser les tables
    monitoredTargets = {}
    messageSentForLowHP = {}
end

return AutoToxicModule

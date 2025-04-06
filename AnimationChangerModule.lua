-- AnimationChangerModule (ModuleScript)
local AnimationChangerModule = {}

-- Services
local Players = game:GetService("Players")

-- Variables du module
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local characterAddedConnection -- Pour stocker la connexion à CharacterAdded
local isRunning = false -- Pour suivre si le module est actif
local currentAnimation = "Default Animation" -- Animation par défaut

-- Table des animations
local animationIdMap = {
    ["Default Animation"] = {
        idle = "http://www.roblox.com/asset/?id=507766388",
        idle2 = "http://www.roblox.com/asset/?id=507766388", -- Default doesn't have a second idle, so reusing the first
        walk = "http://www.roblox.com/asset/?id=507777826",
        run = "http://www.roblox.com/asset/?id=507767714",
        jump = "http://www.roblox.com/asset/?id=507765000",
        climb = "http://www.roblox.com/asset/?id=507765644", -- Default climb animation (you can search for the exact ID if needed)
        fall = "http://www.roblox.com/asset/?id=507767968"  -- Default fall animation (you can search for the exact ID if needed)
    },
    ["Rthro Animation"] = {
        idle = "http://www.roblox.com/asset/?id=2510196951",
        idle2 = "http://www.roblox.com/asset/?id=2510197257", -- Rthro has a second idle animation
        walk = "http://www.roblox.com/asset/?id=2510202577",
        run = "http://www.roblox.com/asset/?id=2510198475",
        jump = "http://www.roblox.com/asset/?id=2510197830",
        climb = "http://www.roblox.com/asset/?id=2510192778",
        fall = "http://www.roblox.com/asset/?id=2510195892"
    },
    ["Oldschool Animation"] = {
        idle = "http://www.roblox.com/asset/?id=5319831086",
        idle2 = "http://www.roblox.com/asset/?id=5319831086", -- Oldschool doesn't have a second idle, so reusing the first
        walk = "http://www.roblox.com/asset/?id=5319847204",
        run = "http://www.roblox.com/asset/?id=5319844329",
        jump = "http://www.roblox.com/asset/?id=5319841935",
        climb = "http://www.roblox.com/asset/?id=5319828216", -- Oldschool climb (you can search for the exact ID if needed)
        fall = "http://www.roblox.com/asset/?id=5319839762"  -- Oldschool fall (you can search for the exact ID if needed)
    },
    ["Toy Animation"] = {
        idle = "http://www.roblox.com/asset/?id=782845736",
        idle2 = "http://www.roblox.com/asset/?id=782841498", -- Toy has a second idle animation
        walk = "http://www.roblox.com/asset/?id=782843345",
        run = "http://www.roblox.com/asset/?id=782842708",
        jump = "http://www.roblox.com/asset/?id=782847020",
        climb = "http://www.roblox.com/asset/?id=782843869",
        fall = "http://www.roblox.com/asset/?id=782846423"
    },
    ["Stylish Animation"] = {
        idle = "http://www.roblox.com/asset/?id=616138447",
        idle2 = "http://www.roblox.com/asset/?id=616136790", -- Stylish has a second idle animation
        walk = "http://www.roblox.com/asset/?id=616146177",
        run = "http://www.roblox.com/asset/?id=616140816",
        jump = "http://www.roblox.com/asset/?id=616139451",
        climb = "http://www.roblox.com/asset/?id=616133594",
        fall = "http://www.roblox.com/asset/?id=616134815"
    },
    ["Robot Animation"] = {
        idle = "http://www.roblox.com/asset/?id=616089559",
        idle2 = "http://www.roblox.com/asset/?id=616088211", -- Robot has a second idle animation
        walk = "http://www.roblox.com/asset/?id=616095330",
        run = "http://www.roblox.com/asset/?id=616091570",
        jump = "http://www.roblox.com/asset/?id=616090535",
        climb = "http://www.roblox.com/asset/?id=616086039",
        fall = "http://www.roblox.com/asset/?id=616087089"
    },
    ["Bubbly Animation"] = {
        idle = "http://www.roblox.com/asset/?id=910009958",
        idle2 = "http://www.roblox.com/asset/?id=910004836", -- Bubbly has a second idle animation
        walk = "http://www.roblox.com/asset/?id=910034870",
        run = "http://www.roblox.com/asset/?id=910025107",
        jump = "http://www.roblox.com/asset/?id=910016857",
        climb = "http://www.roblox.com/asset/?id=910028158", -- Using swim as a placeholder since climb isn't specified
        fall = "http://www.roblox.com/asset/?id=910001910"
    },
    ["Ninja Animation"] = {
        idle = "http://www.roblox.com/asset/?id=656118341",
        idle2 = "http://www.roblox.com/asset/?id=656117400", -- Ninja has a second idle animation
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Cartoony Animation"] = {
        idle = "http://www.roblox.com/asset/?id=742638445",
        idle2 = "http://www.roblox.com/asset/?id=742637544", -- Cartoony has a second idle animation
        walk = "http://www.roblox.com/asset/?id=742640026",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Mage Animation"] = {
        idle = "http://www.roblox.com/asset/?id=707855907",
        idle2 = "http://www.roblox.com/asset/?id=707742142", -- Mage has a second idle animation
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=707861613",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Elder Animation"] = {
        idle = "http://www.roblox.com/asset/?id=845400520",
        idle2 = "http://www.roblox.com/asset/?id=845397899", -- Elder has a second idle animation
        walk = "http://www.roblox.com/asset/?id=845403856",
        run = "http://www.roblox.com/asset/?id=845386501",
        jump = "http://www.roblox.com/asset/?id=845398858",
        climb = "http://www.roblox.com/asset/?id=845392038",
        fall = "http://www.roblox.com/asset/?id=845396048"
    },
    ["Werewolf Animation"] = {
        idle = "http://www.roblox.com/asset/?id=1083214717",
        idle2 = "http://www.roblox.com/asset/?id=1083195517", -- Werewolf has a second idle animation
        walk = "http://www.roblox.com/asset/?id=1083178339",
        run = "http://www.roblox.com/asset/?id=1083216690",
        jump = "http://www.roblox.com/asset/?id=1083218792",
        climb = "http://www.roblox.com/asset/?id=1083182000",
        fall = "http://www.roblox.com/asset/?id=1083189019"
    },
    ["Vampire Animation"] = {
        idle = "http://www.roblox.com/asset/?id=1083450166",
        idle2 = "http://www.roblox.com/asset/?id=1083445855", -- Vampire has a second idle animation
        walk = "http://www.roblox.com/asset/?id=1083473930",
        run = "http://www.roblox.com/asset/?id=1083462077",
        jump = "http://www.roblox.com/asset/?id=1083455352",
        climb = "http://www.roblox.com/asset/?id=1083439238",
        fall = "http://www.roblox.com/asset/?id=1083443587"
    },
    ["Astronaut Animation"] = {
        idle = "http://www.roblox.com/asset/?id=891633237",
        idle2 = "http://www.roblox.com/asset/?id=891621366", -- Astronaut has a second idle animation
        walk = "http://www.roblox.com/asset/?id=891667138",
        run = "http://www.roblox.com/asset/?id=891636393",
        jump = "http://www.roblox.com/asset/?id=891627522",
        climb = "http://www.roblox.com/asset/?id=891609353",
        fall = "http://www.roblox.com/asset/?id=891617961"
    },
    ["Superhero Animation"] = {
        idle = "http://www.roblox.com/asset/?id=616113536",
        idle2 = "http://www.roblox.com/asset/?id=616111295", -- Superhero has a second idle animation
        walk = "http://www.roblox.com/asset/?id=616122287",
        run = "http://www.roblox.com/asset/?id=616117076",
        jump = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Levitation Animation"] = {
        idle = "http://www.roblox.com/asset/?id=616008087",
        idle2 = "http://www.roblox.com/asset/?id=616006778", -- Levitation has a second idle animation
        walk = "http://www.roblox.com/asset/?id=616013216",
        run = "http://www.roblox.com/asset/?id=616010382",
        jump = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall = "http://www.roblox.com/asset/?id=616005863"
    },
    ["Knight Animation"] = {
        idle = "http://www.roblox.com/asset/?id=657568135",
        idle2 = "http://www.roblox.com/asset/?id=657595757", -- Knight has a second idle animation
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=657564596",
        jump = "http://www.roblox.com/asset/?id=658409194",
        climb = "http://www.roblox.com/asset/?id=658360781",
        fall = "http://www.roblox.com/asset/?id=657600338"
    },
    ["Pirate Animation"] = {
        idle = "http://www.roblox.com/asset/?id=750782770",
        idle2 = "http://www.roblox.com/asset/?id=750781874", -- Pirate has a second idle animation
        walk = "http://www.roblox.com/asset/?id=750785693",
        run = "http://www.roblox.com/asset/?id=750783738",
        jump = "http://www.roblox.com/asset/?id=750782230",
        climb = "http://www.roblox.com/asset/?id=750779899",
        fall = "http://www.roblox.com/asset/?id=750780242"
    },
    -- Ajout de l'animation Sneaky avec toutes les animations (idle1, idle2, walk, run, jump, climb, fall)
    ["Sneaky Animation"] = {
        idle = "http://www.roblox.com/asset/?id=1132473842", -- Animation1 (première idle)
        idle2 = "http://www.roblox.com/asset/?id=1132477671", -- Animation2 (deuxième idle)
        walk = "http://www.roblox.com/asset/?id=1132510133",
        run = "http://www.roblox.com/asset/?id=1132494274",
        jump = "http://www.roblox.com/asset/?id=1132489853",
        climb = "http://www.roblox.com/asset/?id=1132461372",
        fall = "http://www.roblox.com/asset/?id=1132469004"
    }
}

-- Fonction pour appliquer une animation
function AnimationChangerModule:ApplyAnimation(selectedOption)
    currentAnimation = selectedOption -- Mettre à jour l'animation actuelle
    local animate = character:FindFirstChild("Animate")
    if not animate then
        print("Erreur : Animate non trouvé dans le personnage")
        return
    end

    local animations = animationIdMap[selectedOption]
    if animations then
        if animate:FindFirstChild("idle") then
            animate.idle.Animation1.AnimationId = animations.idle
            animate.idle.Animation2.AnimationId = animations.idle2 -- Appliquer la deuxième animation idle
        end
        if animate:FindFirstChild("walk") then
            animate.walk.WalkAnim.AnimationId = animations.walk
        end
        if animate:FindFirstChild("run") then
            animate.run.RunAnim.AnimationId = animations.run
        end
        if animate:FindFirstChild("jump") then
            animate.jump.JumpAnim.AnimationId = animations.jump
        end
        if animate:FindFirstChild("climb") then
            animate.climb.ClimbAnim.AnimationId = animations.climb
        end
        if animate:FindFirstChild("fall") then
            animate.fall.FallAnim.AnimationId = animations.fall
        end
        print("Animation applied:", selectedOption)
    else
        print("Animation not found for selection:", selectedOption)
    end
end

-- Fonction pour gérer le respawn
local function onCharacterRespawn(newChar)
    character = newChar
    local animate = character:WaitForChild("Animate", 5) -- Attendre jusqu'à 5 secondes
    if animate then
        AnimationChangerModule:ApplyAnimation(currentAnimation)
    else
        print("Erreur : Animate non trouvé après respawn")
    end
end

-- Fonction pour démarrer la gestion des animations
function AnimationChangerModule:Start()
    if isRunning then
        print("Animation Changer is already running!")
        return
    end

    -- Gérer le respawn
    characterAddedConnection = player.CharacterAdded:Connect(onCharacterRespawn)

    -- Appliquer l'animation initiale
    if character then
        onCharacterRespawn(character)
    end

    isRunning = true
    print("Animation Changer module started successfully!")
end

-- Fonction pour arrêter la gestion des animations
function AnimationChangerModule:Stop()
    if not isRunning then
        print("Animation Changer is not running!")
        return
    end

    -- Déconnecter les événements
    if characterAddedConnection then
        characterAddedConnection:Disconnect()
        characterAddedConnection = nil
    end

    isRunning = false
    print("Animation Changer module stopped.")
end

-- Fonction pour vérifier si le module est en cours d'exécution
function AnimationChangerModule:IsRunning()
    return isRunning
end

-- Fonction pour obtenir la liste des animations disponibles
function AnimationChangerModule:GetAnimationOptions()
    local options = {}
    for animationName, _ in pairs(animationIdMap) do
        table.insert(options, animationName)
    end
    return options
end

return AnimationChangerModule

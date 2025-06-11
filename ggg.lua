local InterServerCommunicationModule = {}
InterServerCommunicationModule.container = nil

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local function isHttpRequestAvailable()
    local success, result = pcall(function() return http_request end)
    return success and type(result) == "function"
end

if not isHttpRequestAvailable() then
    warn("http_request is not available. Ensure your exploit executor is configured.")
    return
end

local player = Players.LocalPlayer
local currentServerId = nil
local displayedMessages = {}
local playerServerCount = 0
local serverButtons = {}
local serverRemovalTimers = {}
local dragging = false
local dragStart = nil
local startPos = nil
local serverOwners = {}
local isBlacklisted = false
local blacklistCheckEnabled = true
local isEnabled = false
local lastPosition = nil

local function createUI(initialPosition)
    if InterServerCommunicationModule.container then return end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game:GetService("CoreGui")

    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local sidebarWidth = isMobile and 60 or 80
    local chatWidth = isMobile and 300 or 450

    InterServerCommunicationModule.container = Instance.new("Frame")
    InterServerCommunicationModule.container.Size = UDim2.new(0, sidebarWidth + chatWidth, isMobile and 0.8 or 1, 0)
    InterServerCommunicationModule.container.BackgroundTransparency = 1
    InterServerCommunicationModule.container.Position = initialPosition or UDim2.new(0, 0, 0, 0)
    InterServerCommunicationModule.container.Visible = false
    InterServerCommunicationModule.container.Parent = screenGui
end

function InterServerCommunicationModule:SetEnabled(value)
    isEnabled = value
    if isEnabled and not InterServerCommunicationModule.container then
        createUI(lastPosition)
    end
    if InterServerCommunicationModule.container then
        InterServerCommunicationModule.container.Visible = isEnabled
        if isEnabled then
        else
            lastPosition = InterServerCommunicationModule.container.Position
        end
    else
        warn("Container is nil, UI not created or failed to initialize")
    end
end

function InterServerCommunicationModule:IsEnabled()
    return isEnabled
end

if InterServerCommunicationModule and InterServerCommunicationModule.SetEnabled then
    print("Module works! Activating...")
    InterServerCommunicationModule:SetEnabled(true)
    wait(2)
    InterServerCommunicationModule:SetEnabled(false)
    print("Module deactivated.")
else
    print("Module or SetEnabled is nil. Something went wrong.")
end

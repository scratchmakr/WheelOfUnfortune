local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Network = require(ReplicatedStorage.Shared.Network)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.Character)
local CircleUtils = require(ReplicatedStorage.Shared.Utils.Circles)

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ToolService = require(ServerScriptService.Server.Services.ToolService)
local EventController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.EventController)

local Assets = ReplicatedStorage.Shared.Assets
local MusicalChairAssets = Assets.MusicalChairs
local 
local TOOL_NAME = Sword.Name
local YIELD_TIME = 3
local CHAIR_TIME = 15

local Format = require(script.Parent.Format)

local SwordFight = {}

function SwordFight.Start(props: Format.format)
    
    local playersAlive = props.playersAlive
    local eventTrove = props.eventTrove
    eventTrove:Add(function()
        for _, player in playersAlive do
            ToolService.revokePlayerTool(player, TOOL_NAME)
            props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        props.roundEnded = true
    end)
    
    for index, player in playersAlive do
        local origin, direction = CircleUtils.computeRayForSlice(index, #playersAlive, Vector3.zero, 100)
    end

    task.wait(YIELD_TIME)

    local finishTime = workspace.DistributedGameTime + CHAIR_TIME
    local finished = false
    local timer = SUBTRACTION_RATE
    local platformSize = DEFAULT_PLATFORM_SIZE
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt: number)
        if (workspace.DistributedGameTime >= finishTime or #playersAlive <= 0) and not finished then
            finished = true
            task.wait(1)
            eventTrove:Clean()
            return
        end

        timer -= dt
        if timer <= 0 then
            timer = SUBTRACTION_RATE
            platformSize = math.max(platformSize - SUBTRACTION_SIZE, MINIMUM_PLATFORM_SIZE)
            props.functions.resizeMap(platformSize)
        end
    end))

    props.functions.resizeMap(100)
end

return SwordFight
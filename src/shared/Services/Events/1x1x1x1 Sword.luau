local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Network = require(ReplicatedStorage.Shared.Network)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.Character)

local StarterPlayer = game:GetService("StarterPlayer")
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(ReplicatedStorage.Shared.Utils.Sound)

local Assets = ReplicatedStorage.Shared.Assets
local BossAssets = Assets["1x1x1x1 Sword"]
local SwordsFolder = BossAssets.Swords
local BossModel = BossAssets["1x1x1x1"]

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TeamGraveyard = {}
local SURVIVAL_TIME = 20
local SWORD_DISTANCE = 105
local SWORD_SPEED = 0.25
local SWORD_RATE = 0.5

local function createSword(seed: number, swordTrove: Trove.Trove, endTime: number)
    local random = Random.new(seed)
    local randomNumber = random:NextInteger(1, #SwordsFolder:GetChildren())
    local randomSword = SwordsFolder:FindFirstChild(`Sword{randomNumber}`)
    local sword = randomSword:Clone()
    sword.Parent = workspace

    swordTrove:Add(sword)

    task.delay(endTime - workspace.DistributedGameTime, function()
        sword:Destroy()
    end)

    local directions = {
        x = if randomNumber == 1 or randomNumber == 4 then SWORD_DISTANCE else 0,
        z = if randomNumber == 2 or randomNumber == 3 then SWORD_DISTANCE else 0,
    }
    local xDirection = randomNumber == 1 and -1 or 1
    local zDirection = randomNumber == 3 and -1 or 1
    local tween = TweenService:Create(sword, TweenInfo.new(1 / SWORD_SPEED), {
        CFrame = sword.CFrame + Vector3.new(
            directions.x * xDirection,
            0,
            directions.z * zDirection
        )
    })
    tween:Play()
    task.defer(function()
        tween.Completed:Wait()
        tween:Destroy()
        swordTrove:Clean()
    end)
    return sword
end

function TeamGraveyard.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local finishTime = workspace.DistributedGameTime + SURVIVAL_TIME
    local goalTime = Fusion.Value(finishTime)

    local playersAlive = props.playersAlive
    eventTrove:Add(function()
        for _, player in playersAlive do
            props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersAlive)
        props.roundEnded = true
    end)

    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Dodge 1x1x1x1's attacks!", finishTime)
    end

    local newMap = BossModel:Clone()
    newMap.Parent = workspace
    eventTrove:Add(newMap)

    local animationProps: Format.animationProps = {
        map = newMap,
        eventKey = props.eventKey,
        endTime = finishTime,
    }
    local debounce = false
    local timer = -1
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt)
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() and not debounce then
            debounce = true
           
            eventTrove:Clean()
        end

        timer -= dt
        if timer <= 0 and not debounce then
            timer = SWORD_RATE * Random.new():NextNumber(0.85, 1.15)
            for _, player in Players:GetPlayers() do
                Network.PlayEventAnimations:Server():Fire(player, animationProps)
            end
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }
    props.functions.resizeMap(100)
    return newMap
end

function TeamGraveyard.PlayAnimations(props: Format.animationProps)
    local endTime = props.endTime
    local swordTrove = Trove.new()
    local newMap = props.map
    local seed = props.seed
    local sword = createSword(seed, swordTrove, endTime)

    local debounces = {}
    swordTrove:Add(sword.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
        if player and humanoid then
            if debounces[player] then return end
            debounces[player] = true
            task.delay(0.2, function()
                debounces[player] = false
            end)
            humanoid:TakeDamage(30)
            Network.TakeDamage:Client():Fire(30)
        end
    end))
end

return TeamGraveyard
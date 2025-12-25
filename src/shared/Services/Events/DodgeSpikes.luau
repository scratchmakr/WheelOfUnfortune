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
local DodgeSpikesAssets = Assets.DodgeSpikes
local PlatformPart = DodgeSpikesAssets.Platform
local SpikeSound = DodgeSpikesAssets.SpikeSound
local Spike = DodgeSpikesAssets.Spike

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local DodgeSpikes = {}
local SURVIVAL_TIME = 15
local SPIKE_RATE = 0.75
local MINIMUM_SPIKE_RATE = 0.1
local SPIKE_HEIGHT = 10
local SPIKE_LIFETIME = 5

function DodgeSpikes.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local finishTime = workspace.DistributedGameTime + SURVIVAL_TIME
    local playersAlive = props.playersAlive
    eventTrove:Add(function()
        for _, player in playersAlive do
            -- props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersAlive)
        props.roundEnded = true
    end)

    for _, player in playersAlive do
        props.functions.changeHumanoidStats(player, {
            WalkSpeed = StarterPlayer.CharacterWalkSpeed * 1.5,
            -- JumpHeight = StarterPlayer.CharacterJumpHeight,
        })
        Network.SendAnnouncement:Server():Fire(player, "Dodge the spikes!", finishTime)
    end

    local startTime = workspace.DistributedGameTime + 2
    local spikeRate = SPIKE_RATE
    local spikeCount = 0
    local timer = -1
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt: number)
        if workspace.DistributedGameTime < startTime then
            return
        end
        if workspace.DistributedGameTime >= finishTime then
            task.wait(1)
            eventTrove:Clean()
            return
        end
        timer -= dt
        if timer <= 0 then
            timer = spikeRate * Random.new():NextNumber(0.85, 1.15)
            spikeRate = math.max(MINIMUM_SPIKE_RATE, spikeRate - 0.05)
            spikeCount += 1
            local seed = spikeCount + math.round(workspace.DistributedGameTime)
            local animationProps: Format.animationProps = {
                map = nil,
                eventKey = props.eventKey,
                endTime = finishTime,
                seed = seed,
            }
            for _, player in Players:GetPlayers() do
                Network.PlayEventAnimations:Server():Fire(player, animationProps)
            end
        end
    end))

    props.functions.resizeMap(85)
end

function DodgeSpikes.PlayAnimations(props: Format.animationProps) -- client
    local seed = props.seed
    local random = Random.new(seed)
    local localPlayer = Players.LocalPlayer
    local endTime = props.endTime
    local spikeTrove = Trove.new()

    local newSpike = Spike:Clone()
    newSpike.Parent = workspace

    local endTimeLeft = endTime - workspace.DistributedGameTime
    local lifetime = endTimeLeft > SPIKE_LIFETIME and SPIKE_LIFETIME or endTimeLeft
    task.delay(lifetime, function()
        spikeTrove:Clean()
    end)

    local scale = random:NextNumber(0.5, 1.5)
    local randomPosition = CharacterUtils.getPositionWithinPlatform(PlatformPart, false, seed)
    newSpike:ScaleTo(scale)
    newSpike:PivotTo(CFrame.new(randomPosition))
    local spikeMesh = newSpike.SpikeMesh
    local hitbox = newSpike.Hitbox
    local hitboxSize = hitbox.Size
    spikeMesh.Transparency = 1
    spikeMesh.Position -= Vector3.new(0, SPIKE_HEIGHT, 0)
    hitbox.Size = Vector3.one * .001
    Spring.target(hitbox, 0.7, 1, {
        Size = hitboxSize,
    })
    spikeTrove:Add(newSpike)
    task.wait(1)
    Spring.target(spikeMesh, 1, 2, {
        Transparency = 0,
    })
    Spring.target(spikeMesh, 0.7, 1, {
        Position = spikeMesh.Position + Vector3.new(0, SPIKE_HEIGHT, 0),
    })

    local debounce = false
    spikeTrove:Add(spikeMesh.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        local character = player and player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and player == localPlayer and not debounce then
            debounce = true
            task.delay(0.2, function()
                debounce = false
            end)
            humanoid:TakeDamage(25)
        end
    end))
    SoundUtils.playSound(SpikeSound, newSpike)
end

return DodgeSpikes
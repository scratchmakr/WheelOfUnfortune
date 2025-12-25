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
local TrainsAssets = Assets.Trains
local TrainHornSound = TrainsAssets.TrainHorn
local Train = TrainsAssets.Train
local MiddlePart = TrainsAssets.Middle
local MapModel = TrainsAssets.Map

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local Trains = {}
local TOTAL_TRAINS = 15
local TRAIN_SPEED = 2.5
local TRAIN_RATE = 1.5
local MINIMUM_TRAIN_RATE = 0.5
local TRAIN_DISTANCE = 250

function Trains.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

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
        props.functions.changeHumanoidStats(player, {
            WalkSpeed = StarterPlayer.CharacterWalkSpeed * 1.5,
            -- JumpHeight = StarterPlayer.CharacterJumpHeight,
        })
        Network.SendAnnouncement:Server():Fire(player, "Survive the trains!")
    end

    local animationProps: Format.animationProps = {
        map = nil,
        eventKey = props.eventKey,
    }

    for _, player in Players:GetPlayers() do
        Network.PlayEventAnimations:Server():Fire(player, animationProps)
    end

    local map = MapModel:Clone()
    map.Parent = workspace

    eventTrove:Add(map)
    local startTime = workspace.DistributedGameTime + 2
    local trainRate = TRAIN_RATE
    local trainCount = 0
    local timer = -1
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt: number)
        if workspace.DistributedGameTime < startTime then
            return
        end
        if trainCount >= TOTAL_TRAINS then
            task.wait(2.5)
            eventTrove:Clean()
            return
        end
        timer -= dt
        if timer <= 0 then
            timer = trainRate * Random.new():NextNumber(0.85, 1.15)
            trainRate = math.max(MINIMUM_TRAIN_RATE, trainRate - 0.1)
            trainCount += 1
            local seed = trainCount + math.round(workspace.DistributedGameTime)
            local random = Random.new(seed)
            local trainTrove = Trove.new()
            local train = Train:Clone()
            local trainPart = train.Train
            local trainHitbox = train.Hitbox
            local trainCFrame: CFrame = MiddlePart.CFrame * CFrame.Angles(0, math.pi * random:NextNumber(0, 1), 0) * CFrame.new(0, 0, TRAIN_DISTANCE)
            local trainDirection = CFrame.lookAt(trainCFrame.Position, MiddlePart.Position)
            trainPart.VectorForce.Force = Vector3.new(0, trainPart:GetMass() * workspace.Gravity, 0) - (Vector3.new(trainDirection.X, 0, trainDirection.Z) * TRAIN_SPEED * trainPart:GetMass())
            train.Parent = workspace
            train:PivotTo(CFrame.new(trainCFrame.Position) * CFrame.Angles(trainDirection:ToEulerAngles()))
            trainTrove:Add(trainHitbox.Touched:Connect(function(hit)
                local player = Players:GetPlayerFromCharacter(hit.Parent)
                local character = player and player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                local hrp = humanoid and character:FindFirstChild("HumanoidRootPart")
                local mass = hrp and CharacterUtils.getMass(character)
                if hrp and mass then
                    humanoid:TakeDamage(100)
                    hrp:ApplyImpulse((Vector3.new(trainDirection.X, 0, trainDirection.Z) * 5 * mass) + Vector3.new(0, 5 * mass, 0))
                end
            end))
            trainTrove:Add(train)
            SoundUtils.playSound(TrainHornSound, trainPart)
        end
    end))

    props.functions.resizeMap(100)
end

-- function Trains.PlayAnimations(props: Format.animationProps) -- client
--     local localPlayer = Players.LocalPlayer
--     local endTime = props.endTime
--     local swordTrove = Trove.new()
--     local newMap = props.map

    
-- end

return Trains
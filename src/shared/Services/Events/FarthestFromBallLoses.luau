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
local EventController = require(StarterPlayer.StarterPlayerScripts.Client.Controllers.EventController)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Sound = require(ReplicatedStorage.Shared.Utils.Sound)

local Assets = ReplicatedStorage.Shared.Assets
local FarthestFromBallLosesAssets = Assets.FarthestFromBallLoses
local PlatformPart = FarthestFromBallLosesAssets.Platform
local Ball = FarthestFromBallLosesAssets.Ball
local WooshSound = FarthestFromBallLosesAssets.Woosh

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local FarthestFromBallLoses = {}
local REDIRECTION_TIME = 10
local BALL_FIND_TIME = 10
local BALL_SPEED = 0.5
local BALL_DAMP = 0.7
local REDIRECTION_RATE = 1
local MINIMUM_REDIRECTION_RATE = 0.25
local MAXIMUM_BALL_SPEED = 2
local FINDING_TIME = 7
local YIELD_TIME = 1.5

function FarthestFromBallLoses.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local finishTime = workspace.DistributedGameTime + REDIRECTION_TIME
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
            WalkSpeed = StarterPlayer.CharacterWalkSpeed * 2,
            -- JumpHeight = StarterPlayer.CharacterJumpHeight,
        })
        Network.SendAnnouncement:Server():Fire(player, "Keep track of the glowing white ball!", finishTime)
    end

    local platformCFrame = PlatformPart.CFrame
    local newBall = Ball:Clone()
    newBall.Parent = workspace
    newBall.CFrame = CFrame.new(platformCFrame.Position.X, Ball.Position.Y, platformCFrame.Position.Z)
    eventTrove:Add(newBall)
    SoundUtils.playSound(Assets.SFX.Pop, workspace)

    local startTime = workspace.DistributedGameTime + 2
    local timer = -1

    local lastPosition
    local findingPeriod = false
    local redirectionRate = REDIRECTION_RATE
    local redirectionCount = 0
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt: number)
        if workspace.DistributedGameTime < startTime then
            return
        end

        if workspace.DistributedGameTime >= finishTime and not findingPeriod then
            findingPeriod = true
            task.wait(YIELD_TIME)
            newBall.Parent = script
            for _, player in playersAlive do
                Network.ToggleOthersVisibility:Server():Fire(player, false)
                props.functions.changeHumanoidStats(player, {
                    WalkSpeed = StarterPlayer.CharacterWalkSpeed * 1.5,
                })
                Network.SendAnnouncement:Server():Fire(player, "The furthest player from the ball will be eliminated!", finishTime + FINDING_TIME + YIELD_TIME)
            end
            task.delay(FINDING_TIME, function()
                for _, player in playersAlive do
                    props.functions.changeHumanoidStats(player, {
                        WalkSpeed = 0,
                    })
                end
                -- print("bal revealed", newBall)
                for _, player in playersAlive do
                    Network.ToggleOthersVisibility:Server():Fire(player, true)
                end
                newBall.Parent = workspace
                task.wait(3)
                local furthestPlayer = nil
                local furthestDistance = 0

                for _, player in playersAlive do
                    local character = player.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local distance = (hrp.Position - lastPosition).Magnitude
                        if distance > furthestDistance then
                            furthestDistance = distance
                            furthestPlayer = player
                        end
                    end
                end

                if furthestPlayer then
                    local character = furthestPlayer.Character
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Health = 0
                    end

                    Network.SendAnnouncement:Server():Fire(furthestPlayer, `{furthestPlayer.Name} has been eliminated!`)
                else
                    Network.SendAnnouncement:Server():Fire(furthestPlayer, "No player was found furthest from the ball!")
                end
                task.wait(1)
                eventTrove:Clean()
            end)

            return
        end

        timer -= dt
        if timer <= 0 and not findingPeriod then
            timer = redirectionRate * Random.new():NextNumber(0.85, 1.15)
            redirectionRate = math.max(MINIMUM_REDIRECTION_RATE, redirectionRate - 0.15)
            redirectionCount += 1
            local seed = redirectionCount + math.round(workspace.DistributedGameTime)
            local animationProps: Format.animationProps = {
                map = newBall,
                eventKey = props.eventKey,
                endTime = finishTime,
                seed = seed,
                iteration = redirectionCount,
            }
            for _, player in Players:GetPlayers() do
                Network.PlayEventAnimations:Server():Fire(player, animationProps)
            end
            lastPosition = CharacterUtils.getPositionWithinPlatform(PlatformPart, false, seed)
        end
    end))

    props.functions.resizeMap(150)
end

function FarthestFromBallLoses.PlayAnimations(props: Format.animationProps) -- client
    local seed = props.seed
    local ball = props.map
    local iteration = props.iteration
    local ballSpeed = math.min(MAXIMUM_BALL_SPEED, BALL_SPEED + (iteration * 0.1))

    local randomPosition = CharacterUtils.getPositionWithinPlatform(PlatformPart, false, seed)
    Spring.target(ball, BALL_DAMP, ballSpeed, {
        CFrame = CFrame.new(randomPosition.X, Ball.Position.Y, randomPosition.Z),
    })
    SoundUtils.playSound(WooshSound, workspace, true)
end

return FarthestFromBallLoses
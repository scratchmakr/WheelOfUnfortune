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
local TeamGraveyardAssets = Assets.TeamGraveyard
local TeamGraveyardMap = TeamGraveyardAssets.TeamGraveyard
local Hand = TeamGraveyardAssets.Hand

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TeamGraveyard = {}
local PREP_TIME = 5
local YIELD_TIME = 1

function TeamGraveyard.Start(props: Format.format)
    local seed = props.seed
    local random = Random.new(seed)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local finishTime = workspace.DistributedGameTime + PREP_TIME
    local goalTime = Fusion.Value(finishTime)

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
        Network.SendAnnouncement:Server():Fire(player, "Stand on either graveyard or die...", finishTime)
    end

    local newMap = TeamGraveyardMap:Clone()
    local leftGraveyard = newMap.Graves.Left
    local rightGraveyard = newMap.Graves.Right
    newMap.Parent = workspace
    eventTrove:Add(newMap)

    local debounce = false
    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() and not debounce then
            debounce = true
            local playerSides = {}
            for _, player in playersAlive do
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = hrp and character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = 0
                    humanoid.JumpHeight = 0

                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Include
                    raycastParams.FilterDescendantsInstances = {newMap}
                    local raycastResult = workspace:Raycast(character.PrimaryPart.Position, Vector3.new(0, -10, 0), raycastParams)
                    print("raycastResult", raycastResult)
                    if not raycastResult then
                        humanoid.Health = 0
                    end

                    local distance1 = (hrp.Position - leftGraveyard.PrimaryPart.Position).Magnitude
                    local distance2 = (hrp.Position - rightGraveyard.PrimaryPart.Position).Magnitude
                    local closestGraveyard = distance1 < distance2 and leftGraveyard or rightGraveyard
                    playerSides[player] = closestGraveyard
                end
                task.delay(YIELD_TIME, function()
                    Network.SendAnnouncement:Server():Fire(player, "Goodluck...")
                end)
            end

            task.wait(YIELD_TIME)
            local handTrove = eventTrove:Extend()
            local random = random:NextInteger(1, 2)
            local side = random == 1 and leftGraveyard or rightGraveyard
            local handAttch: Attachment = side.Main:FindFirstChild("HandPos")
            local newHand = Fusion.Hydrate(Hand:Clone()) {
                Parent = workspace,
            }
            newHand:PivotTo(CFrame.new(handAttch.WorldCFrame.Position) * CFrame.Angles(Hand:GetPivot():ToEulerAngles()))
            local tween = TweenService:Create(newHand.PrimaryPart, TweenInfo.new(2.5), {
                CFrame = newHand:GetPivot() - Vector3.new(0, 150, 0),
            })
            tween:Play()
            handTrove:Add(tween)
            handTrove:Add(newHand)

            handTrove:Add(RunService.Heartbeat:Connect(function()
                for _, player in playersAlive do
                    local character = player.Character
                    local head = character and character:FindFirstChild("Head")
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    if head and head.Position.Y > (newHand.PrimaryPart.Position.Y - 5) then
                        if playerSides[player] == side then
                            humanoid.Health = 0
                        end
                    end
                end
            end))
            SoundUtils.playSound(TeamGraveyardAssets.BreatheDeath, newHand)
            tween.Completed:Wait()
            handTrove:Clean()
            task.wait(1)
            eventTrove:Clean()
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }

    local animationProps: Format.animationProps = {
        map = newMap,
        eventKey = props.eventKey
    }
    for _, player in Players:GetPlayers() do
        Network.PlayEventAnimations:Server():Fire(player, animationProps)
    end

    return newMap
end

function TeamGraveyard.PlayAnimations(props: Format.animationProps)
    local newMap = props.map
    local graveyardFolder = newMap.Graves
    
    -- local graveyardTrove = Trove.new()
    for _, graveyard in graveyardFolder:GetChildren() do
        local dirt = graveyard:FindFirstChild("Main")
        if dirt then
            for _, child in dirt:GetChildren() do
                if child:IsA("Texture") then
                    Spring.target(child, 1, 1, {
                        Transparency = 0,
                    })
                end
            end
        end

        local Stone = graveyard:FindFirstChild("Stone")
        local PrimaryPart = Stone and Stone.PrimaryPart
        if PrimaryPart then
            for _, child in Stone:GetChildren() do
                if child:IsA("BasePart") then
                    child.Transparency = 0
                end
            end
            PrimaryPart.CFrame -= Vector3.new(0, 15.5, 0)

            local tween = TweenService:Create(PrimaryPart, TweenInfo.new(4.146), {
                CFrame = PrimaryPart.CFrame + Vector3.new(0, 15.5, 0),
            })
            tween:Play()
            SoundUtils.playSound(TeamGraveyardAssets.StoneGrind, PrimaryPart)
            SoundUtils.playSound(TeamGraveyardAssets.Rumbling, PrimaryPart)
        end
    end

end

return TeamGraveyard
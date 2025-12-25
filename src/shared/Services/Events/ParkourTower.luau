local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Network = require(ReplicatedStorage.Shared.Network)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)

local StarterPlayer = game:GetService("StarterPlayer")
local Sound = require(ReplicatedStorage.Shared.Utils.Sound)

local Assets = ReplicatedStorage.Shared.Assets
local ParkourTowerAssets = Assets.ParkourTower
local Map = ParkourTowerAssets.ParkourTower

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TileOutline = {}
local COMPLETION_TIME = 25

function TileOutline.Start(props: Format.format)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local goalTime = Fusion.Value(10000000)

    local playersAlive = props.playersAlive
    local playersFinished = {}
    eventTrove:Add(function()
        for _, player in playersAlive do
            if not table.find(playersFinished, player) then
                local character = player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            else
                props.functions.teleportBackToPlatform(player)
            end
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersFinished, #playersAlive)
        props.roundEnded = true
    end)

    local newMap = Map:Clone()
    newMap.Parent = workspace

    task.defer(function()
        task.wait(1)
        local animationProps = {
            map = newMap,
            eventKey = props.eventKey
        } :: Format.animationProps

        for _, player in Players:GetPlayers() do
            Network.PlayEventAnimations:Server():Fire(player, animationProps)
            task.delay(1, function()
                local finishTime = workspace.DistributedGameTime + COMPLETION_TIME
                goalTime:set(finishTime)
                for _, player in playersAlive do
                    Network.SendAnnouncement:Server():Fire(player, "Make it to the top of the tower!", finishTime)
                end
            end)
        end
    end)
    
    eventTrove:Add(newMap)
    eventTrove:Add(newMap.Tower.FinishPart.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if player then
            table.insert(playersFinished, player)
            -- TODO: ADD FINISH SFX
            if #playersFinished >= #playersAlive then
                props.eventTrove:Clean()
            end
        end
    end))

    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() then
            eventTrove:Clean()
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }

    return newMap
end

function TileOutline.PlayAnimations(props: Format.animationProps)
    local newMap = props.map

    local towerModel = newMap.Tower
    local platformsFolder = towerModel.Platforms
    local mainPart = towerModel.Main

    for i = 1, #platformsFolder:GetChildren() do
        local platform = platformsFolder:FindFirstChild(tostring(i))
        local correspondingAttachment: Attachment = platform and mainPart:FindFirstChild(platform:GetAttribute("Side"))
        if correspondingAttachment and correspondingAttachment:IsA("Attachment") then
            local position = correspondingAttachment.WorldCFrame.Position
            Spring.target(platform, 0.7, 0.8, {
                CFrame = CFrame.new(Vector3.new(position.X, platform.Position.Y, position.Z))
            })
            SoundUtils.playSound(Assets.SFX.Woosh)
        task.wait(0.2)
        end
    end
end

return TileOutline
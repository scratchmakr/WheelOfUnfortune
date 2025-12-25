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
local Sound = require(ReplicatedStorage.Shared.Utils.Sound)

local Assets = ReplicatedStorage.Shared.Assets
local RisingLavaAssets = Assets.RisingLava
local Map = RisingLavaAssets.RisingLava
local Lava = RisingLavaAssets.Lava

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TileOutline = {}
local RISING_TIME = 10
local LAVA_HEIGHT = 45
local READY_TIME = 10

function TileOutline.Start(props: Format.format)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local goalTime = Fusion.Value(workspace.DistributedGameTime + READY_TIME)

    local playersAlive = props.playersAlive
    eventTrove:Add(function()
        for _, player in playersAlive do
            props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersAlive)
        props.roundEnded = true
    end)

    local newMap = Map:Clone()
    newMap.Parent = workspace

    for _, player in playersAlive do
        CharacterUtils.teleportWithinPlatform(player.Character, newMap.SpawnPart)
    end

    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Get to a high area to avoid the lava!")
    end

    eventTrove:Add(newMap)
    local lavaIsRising = false
    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() then
            if not lavaIsRising then
                lavaIsRising = true
                goalTime:set(workspace.DistributedGameTime + RISING_TIME)
                local newLava = Fusion.Hydrate(Lava:Clone()) {
                    Parent = workspace,
                }
            
                local lavalPrimaryPart = newLava.PrimaryPart
                Fusion.Hydrate(lavalPrimaryPart) {
                    [Fusion.OnEvent("Touched")] = function(hit)
                        local player = Players:GetPlayerFromCharacter(hit.Parent)
                        if player then
                            local character = player.Character
                            local humanoid = character and character:FindFirstChild("Humanoid")
                            if humanoid then
                                humanoid.Health = 0
                            end
                        end
                    end
                }
                eventTrove:Add(newLava)
                local currentCFrame: CFrame = lavalPrimaryPart.CFrame
                local tween = TweenService:Create(lavalPrimaryPart, TweenInfo.new(RISING_TIME), {
                    CFrame = CFrame.new(lavalPrimaryPart.Position.X, lavalPrimaryPart.Position.Y + LAVA_HEIGHT, lavalPrimaryPart.Position.Z) * CFrame.Angles(currentCFrame:ToEulerAngles())
                })
                tween:Play()
                eventTrove:Add(tween)
                for _, player in playersAlive do
                    Network.SendAnnouncement:Server():Fire(player, "The lava is rising! Avoid it!")
                end
            else
                eventTrove:Clean()
            end
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }

    return newMap
end

-- function TileOutline.PlayAnimations(props: Format.animationProps)

-- end

return TileOutline
local Debris = game:GetService("Debris")
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
local TacosOfDeathAssets = Assets.TacosOfDeath
local SpawnPart = TacosOfDeathAssets.SpawnPart
local Taco = TacosOfDeathAssets.Taco

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TileOutline = {}
local SURVIVAL_TIME = 15
local TACO_RATE = 0.1
local TACO_LIFETIME = 5

function TileOutline.Start(props: Format.format)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local finishTime = workspace.DistributedGameTime + SURVIVAL_TIME
    local goalTime = Fusion.Value(finishTime)

    local playersAlive = props.playersAlive
    eventTrove:Add(function()
        for _, player in playersAlive do
            props.functions.teleportBackToPlatform(player) -- bcus platform expands
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        print("playersFinished", #playersAlive)
        props.roundEnded = true
    end)

    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Survive the falling tacos!", finishTime)
    end

    local timer = -1
    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() then
            eventTrove:Clean()
        end

        if os.clock() - timer > TACO_RATE then
            timer = os.clock()

            if timerState:get() >= goalTime:get() - 1 then
                return
            end
            
            local newTaco = Fusion.Hydrate(Taco:Clone()) {
                Parent = workspace,
            }
            newTaco:PivotTo(CFrame.new(CharacterUtils.getPositionWithinPlatform(SpawnPart, true)))
            eventTrove:Add(newTaco)
            SoundUtils.playSound(Assets.SFX.Pop, workspace)

            local debounces = {}
            eventTrove:Add(newTaco.PrimaryPart.Touched:Connect(function(hit)
                local player = Players:GetPlayerFromCharacter(hit.Parent)
                if player then
                    if debounces[player] then
                        return
                    end
                    debounces[player] = true
                    task.delay(0.25, function()
                        debounces[player] = false
                    end)
                    local character = player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.Health -= 15
                    end
                end
            end))

            Debris:AddItem(newTaco, TACO_LIFETIME)
            eventTrove:Add(newTaco)
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }

    props.functions.resizeMap(120)
end

-- function TileOutline.PlayAnimations(props: Format.animationProps)

-- end

return TileOutline
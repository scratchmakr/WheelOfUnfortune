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
local GoombaStompAssets = Assets.GoombaStomp
local Goomba = GoombaStompAssets.Goomba

local Scriptables = workspace:WaitForChild("Scriptables")

local Format = require(script.Parent.Format)

local TileOutline = {}
local SURVIVAL_TIME = 15

function TileOutline.Start(props: Format.format)
    local eventTrove = props.eventTrove

    local timerState = Fusion.Value(workspace.DistributedGameTime)
    local finishTime = workspace.DistributedGameTime + SURVIVAL_TIME
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

    local currentGoombas = {}
    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Survive the goombas!", finishTime)

        -- stomp
        local character = player.Character
        local humanoid: Humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            eventTrove:Add(humanoid.StateChanged:Connect(function(oldState, newState)
                -- print("newState", newState)
                if newState == Enum.HumanoidStateType.Landed then
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Include
                    raycastParams.FilterDescendantsInstances = currentGoombas
                    local raycastResult = workspace:Raycast(character.PrimaryPart.Position, Vector3.new(0, -15, 0), raycastParams)
                    print("raycastResult", raycastResult)
                    local goomba = raycastResult and raycastResult.Instance
                    local humanoid: Humanoid = goomba and goomba.Parent:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.Health = 0
                    end
                end
            end))
        end
    end

    local timer = -1
    local lavaIsRising = false
    eventTrove:Add(RunService.Heartbeat:Connect(function()
        -- print("timerState", timerState:get(), "goalTime", goalTime:get())
        if timerState:get() >= goalTime:get() then
            eventTrove:Clean()
        end

        if timer ~= os.time() then
            timer = os.time()
            local goombaTrove = eventTrove:Extend()
            local newGoomba = Fusion.Hydrate(Goomba:Clone()) {
                Parent = workspace,
            }
            local humanoid: Humanoid = newGoomba:FindFirstChild("Humanoid")
            goombaTrove:Add(humanoid.Died:Connect(function()
                table.remove(currentGoombas, table.find(currentGoombas, newGoomba))
                goombaTrove:Destroy()
            end))
            table.insert(currentGoombas, newGoomba)

            eventTrove:Add(newGoomba)
        end
    end))

    Fusion.Hydrate(workspace) {
        [Fusion.Out("DistributedGameTime")] = timerState
    }
end

-- function TileOutline.PlayAnimations(props: Format.animationProps)

-- end

return TileOutline
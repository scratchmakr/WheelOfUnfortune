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
local ChairsFolder = MusicalChairAssets.Chairs
local ThemeSong = MusicalChairAssets.Theme

local YIELD_TIME = 3
local CHAIR_TIME = 15

local Format = require(script.Parent.Format)

local MusicalChairs = {}

function MusicalChairs.Start(props: Format.format)
    
    local playersAlive = props.playersAlive
    local eventTrove = props.eventTrove
    eventTrove:Add(function()
        for _, player in playersAlive do
            props.functions.teleportBackToPlatform(player)
            Network.SendAnnouncement:Server():Fire(player) -- remove announcements
        end

        props.roundEnded = true
    end)
    
    local currentThemeSong = SoundUtils.playSound(ThemeSong, workspace)
    eventTrove:Add(currentThemeSong)
    for index, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Find a chair and sit on it!")
        local origin, direction = CircleUtils.computeRayForSlice(index, #playersAlive, Vector3.zero, 100)
        local character = player.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(origin, direction)
        end
    end
    local maxChairs = math.min(1, #playersAlive - 1)
    local chairs = Fusion.Value({})
    for i = 1, maxChairs do
        local chair = ChairsFolder:FindFirstChild(tostring(i))
        if chair then
            local newChair = Fusion.Hydrate(chair:Clone()) {
                Parent = workspace,
            }
            local seat: Seat = newChair:FindFirstAncestorOfClass("Seat")
            if seat then
                seat:GetPropertyChangedSignal("Occupant"):Connect(function()
                    local occupant = seat.Occupant
                    local current = chairs:get()
                    current[i] = occupant
                    chairs:set(current)
                end)
            end
            table.insert(chairs, newChair)
            eventTrove:Add(newChair)
        end
    end
    task.wait(YIELD_TIME)
    
    local allSat = false
    eventTrove:Add(Fusion.Observer(chairs):onChange(function()
        local current = chairs:get()
        if #current >= maxChairs then
            allSat = true
        end
    end))
    local finishTime = workspace.DistributedGameTime + CHAIR_TIME
    for _, player in playersAlive do
        Network.SendAnnouncement:Server():Fire(player, "Find a chair and sit on it!", finishTime)
    end

    local finished = false
    eventTrove:Add(RunService.Heartbeat:Connect(function(dt: number)
        if (workspace.DistributedGameTime >= finishTime or #playersAlive <= 0 or allSat) and not finished then
            finished = true
            for _, player in playersAlive do
                props.functions.changeHumanoidStats(player, {
                    JumpHeight = 0,
                })
                local character = player.Character
                local humanoid = character and character:FindFirstAncestorOfClass("Humanoid")
                if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
                    task.delay(1, function()
                        humanoid.Health = 0
                    end)
                end
            end
            currentThemeSong:Stop()
            task.wait(1)
            eventTrove:Clean()
            return
        end
    end))
end

return MusicalChairs
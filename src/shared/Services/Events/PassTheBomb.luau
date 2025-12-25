local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)

local StarterPlayer = game:GetService("StarterPlayer")

local Assets = ReplicatedStorage.Shared.Assets
local PassTheBombAssets = Assets.PassTheBomb
local TimerBombTemplate = PassTheBombAssets.Bomb

local Format = require(script.Parent.Format)

local PassTheBomb = {}

function PassTheBomb.Start(props: Format.format)
    local eventTrove = props.eventTrove
    local playersAlive = props.playersAlive

    local currentPlayerWithBomb = nil
    local lastPassTime = -1
    local stateTrove = eventTrove:Extend()
    local timerState = Fusion.Value(15)
    local function chooseRandomPlayer()
        return playersAlive[math.random(1, #playersAlive)]
    end

    local function weldBombToPlayer(player: Player)
        currentPlayerWithBomb = player
        local character = player.Character
        local torso = character and (character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
        local humanoid = torso and character:FindFirstChild("Humanoid")
        if not humanoid then
            warn("Humanoid not found for player: ", player.Name)
            task.wait(0.1)
            weldBombToPlayer(chooseRandomPlayer())
            return
        end
        stateTrove:Clean()
        humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed + 4
        stateTrove:Add(function()
            humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
        end)
        stateTrove:Add(humanoid.Died:Connect(function()
            eventTrove:Clean()
        end))
        stateTrove:Add(torso.Touched:Connect(function(hit)
            if os.clock() - lastPassTime < 0.2 then
                return
            end

            local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
            local humanoid = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
            if hitPlayer ~= player and humanoid and humanoid.Health > 0 then
                lastPassTime = os.clock()
                weldBombToPlayer(hitPlayer)
            end
        end))
        
        local highlight = Fusion.New("Highlight") {
            Parent = character,
            FillColor = Color3.fromRGB(255, 0, 0),
            FillTransparency = 0.75,
            OutlineColor = Color3.fromRGB(255, 255, 255),
            OutlineTransparency = 0.3,
        }
        local newBomb = Fusion.Hydrate(TimerBombTemplate:Clone()) {
            Parent = character
        }
        newBomb:PivotTo(torso.CFrame)
        stateTrove:Add(highlight)
        stateTrove:Add(newBomb)
        Fusion.New("WeldConstraint") {
            Parent = newBomb.MainPart,
            Part0 = newBomb.MainPart,
            Part1 = torso,
        }

        Fusion.Hydrate(newBomb.MainPart.Attachment.TimerGui.Title) {
            Text = Fusion.Computed(function()
                return timerState:get()
            end)
        }
    end

    weldBombToPlayer(chooseRandomPlayer())

    eventTrove:Add(function() -- explosion
        if currentPlayerWithBomb then
            local character = currentPlayerWithBomb.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = humanoidRootPart and character:FindFirstChild("Humanoid")
            if humanoid then
                local explosion = Instance.new("Explosion")
                explosion.BlastRadius = 5
                explosion.DestroyJointRadiusPercent = 0
                explosion.BlastPressure = 10000
                explosion.Position = humanoidRootPart.Position
                explosion.Parent = character
                humanoid.Health = 0
            end
        end
        props.roundEnded = true
    end)

    eventTrove:Add(Players.PlayerRemoving:Connect(function(player)
        if player == currentPlayerWithBomb then
            currentPlayerWithBomb = nil
            -- weldBombToPlayer(chooseRandomPlayer())
            -- TODO: announce plr left and move on
            eventTrove:Clean()
        end
    end))

    local currentTimer = os.time()
    eventTrove:Add(RunService.Heartbeat:Connect(function()
        if currentTimer ~= os.time() then
            currentTimer = os.time()
            timerState:set(timerState:get() - 1)

            if timerState:get() <= 0 then
                eventTrove:Clean()
            end
        end
    end))
end

return PassTheBomb
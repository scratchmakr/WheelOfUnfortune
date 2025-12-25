local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpinService = require(ReplicatedStorage.Shared.Services.SpinService)
local Network = require(ReplicatedStorage.Shared.Network)
local RblxUtils = require(ReplicatedStorage.Packages.RblxUtils)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local AnimationUtils = require(ReplicatedStorage.Shared.Utils.Animation)

local Difficulties = require(ReplicatedStorage.Shared.Constants.Difficulties)
local DifficultyTypes = require(ReplicatedStorage.Shared.Types.Difficulties)

local StarterPlayer = game:GetService("StarterPlayer")
local UIEvents = require(StarterPlayer.StarterPlayerScripts.Client.UIEvents)

local Scriptables = workspace:WaitForChild("Scriptables")
local Wheel = Scriptables:WaitForChild("Wheel")
local WheelPart = Wheel:WaitForChild("Wheel")
local MainFrame = WheelPart.MainGui.Main

local Assets = ReplicatedStorage.Shared.Assets
local PlanktonAnimation = Assets.Animations.PlanktonSpin

local leverModel = Wheel:WaitForChild("Lever")
-- local lever = leverModel:WaitForChild("Lever")
local clickDetector: ClickDetector = leverModel:WaitForChild("ClickPart"):WaitForChild("ClickDetector")
local leverAnchorPart = leverModel:WaitForChild("MainPart")
local plankton = Wheel:WaitForChild("Plankton")

local WheelController = {}
local TOTAL_REVOLUTIONS = 360 * 8

function WheelController.init()
    print("WheelController initialized")
    local planktonAnimation = AnimationUtils.LoadAnimation(plankton, PlanktonAnimation)

    print("plankton", planktonAnimation)
    local debounce = false
    clickDetector.MouseClick:Connect(function()
        if not debounce then
            debounce = true
            task.delay(1, function()
                debounce = false
            end)
            Network.ClickLever:Client():Fire()
        end
    end)

    Network.ClickLever:Client():On(function() -- animation
        planktonAnimation:Play()

        task.wait(0.77)
        Spring.target(leverAnchorPart, 0.65, 1.2, {
            CFrame = CFrame.new(leverAnchorPart.Position) * CFrame.Angles(0, 0, math.rad(45))
        })
        task.wait(3.5)
        Spring.target(leverAnchorPart, 0.65, 1.2, {
            CFrame = CFrame.new(leverAnchorPart.Position) * CFrame.Angles(0, 0, math.rad(-45))
        })
    end)

    Network.SpinWheel:Client():On(function(seed)
        print("SpinWheel", seed)

        local spinData = SpinService.rollEvent(seed)
        local eventKey = spinData.eventKey
        local difficultyKey = spinData.difficultyKey
        local difficultyMetadata = Difficulties[difficultyKey]
        local offset = spinData.offset

        task.wait(0.5)
        -- print("difficultyKey", difficultyKey, offset, difficultyMetadata.Degrees)
        local revolutionState = Fusion.Value(0)
        local revolutionTween = Fusion.Tween(revolutionState, TweenInfo.new(4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
        local orientation = Fusion.Computed(function()
            local totalDegrees = revolutionTween:get() * (revolutionTween:get() * ((TOTAL_REVOLUTIONS) - 67.5 - difficultyMetadata.Degrees + offset))
            -- print("totalDegrees", totalDegrees)
            return totalDegrees
        end)

        Fusion.Hydrate(MainFrame) {
            Rotation = Fusion.Computed(function()
                local orientation = orientation:get()
                -- print("orientation", orientation)
                return orientation
            end)
        }
        revolutionState:set(1)
        task.wait(4)
        UIEvents.NewEvent:Fire(eventKey, seed)
    end)

    --initialize the wheel
    for i = 1, #RblxUtils.Table.keys(Difficulties) do
        local key = RblxUtils.Table.keys(Difficulties)[i]
        local metadata = Difficulties[key]

        local frame = MainFrame:FindFirstChild(tostring(i))
        frame.Title.Text = metadata.Name
        frame.Icon.Image = metadata.Image
        frame.Rotation = metadata.Degrees
    end
end

return WheelController
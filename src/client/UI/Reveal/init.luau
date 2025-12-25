local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Spring = require(ReplicatedStorage.Packages.Spring)
local Difficulties = require(ReplicatedStorage.Shared.Constants.Difficulties)
local Events = require(ReplicatedStorage.Shared.Constants.Events)
local EventTypes = require(ReplicatedStorage.Shared.Types.Events)
local SoundUtils = require(ReplicatedStorage.Shared.Utils.Sound)

local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")
local UIContainer = require(StarterPlayer.StarterPlayerScripts.Client.Constants.UIContainer)
local UIEvents = require(StarterPlayer.StarterPlayerScripts.Client.UIEvents)

local RevealFrame = UIContainer.MainSGui.RevealFrame
local MainFrame = RevealFrame.Main
local IconTemplate = MainFrame.IconTemplate
local EndIcon = MainFrame.End
local TextGradient = MainFrame.CanvasGroup.UIGradient
local EventDescription = MainFrame.CanvasGroup.Description
local EventTitle = MainFrame.CanvasGroup.Title

return function()
    print("Reveal initialized")
    UIEvents.NewEvent:Connect(function(eventType: string, seed: number)
        -- print("eventType", eventType, Events[eventType])
        local random = Random.new(seed)
        local eventMetadata = Events[eventType]
        local difficultyMetadata = Difficulties[eventMetadata.Difficulty]
        print("difficultyMetadata", eventMetadata.Difficulty, difficultyMetadata)
        RevealFrame.Visible = true
        Spring.target(RevealFrame, 1, 1.5, {
            BackgroundTransparency = 0.5,
        })
        task.wait(0.75)

        local playbackLoudness = Fusion.Value(0)
        local playbackLoudnessTween = Fusion.Tween(playbackLoudness, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut))
        local newIcon = Fusion.Hydrate(IconTemplate:Clone()) {
            Visible = true,
            Image = difficultyMetadata.Image,
            Parent = IconTemplate.Parent,
            Rotation = 20,
            Position = UDim2.fromScale(IconTemplate.Position.X.Scale, IconTemplate.Position.Y.Scale + 3),
            Size = Fusion.Computed(function()
                local playbackLoudness = playbackLoudnessTween:get()
                local scale = IconTemplate.Size.Y.Scale * (1 + (playbackLoudness/575))
                -- print("scale", scale)
                return UDim2.fromScale(scale, scale)
            end),
        }
        Spring.target(newIcon, 0.7, 1, {
            Position = UDim2.fromScale(IconTemplate.Position.X.Scale, IconTemplate.Position.Y.Scale),
        })
        task.wait(0.5)

        local transparencyState = Fusion.Value(0)
        local transparencySpring = Fusion.Spring(transparencyState, 14, 1)
        -- local iconSpring = Fusion.Spring(transparencyState, 20, 1)
        Fusion.Hydrate(TextGradient) {
            Transparency = Fusion.Computed(function()
                local timePosition = math.clamp(1 - transparencySpring:get(), 0.02, 0.999)
                -- print("timePosition", timePosition)
                return NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(timePosition - 0.01, 1),
                    NumberSequenceKeypoint.new(timePosition, 0),
                    NumberSequenceKeypoint.new(1, 0),
                })
            end)
        }

        Spring.stop(newIcon)
        Spring.target(newIcon, 0.65, 1.5, {
            Position = EndIcon.Position,
            Rotation = EndIcon.Rotation,
        })

        transparencyState:set(1)
        Fusion.Hydrate(EventDescription) {
            Visible = true,
            Text = eventMetadata.Description,
        }
        Fusion.Hydrate(EventTitle) {
            Visible = true,
            Text = eventMetadata.Name,
        }

        local randomSoundID = difficultyMetadata.SoundIDs[random:NextInteger(1, #difficultyMetadata.SoundIDs)]
        local sound = SoundUtils.playSound(randomSoundID)
        RunService.Heartbeat:Connect(function()
            playbackLoudness:set(sound.PlaybackLoudness)
        end)

        task.wait(5)
        Spring.target(MainFrame, 1, 1, {
            Position = UDim2.fromScale(0.5, 1.5),
            Rotation = -15,
        })
        task.wait(0.75)
        Spring.target(RevealFrame, 1, 1.5, {
            BackgroundTransparency = 1,
        })
        task.wait(0.5)

        --// Clean up
        RevealFrame.Visible = false
        Spring.stop(MainFrame)
        MainFrame.Position = UDim2.fromScale(0.5, 0.5)
        MainFrame.Rotation = 0
        EventDescription.Visible = false
        EventTitle.Visible = false
        newIcon:Destroy()
    end)

    -- task.wait(2)
    -- UIEvents.NewEvent:Fire(EventTypes.PASS_THE_BOMB)

end
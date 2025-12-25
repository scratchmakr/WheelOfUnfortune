local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Configs = require(ReplicatedStorage.Shared.Constants.Configs)
local Events = require(ReplicatedStorage.Shared.Constants.Events)
local Network = require(ReplicatedStorage.Shared.Network)

local GameValues = ReplicatedStorage.GameValues
local Countdown = GameValues.Countdown
local GameStateValue = GameValues.GameState
local EventValue = GameValues.Event

local StarterPlayer = game:GetService("StarterPlayer")
local UIContainer = require(StarterPlayer.StarterPlayerScripts.Client.Constants.UIContainer)
local AnnouncementsFrame = UIContainer.MainSGui.Announcements
local AnnouncementTitle = AnnouncementsFrame.Title

return function()
    local eventState = Fusion.Value(EventValue.Value)
    local gameState = Fusion.Value(GameStateValue.Value)
    local countdownState = Fusion.Value(0)
    local announcementState = Fusion.Value("")
    local timerState = Fusion.Value(0)
    local goalTime = Fusion.Value(workspace.DistributedGameTime)

    Fusion.Hydrate(AnnouncementTitle) {
        Text = Fusion.Computed(function()
            local announcement = announcementState:get()
            local timer = timerState:get()
            local goal = goalTime:get()
            -- print("client timer", timer, "goalTime", goal)
            if #announcement > 0 then
                if goal and timer <= goal then
                    return `{announcement} ({math.round(goal - timer)}s)`
                elseif not goal then
                    return announcement
                end
            end

            -- local gameState = gameState:get()
            -- local countdown = countdownState:get()
            if #Players:GetPlayers() < Configs.MINIMUM_PLAYERS then
                return "Waiting for players..."
            end

            -- local metadata = Events[eventState]
            -- local objective = metadata and metadata.Objective
            -- if countdown > 0 then
            --     if gameState == Configs.GAME_STATES.PRE_GAME then
            --         return "Starting in " .. countdown .. " seconds..."
            --     elseif gameState == Configs.GAME_STATES.IN_GAME and objective then
            --         return `{objective} ({countdown}s)`
            --     end
            -- end

            return ""
        end)
    }

    Countdown.Changed:Connect(function(value)
        countdownState:set(value)
    end)

    Fusion.Hydrate(GameStateValue) {
        [Fusion.Out("Value")] = gameState
    }

    Fusion.Hydrate(EventValue) {
        [Fusion.Out("Value")] = eventState
    }

    -- Fusion.Hydrate(workspace) {
        -- [Fusion.Out("DistributedGameTime")] = timerState
    -- }

    RunService.Heartbeat:Connect(function()
        timerState:set(workspace.DistributedGameTime)
    end)

    Network.SendAnnouncement:Client():On(function(announcement, finishTime)
        announcementState:set(announcement or "")
        goalTime:set(finishTime)
    end)
end
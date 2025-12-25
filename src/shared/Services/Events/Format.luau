local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

export type format = {
    eventTrove: Trove.Trove,
    playersAlive: {Player},
    roundEnded: boolean,
    functions: {
        teleportBackToPlatform: (player: Player) -> nil,
        resizeMap: (studs: number) -> nil,
        changeHumanoidStats: (player: Player, properties: {[string]: any}) -> nil,
    },
    seed: number,
    eventKey: string,
    inProgress: boolean,
}

export type animationProps = {
    startTime: number?,
    seed: number?,
    map: Model,
    eventKey: string,
    endTime: number?,
    iteration: number?,
}

return {}
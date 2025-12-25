local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = {
    Wins = 0,
    Gold = 0,
}

export type Data = typeof(Data)

return {
    TEMPLATE = Data,
}
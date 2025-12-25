local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DifficultyTypes = require(ReplicatedStorage.Shared.Types.Difficulties)

export type metadata = {
    Name: string,
    Order: number,
    Weight: number,
    Image: string,
    Degrees: number?,
    SoundIDs: {number}
}

local Difficulties = {
    [DifficultyTypes.EASY] = {
        Name = "Easy",
        Order = 1,
        Weight = 1,
        Image = "rbxassetid://125498391890833",
        SoundIDs = {8304443672, 18843924331, 74650015948351},
    },
    [DifficultyTypes.NORMAL] = {
        Name = "Normal",
        Order = 2,
        Weight = 1,
        Image = "rbxassetid://79908557270541",
        SoundIDs = {81966219550694, 116756403169858, 18298978146},
    },
    [DifficultyTypes.HARD] = {
        Name = "Hard",
        Order = 3,
        Weight = 1,
        Image = "rbxassetid://74488206877163",
        SoundIDs = {157636218, 6308606116, 109263303377273},
    },
    [DifficultyTypes.HARDER] = {
        Name = "Harder",
        Order = 4,
        Weight = 1,
        Image = "rbxassetid://71205904227268",
        SoundIDs = {8304443672, 18843924331, 74650015948351},
    },
    [DifficultyTypes.INSANE] = {
        Name = "Insane",
        Order = 5,
        Weight = 1,
        Image = "rbxassetid://75725281338708",
        SoundIDs = {114988094619585, 90128372088135, 100929391752820},
    },
    [DifficultyTypes.CURSED] = {
        Name = "Cursed",
        Order = 6,
        Weight = 1,
        Image = "rbxassetid://117540744494476",
        SoundIDs = {127758670731005, 84766291779256, 17620645740},
    },
    [DifficultyTypes.IMPOSSIBLE] = {
        Name = "Impossible",
        Order = 7,
        Weight = 1,
        Image = "rbxassetid://118605780150823",
        SoundIDs = {122119501933578, 117100627132512, 75238413616581},
    },
    [DifficultyTypes.DEATH] = {
        Name = "Death",
        Order = 8,
        Weight = 1,
        Image = "rbxassetid://86158571250245",
        SoundIDs = {9043356686, 134983127473498},
    },
} :: { [string]: metadata }

for key, metadata in Difficulties do
    metadata.Degrees = (metadata.Order - 1) * 45
end

print("Difficulties", Difficulties)
return Difficulties
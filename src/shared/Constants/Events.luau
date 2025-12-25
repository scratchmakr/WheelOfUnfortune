local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DifficultyTypes = require(ReplicatedStorage.Shared.Types.Difficulties)
local EventTypes = require(ReplicatedStorage.Shared.Types.Events)
local Difficulties = require(ReplicatedStorage.Shared.Constants.Difficulties)

export type metadata = {
    Name: string,
    Description: string,
    Difficulty: string,
    Objective: string?, -- "______ (30s)"
    Rewards: {[string]: number}?,
}

local Events = {
    [EventTypes.PASS_THE_BOMB] = {
        Name = "Pass the Bomb",
        Description = "Avoid being the player with the bomb when it explodes.",
        Difficulty = DifficultyTypes.NORMAL,
        Objective = "Don't hold the bomb when it explodes.",
    },
    [EventTypes.RISING_LAVA] = {
        Name = "Floor is Lava",
        Description = "Lava will rise from the ground, avoid it.",
        Difficulty = DifficultyTypes.NORMAL,
    },
    -- [EventTypes.CAT_AND_MOUSE] = {
    --     Name = "Cat and Mouse",
    --     Description = "You are mice. Avoid the cat.",
    --     Difficulty = DifficultyTypes.NORMAL,
    -- },
    [EventTypes.SWORD_FIGHT] = {
        Name = "Sword Fight",
        Description = "You will be given a sword. Survive.",
        Difficulty = DifficultyTypes.HARDER,
        Objective = "Survive the sword fight.",
    },
    [EventTypes.TRAINS] = {
        Name = "Trains",
        Description = "Trains will appear from every angle, avoid the trains.",
        Difficulty = DifficultyTypes.CURSED,
        Objective = "Survive the trains.",
    },
    [EventTypes.DODGE_SPIKES] = {
        Name = "Dodge Spikes",
        Description = "Spikes will appear from the ground, avoid them.",
        Difficulty = DifficultyTypes.HARD,
        Objective = "Survive the spikes.",
    },
    [EventTypes.SANS_LASERS] = {
        Name = "Gaster Blaster's Lasers",
        Description = "Gaster blaster will appear! Avoid his lasers!!!.",
        Difficulty = DifficultyTypes.INSANE,
        Objective = "Survive the lasers.",
    },
    [EventTypes.GOOMBA_STOMP] = {
        Name = "Goomba Stomp",
        Description = "Goombas will appear! Avoid them or stomp on them!",
        Difficulty = DifficultyTypes.NORMAL,
        Objective = "Survive the goombas.",
    },
    [EventTypes.PARKOUR_TOWER] = {
        Name = "Parkour Tower",
        Description = "Reach the top of the tower before the timer runs out!",
        Difficulty = DifficultyTypes.NORMAL,
        Objective = "Reach the top of the tower.",
    },
    [EventTypes.FARTHEST_FROM_BALL_LOSES] = {
        Name = "Farthest from Ball Loses",
        Description = "A ball will appear and move to a random spot on the map. The furthest few players from the ball are eliminated.",
        Difficulty = DifficultyTypes.HARDER,
    },
    [EventTypes.MUSICAL_CHAIRS] = {
        Name = "Musical Chairs",
        Description = "A classic game of musical chairs. Sit on a chair when the music stops.",
        Difficulty = DifficultyTypes.NORMAL,
    },
    [EventTypes.BLIND_SHOOTING] = {
        Name = "Blind Shooting",
        Description = "Your opponents are invisible. With your gun, aim for where you think your opponents are and avoid getting shot.",
        Difficulty = DifficultyTypes.IMPOSSIBLE,
        Objective = "Aim your weapon.",
    },
    [EventTypes.LASER_PARKOUR] = {
        Name = "Laser Parkour",
        Description = "Make it to the other side of the map without getting hit by the lasers!",
        Difficulty = DifficultyTypes.HARDER,
        Objective = "Make it to the other side.",
    },
    [EventTypes.JENGA_CANNON] = {
        Name = "Jenga Cannon",
        Description = "Avoid falling off the jenga tower while the cannon is firing at you!",
        Difficulty = DifficultyTypes.INSANE,
        Objective = "Avoid falling off the jenga tower.",
    },
    [EventTypes.TEAM_GRAVEYARD] = {
        Name = "Team Graveyard",
        Description = "Be wise and pick a side. 50/50 chance of survival...",
        Difficulty = DifficultyTypes.HARDER,
        Objective = "Pick a side.",
    },
    [EventTypes["1x1x1x1 Sword"]] = {
        Name = "1x1x1x1 Boss Fight",
        Description = "1x1x1x1 will appear. Jump over and avoid his moving swords!",
        Difficulty = DifficultyTypes.DEATH,
        Objective = "Survive the swords.",
    },
    [EventTypes.SLAP_BATTLE] = {
        Name = "Slap Battle",
        Description = "Everyone receives a slap tool. Avoid falling off the platform!",
        Difficulty = DifficultyTypes.EASY,
        Objective = "Avoid falling off the platform.",
    },
    [EventTypes.CHOOSE_COLOR] = {
        Name = "Color Tiles",
        Description = "Choose a random colored tile. One tile will be eliminated...",
        Difficulty = DifficultyTypes.NORMAL,
        Objective = "Choose a color.",
    },
    [EventTypes.TILE_OUTLINE] = {
        Name = "Tiles Path",
        Description = "Memorize the tile pattern that appears and make it across to the other side.",
        Difficulty = DifficultyTypes.EASY,
        Objective = "Make it across to the other side.",
    },
    [EventTypes.BALDIS_MATH_QUIZ] = {
        Name = "Baldis Math Quiz",
        Description = "Answer Baldi's math quiz correctly to avoid elimination.",
        Difficulty = DifficultyTypes.HARD,
        Objective = "Answer the math quiz correctly.",
    },
    [EventTypes.TACOS_OF_DEATH] = {
        Name = "Tacos of Death",
        Description = "STEAMING HOT TACOS ARE FALLING FROM THE SKY! BEWARE!!!",
        Difficulty = DifficultyTypes.NORMAL,
        Objective = "Survive the tacos.",
    },
}

local insaneDifficultyScale = Difficulties[DifficultyTypes.INSANE].Order

for _, metadata in Events do
    local difficultyMetadata = Difficulties[metadata.Difficulty]
    local rewards = {
        Gold = 50 * difficultyMetadata.Order,
        Wins = if difficultyMetadata.Order >= insaneDifficultyScale then 1 else 0,
    }
    metadata.Rewards = rewards
end

print("Events", Events)
return Events
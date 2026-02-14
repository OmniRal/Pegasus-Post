-- OmniRal

local LevelEnum = {}

export type SystemType = "Slot" | "Hall" | "Room" | "Chunk" | "Biome" | "Level"

export type Slot = {
    SystemType: SystemType,
    Open: boolean, -- If the slot can allow a connection
    Index: number, -- Identification
    SlotPart: BasePart, -- This part is inside the room, represents where the slot is and which way it's facing.
    WallPart: BasePart?, -- Invisible wall whose collisions can be toggled on/off
    ConnectedTo: Hall? | Room?,
}

export type Hall = {
    SystemType: SystemType,

    Build: Model,
    CFrame: CFrame,
    Size: Vector3,
    
    FloorParts: {BasePart}, -- Creates the boundary of the room; helps detect which players are in the room
    Slots: {Slot},

    Decor: {BasePart? | Model?},

    Players: {Player?}, -- Track which players are in the hall
}

export type RoomType = "Normal" | "Trap" | "Miniboss" | "Boss" | "Shop" | "Lore"
export type WaveEnemyTracker = {
    Enemies: {}, -- @Enemies = Contains all the current enemies
    Spawned: number, -- @Spawned = How many enemies have been created for this wave
    Killed: number, -- @Killed = How many killed in this wave
}  

export type Room = {
    SystemType: SystemType,
    
    ID: number,
    RoomType: RoomType,
    Started: boolean,
    Completed: boolean,
    Values: {any}, -- Rooms don't need this, but handy if certain rooms have specific functionality; such as traps 

    Build: Model,
    CFrame: CFrame,
    Size: Vector3,
    
    FloorParts: {BasePart},
    Slots: {Slot},

    Spawners: {[number]: Model}?, -- Still need to be defined, these will be the spawners, which manage their own NPCs
    NPCs: {}?, -- Still need to be define, will mostly contain enemies, occasionaly friendly NPCs

    WavesCleared: boolean?,
    WaveNum: number?,
    Waves: {
        {WaveEnemyTracker}
    }?,

    PuzzlesSolved: boolean?,

    RewardSlots: {CFrame}?,
    
    Decor: {BasePart | Model},
    Lighting: UniqueLighting?, -- Rooms don't _need_ to have custom lighting like biomes, but the option is there
    
    Players: {Player?}, -- Track which players are in the room
}

export type Chunk = {
    SystemType: SystemType,

    ID: number,

    Active: boolean, -- If the chunk is the current one players are in
    Completed: boolean, -- If the chunk has been completed, players are able to progress
    
    Build: Model, -- Easy reference 
    Rooms: {Room},
    Halls: {Hall},
    Entrances: {BasePart},
    Choices: {[BasePart]: number},

    Biome: string?,
    
    TitleCard: string?, -- If there is a title card, this will show up in the players UI when they first enter the chunk. Ideal for biome transitions    
}

export type BiomeTypes = "Test"
export type Biome = {
    SystemType: SystemType,

    Name: string,

    CloseSlot: (Room: Room, Slot: Slot) -> (),

	RoomMethods: {
		[string]: {
			Init: () -> ()?, -- Only happens once when the floor is done being built
			Enter: () -> ()?, -- Triggers anytime a player enters the room
			Update: () -> ()?, -- Updates the room on every frame
			Exit: () -> ()?, -- Triggers anytime a player leaves the room
		}?
	},

    Lighting: UniqueLighting,
}

export type Grid = {
    Center: Vector3,
    Occupied: {Vector2}, -- Spaces taken up
}

export type LevelScale = "Routine" | "Hazard" | "Crisis" | "Disaster" | "Cataclysm"

-- Contains everything that is within the level. From chunks, to flavor details.
export type Level = {
    Details: LevelDetails,
    Chunks: {Chunk},
    Rooms: {Room},
    Halls: {Hall},

    Build: Model,

    CurrentChunk: Chunk?,
    CurrentData: SpaceData?,
    AvailableSpawns: {CFrame}?,

    Module: LevelModule,
}

export type LevelDetails = {
    ID: number,
    Name: string,
    Description: string,
    Scale: LevelScale,

    ModelID: number,
}

export type CompletionData = {
    IsTrue: boolean,
    Details: {any},
}

export type RewardType = "None" | "Relic" | "Item" -- "Coins"

export type SpaceData = {
    SystemType: SystemType,

    ID: number,

    CompletionRequirements: {
        Rooms: {number}?, -- For chunks; put all the rooms that NEED to be completed in order for the chunk to be completed

        ClearWaves: boolean?, -- For rooms
        SolvePuzzles: boolean?, -- For rooms
    },

    AllPlayersRequiredToStart: boolean?, -- For rooms
    RoomBlockedOutUntilComplete: boolean?, -- For rooms
    UpdateWithoutPlayers: boolean?, -- For rooms
    Waves: {
        { -- Wave data can have multiple enemies in it
            {SpawnerIDs: {number}, EnemyName: string, Amount: number, UnitValues: {any}, Chance: number?}
            -- @SpawnerIDs = Which spawners the enemy can spawn from; leaving it empty will pick a random spawner 
            -- @EnemyName = Which enemy to spawn
            -- @Amount = How many to create for this wave
            -- @UnitValues = Changes in the enemies stats such as health, evasion, attack speed, etc
            -- @Chance = If exists, it will a dice to see if this enemy spawns in
        }
    }?, -- For rooms

    Rewards: {
        {Choice: RewardType, Chance: number}
    }?, -- For rooms

    Methods: {
        Init: (Space: Chunk | Room?) -> ()?, -- Only happens once when the space is first loaded
		Enter: (Space: Chunk | Room) -> ()?, -- Triggers anytime a player enters the space
		Update: (Space: Chunk | Room) -> ()?, -- Updates the space on every frame
		Exit: (Space: Chunk | Room) -> ()?, -- Triggers anytime a player leaves the space

        StartRoom: (Room: Room) -> ()?, -- Triggers when all the players (if AllPlayersRequiredToStart = true) enter a room for the first time
    }   
}

export type LevelModule = {
    [string]: SpaceData -- This can be any space (chunk or room)
}

-- When a biome or room has custom lighting, it can use these parameters. From their, the system can adjust the lighting accordingly
export type UniqueLighting = {
	Base: {
		Ambient: Color3?,
		Brightness: number?,
		ColorShift_Bottom: Color3?,
		ColorShift_Top: Color3?,
		EnvironmentDiffuseScale: number?,
		EnvironmentSpecularScale: number?,
		OutdoorAmbient: Color3?,
		ClockTime: number?,
		GeographicLatitude: number?,
		ExposureCompensation: number?,
	}?,
	
	Atmosphere: {
		Density: number?,
		Offset: number?,
		Color: Color3?,
		Decay: Color3?,
		Glare: number?,
		Haze: number?,
	}?,
	
	Bloom: {
		Intensity: number?,
		Size: number?,
		Threshold: number?,
	}?,
	
	DepthOfField: {
		FarIntensity: number?,
		FocusDistance: number?,
		InFocusRadius: number?,
		NearIntensity: number?,
	}?,
	
	SunRays: {
		Intensity: number?,
		Spread: number?,
	}?,
}

return LevelEnum
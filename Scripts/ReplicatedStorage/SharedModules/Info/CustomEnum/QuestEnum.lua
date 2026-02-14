-- OmniRal

local QuestEnum = {}

export type QuestType = "Story" | "Generated"
export type QuestStyle = "Elimination" | "Retrieval" | "Delivery" | "Escort" | "Collection"
export type QuestStatus = "Inactive" | "Started" | "Active" | "Paused" | "Complete" | "Cleaning"
export type QuestTask = "Kill"

export type QuestConstructor = {
    Name: string,
    Players: {Player},
    Zone: string,

    Type: QuestType,
    Style: QuestStyle,

    Requirements: {
        Level: number,
        Quests: {string},
    },

    Rewards: {
        Money: number,
        XP: number,
        Items: {
            [string]: number,
        }
    },

    Tasks: {
        {Name: string, Display: string, Amount: number, CheckInventoryFor: string}
    },
}

export type Quest = {
    Name: string,
    Players: {Player},

    Type: QuestType,
    Style: QuestStyle,

    Requirements: {
        Level: number,
        Quests: {string}
    },

    Rewards: {
        Money: number,
        XP: number,
        Items: {
            [string]: number,
        }
    },

    Tasks: {
        {Name: string, Display: string, Amount: number, CheckInventoryFor: string}
    },

    Zone: "Any" | string,
    Status: QuestStatus,
    TimeStarted: number,
    TimeComplete: number,
    Module: QuestModule?,
    Details: {any},
    Step: number,
}

export type QuestModule = {    
    Begin: () -> (), -- What happens when a new quest is first started
    Update: () -> (), -- What happens when the quest step counter goes up by 1. Should be something that is repeated rather than unique; those are for methods under "Steps"
    Complete: () -> (), -- What happens when the quest is complete
    Clean: () -> (), -- Clean up and destroy the quest

    Steps: {
        [string]: () -> (), -- Unique things that happen when the step reaches a specific number. Name examples: "function Step_1(Quest: CustomEnum.Quest)"
    }
}

export type QuestBoard = {
    Model: Model,
    Module: QuestBoardModule,
    Quests: {
        [Model]: Quest,
        -- Display is the physical model that gets placed onto the quest board representing a specific quest
    },
    Details: {any}
}

export type QuestBoardModule = {
    Init: (QuestBoard) -> (),
    Spawn: (QuestBoard, Quest) -> (), -- Create a new display for the latest quest posted onto that board
    Start: (Quest) -> (), -- Changes the status of a display to show that a quest has been started by a player
    Drop: (Quest) -> (), -- Changes the display to show the quest was dropped and is available again
    Complete: (Quest) -> (), -- Change the display to show the quest was completed
    Clean: (Quest) -> (), -- Clean up and destroy a display 
}

return QuestEnum
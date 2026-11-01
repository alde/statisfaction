local _, ns = ...

-- Comprehensive Stat Priority Database by Spec ID and Hero Talent Tree
-- All entries checked against Method's 12.1 guides (Sep 2026). Where Method
-- splits raid / M+ or single target / AoE, the variant is noted and used.
-- ">>" / ">>>" in the guides are treated as ">".
-- Re-verified against all 40 Method stat pages on 2026-09-29. Only Blood, Elemental,
-- Subtlety and Shadow have per-hero-tree priorities; every other spec uses one list.
-- Values are rank maps (lower = higher priority); see NormalizePriority in Priorities.lua.
ns.SPEC_STAT_PRIORITIES = {
    -- Death Knight
    [250] = { -- Blood (Method 12.1)
        specName = "Blood Death Knight",
        default = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
        heroTrees = {
            ["Deathbringer"] = { CRIT = 1, MASTERY = 1, VERS = 1, HASTE = 2 },
            ["San'layn"]     = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
        },
    },
    [251] = { -- Frost (Method 12.1)
        specName = "Frost Death Knight",
        default = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },
    },
    [252] = { -- Unholy (Method 12.1)
        specName = "Unholy Death Knight",
        default = { CRIT = 1, MASTERY = 2, HASTE = 2.5, VERS = 3.5 },
    },

    -- Demon Hunter
    [577] = { -- Havoc (Method 12.1)
        specName = "Havoc Demon Hunter",
        default = { CRIT = 1, MASTERY = 2, HASTE = 3, VERS = 4 },
    },
    [581] = { -- Vengeance (Method 12.1, defensive)
        specName = "Vengeance Demon Hunter",
        default = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 2 },
    },
    [1480] = { -- Devourer (Method 12.1)
        specName = "Devourer Demon Hunter",
        default = { MASTERY = 1, HASTE = 2, CRIT = 2.5, VERS = 3.5 },
    },

    -- Paladin
    [65] = { -- Holy (Method 12.1)
        specName = "Holy Paladin",
        default = { MASTERY = 1, CRIT = 2, HASTE = 2, VERS = 3 },
    },
    [66] = { -- Protection (Method 12.1)
        specName = "Protection Paladin",
        default = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 4 },
    },
    [70] = { -- Retribution (Method 12.1)
        specName = "Retribution Paladin",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
    },

    -- Evoker
    [1467] = { -- Devastation (Method 12.1)
        specName = "Devastation Evoker",
        default = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },
    },
    [1468] = { -- Preservation (Method 12.1, raid)
        specName = "Preservation Evoker",
        default = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 3 },
    },
    [1473] = { -- Augmentation (Method 12.1)
        specName = "Augmentation Evoker",
        default = { MASTERY = 1, CRIT = 2, HASTE = 2, VERS = 3 },
    },

    -- Monk
    [268] = { -- Brewmaster (Method 12.1)
        specName = "Brewmaster Monk",
        default = { CRIT = 1, VERS = 1, MASTERY = 2, HASTE = 3 },
    },
    [269] = { -- Windwalker (Method 12.1)
        specName = "Windwalker Monk",
        default = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 },
    },
    [270] = { -- Mistweaver (Method 12.1)
        specName = "Mistweaver Monk",
        default = { HASTE = 1, CRIT = 2, VERS = 2, MASTERY = 3 },
    },

    -- Shaman
    [262] = { -- Elemental (Method 12.1)
        specName = "Elemental Shaman",
        default = { MASTERY = 1, HASTE = 2, CRIT = 2.5, VERS = 3.5 },
        heroTrees = {
            ["Farseer"]      = { MASTERY = 1, HASTE = 2, CRIT = 2.5, VERS = 3.5 },
            ["Stormbringer"] = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        },
    },
    [263] = { -- Enhancement (Method 12.1)
        specName = "Enhancement Shaman",
        default = { MASTERY = 1, HASTE = 1.5, CRIT = 2.5, VERS = 3 },
    },
    [264] = { -- Restoration (Method 12.1, raid)
        specName = "Restoration Shaman",
        default = { CRIT = 1, HASTE = 2, VERS = 2, MASTERY = 3 },
    },

    -- Warlock
    [265] = { -- Affliction (Method 12.1, single target)
        specName = "Affliction Warlock",
        default = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },
    },
    [266] = { -- Demonology (Method 12.1)
        specName = "Demonology Warlock",
        default = { CRIT = 1, HASTE = 2, MASTERY = 2, VERS = 3 },
    },
    [267] = { -- Destruction (Method 12.1)
        specName = "Destruction Warlock",
        default = { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 },
    },

    -- Mage
    [62] = { -- Arcane (Method 12.1)
        specName = "Arcane Mage",
        default = { HASTE = 1, VERS = 2, CRIT = 3, MASTERY = 4 },
    },
    [63] = { -- Fire (Method 12.1)
        specName = "Fire Mage",
        default = { HASTE = 1, VERS = 2, MASTERY = 3, CRIT = 4 },
    },
    [64] = { -- Frost (Method 12.1)
        specName = "Frost Mage",
        default = { CRIT = 1, MASTERY = 1, HASTE = 2, VERS = 3 },
    },

    -- Warrior
    [71] = { -- Arms (Method 12.1)
        specName = "Arms Warrior",
        default = { CRIT = 1, HASTE = 2, MASTERY = 3, VERS = 4 },
    },
    [72] = { -- Fury (Method 12.1)
        specName = "Fury Warrior",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 3 },
    },
    [73] = { -- Protection (Method 12.1)
        specName = "Protection Warrior",
        default = { HASTE = 1, CRIT = 2, VERS = 2, MASTERY = 3 },
    },

    -- Hunter
    [253] = { -- Beast Mastery (Method 12.1, single target)
        specName = "Beast Mastery Hunter",
        default = { MASTERY = 1, HASTE = 2, CRIT = 2.5, VERS = 3.5 },
    },
    [254] = { -- Marksmanship (Method 12.1)
        specName = "Marksmanship Hunter",
        default = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
    },
    [255] = { -- Survival (Method 12.1, single target)
        specName = "Survival Hunter",
        default = { MASTERY = 1, CRIT = 2, HASTE = 2, VERS = 3 },
    },

    -- Rogue
    [259] = { -- Assassination (Method 12.1)
        specName = "Assassination Rogue",
        default = { CRIT = 1, HASTE = 2, MASTERY = 3, VERS = 4 },
    },
    [260] = { -- Outlaw (Method 12.1)
        specName = "Outlaw Rogue",
        default = { HASTE = 1, CRIT = 2, VERS = 3, MASTERY = 4 },
    },
    [261] = { -- Subtlety (Method 12.1)
        specName = "Subtlety Rogue",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Trickster"]    = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Deathstalker"] = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
        },
    },

    -- Priest
    [256] = { -- Discipline (Method 12.1)
        specName = "Discipline Priest",
        default = { HASTE = 1, MASTERY = 2, CRIT = 3, VERS = 4 },
    },
    [257] = { -- Holy (Method 12.1, raid)
        specName = "Holy Priest",
        default = { CRIT = 1, MASTERY = 2, VERS = 3, HASTE = 4 },
    },
    [258] = { -- Shadow (Method 12.1, single target)
        specName = "Shadow Priest",
        default = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
        heroTrees = {
            ["Voidweaver"] = { MASTERY = 1, HASTE = 2, CRIT = 3, VERS = 4 },
            ["Archon"]     = { MASTERY = 1, CRIT = 2, HASTE = 3, VERS = 4 },
        },
    },

    -- Druid
    [102] = { -- Balance (Method 12.1)
        specName = "Balance Druid",
        default = { MASTERY = 1, CRIT = 2, HASTE = 2, VERS = 3 },
    },
    [103] = { -- Feral (Method 12.1: no fixed priority, sim your gear)
        specName = "Feral Druid",
        default = { CRIT = 1, HASTE = 1, MASTERY = 1, VERS = 1 },
    },
    [104] = { -- Guardian (Method 12.1)
        specName = "Guardian Druid",
        default = { HASTE = 1, VERS = 2, CRIT = 2.5, MASTERY = 3.5 },
    },
    [105] = { -- Restoration (Method 12.1, raid)
        specName = "Restoration Druid",
        default = { HASTE = 1, MASTERY = 1, CRIT = 2, VERS = 2.5 },
    },
}

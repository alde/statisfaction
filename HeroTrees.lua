local _, ns = ...
local Statisfaction = ns.addon
local IsSecret = ns.IsSecret

-- Hero talent trees by SubTreeID, as returned by C_ClassTalents.GetActiveHeroTalentSpec().
-- The English names are the keys used in Data.lua and by priority providers, so
-- lookups work the same on every client language.
-- Source: https://warcraft.wiki.gg/wiki/API_C_ClassTalents.GetActiveHeroTalentSpec
local HERO_TREES = {
    -- Death Knight
    [31] = "San'layn", [32] = "Rider of the Apocalypse", [33] = "Deathbringer",
    -- Demon Hunter
    [34] = "Fel-Scarred", [35] = "Aldrachi Reaver", [124] = "Annihilator",
    -- Druid
    [21] = "Druid of the Claw", [22] = "Wildstalker", [23] = "Keeper of the Grove", [24] = "Elune's Chosen",
    -- Evoker
    [36] = "Scalecommander", [37] = "Flameshaper", [38] = "Chronowarden",
    -- Hunter
    [42] = "Sentinel", [43] = "Pack Leader", [44] = "Dark Ranger",
    -- Mage
    [39] = "Sunfury", [40] = "Spellslinger", [41] = "Frostfire",
    -- Monk
    [64] = "Conduit of the Celestials", [65] = "Shado-Pan", [66] = "Master of Harmony",
    -- Paladin
    [48] = "Templar", [49] = "Lightsmith", [50] = "Herald of the Sun",
    -- Priest
    [18] = "Voidweaver", [19] = "Archon", [20] = "Oracle",
    -- Rogue
    [51] = "Trickster", [52] = "Fatebound", [53] = "Deathstalker",
    -- Shaman
    [54] = "Totemic", [55] = "Stormbringer", [56] = "Farseer",
    -- Warlock
    [57] = "Soul Harvester", [58] = "Hellcaller", [59] = "Diabolist",
    -- Warrior
    [60] = "Slayer", [61] = "Mountain Thane", [62] = "Colossus",
}
ns.HERO_TREES = HERO_TREES

-- The client's (localized) display name for a sub-tree, or nil.
local function GetDisplayName(subTreeID)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetSubTreeInfo) then
        return nil
    end
    local okC, configID = pcall(C_ClassTalents.GetActiveConfigID)
    if not okC or not configID or IsSecret(configID) then return nil end
    local okI, info = pcall(C_Traits.GetSubTreeInfo, configID, subTreeID)
    if not okI or type(info) ~= "table" or IsSecret(info) then return nil end
    local name = info.name
    if name and not IsSecret(name) and name ~= "" then return name end
    return nil
end

--- Active hero talent tree.
--- Returns key (English name used for priority lookups) and displayName (client
--- language), or nil when no hero tree is active (below max level, talents not
--- loaded yet). TRAIT_CONFIG_UPDATED refreshes the panel once talents load.
function Statisfaction:GetActiveHeroTree()
    if not (C_ClassTalents and C_ClassTalents.GetActiveHeroTalentSpec) then return nil end
    local ok, subTreeID = pcall(C_ClassTalents.GetActiveHeroTalentSpec)
    if not ok or not subTreeID or IsSecret(subTreeID) then return nil end

    local key = HERO_TREES[subTreeID]
    local display = GetDisplayName(subTreeID)
    -- A tree added after this table was written: use whatever name the client gives.
    key = key or display
    if not key then return nil end
    return key, display or key
end

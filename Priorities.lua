local _, ns = ...
local Statisfaction = ns.addon
local IsSecret, SafeNumber = ns.IsSecret, ns.SafeNumber

-- WoW Combat Rating constants fallback
local CR_CRIT = _G.CR_CRIT_MELEE or 9
local CR_HASTE = _G.CR_HASTE_MELEE or 18
local CR_MASTERY = _G.CR_MASTERY or 26
local CR_VERSATILITY = _G.CR_VERSATILITY_DAMAGE_DONE or 29

-- Stat Definitions
local STAT_ORDER = { "CRIT", "HASTE", "MASTERY", "VERS" }
local STATS_KEYS_UPPER = { CRIT = "CRIT", HASTE = "HASTE", MASTERY = "MASTERY", VERS = "VERS" }
ns.STAT_ORDER = STAT_ORDER

-- Stat priorities are rank maps: lower rank = higher priority.
--   { HASTE = 1, MASTERY = 1.5, CRIT = 2.5, VERS = 3.5 }  -> Haste >= Mastery > Crit > Vers
-- Equal ranks read as "=", a gap under 1 as ">=", a gap of 1 or more as ">".
-- Legacy strings ("Haste >= Mastery > Critical Strike > Versatility") are still
-- accepted and converted.
local DR_RANK_PER_10_PERCENT = 0.5 -- each 10% DR penalty drops a stat half a rank

local STAT_NAME_ALIASES = {
    ["critical strike"] = "CRIT", ["crit"] = "CRIT",
    ["haste"] = "HASTE",
    ["mastery"] = "MASTERY",
    ["versatility"] = "VERS", ["vers"] = "VERS",
}
local RELATION_STEP = { [">"] = 1, [">="] = 0.5, ["="] = 0 }

local function ParsePriorityString(str)
    local ranks, rank, op = {}, 1, nil
    local rest = str
    while true do
        local s, e, found = rest:find("%s*([>=]+)%s*")
        local name = (s and rest:sub(1, s - 1) or rest):match("^%s*(.-)%s*$")
        local key = STAT_NAME_ALIASES[name:lower()]
        if not key or ranks[key] then return nil end
        if op then
            if not RELATION_STEP[op] then return nil end
            rank = rank + RELATION_STEP[op]
        end
        ranks[key] = rank
        if not s then break end
        op, rest = found, rest:sub(e + 1)
    end
    return ranks
end

--- Normalise a priority (rank map or legacy string) into a rank map, or nil if invalid.
local function NormalizePriority(value)
    if type(value) == "string" then
        return ParsePriorityString(value)
    elseif type(value) == "table" then
        local ranks = {}
        for k, v in pairs(value) do
            local key = type(k) == "string" and (STATS_KEYS_UPPER[k:upper()] or STAT_NAME_ALIASES[k:lower()])
            if key and type(v) == "number" then ranks[key] = v end
        end
        return next(ranks) and ranks or nil
    end
    return nil
end
ns.NormalizePriority = NormalizePriority

--- Stat keys sorted by rank (ties keep the default Crit/Haste/Mastery/Vers order).
--- Stats missing from the map go last.
local function OrderByRank(ranks)
    local order = {}
    for i, key in ipairs(STAT_ORDER) do order[i] = key end
    local index = {}
    for i, key in ipairs(STAT_ORDER) do index[key] = i end
    table.sort(order, function(a, b)
        local ra, rb = ranks[a] or math.huge, ranks[b] or math.huge
        if ra ~= rb then return ra < rb end
        return index[a] < index[b]
    end)
    return order
end
ns.OrderByRank = OrderByRank

--- Copy of `ranks` with stats past diminishing returns pushed down.
function ns.ApplyDRToRanks(ranks, statData)
    local adjusted = {}
    for key, rank in pairs(ranks) do
        local d = statData and statData[key]
        local penalty = d and d.penalty or 0
        adjusted[key] = rank + (penalty / 10) * DR_RANK_PER_10_PERCENT
    end
    return adjusted
end

local STATS = {
    CRIT = {
        key = "CRIT",
        name = "Critical Strike",
        short = "Crit",
        crIndex = CR_CRIT,
        color = { 1.0, 0.49, 0.04 },
        hex = "ff7d0a",
        getVal = function()
            local ok, val = pcall(GetCritChance)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    HASTE = {
        key = "HASTE",
        name = "Haste",
        short = "Haste",
        crIndex = CR_HASTE,
        color = { 1.0, 0.82, 0.0 },
        hex = "ffd100",
        getVal = function()
            local ok, val = pcall(GetHaste)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    MASTERY = {
        key = "MASTERY",
        name = "Mastery",
        short = "Mastery",
        crIndex = CR_MASTERY,
        color = { 0.70, 0.40, 1.0 },
        hex = "b366ff",
        getVal = function()
            local ok, val = pcall(GetMasteryEffect)
            return (ok and not IsSecret(val) and val) or 0
        end,
    },
    VERS = {
        key = "VERS",
        name = "Versatility",
        short = "Vers",
        crIndex = CR_VERSATILITY,
        color = { 0.20, 0.80, 0.95 },
        hex = "33ccf2",
        getVal = function()
            local okB, bonus = pcall(GetCombatRatingBonus, CR_VERSATILITY)
            if not okB or not bonus or IsSecret(bonus) then return 0 end
            local extra = 0
            if GetVersatilityBonus then
                local okE, e = pcall(GetVersatilityBonus, CR_VERSATILITY)
                if okE and e and not IsSecret(e) then extra = e end
            end
            return SafeNumber(bonus, 0) + SafeNumber(extra, 0)
        end,
    },
}
ns.STATS = STATS

-- Diminishing Returns tier and penalty from rating bonus %
-- Returns penalty %, tier, next bracket threshold.
function ns.CalculateDR(ratingBonus)
    local num = SafeNumber(ratingBonus, 0)
    if num >= 66 then
        return 50, 5, 126
    elseif num >= 54 then
        return 40, 4, 66
    elseif num >= 47 then
        return 30, 3, 54
    elseif num >= 39 then
        return 20, 2, 47
    elseif num >= 30 then
        return 10, 1, 39
    else
        return 0, 0, 30
    end
end

--- Recommended stat priority for the current spec & hero tree.
--- Returns ranks, heroTree (English key), label, source, heroDisplay (client language).
function Statisfaction:GetRecommendedPriority()
    local specIndex = GetSpecialization()
    local specId, specName
    if specIndex then specId, specName = GetSpecializationInfo(specIndex) end
    local heroTree, heroDisplay = self:GetActiveHeroTree()

    -- 1. External providers (e.g. OffBeat's active profile)
    for _, provider in ipairs(self.providers) do
        local ok, value, label = pcall(provider.fn, specId, heroTree)
        local ranks = ok and NormalizePriority(value)
        if ranks then return ranks, heroTree, label or specName, provider.name, heroDisplay end
    end

    -- 2. Built-in database
    local entry = specId and ns.SPEC_STAT_PRIORITIES[specId]
    if entry then
        local hero = heroTree and entry.heroTrees and NormalizePriority(entry.heroTrees[heroTree])
        if hero then return hero, heroTree, entry.specName, "built-in", heroDisplay end
        return NormalizePriority(entry.default), heroTree, entry.specName, "built-in", heroDisplay
    end

    -- 3. Generic fallback
    return { HASTE = 1, CRIT = 2, MASTERY = 2.5, VERS = 3.5 }, heroTree, specName or "Unknown Spec", "fallback", heroDisplay
end

--- Render a rank map as "Haste >= Mastery > Crit > Vers" with stat colours.
--- Stats with a DR penalty in `statData` get an orange asterisk.
function Statisfaction:FormatPriority(ranks, statData)
    if not ranks then return "" end
    local order = {}
    for _, key in ipairs(OrderByRank(ranks)) do
        if ranks[key] then order[#order + 1] = key end -- unlisted stats aren't shown
    end
    local parts = {}
    for i, key in ipairs(order) do
        local def = STATS[key]
        if i > 1 then
            local gap = ranks[key] - ranks[order[i - 1]]
            parts[#parts + 1] = gap <= 0 and " = " or (gap < 1 and " >= " or " > ")
        end
        local token = string.format("|cff%s%s|r", def.hex, def.short)
        local d = statData and statData[key]
        if d and SafeNumber(d.penalty, 0) > 0 then
            token = token .. "|cffff8800*|r"
        end
        parts[#parts + 1] = token
    end
    return table.concat(parts)
end

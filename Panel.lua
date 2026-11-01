local _, ns = ...
local Statisfaction = ns.addon
local IsSecret, SafeNumber = ns.IsSecret, ns.SafeNumber
local STATS, STAT_ORDER = ns.STATS, ns.STAT_ORDER

local PADDING = 8
local ROW_HEIGHT = 18
local BAR_HEIGHT = 10
local PANEL_WIDTH = 250
local COMPACT_HEIGHT = 52
local FULL_HEIGHT = 182

local ICON_OK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:0|t"
local ICON_WARN = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:0|t"

local cachedStats = {}

-- True when the panel should dock to (and only show with) the Character panel.
local function IsAttached()
    return Statisfaction.db.profile.attachCharacter and _G.CharacterFrame ~= nil
end

-- Lifecycle

function Statisfaction:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Refresh")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("TRAIT_CONFIG_UPDATED", "Refresh")
    self:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED", "Refresh")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "Refresh")
    self:RegisterEvent("UNIT_STATS")
    self:RegisterEvent("COMBAT_RATING_UPDATE", "MarkDirty")
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "MarkDirty")

    -- Rating events fire in bursts (gear swaps); coalesce them.
    self.updateTimer = self:ScheduleRepeatingTimer("ThrottledRefresh", 0.5)

    self:HookCharacterFrame()
    self:ApplyAnchor()
    self:Refresh()
end

function Statisfaction:OnDisable()
    self:UnregisterAllEvents()
    if self.updateTimer then
        self:CancelTimer(self.updateTimer)
        self.updateTimer = nil
    end
    if self.frame then self.frame:Hide() end
end

function Statisfaction:PLAYER_SPECIALIZATION_CHANGED(_, unit)
    if unit and unit ~= "player" then return end
    self:Refresh()
end

function Statisfaction:UNIT_STATS(_, unit)
    if unit and unit ~= "player" then return end
    self.isDirty = true
end

function Statisfaction:MarkDirty()
    self.isDirty = true
end

function Statisfaction:PLAYER_REGEN_DISABLED()
    if self.db.profile.combatOnly and not self.db.profile.shown then return end
    self:Refresh()
end

function Statisfaction:ThrottledRefresh()
    if self.isDirty then
        self.isDirty = false
        self:Refresh()
    end
end

function Statisfaction:ApplyAppearance()
    if not self.frame then return end
    self.frame:SetBackdrop(self:BuildBackdrop())
    self.frame:SetBackdropColor(0.05, 0.05, 0.05, self.db.profile.opacity)
    self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    self.frame:SetScale(self.db.profile.scale or 1)
    self:ApplyFonts()
    self:Refresh()
end

function Statisfaction:SetLocked(locked)
    self.db.profile.locked = locked
    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not locked and not IsAttached())
    end
end

-- Character panel attachment
-- When enabled, the panel docks to the right edge of the Character panel and is
-- only visible while that panel is open, instead of floating on screen all the time.

function Statisfaction:HookCharacterFrame()
    if self.characterHooked or not _G.CharacterFrame then return end
    self.characterHooked = true
    local function onToggle()
        if Statisfaction:IsEnabled() and IsAttached() then
            Statisfaction:Refresh()
        end
    end
    _G.CharacterFrame:HookScript("OnShow", onToggle)
    _G.CharacterFrame:HookScript("OnHide", onToggle)
end

function Statisfaction:ApplyAnchor()
    local f = self:GetFrame()
    f:ClearAllPoints()
    -- Docked panels can't be dragged; detached panels drag when unlocked.
    if IsAttached() then f:RegisterForDrag() else f:RegisterForDrag("LeftButton") end
    if IsAttached() then
        f:SetFrameStrata(_G.CharacterFrame:GetFrameStrata())
        f:SetFrameLevel(_G.CharacterFrame:GetFrameLevel() + 5)
        f:SetPoint("TOPLEFT", _G.CharacterFrame, "TOPRIGHT", 4, 0)
    else
        f:SetFrameStrata("MEDIUM")
        local pos = self.db.profile.position
        if pos then
            f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
        else
            f:SetPoint("CENTER", UIParent, "CENTER", 260, 100)
        end
    end
    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not self.db.profile.locked and not IsAttached())
    end
end

function Statisfaction:SetAttachToCharacter(attached)
    self.db.profile.attachCharacter = attached
    self:HookCharacterFrame()
    self:ApplyAnchor()
    self:Refresh()
end

function Statisfaction:SetShown(shown)
    self.db.profile.shown = shown
    self:Refresh()
end

function Statisfaction:Toggle()
    if IsAttached() then
        -- In attached mode the panel follows the Character panel; toggle that instead.
        if not self.db.profile.shown then self:SetShown(true) end
        if _G.ToggleCharacter then ToggleCharacter("PaperDollFrame") end
        return
    end
    local shown = not self:GetFrame():IsShown()
    self:SetShown(shown)
    self:Print("Stat priority panel " .. (shown and "|cff55ff55shown|r." or "|cffff5555hidden|r."))
end

-- Frame Construction

local function CreateUnlockOverlay(parent, label)
    local overlay = CreateFrame("Frame", nil, parent)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(parent:GetFrameLevel() + 10)

    local bg = overlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.4, 0.8, 0.3)

    local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(label)
    text:SetTextColor(1, 1, 1, 0.9)

    overlay:Hide()
    return overlay
end

function Statisfaction:GetFrame()
    if self.frame then return self.frame end
    local db = self.db.profile

    local f = CreateFrame("Frame", "StatisfactionPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_WIDTH, FULL_HEIGHT)
    f:SetScale(db.scale or 1)
    f:SetBackdrop(self:BuildBackdrop())
    f:SetBackdropColor(0.05, 0.05, 0.05, db.opacity)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetScript("OnDragStart", function(frame)
        if not Statisfaction.db.profile.locked and not IsAttached() then frame:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        Statisfaction.db.profile.position = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", PADDING, -PADDING)
    header:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    header:SetHeight(20)
    f.header = header

    f.specLabel = header:CreateFontString(nil, "OVERLAY")
    f.specLabel:SetPoint("LEFT", header, "LEFT", 0, 0)

    f.heroBadge = header:CreateFontString(nil, "OVERLAY")
    f.heroBadge:SetPoint("RIGHT", header, "RIGHT", 0, 0)
    f.heroBadge:SetTextColor(1.0, 0.82, 0.0, 0.9)

    -- Priority banner
    local prioBanner = f:CreateFontString(nil, "OVERLAY")
    prioBanner:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    prioBanner:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -3)
    prioBanner:SetJustifyH("LEFT")
    prioBanner:SetWordWrap(false)
    f.prioBanner = prioBanner

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", prioBanner, "BOTTOMLEFT", 0, -4)
    sep:SetPoint("TOPRIGHT", prioBanner, "BOTTOMRIGHT", 0, -4)
    sep:SetColorTexture(1, 1, 1, 0.08)
    f.sep = sep

    -- Stat rows
    f.rows = {}
    for i, statKey in ipairs(STAT_ORDER) do
        local def = STATS[statKey]
        local row = CreateFrame("Frame", nil, f)
        row:SetHeight(ROW_HEIGHT)

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetPoint("LEFT", row, "LEFT", 0, 0)
        name:SetWidth(42)
        name:SetJustifyH("LEFT")
        name:SetTextColor(def.color[1], def.color[2], def.color[3])
        row.name = name

        local val = row:CreateFontString(nil, "OVERLAY")
        val:SetPoint("LEFT", name, "RIGHT", 4, 0)
        val:SetWidth(76)
        val:SetJustifyH("LEFT")
        val:SetTextColor(1, 1, 1, 0.9)
        row.val = val

        local drBadge = row:CreateFontString(nil, "OVERLAY")
        drBadge:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        drBadge:SetWidth(48)
        drBadge:SetJustifyH("RIGHT")
        row.drBadge = drBadge

        -- Progress towards the first DR bracket (30%)
        local bar = CreateFrame("StatusBar", nil, row)
        bar:SetPoint("LEFT", val, "RIGHT", 4, 0)
        bar:SetPoint("RIGHT", drBadge, "LEFT", -4, 0)
        bar:SetHeight(BAR_HEIGHT)
        bar:SetMinMaxValues(0, 30)

        local barBg = bar:CreateTexture(nil, "BACKGROUND")
        barBg:SetAllPoints()
        barBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        row.barBg = barBg

        row.bar = bar
        row.statKey = statKey
        f.rows[i] = row
    end

    -- DR advisory footer
    local footer = f:CreateFontString(nil, "OVERLAY")
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PADDING, PADDING)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    footer:SetJustifyH("LEFT")
    footer:SetWordWrap(true)
    f.footer = footer

    -- Compact view line
    local compactLine = f:CreateFontString(nil, "OVERLAY")
    compactLine:SetPoint("TOPLEFT", prioBanner, "BOTTOMLEFT", 0, -2)
    compactLine:SetPoint("TOPRIGHT", prioBanner, "BOTTOMRIGHT", 0, -2)
    compactLine:SetJustifyH("LEFT")
    f.compactLine = compactLine

    self.unlockOverlay = CreateUnlockOverlay(f, "Statisfaction")
    self.unlockOverlay:SetShown(not db.locked and not IsAttached())

    self.frame = f
    self:ApplyFonts()
    for _, row in ipairs(f.rows) do row.name:SetText(STATS[row.statKey].short) end
    return f
end

function Statisfaction:ApplyFonts()
    local f = self.frame
    if not f then return end
    f.specLabel:SetFont(self:GetFont(1))
    f.heroBadge:SetFont(self:GetFont(-1))
    f.prioBanner:SetFont(self:GetFont(0))
    f.footer:SetFont(self:GetFont(-2))
    f.compactLine:SetFont(self:GetFont(-1))
    for _, row in ipairs(f.rows) do
        row.name:SetFont(self:GetFont(-1))
        row.val:SetFont(self:GetFont(-1))
        row.drBadge:SetFont(self:GetFont(-2))
    end
end

-- Live stat collection

local function CollectStats()
    local statData, penaltyDetails = {}, {}
    for _, key in ipairs(STAT_ORDER) do
        local def = STATS[key]
        -- Combat ratings can come back as secret values (e.g. in combat / restricted
        -- content). Secrets can't be used in arithmetic, comparisons or math.*, so
        -- sanitize them here and fall back to the last known readable values.
        local okB, rawBonus = pcall(GetCombatRatingBonus, def.crIndex)
        local okR, rawRating = pcall(GetCombatRating, def.crIndex)
        local cache = cachedStats[key]
        local ratingBonus, rating, totalPercent
        if not okB or not okR or IsSecret(rawBonus) or IsSecret(rawRating) then
            ratingBonus = cache and cache.ratingBonus or 0
            rating = cache and cache.rating or 0
            totalPercent = cache and cache.totalPercent or 0
        else
            ratingBonus = SafeNumber(rawBonus, 0)
            rating = SafeNumber(rawRating, 0)
            totalPercent = SafeNumber(def.getVal(), 0)
            cachedStats[key] = { ratingBonus = ratingBonus, rating = rating, totalPercent = totalPercent }
        end
        local penalty, tier, nextCap = ns.CalculateDR(ratingBonus)
        if penalty > 0 then
            penaltyDetails[#penaltyDetails + 1] =
                string.format("%s (%.1f%%, -%d%% DR)", def.short, ratingBonus, penalty)
        end
        statData[key] = {
            rating = rating,
            ratingBonus = ratingBonus,
            totalPercent = totalPercent,
            penalty = penalty,
            tier = tier,
            nextCap = nextCap,
        }
    end
    return statData, penaltyDetails
end

-- Refresh

function Statisfaction:Refresh()
    if not self.db then return end
    local f = self:GetFrame()
    local db = self.db.profile

    if not db.shown then
        f:Hide()
        return
    end
    if IsAttached() then
        if not _G.CharacterFrame:IsShown() then
            f:Hide()
            return
        end
    elseif db.combatOnly and not InCombatLockdown() then
        f:Hide()
        return
    end

    f:Show()

    local barTex = self:GetBarTexture()
    local classR, classG, classB = self:GetClassColor()

    local baseRanks, _, specName, _, heroDisplay = self:GetRecommendedPriority()
    f.specLabel:SetText(specName or "")
    f.specLabel:SetTextColor(classR, classG, classB)
    f.heroBadge:SetText(heroDisplay and ("[" .. heroDisplay .. "]") or "")

    local statData, penaltyDetails = CollectStats()

    -- Effective priority: stats past diminishing returns drop down the order,
    -- so the banner and rows show what to aim for right now.
    local ranks = ns.ApplyDRToRanks(baseRanks, statData)
    f.prioBanner:SetText(self:FormatPriority(ranks, statData))
    local order = ns.OrderByRank(ranks)

    if db.compact then
        f:SetHeight(COMPACT_HEIGHT)
        f.sep:Hide()
        f.footer:Hide()
        for _, row in ipairs(f.rows) do row:Hide() end

        local parts = {}
        for _, key in ipairs(order) do
            local def, d = STATS[key], statData[key]
            local drMarker = ""
            if db.showDR and d.penalty > 0 then
                drMarker = string.format(" |cffff8800-%d%%|r", d.penalty)
            end
            parts[#parts + 1] = string.format("|cff%s%s:|r %.1f%%%s", def.hex, def.short, d.totalPercent, drMarker)
        end
        f.compactLine:SetText(table.concat(parts, "  "))
        f.compactLine:Show()
    else
        f:SetHeight(FULL_HEIGHT)
        f.compactLine:Hide()
        f.sep:Show()
        f.footer:Show()

        -- Rows in priority order (highest priority on top)
        local rowByKey = {}
        for _, r in ipairs(f.rows) do rowByKey[r.statKey] = r end
        for i, key in ipairs(order) do
            local row = rowByKey[key]
            local offset = -((i - 1) * (ROW_HEIGHT + 2) + 4)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.sep, "BOTTOMLEFT", 0, offset)
            row:SetPoint("TOPRIGHT", f.sep, "BOTTOMRIGHT", 0, offset)
            row:Show()
            local def, d = STATS[key], statData[key]

            row.bar:SetStatusBarTexture(barTex)

            if db.showValues then
                row.val:SetText(string.format("%.1f%% |cff888888(%d)|r", d.totalPercent, d.rating))
            else
                row.val:SetText(string.format("%.1f%%", d.totalPercent))
            end

            row.bar:SetValue(math.min(d.ratingBonus, 30))

            if d.penalty == 0 then
                row.bar:SetStatusBarColor(def.color[1], def.color[2], def.color[3], 0.85)
                row.drBadge:SetText(db.showDR and "|cff55ff55OK|r" or "")
            elseif d.penalty == 10 then
                row.bar:SetStatusBarColor(1.0, 0.8, 0.0, 0.9)
                row.drBadge:SetText("|cffffcc00-10%|r")
            elseif d.penalty == 20 then
                row.bar:SetStatusBarColor(1.0, 0.5, 0.0, 0.9)
                row.drBadge:SetText("|cffff8800-20%|r")
            else
                row.bar:SetStatusBarColor(1.0, 0.2, 0.2, 0.9)
                row.drBadge:SetText(string.format("|cffff3333-%d%%|r", d.penalty))
            end
        end

        if db.showDR then
            if #penaltyDetails > 0 then
                f.footer:SetText(ICON_WARN .. " |cffffaa00DR active:|r " .. table.concat(penaltyDetails, ", "))
            else
                f.footer:SetText(ICON_OK .. " |cff55ff55Stats below 30% DR threshold (optimal returns)|r")
            end
        else
            f.footer:SetText("")
        end
    end

    if self.unlockOverlay then
        self.unlockOverlay:SetShown(not db.locked and not IsAttached())
    end
end

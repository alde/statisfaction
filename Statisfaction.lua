local ADDON_NAME, ns = ...

local Statisfaction = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G.Statisfaction = Statisfaction
ns.addon = Statisfaction

local LSM = LibStub("LibSharedMedia-3.0")

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata
Statisfaction.VERSION = (GetMeta and GetMeta(ADDON_NAME, "Version")) or "dev"

local defaults = {
    profile = {
        shown = true,
        locked = false,
        attachCharacter = true, -- dock to the Character panel and only show with it
        combatOnly = false,     -- detached mode only
        position = nil,
        compact = false,
        showDR = true,
        showValues = true,

        -- Appearance
        scale = 1.0,
        opacity = 0.85,
        font = "Friz Quadrata TT",
        fontSize = 10,
        fontOutline = "NONE",
        barTexture = "Blizzard",
        borderTexture = "Blizzard Tooltip",
    },
}

-- Secret-value guards (combat ratings can be secret in restricted content)

function ns.IsSecret(val)
    if val == nil then return false end
    if _G.issecretvalue then
        local ok, secret = pcall(_G.issecretvalue, val)
        return ok and secret
    end
    return false
end

function ns.SafeNumber(val, default)
    if val == nil or ns.IsSecret(val) then return default or 0 end
    local ok, num = pcall(tonumber, val)
    if ok and num and not ns.IsSecret(num) then
        return num
    end
    return default or 0
end

-- Priority providers
-- Other addons can supply stat priorities that take precedence over the
-- built-in database (e.g. a rotation addon's active profile):
--
--   Statisfaction:RegisterPriorityProvider("MyAddon", function(specId, heroTree)
--       return { HASTE = 1, CRIT = 2, MASTERY = 2, VERS = 3 }, "My Profile"
--   end)
--
-- The function returns a rank map (lower = higher priority) or a legacy string
-- like "Haste > Crit = Mastery > Vers", plus an optional label; nil to pass.
-- Call Statisfaction:RequestRefresh() when your answer changes.

Statisfaction.providers = {}

function Statisfaction:RegisterPriorityProvider(name, fn)
    assert(type(name) == "string", "provider name must be a string")
    assert(type(fn) == "function", "provider must be a function")
    for i, p in ipairs(self.providers) do
        if p.name == name then
            self.providers[i].fn = fn
            self:RequestRefresh()
            return
        end
    end
    table.insert(self.providers, { name = name, fn = fn })
    self:RequestRefresh()
end

function Statisfaction:UnregisterPriorityProvider(name)
    for i, p in ipairs(self.providers) do
        if p.name == name then
            table.remove(self.providers, i)
            self:RequestRefresh()
            return
        end
    end
end

function Statisfaction:RequestRefresh()
    if self.db and self:IsEnabled() and self.Refresh then
        self:Refresh()
    end
end

-- Shared media helpers

function Statisfaction:GetFont(sizeOffset)
    local db = self.db.profile
    local path = LSM:Fetch("font", db.font) or STANDARD_TEXT_FONT
    local outline = db.fontOutline
    if outline == "NONE" then outline = "" end
    return path, db.fontSize + (sizeOffset or 0), outline
end

function Statisfaction:GetBarTexture()
    return LSM:Fetch("statusbar", self.db.profile.barTexture)
end

function Statisfaction:BuildBackdrop()
    local backdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true,
        tileSize = 16,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    }
    local name = self.db.profile.borderTexture
    local border = name ~= "None" and LSM:Fetch("border", name)
    if border then
        backdrop.edgeFile = border
        backdrop.edgeSize = 12
    end
    return backdrop
end

function Statisfaction:GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then return color.r, color.g, color.b end
    return 0.6, 0.6, 0.6
end

-- Lifecycle

function Statisfaction:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("StatisfactionDB", defaults, true)
    self:RegisterChatCommand("statisfaction", "OnSlashCommand")
    self:RegisterChatCommand("statis", "OnSlashCommand")
    if self.RegisterOptions then self:RegisterOptions() end
end

-- Slash commands

function Statisfaction:OnSlashCommand(input)
    local cmd = self:GetArgs(input, 1)
    cmd = cmd and cmd:lower() or ""

    if cmd == "" or cmd == "toggle" or cmd == "show" then
        self:Toggle()
    elseif cmd == "config" or cmd == "options" then
        self:OpenOptions()
    elseif cmd == "lock" then
        self:SetLocked(not self.db.profile.locked)
        self:Print("Panel " .. (self.db.profile.locked and "locked" or "unlocked") .. ".")
    elseif cmd == "compact" then
        self.db.profile.compact = not self.db.profile.compact
        self:Refresh()
    elseif cmd == "dock" then
        self:SetAttachToCharacter(not self.db.profile.attachCharacter)
        self:Print("Panel " .. (self.db.profile.attachCharacter and "docked to the Character panel" or "detached") .. ".")
    elseif cmd == "reset" then
        self.db.profile.position = nil
        self:ApplyAnchor()
        self:Print("Position reset.")
    elseif cmd == "info" then
        self:PrintInfo()
    else
        self:Print("Statisfaction v" .. self.VERSION)
        self:Print("  /statis          - Toggle the panel")
        self:Print("  /statis config   - Open settings")
        self:Print("  /statis dock     - Dock to / detach from the Character panel")
        self:Print("  /statis lock     - Lock/unlock the detached panel")
        self:Print("  /statis compact  - Toggle compact mode")
        self:Print("  /statis reset    - Reset position")
        self:Print("  /statis info     - Print spec, hero tree and priority")
    end
end

function Statisfaction:PrintInfo()
    local ranks, _, specName, source, heroTree = self:GetRecommendedPriority()
    self:Print(string.format("%s%s", specName or "Unknown spec",
        heroTree and (" [" .. heroTree .. "]") or ""))
    self:Print("Priority: " .. self:FormatPriority(ranks))
    self:Print("Source: " .. (source or "built-in"))
end

function Statisfaction:OpenOptions()
    if self.optionsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.optionsCategory:GetID())
    else
        self:Print("Settings panel unavailable; use /statis help.")
    end
end

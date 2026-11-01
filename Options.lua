local ADDON_NAME, ns = ...
local Statisfaction = ns.addon
local LSM = LibStub("LibSharedMedia-3.0")

-- Native Settings panel (Esc > Options > AddOns > Statisfaction)

local VarType = Settings and Settings.VarType or {}
local BOOL = VarType.Boolean or "boolean"
local NUM = VarType.Number or "number"
local STR = VarType.String or "string"

function Statisfaction:RegisterOptions()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("Statisfaction")
    self.optionsCategory = category
    local db = function() return Statisfaction.db.profile end

    local function Section(title)
        if layout and CreateSettingsListSectionHeaderInitializer then
            layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title))
        end
    end

    -- Registers a proxy setting bound to db.profile[key]; `apply` runs after a change.
    local function Proxy(key, varType, label, apply)
        return Settings.RegisterProxySetting(category, ADDON_NAME .. "_" .. key, varType, label,
            Statisfaction.db.defaults.profile[key],
            function() return db()[key] end,
            function(value)
                db()[key] = value
                if apply then apply(value) else Statisfaction:Refresh() end
            end)
    end

    local function Checkbox(key, label, tooltip, apply)
        Settings.CreateCheckbox(category, Proxy(key, BOOL, label, apply), tooltip)
    end

    local function Slider(key, label, tooltip, min, max, step, fmt, apply)
        local options = Settings.CreateSliderOptions(min, max, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, fmt)
        Settings.CreateSlider(category, Proxy(key, NUM, label, apply), options, tooltip)
    end

    local function MediaDropdown(key, label, tooltip, mediaType, apply)
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            for _, name in ipairs(LSM:List(mediaType)) do container:Add(name, name) end
            return container:GetData()
        end
        Settings.CreateDropdown(category, Proxy(key, STR, label, apply), GetOptions, tooltip)
    end

    local applyAppearance = function() Statisfaction:ApplyAppearance() end
    local pct = function(v) return string.format("%d%%", v * 100 + 0.5) end

    Section("Display")
    Checkbox("shown", "Show Panel", "Show the stat priority panel.")
    Checkbox("attachCharacter", "Attach to Character Panel",
        "Dock the panel to the right of the Character panel and only show it while that is open.",
        function(v) Statisfaction:SetAttachToCharacter(v) end)
    Checkbox("combatOnly", "Only in Combat (when detached)",
        "When detached, only show the panel while you are in combat.")
    Checkbox("locked", "Lock Position", "Prevent dragging the detached panel.",
        function(v) Statisfaction:SetLocked(v) end)
    Checkbox("compact", "Compact Mode", "Show the priority and a single line of percentages.")
    Checkbox("showDR", "Show Diminishing Returns",
        "Show DR badges and the DR advisory line. Stats past a DR bracket drop down the priority either way.")
    Checkbox("showValues", "Show Rating Values", "Show raw rating next to each percentage.")

    Section("Appearance")
    Slider("scale", "Scale", nil, 0.5, 2.0, 0.05, pct, applyAppearance)
    Slider("opacity", "Background Opacity", nil, 0, 1, 0.05, pct, applyAppearance)
    Slider("fontSize", "Font Size", nil, 8, 18, 1, function(v) return tostring(v) end, applyAppearance)
    MediaDropdown("font", "Font", nil, "font", applyAppearance)
    MediaDropdown("barTexture", "Bar Texture", nil, "statusbar", applyAppearance)
    MediaDropdown("borderTexture", "Border", nil, "border", applyAppearance)

    Settings.RegisterAddOnCategory(category)
end

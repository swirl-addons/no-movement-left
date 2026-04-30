local MOVEMENT_ABILITIES = {
    DEATHKNIGHT = {48265}, -- death's advance
    DEMONHUNTER = {195072, 189110, 1234796}, -- fel rush, infernal strike, shift
    DRUID = {252216, 102401}, -- dash, tiger dash, wild charge
    EVOKER = {358267}, -- hover
    HUNTER = {781}, -- disengage
    MAGE = {212653, 1953}, -- shimmer, blink
    MONK = {109132, 115008}, -- roll, chi torpedo
    PALADIN = {190784}, -- divine steed
    PRIEST = {121536}, -- angelic feather
    ROGUE = {36554, 195457}, -- shadowstep, grappling hook
    SHAMAN = {192063}, -- gust of wind
    WARLOCK = {48020}, -- demonic circle teleport
    WARRIOR = {6544}, -- heroic leap
}

local NAME_OVERRIDES = {
    [48265] = "DA", -- death's advance
    [195072] = "RUSH", -- fel rush
    [189110] = "LEAP", -- infernal strike
    [252216] = "DASH", -- tiger dash
    [102401] = "CHARGE", -- wild charge
    [115008] = "TORPEDO", -- chi torpedo
    [190784] = "STEED", -- divine steed
    [121536] = "FEATHER", -- angelic feather
    [36554] = "STEP", -- shadowstep
    [195457] = "GRAPPLE", -- grappling hook
    [192063] = "GUST", -- gust of wind
    [48020] = "CIRCLE", -- demonic circle teleport
    [6544] = "LEAP", -- heroic leap
}

local MOVEMENT_SPELL_ID = nil
local MOVEMENT_SPELL_NAME = nil

local frame = CreateFrame("Frame", "NoMovementLeft", UIParent)

local movementText = UIParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
local fontName, fontSize, _ = movementText:GetFont()
movementText:SetFont(fontName, fontSize, "OUTLINE")
movementText:SetTextColor(1, 1, 1, 1)
movementText:SetShadowColor(0, 0, 0, 0)
movementText:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
movementText:SetJustifyH("CENTER")

local updateInterval = 0.1
local timeSinceLastUpdate = 0

local function CacheMovementSpell()
    local _, playerClass = UnitClass("player")
    local abilities = MOVEMENT_ABILITIES[playerClass]

    if not abilities then
        return
    end

    for _, spellID in ipairs(abilities) do
        if C_SpellBook.IsSpellKnown(spellID) then
            MOVEMENT_SPELL_ID = spellID
            if NAME_OVERRIDES[spellID] then
                MOVEMENT_SPELL_NAME = NAME_OVERRIDES[spellID]
            else
                local spellInfo = C_Spell.GetSpellInfo(spellID)
                MOVEMENT_SPELL_NAME = spellInfo and string.upper(spellInfo.name) or "MOVEMENT"
            end
            return
        end
    end
end

local function UpdateMovementAlert()
    if not MOVEMENT_SPELL_ID or not MOVEMENT_SPELL_NAME then
        movementText:Hide()
        return
    end

    local cdInfo = C_Spell.GetSpellCooldown(MOVEMENT_SPELL_ID)

    if cdInfo and cdInfo.timeUntilEndOfStartRecovery and not cdInfo.isOnGCD and cdInfo.isOnGCD ~= nil then
        movementText:SetText(string.format("NO %s (%.1f)", MOVEMENT_SPELL_NAME, cdInfo.timeUntilEndOfStartRecovery))
        movementText:Show()
    else
        movementText:Hide()
    end
end

frame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastUpdate = timeSinceLastUpdate + elapsed
    if timeSinceLastUpdate >= updateInterval then
        UpdateMovementAlert()
        timeSinceLastUpdate = 0
    end
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        CacheMovementSpell()
        if not MOVEMENT_SPELL_ID then
            print("|cff57e3adNoMovementLeft:|r No movement ability found for this class/spec")
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        C_Timer.After(0.5, function()
            CacheMovementSpell()
        end)
    end
end)
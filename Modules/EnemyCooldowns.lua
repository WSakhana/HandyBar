------------------------------------------------------------------------
-- HandyBar - Enemy Cooldown Auto Detection
-- Midnight-safe arena tracking based on aura instance IDs and timing.
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB

local AUTO_DEDUPE_WINDOW = 0.35
local RULE_TOLERANCE = 0.5
local CAST_WINDOW = 0.15
local EVIDENCE_TOLERANCE = 0.15
local GENERIC_RULE_TOLERANCE = 1.25
local GENERIC_RULE_EXTENSION_WINDOW = 4.0

local AURA_FILTERS = {
    { key = "BIG_DEFENSIVE", filter = "HELPFUL|BIG_DEFENSIVE" },
    { key = "EXTERNAL_DEFENSIVE", filter = "HELPFUL|EXTERNAL_DEFENSIVE" },
    { key = "IMPORTANT", filter = "HELPFUL|IMPORTANT" },
}

local trackingFrame
local trackedAurasByUnit = {}
local lastAutoTriggerAt = {}
local lastDebuffTime = {}
local lastShieldTime = {}
local lastCastTime = {}
local lastUnitFlagsTime = {}
local lastFeignDeathTime = {}
local lastFeignDeathState = {}
local candidateEvidenceScratch = {}

local E_CAST = "Cast"
local E_BUBBLE = { "Cast", "Debuff", "UnitFlags" }
local E_SHIELD = { "Cast", "Shield" }
local E_CAST_FLAGS = { "Cast", "UnitFlags" }

local function ExpandRules(rows)
    local rules = {}
    for i = 1, #rows do
        local row = rows[i]
        rules[i] = {
            SpellId = row[1],
            BuffDuration = row[2],
            BigDefensive = row[3],
            ExternalDefensive = row[4],
            Important = row[5],
            RequiresEvidence = row[6],
            CanCancelEarly = row[7],
            MinDuration = row[8],
        }
    end
    return rules
end

local AUTO_RULES = {
    BySpec = {
        [65] = ExpandRules({
            { 31884, 12, false, false, true, E_CAST, nil, true },
            { 642, 8, true, false, true, E_BUBBLE, true },
            { 1022, 10, false, true, false, E_CAST, true },
            { 6940, 12, false, true, false, E_CAST },
        }),
        [66] = ExpandRules({
            { 31884, 25, false, false, true, E_CAST, nil, true },
            { 642, 8, true, false, true, E_BUBBLE, true },
            { 31850, 8, true, false, true, E_CAST },
            { 86659, 8, true, false, false, E_CAST },
            { 1022, 10, false, true, false, E_CAST, true },
            { 6940, 12, false, true, false, E_CAST },
        }),
        [70] = ExpandRules({
            { 31884, 24, false, false, true, E_CAST },
            { 642, 8, true, false, true, E_BUBBLE, true },
            { 1022, 10, false, true, false, E_CAST, true },
            { 6940, 12, false, true, false, E_CAST },
        }),
        [62] = ExpandRules({
            { 365350, 15, false, false, true, E_CAST, nil, true },
        }),
        [63] = ExpandRules({
            { 190319, 10, false, false, true, E_CAST, nil, true },
        }),
        [71] = ExpandRules({
            { 118038, 8, true, false, true, E_CAST },
            { 107574, 20, false, false, true, E_CAST, nil, true },
        }),
        [72] = ExpandRules({
            { 184364, 8, true, false, true, E_CAST },
            { 184364, 11, true, false, true, E_CAST },
            { 107574, 20, false, false, true, E_CAST, nil, true },
        }),
        [73] = ExpandRules({
            { 871, 8, true, false, true, E_CAST },
            { 107574, 20, false, false, true, E_CAST, nil, true },
        }),
        [250] = ExpandRules({
            { 55233, 10, true, false, true, E_CAST },
            { 55233, 12, true, false, true, E_CAST },
            { 55233, 14, true, false, true, E_CAST },
        }),
        [251] = ExpandRules({
            { 51271, 12, false, false, true, E_CAST, nil, true },
        }),
        [256] = ExpandRules({
            { 33206, 8, false, true, false, E_CAST },
        }),
        [257] = ExpandRules({
            { 47788, 10, false, true, false, E_CAST, true },
            { 64843, 5, false, false, true, E_CAST, true },
        }),
        [258] = ExpandRules({
            { 47585, 6, true, false, true, E_CAST, true },
            { 228260, 20, false, false, true, E_CAST },
        }),
        [102] = ExpandRules({
            { 102560, 20, false, false, true, E_CAST, nil, true },
        }),
        [103] = ExpandRules({
            { 106951, 15, false, false, true, E_CAST, nil, true },
            { 102543, 20, false, false, true, E_CAST },
        }),
        [104] = ExpandRules({
            { 102558, 30, false, false, true, E_CAST },
        }),
        [105] = ExpandRules({
            { 102342, 12, false, true, false, E_CAST },
        }),
        [268] = ExpandRules({
            { 115203, 15, true, false, false, E_CAST },
        }),
        [270] = ExpandRules({
            { 116849, 12, false, true, false, E_CAST, true },
        }),
        [577] = ExpandRules({
            { 198589, 10, true, false, true, E_CAST },
        }),
        [581] = ExpandRules({
            { 204021, 12, true, false, false, E_CAST, nil, true },
        }),
        [254] = ExpandRules({
            { 288613, 15, false, false, true, E_CAST },
            { 288613, 17, false, false, true, E_CAST },
        }),
        [261] = ExpandRules({
            { 121471, 16, false, false, true, E_CAST },
            { 121471, 18, false, false, true, E_CAST },
            { 121471, 20, false, false, true, E_CAST },
        }),
        [1467] = ExpandRules({
            { 375087, 18, false, false, true, E_CAST, nil, true },
        }),
        [1468] = ExpandRules({
            { 357170, 8, false, true, false, E_CAST },
        }),
        [1473] = ExpandRules({
            { 363916, 13.4, true, false, true, E_CAST, nil, true },
        }),
    },
    ByClass = {
        PALADIN = ExpandRules({
            { 642, 8, true, false, true, E_BUBBLE, true },
            { 1044, 8, false, false, true, E_CAST, true },
            { 1022, 10, false, true, false, E_CAST, true },
        }),
        MAGE = ExpandRules({
            { 45438, 10, true, false, true, E_BUBBLE, true },
        }),
        HUNTER = ExpandRules({
            { 186265, 8, true, false, true, E_CAST_FLAGS, true },
            { 264735, 6, true, false, true, E_CAST, nil, true },
            { 264735, 8, true, false, true, E_CAST, nil, true },
        }),
        DRUID = ExpandRules({
            { 22812, 8, true, false, true, E_CAST },
            { 22812, 12, true, false, true, E_CAST },
        }),
        ROGUE = ExpandRules({
            { 5277, 10, false, false, true, E_CAST },
            { 31224, 5, true, false, false, E_CAST },
        }),
        DEATHKNIGHT = ExpandRules({
            { 48707, 5, true, false, true, E_SHIELD, true },
            { 48707, 7, true, false, true, E_SHIELD, true },
            { 48792, 8, true, false, true, E_CAST },
            { 48707, 5, false, false, true, E_SHIELD, true },
            { 48707, 7, false, false, true, E_SHIELD, true },
        }),
        MONK = ExpandRules({
            { 115203, 15, true, false, false, E_CAST },
        }),
        SHAMAN = ExpandRules({
            { 108271, 12, true, false, true, E_CAST },
        }),
        WARLOCK = ExpandRules({
            { 104773, 8, true, false, true, E_CAST },
        }),
        PRIEST = ExpandRules({
            { 19236, 10, true, false, true, E_CAST },
        }),
        EVOKER = ExpandRules({
            { 363916, 12, true, false, true, E_CAST, nil, true },
        }),
    },
}

local function IsArenaUnit(unit)
    return type(unit) == "string" and unit:match("^arena%d+$") ~= nil
end

local function GetArenaSlotFromUnit(unit)
    if not IsArenaUnit(unit) then
        return nil
    end
    return tonumber(unit:match("^arena(%d+)$"))
end

local function GetArenaUnitClass(unit)
    local slotIndex = GetArenaSlotFromUnit(unit)
    return slotIndex and HB:GetArenaSlotClass(slotIndex) or nil
end

local function GetArenaUnitSpec(unit)
    local slotIndex = GetArenaSlotFromUnit(unit)
    if not slotIndex then
        return nil
    end
    local specID = HB:GetArenaSlotSpec(slotIndex)
    return specID and specID > 0 and specID or nil
end

local function IsAutoTrackingActive()
    return HB.db
        and HB.db.profile
        and HB.db.profile.autoEnemyCooldowns ~= false
        and HB:IsInArena()
        and not HB:IsTestMode()
end

local function DebugAuto(message, ...)
    if HB.db and HB.db.profile and HB.db.profile.debug then
        HB:Print("|cFF00FF00[HandyBar]|r " .. format(message, ...))
    end
end

local function FormatAuraTypes(auraTypes)
    local tags = {}
    if auraTypes["BIG_DEFENSIVE"] then
        tags[#tags + 1] = "BIG_DEFENSIVE"
    end
    if auraTypes["EXTERNAL_DEFENSIVE"] then
        tags[#tags + 1] = "EXTERNAL_DEFENSIVE"
    end
    if auraTypes["IMPORTANT"] then
        tags[#tags + 1] = "IMPORTANT"
    end
    return #tags > 0 and table.concat(tags, "+") or "none"
end

local function FormatEvidence(evidence)
    if not evidence then
        return "none"
    end

    local tags = {}
    if evidence.Cast then
        tags[#tags + 1] = "Cast"
    end
    if evidence.Debuff then
        tags[#tags + 1] = "Debuff"
    end
    if evidence.Shield then
        tags[#tags + 1] = "Shield"
    end
    if evidence.UnitFlags then
        tags[#tags + 1] = "UnitFlags"
    end
    if evidence.FeignDeath then
        tags[#tags + 1] = "FeignDeath"
    end

    return #tags > 0 and table.concat(tags, "+") or "none"
end

local function GetKnownSpellData(spellID)
    if not spellID or not HB.MC or not HB.MC.GetBySpellID then
        return nil
    end
    return HB.MC:GetBySpellID(spellID)
end

local function GetUnitAurasByFilter(unit, filter)
    if C_UnitAuras and C_UnitAuras.GetUnitAuras then
        return C_UnitAuras.GetUnitAuras(unit, filter) or {}
    end

    local fallback = {}
    if AuraUtil and AuraUtil.ForEachAura then
        AuraUtil.ForEachAura(unit, filter, nil, function(aura)
            fallback[#fallback + 1] = aura
        end, true)
    end
    return fallback
end

local function CollectCurrentTrackedAuras(unit)
    local current = {}
    if not UnitExists(unit) then
        return current
    end

    for i = 1, #AURA_FILTERS do
        local filterInfo = AURA_FILTERS[i]
        local auras = GetUnitAurasByFilter(unit, filterInfo.filter)
        for auraIndex = 1, #auras do
            local aura = auras[auraIndex]
            local auraInstanceID = aura and aura.auraInstanceID
            if auraInstanceID then
                current[auraInstanceID] = current[auraInstanceID] or { AuraTypes = {} }
                current[auraInstanceID].AuraTypes[filterInfo.key] = true
            end
        end
    end

    return current
end

local function BuildEvidenceSet(unit, detectionTime)
    local evidence
    if lastDebuffTime[unit] and math.abs(lastDebuffTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then
        evidence = evidence or {}
        evidence.Debuff = true
    end
    if lastShieldTime[unit] and math.abs(lastShieldTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then
        evidence = evidence or {}
        evidence.Shield = true
    end
    if lastFeignDeathTime[unit] and math.abs(lastFeignDeathTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence.FeignDeath = true
    elseif lastUnitFlagsTime[unit] and math.abs(lastUnitFlagsTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence.UnitFlags = true
    end
    if lastCastTime[unit] and math.abs(lastCastTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence.Cast = true
    end
    return evidence
end

local function BuildAuraTypesSignature(auraTypes)
    local signature = ""
    if auraTypes["BIG_DEFENSIVE"] then
        signature = signature .. "B"
    end
    if auraTypes["EXTERNAL_DEFENSIVE"] then
        signature = signature .. "E"
    end
    if auraTypes["IMPORTANT"] then
        signature = signature .. "I"
    end
    return signature
end

local function AuraTypeMatchesRule(auraTypes, rule)
    if rule.BigDefensive == true and not auraTypes["BIG_DEFENSIVE"] then
        return false
    end
    if rule.BigDefensive == false and auraTypes["BIG_DEFENSIVE"] then
        return false
    end
    if rule.ExternalDefensive == true and not auraTypes["EXTERNAL_DEFENSIVE"] then
        return false
    end
    if rule.ExternalDefensive == false and auraTypes["EXTERNAL_DEFENSIVE"] then
        return false
    end
    if rule.Important == true and not auraTypes["IMPORTANT"] then
        return false
    end
    return true
end

local function EvidenceMatchesReq(req, evidence)
    if req == nil then
        return true
    end
    if req == false then
        return not evidence or not next(evidence)
    end
    if type(req) == "string" then
        return evidence ~= nil and evidence[req] == true
    end
    if type(req) == "table" then
        if not evidence then
            return false
        end
        for i = 1, #req do
            if not evidence[req[i]] then
                return false
            end
        end
        return true
    end
    return false
end

local function DurationMatchesRule(rule, measuredDuration)
    if rule.MinDuration then
        return measuredDuration >= (rule.BuffDuration - RULE_TOLERANCE)
    end
    if rule.CanCancelEarly then
        return measuredDuration <= (rule.BuffDuration + RULE_TOLERANCE)
    end
    return math.abs(measuredDuration - rule.BuffDuration) <= RULE_TOLERANCE
end

local function RuleMatchesTrackableSpell(rule, unit)
    local spellData = GetKnownSpellData(rule.SpellId)
    local slotIndex = GetArenaSlotFromUnit(unit)
    return spellData ~= nil and slotIndex ~= nil and HB:SpellMatchesArenaSlot(spellData, slotIndex)
end

local function SpellDataMatchesSpec(spellData, specID)
    if not spellData then
        return false
    end

    local specs = spellData.specs or {}
    if #specs == 0 or not specID then
        return true
    end

    for i = 1, #specs do
        if specs[i] == specID then
            return true
        end
    end

    return false
end

local function GetGenericAuraScore(spellData, auraTypes)
    if not spellData or not HB.MC or not HB.MC.Category then
        return nil
    end

    local C = HB.MC.Category
    if spellData.category == C.BURST or spellData.category == C.OFFENSIVE then
        if auraTypes["IMPORTANT"] then
            return 0
        end
        return nil
    end

    if spellData.category == C.DEFENSIVE then
        if auraTypes["BIG_DEFENSIVE"] then
            return 0
        end
        if auraTypes["IMPORTANT"] then
            return 0.4
        end
        return nil
    end

    if spellData.category == C.UTILITY then
        if auraTypes["EXTERNAL_DEFENSIVE"] then
            return 0
        end
        if auraTypes["IMPORTANT"] then
            return 0.5
        end
        return nil
    end

    return nil
end

local function GetGenericDurationScore(spellData, measuredDuration)
    local expected = spellData and spellData.effectDuration
    if not expected or expected <= 0 then
        return nil
    end

    local delta = math.abs(measuredDuration - expected)
    if delta <= GENERIC_RULE_TOLERANCE then
        return delta
    end

    if measuredDuration > expected then
        local extension = measuredDuration - expected
        if extension <= GENERIC_RULE_EXTENSION_WINDOW then
            return 0.75 + extension
        end
    end

    return nil
end

local function MatchGenericRule(unit, auraTypes, measuredDuration, evidence)
    if not EvidenceMatchesReq(E_CAST, evidence) then
        return nil
    end

    local classToken = GetArenaUnitClass(unit)
    if not classToken or not HB.MC or not HB.MC.GetByClass then
        return nil
    end

    local specID = GetArenaUnitSpec(unit)
    local candidates = HB.MC:GetByClass(classToken) or {}
    local bestSpellData
    local bestScore
    local bestSpellID
    local ambiguous = false
    local seenSpellIDs = {}

    for i = 1, #candidates do
        local spellData = candidates[i]
        local spellID = spellData and spellData.spellID

        if spellID
            and not seenSpellIDs[spellID]
            and spellData.effectDuration
            and spellData.effectDuration > 0
            and SpellDataMatchesSpec(spellData, specID)
        then
            seenSpellIDs[spellID] = true

            local auraScore = GetGenericAuraScore(spellData, auraTypes)
            local durationScore = auraScore and GetGenericDurationScore(spellData, measuredDuration) or nil
            local matchesSlot = durationScore ~= nil and HB:SpellMatchesArenaSlot(spellData, GetArenaSlotFromUnit(unit))

            if matchesSlot then
                local totalScore = auraScore + durationScore
                if not bestScore or totalScore < bestScore then
                    bestSpellData = spellData
                    bestSpellID = spellID
                    bestScore = totalScore
                    ambiguous = false
                elseif bestSpellID ~= spellID and math.abs(totalScore - bestScore) <= 0.05 then
                    ambiguous = true
                end
            end
        end
    end

    if ambiguous or not bestSpellData then
        return nil
    end

    return {
        SpellId = bestSpellData.spellID,
        BuffDuration = bestSpellData.effectDuration,
        Generic = true,
    }
end

local function MatchRule(unit, auraTypes, measuredDuration, evidence)
    local classToken = GetArenaUnitClass(unit)
    if not classToken then
        return nil
    end
    local specID = GetArenaUnitSpec(unit)

    local function TryRuleList(ruleList)
        if not ruleList then
            return nil
        end
        for i = 1, #ruleList do
            local rule = ruleList[i]
            if AuraTypeMatchesRule(auraTypes, rule)
                and EvidenceMatchesReq(rule.RequiresEvidence, evidence)
                and DurationMatchesRule(rule, measuredDuration)
                and RuleMatchesTrackableSpell(rule, unit)
            then
                return rule
            end
        end
        return nil
    end

    return TryRuleList(specID and AUTO_RULES.BySpec[specID])
        or TryRuleList(AUTO_RULES.ByClass[classToken])
        or MatchGenericRule(unit, auraTypes, measuredDuration, evidence)
end

local function GetCandidateUnits()
    local units = {}
    for slotIndex = 1, 5 do
        local unit = HB:GetArenaUnitToken(slotIndex)
        if unit and UnitExists(unit) then
            units[#units + 1] = unit
        end
    end
    return units
end

local function TryAutoStartRule(rule, ruleUnit, detectedUnit, trackedStartTime, measuredDuration)
    if not IsAutoTrackingActive() or not rule or not rule.SpellId then
        return false
    end

    local slotIndex = GetArenaSlotFromUnit(ruleUnit)
    if not slotIndex then
        return false
    end

    local now = GetTime()
    local dedupeKey = tostring(rule.SpellId) .. ":" .. tostring(slotIndex)
    local lastAt = lastAutoTriggerAt[dedupeKey]
    if lastAt and (now - lastAt) <= AUTO_DEDUPE_WINDOW then
        return false
    end

    local started = HB:StartCooldownBySpellID(rule.SpellId, slotIndex, {
        ignoreIfActive = true,
        startTime = trackedStartTime,
    })

    if started > 0 then
        lastAutoTriggerAt[dedupeKey] = now
        local spellInfo = HB:GetSpellData(rule.SpellId)
        DebugAuto(
            "Auto-detected %s on %s (seen on %s, %.1fs aura)",
            spellInfo.name or tostring(rule.SpellId),
            ruleUnit or "?",
            detectedUnit or "?",
            measuredDuration or 0
        )
        return true
    end

    return false
end

local function FindBestCandidate(unit, tracked, measuredDuration, candidateUnits)
    local bestRule
    local bestUnit = unit
    local bestCastTime
    local isExternal = tracked.AuraTypes["EXTERNAL_DEFENSIVE"] == true

    local function Consider(candidateUnit, isTarget)
        local scratch = candidateEvidenceScratch
        scratch.Debuff = nil
        scratch.Shield = nil
        scratch.UnitFlags = nil
        scratch.FeignDeath = nil
        scratch.Cast = nil

        local hasEvidence = false
        if tracked.Evidence then
            for key, value in pairs(tracked.Evidence) do
                if key ~= "Cast" and value then
                    scratch[key] = true
                    hasEvidence = true
                end
            end
        end

        local castTime = tracked.CastSnapshot[candidateUnit]
        if castTime and math.abs(castTime - tracked.StartTime) <= CAST_WINDOW then
            scratch.Cast = true
            hasEvidence = true
        end

        local candidateRule = MatchRule(candidateUnit, tracked.AuraTypes, measuredDuration, hasEvidence and scratch or nil)
        if not candidateRule then
            return
        end

        local isBetter = not bestRule
            or (castTime and (not bestCastTime or castTime > bestCastTime))
            or (not castTime and not bestCastTime and isExternal and not isTarget)

        if isBetter then
            bestRule = candidateRule
            bestUnit = candidateUnit
            bestCastTime = castTime
        end
    end

    Consider(unit, true)
    for i = 1, #candidateUnits do
        local candidateUnit = candidateUnits[i]
        if candidateUnit ~= unit then
            Consider(candidateUnit, false)
        end
    end

    return bestRule, bestUnit
end

local function TrackNewAura(unit, trackedAuras, auraInstanceID, info, now)
    local evidence = BuildEvidenceSet(unit, now)
    local castSnapshot = {}
    for snapshotUnit, snapshotTime in pairs(lastCastTime) do
        castSnapshot[snapshotUnit] = snapshotTime
    end

    trackedAuras[auraInstanceID] = {
        StartTime = now,
        AuraTypes = info.AuraTypes,
        Evidence = evidence,
        CastSnapshot = castSnapshot,
    }

    DebugAuto(
        "Tracking aura %s on %s (%s, evidence=%s)",
        tostring(auraInstanceID),
        unit,
        FormatAuraTypes(info.AuraTypes),
        FormatEvidence(evidence)
    )

    C_Timer.After(EVIDENCE_TOLERANCE, function()
        local tracked = trackedAuras[auraInstanceID]
        if not tracked then
            return
        end

        local backfilledEvidence = BuildEvidenceSet(unit, now)
        if backfilledEvidence then
            tracked.Evidence = tracked.Evidence or {}
            for key in pairs(backfilledEvidence) do
                tracked.Evidence[key] = true
            end
        end

        for snapshotUnit, snapshotTime in pairs(lastCastTime) do
            if math.abs(snapshotTime - now) <= CAST_WINDOW and not tracked.CastSnapshot[snapshotUnit] then
                tracked.CastSnapshot[snapshotUnit] = snapshotTime
            end
        end
    end)
end

local function OnAuraRemoved(unit, tracked, now, candidateUnits)
    local measuredDuration = now - tracked.StartTime
    local rule, ruleUnit = FindBestCandidate(unit, tracked, measuredDuration, candidateUnits)
    if not rule then
        DebugAuto(
            "No rule match for %s on %s (%.1fs, %s, evidence=%s)",
            BuildAuraTypesSignature(tracked.AuraTypes),
            unit,
            measuredDuration,
            FormatAuraTypes(tracked.AuraTypes),
            FormatEvidence(tracked.Evidence)
        )
        return false
    end

    if rule.Generic then
        local spellInfo = HB:GetSpellData(rule.SpellId)
        DebugAuto(
            "Generic match %s for %s (%.1fs, %s, evidence=%s)",
            spellInfo.name or tostring(rule.SpellId),
            ruleUnit or unit,
            measuredDuration,
            FormatAuraTypes(tracked.AuraTypes),
            FormatEvidence(tracked.Evidence)
        )
    end

    return TryAutoStartRule(rule, ruleUnit, unit, tracked.StartTime, measuredDuration)
end

local function ProcessUnitAuraState(unit)
    if not IsArenaUnit(unit) then
        return
    end

    if not IsAutoTrackingActive() or not UnitExists(unit) then
        trackedAurasByUnit[unit] = nil
        return
    end

    local trackedAuras = trackedAurasByUnit[unit] or {}
    local current = CollectCurrentTrackedAuras(unit)
    local now = GetTime()
    local candidateUnits = GetCandidateUnits()
    local unmatchedNewIds = {}
    local newIdsBySignature = {}

    for auraInstanceID in pairs(current) do
        if not trackedAuras[auraInstanceID] then
            unmatchedNewIds[#unmatchedNewIds + 1] = auraInstanceID
        end
    end

    for i = 1, #unmatchedNewIds do
        local auraInstanceID = unmatchedNewIds[i]
        local signature = BuildAuraTypesSignature(current[auraInstanceID].AuraTypes)
        newIdsBySignature[signature] = newIdsBySignature[signature] or {}
        newIdsBySignature[signature][#newIdsBySignature[signature] + 1] = auraInstanceID
    end

    for auraInstanceID, tracked in pairs(trackedAuras) do
        if not current[auraInstanceID] then
            local signature = BuildAuraTypesSignature(tracked.AuraTypes)
            local candidates = newIdsBySignature[signature]
            if candidates and #candidates > 0 then
                trackedAuras[table.remove(candidates, 1)] = tracked
            else
                OnAuraRemoved(unit, tracked, now, candidateUnits)
            end
            trackedAuras[auraInstanceID] = nil
        end
    end

    for auraInstanceID, info in pairs(current) do
        if not trackedAuras[auraInstanceID] then
            TrackNewAura(unit, trackedAuras, auraInstanceID, info, now)
        end
    end

    trackedAurasByUnit[unit] = trackedAuras
end

local function RescanAllArenaUnits()
    for slotIndex = 1, 5 do
        ProcessUnitAuraState(HB:GetArenaUnitToken(slotIndex))
    end
end

local function RecordCast(unit)
    if IsArenaUnit(unit) then
        lastCastTime[unit] = GetTime()
    end
end

local function RecordShield(unit)
    if IsArenaUnit(unit) then
        lastShieldTime[unit] = GetTime()
    end
end

local function RecordUnitFlagsChange(unit)
    if not IsArenaUnit(unit) then
        return
    end

    local now = GetTime()
    local isFeign = UnitIsFeignDeath(unit) or false
    if isFeign and not lastFeignDeathState[unit] then
        lastFeignDeathTime[unit] = now
    end
    lastFeignDeathState[unit] = isFeign
    if not isFeign then
        lastUnitFlagsTime[unit] = now
    end
end

local function TryRecordDebuffEvidence(unit, updateInfo)
    if not IsArenaUnit(unit) or not updateInfo or not updateInfo.addedAuras then
        return
    end

    for i = 1, #updateInfo.addedAuras do
        local aura = updateInfo.addedAuras[i]
        local auraInstanceID = aura and aura.auraInstanceID
        if auraInstanceID and not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraInstanceID, "HARMFUL") then
            lastDebuffTime[unit] = GetTime()
            break
        end
    end
end

local function OnTrackingEvent(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit = ...
        RecordCast(unit)
    elseif event == "UNIT_FLAGS" then
        local unit = ...
        RecordUnitFlagsChange(unit)
    elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
        local unit = ...
        RecordShield(unit)
    elseif event == "UNIT_AURA" then
        local unit, updateInfo = ...
        TryRecordDebuffEvidence(unit, updateInfo)
        ProcessUnitAuraState(unit)
    end
end

function HB:InitializeEnemyCooldownTracking()
    if trackingFrame then
        return
    end

    trackingFrame = CreateFrame("Frame")
    trackingFrame:SetScript("OnEvent", OnTrackingEvent)
    trackingFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "arena1", "arena2", "arena3", "arena4", "arena5")
    trackingFrame:RegisterUnitEvent("UNIT_FLAGS", "arena1", "arena2", "arena3", "arena4", "arena5")
    trackingFrame:RegisterUnitEvent("UNIT_AURA", "arena1", "arena2", "arena3", "arena4", "arena5")
    trackingFrame:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
end

function HB:DisableEnemyCooldownTracking()
    if trackingFrame then
        trackingFrame:UnregisterAllEvents()
        trackingFrame:SetScript("OnEvent", nil)
        trackingFrame = nil
    end
    self:ResetEnemyCooldownTracking()
end

function HB:ResetEnemyCooldownTracking()
    trackedAurasByUnit = {}
    lastAutoTriggerAt = {}
    lastDebuffTime = {}
    lastShieldTime = {}
    lastCastTime = {}
    lastUnitFlagsTime = {}
    lastFeignDeathTime = {}
    lastFeignDeathState = {}
end

function HB:RefreshEnemyCooldownTracking()
    if not trackingFrame then
        return
    end
    if not IsAutoTrackingActive() then
        self:ResetEnemyCooldownTracking()
        return
    end
    RescanAllArenaUnits()
end

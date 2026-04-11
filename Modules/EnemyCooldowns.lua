------------------------------------------------------------------------
-- HandyBar - Enemy Cooldown Auto Detection
-- Midnight-safe arena tracking based on aura instance IDs and timing.
------------------------------------------------------------------------
local addonName, ns = ...
local HB = ns.HB
local MC = HB.MC
local AUTO_AURA = MC.AutoTrackAura
local AUTO_EVIDENCE = MC.AutoTrackEvidence

local AUTO_DEDUPE_WINDOW = 0.35
local RULE_TOLERANCE = 0.5
local CAST_WINDOW = 0.15
local EVIDENCE_TOLERANCE = 0.15
local GENERIC_RULE_TOLERANCE = 1.25
local GENERIC_RULE_EXTENSION_WINDOW = 4.0

local AURA_FILTERS = {
    { key = AUTO_AURA.BIG_DEFENSIVE, filter = "HELPFUL|BIG_DEFENSIVE" },
    { key = AUTO_AURA.EXTERNAL_DEFENSIVE, filter = "HELPFUL|EXTERNAL_DEFENSIVE" },
    { key = AUTO_AURA.IMPORTANT, filter = "HELPFUL|IMPORTANT" },
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
local unitCanFeign = {}
local lastMaxHealthChangeTime = {}
local candidateEvidenceScratch = {}

local E_CAST = AUTO_EVIDENCE.CAST

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
    if auraTypes[AUTO_AURA.BIG_DEFENSIVE] then
        tags[#tags + 1] = AUTO_AURA.BIG_DEFENSIVE
    end
    if auraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] then
        tags[#tags + 1] = AUTO_AURA.EXTERNAL_DEFENSIVE
    end
    if auraTypes[AUTO_AURA.IMPORTANT] then
        tags[#tags + 1] = AUTO_AURA.IMPORTANT
    end
    return #tags > 0 and table.concat(tags, "+") or "none"
end

local function FormatEvidence(evidence)
    if not evidence then
        return "none"
    end

    local tags = {}
    if evidence[AUTO_EVIDENCE.CAST] then
        tags[#tags + 1] = AUTO_EVIDENCE.CAST
    end
    if evidence[AUTO_EVIDENCE.DEBUFF] then
        tags[#tags + 1] = AUTO_EVIDENCE.DEBUFF
    end
    if evidence[AUTO_EVIDENCE.SHIELD] then
        tags[#tags + 1] = AUTO_EVIDENCE.SHIELD
    end
    if evidence[AUTO_EVIDENCE.UNIT_FLAGS] then
        tags[#tags + 1] = AUTO_EVIDENCE.UNIT_FLAGS
    end
    if evidence[AUTO_EVIDENCE.FEIGN_DEATH] then
        tags[#tags + 1] = AUTO_EVIDENCE.FEIGN_DEATH
    end
    if evidence[AUTO_EVIDENCE.MAX_HEALTH] then
        tags[#tags + 1] = AUTO_EVIDENCE.MAX_HEALTH
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
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then
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
        evidence[AUTO_EVIDENCE.DEBUFF] = true
    end
    if lastShieldTime[unit] and math.abs(lastShieldTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then
        evidence = evidence or {}
        evidence[AUTO_EVIDENCE.SHIELD] = true
    end
    if lastFeignDeathTime[unit] and math.abs(lastFeignDeathTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence[AUTO_EVIDENCE.FEIGN_DEATH] = true
    elseif lastUnitFlagsTime[unit] and math.abs(lastUnitFlagsTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence[AUTO_EVIDENCE.UNIT_FLAGS] = true
    end
    if lastCastTime[unit] and math.abs(lastCastTime[unit] - detectionTime) <= CAST_WINDOW then
        evidence = evidence or {}
        evidence[AUTO_EVIDENCE.CAST] = true
    end
    if lastMaxHealthChangeTime[unit] and math.abs(lastMaxHealthChangeTime[unit] - detectionTime) <= EVIDENCE_TOLERANCE then
        evidence = evidence or {}
        evidence[AUTO_EVIDENCE.MAX_HEALTH] = true
    end
    return evidence
end

local function BuildAuraTypesSignature(auraTypes)
    local signature = ""
    if auraTypes[AUTO_AURA.BIG_DEFENSIVE] then
        signature = signature .. "B"
    end
    if auraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] then
        signature = signature .. "E"
    end
    if auraTypes[AUTO_AURA.IMPORTANT] then
        signature = signature .. "I"
    end
    return signature
end

local function AuraTypeMatchesRule(auraTypes, rule)
    if rule.BigDefensive == true and not auraTypes[AUTO_AURA.BIG_DEFENSIVE] then
        return false
    end
    if rule.BigDefensive == false and auraTypes[AUTO_AURA.BIG_DEFENSIVE] then
        return false
    end
    if rule.ExternalDefensive == true and not auraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] then
        return false
    end
    if rule.ExternalDefensive == false and auraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] then
        return false
    end
    if rule.Important == true and not auraTypes[AUTO_AURA.IMPORTANT] then
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
            and (not rule.MinCancelDuration or measuredDuration >= rule.MinCancelDuration)
    end
    return math.abs(measuredDuration - rule.BuffDuration) <= RULE_TOLERANCE
end

local function GetEvidenceSpecificity(req)
    if req == nil or req == false then
        return 0
    end
    if type(req) == "string" then
        return 1
    end
    if type(req) == "table" then
        return #req
    end
    return 0
end

local function GetAuraSpecificity(rule)
    local score = 0
    if rule.BigDefensive ~= nil then
        score = score + 1
    end
    if rule.ExternalDefensive ~= nil then
        score = score + 1
    end
    if rule.Important ~= nil then
        score = score + 1
    end
    return score
end

local function GetRuleDurationDistance(rule, measuredDuration)
    return math.abs((rule and rule.BuffDuration or 0) - measuredDuration)
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
        if auraTypes[AUTO_AURA.IMPORTANT] then
            return 0
        end
        return nil
    end

    if spellData.category == C.DEFENSIVE then
        if auraTypes[AUTO_AURA.BIG_DEFENSIVE] then
            return 0
        end
        if auraTypes[AUTO_AURA.IMPORTANT] then
            return 0.4
        end
        return nil
    end

    if spellData.category == C.UTILITY then
        if auraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] then
            return 0
        end
        if auraTypes[AUTO_AURA.IMPORTANT] then
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

local function IsSpellOnCooldownForSlot(spellID, slotIndex)
    if not spellID or not slotIndex then
        return false
    end
    local onCooldown = false
    local now = GetTime()
    HB:ForEachSpellButton(spellID, slotIndex, function(button)
        if button.cooldownEndTime and button.cooldownEndTime > now then
            onCooldown = true
        end
    end)
    return onCooldown
end

local function MatchRule(unit, auraTypes, measuredDuration, evidence, slotIndex)
    local classToken = GetArenaUnitClass(unit)
    if not classToken then
        return nil
    end
    local specID = GetArenaUnitSpec(unit)

    local function TryRuleList(ruleList)
        if not ruleList then
            return nil
        end
        local bestRule
        local bestEvidenceSpecificity
        local bestAuraSpecificity
        local bestDurationDistance
        local fallback
        local ambiguous = false
        for i = 1, #ruleList do
            local rule = ruleList[i]
            if AuraTypeMatchesRule(auraTypes, rule)
                and EvidenceMatchesReq(rule.RequiresEvidence, evidence)
                and DurationMatchesRule(rule, measuredDuration)
                and RuleMatchesTrackableSpell(rule, unit)
            then
                local alreadyOnCd = slotIndex and rule.SpellId and IsSpellOnCooldownForSlot(rule.SpellId, slotIndex)
                if alreadyOnCd then
                    if not fallback then
                        fallback = rule
                    end
                else
                    local evidenceSpecificity = GetEvidenceSpecificity(rule.RequiresEvidence)
                    local auraSpecificity = GetAuraSpecificity(rule)
                    local durationDistance = GetRuleDurationDistance(rule, measuredDuration)
                    local isBetter = not bestRule
                        or evidenceSpecificity > bestEvidenceSpecificity
                        or (evidenceSpecificity == bestEvidenceSpecificity and auraSpecificity > bestAuraSpecificity)
                        or (evidenceSpecificity == bestEvidenceSpecificity
                            and auraSpecificity == bestAuraSpecificity
                            and durationDistance < bestDurationDistance)

                    if isBetter then
                        bestRule = rule
                        bestEvidenceSpecificity = evidenceSpecificity
                        bestAuraSpecificity = auraSpecificity
                        bestDurationDistance = durationDistance
                        ambiguous = false
                    elseif bestRule
                        and bestRule.SpellId ~= rule.SpellId
                        and evidenceSpecificity == bestEvidenceSpecificity
                        and auraSpecificity == bestAuraSpecificity
                        and math.abs(durationDistance - bestDurationDistance) <= 0.05
                    then
                        ambiguous = true
                    end
                end
            end
        end

        if ambiguous then
            return nil
        end

        return bestRule or fallback
    end

    return TryRuleList(specID and MC:GetAutoTrackRulesBySpec(specID))
        or TryRuleList(MC:GetAutoTrackRulesByClass(classToken))
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
    local isExternal = tracked.AuraTypes[AUTO_AURA.EXTERNAL_DEFENSIVE] == true

    local function Consider(candidateUnit, isTarget)
        local scratch = candidateEvidenceScratch
        scratch[AUTO_EVIDENCE.DEBUFF] = nil
        scratch[AUTO_EVIDENCE.SHIELD] = nil
        scratch[AUTO_EVIDENCE.UNIT_FLAGS] = nil
        scratch[AUTO_EVIDENCE.FEIGN_DEATH] = nil
        scratch[AUTO_EVIDENCE.CAST] = nil
        scratch[AUTO_EVIDENCE.MAX_HEALTH] = nil

        local hasEvidence = false
        if tracked.Evidence then
            for key, value in pairs(tracked.Evidence) do
                if key ~= AUTO_EVIDENCE.CAST and value then
                    scratch[key] = true
                    hasEvidence = true
                end
            end
        end

        local castTime = tracked.CastSnapshot[candidateUnit]
        if castTime and math.abs(castTime - tracked.StartTime) <= CAST_WINDOW then
            scratch[AUTO_EVIDENCE.CAST] = true
            hasEvidence = true
        end

        local candidateSlotIndex = GetArenaSlotFromUnit(candidateUnit)
        local candidateRule = MatchRule(candidateUnit, tracked.AuraTypes, measuredDuration, hasEvidence and scratch or nil, candidateSlotIndex)
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

local function TryEarlyDetection(unit, tracked, startTime)
    if not IsAutoTrackingActive() or not tracked or not tracked.Evidence then
        return
    end
    if not tracked.Evidence[AUTO_EVIDENCE.CAST] then
        return
    end

    local classToken = GetArenaUnitClass(unit)
    if not classToken then
        return
    end
    local specID = GetArenaUnitSpec(unit)
    local slotIndex = GetArenaSlotFromUnit(unit)
    if not slotIndex then
        return
    end

    local function TryEarlyRuleList(ruleList)
        if not ruleList then
            return nil
        end
        local bestRule
        local ambiguous = false
        for i = 1, #ruleList do
            local rule = ruleList[i]
            if rule.EarlyDetect
                and AuraTypeMatchesRule(tracked.AuraTypes, rule)
                and EvidenceMatchesReq(rule.RequiresEvidence, tracked.Evidence)
                and RuleMatchesTrackableSpell(rule, unit)
                and not IsSpellOnCooldownForSlot(rule.SpellId, slotIndex)
            then
                if not bestRule then
                    bestRule = rule
                elseif bestRule.SpellId ~= rule.SpellId then
                    ambiguous = true
                end
            end
        end
        if ambiguous then
            return nil
        end
        return bestRule
    end

    local rule = TryEarlyRuleList(specID and MC:GetAutoTrackRulesBySpec(specID))
        or TryEarlyRuleList(MC:GetAutoTrackRulesByClass(classToken))
    if not rule then
        return
    end

    tracked.EarlyDetected = true
    local started = TryAutoStartRule(rule, unit, unit, startTime, rule.BuffDuration)
    if started then
        DebugAuto(
            "Early-detected %s on %s (%s, evidence=%s)",
            tostring(rule.SpellId),
            unit,
            FormatAuraTypes(tracked.AuraTypes),
            FormatEvidence(tracked.Evidence)
        )
    end
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
        EarlyDetected = false,
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

        if not tracked.EarlyDetected then
            TryEarlyDetection(unit, tracked, now)
        end
    end)
end

local function OnAuraRemoved(unit, tracked, now, candidateUnits)
    if tracked.EarlyDetected then
        return true
    end
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
        local now = GetTime()
        if lastCastTime[unit] ~= now then
            lastCastTime[unit] = now
        end
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
    local canFeign = unitCanFeign[unit]
    if canFeign == nil then
        local classToken = GetArenaUnitClass(unit)
        canFeign = classToken == "HUNTER"
        unitCanFeign[unit] = canFeign
    end
    local isFeign = canFeign and UnitIsFeignDeath(unit) or false
    if isFeign and not lastFeignDeathState[unit] then
        lastFeignDeathTime[unit] = now
    end
    lastFeignDeathState[unit] = isFeign
    if not isFeign then
        lastUnitFlagsTime[unit] = now
    end
end

local function RecordMaxHealthChange(unit)
    if not IsArenaUnit(unit) then
        return
    end

    -- Midnight exposes arena max health as a secret value, so use the event timing
    -- as evidence instead of touching UnitHealthMax(unit) directly.
    lastMaxHealthChangeTime[unit] = GetTime()
end

local function TryRecordDebuffEvidence(unit, updateInfo)
    if not IsArenaUnit(unit)
        or not updateInfo
        or updateInfo.isFullUpdate
        or not updateInfo.addedAuras
    then
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
    elseif event == "UNIT_MAXHEALTH" then
        local unit = ...
        RecordMaxHealthChange(unit)
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
    trackingFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "arena1", "arena2", "arena3", "arena4", "arena5")
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
    unitCanFeign = {}
    lastMaxHealthChangeTime = {}
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

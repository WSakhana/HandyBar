-- ============================================================================
-- MajorCooldowns | Core
-- Library initialization via LibStub.
-- ============================================================================

---@class MajorCooldowns
local MAJOR, MINOR = "MajorCooldowns", 2
local lib, oldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

-- Store minor so other files can guard against stale loads
lib._minor = MINOR

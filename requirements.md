# 📄 HandyBar – Functional & Behavioral Requirements

**World of Warcraft Addon (Retail – Midnight)**

---

## 1. Purpose

HandyBar is a **manual cooldown tracking addon** for **World of Warcraft: Midnight**, designed primarily for **PvP Arenas**.

Due to the removal or restriction of Combat Log–based APIs in Midnight, HandyBar **must not rely on any automatic detection** of enemy spell usage.

Instead, HandyBar provides **clickable cooldown icons (bars)** that the player manually triggers when an enemy uses a known ability.

---

## 2. Core Principles (Non-Negotiable)

* ❌ No Combat Log usage
* ❌ No spellcast detection
* ❌ No guessing, scanning, or inference of enemy actions
* ✅ Cooldowns are triggered **only by explicit user interaction**
* ✅ The addon must remain fully functional in PvP instances under Midnight API restrictions
* ✅ Behavior must be deterministic and predictable

---

## 3. Functional Scope

### 3.1 Bars

* The addon must allow the user to create **multiple independent bars**
* Each bar represents a logical group of spells (e.g. Interrupts, Defensives, Crowd Control, Offensives)
* Bars must be:

  * Movable
  * Resizable
  * Configurable independently

---

### 3.2 Spells

* The list of available spells **must come exclusively from**:

  * **MajorCooldowns**

* Each spell includes:

  * Spell ID
  * Name
  * Icon
  * Base cooldown duration
  * Associated class

* The user must be able to:

  * Enable or disable spells per bar
  * Assign spells to specific bars
  * Filter spells by class

---

## 4. Manual Cooldown Triggering

### 4.1 User Interaction

* Each spell icon displayed on a bar must be **clickable**
* When the player visually observes an enemy using an ability, they manually click the corresponding icon
* Clicking an icon:

  * Starts the cooldown timer
  * Displays a cooldown overlay (spiral, timer text, or both)
  * Visually indicates that the spell is on cooldown (e.g. desaturated icon)

---

### 4.2 Reset & Control

* The addon must support:

  * Manual reset of a cooldown (e.g. right-click or modifier click)
  * Optional full bar reset
* Cooldowns must:

  * End exactly when their duration completes
  * Return to a “ready” visual state

---

## 5. Arena-Aware Behavior

### 5.1 Arena Detection

* When entering an Arena match, the addon must:

  * Detect active enemy units using `arena1`, `arena2`, `arena3`
  * Determine their classes
* Only spells matching the detected enemy classes must be displayed

Example:

* Enemy team: Mage + Warrior
* Only Mage and Warrior spells appear on bars

---

### 5.2 Dynamic Filtering

* If enemy composition changes (e.g. between rounds):

  * Bars must update accordingly
* Spells unrelated to present enemy classes must be hidden

---

## 6. Test Mode

### 6.1 Purpose

Test Mode exists to allow:

* Layout configuration
* Visual testing
* Cooldown interaction testing
* Bar tuning outside of Arena

---

### 6.2 Behavior

When Test Mode is enabled:

* All bars are forced visible
* All spells assigned to each bar are shown
* Arena filtering is **completely ignored**
* All spells are interactable
* Cooldowns behave as normal but are purely simulated

---

### 6.3 Activation

* Test Mode must be toggleable via:

  * Slash command
  * GUI option

---

## 7. Configuration & User Interface

### 7.1 Libraries

The addon must use:

* **Ace3 libraries** for:

  * Configuration
  * GUI
  * Console commands
  * Saved variables
  * Event handling

---

### 7.2 Configuration Features

The configuration UI must allow:

* Creating / deleting bars
* Assigning spells to bars
* Enabling or disabling spells
* Adjusting:

  * Icon size
  * Spacing
  * Orientation
  * Cooldown text visibility
* Enabling / disabling Test Mode
* Resetting cooldowns

---

## 8. Persistence

* All user configuration must persist between sessions
* Support multiple profiles (at least global and character-based)

---

## 9. Visual & UX Requirements

* Cooldowns must be clearly readable during combat
* Icons must:

  * Be visually disabled while on cooldown
  * Clearly indicate readiness when available
* User interactions must be:

  * Instant
  * Latency-free
  * Consistent

---

## 10. Performance Constraints

* The addon must:

  * Avoid unnecessary OnUpdate loops
  * Scale correctly with multiple bars and many spells
  * Not cause FPS drops in Arenas

---

## 11. Compatibility

* Target game version: **World of Warcraft Retail – Midnight**
* Focused on:

  * Arenas (2v2, 3v3, Solo Shuffle)
* Must not rely on deprecated or restricted APIs

---

## 12. Non-Goals

HandyBar explicitly does **not**:

* Automatically detect spell usage
* Replace skill awareness or decision-making
* Attempt to bypass Blizzard API restrictions

---

## 13. Positioning Statement

HandyBar is a **manual-first OmniBar alternative**, built specifically for Midnight, prioritizing **reliability, control, and player intent** over automation.

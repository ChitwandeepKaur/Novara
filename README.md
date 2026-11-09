# ASCEND: A Real-Life RPG for iOS

> *"Your avatar represents who you are becoming. Your world represents the life you are building."*

**ASCEND** is a native iOS single-player, goal-driven life RPG built with **Swift** and **SwiftUI**. Unlike conventional habit trackers or to-do lists, ASCEND transforms real-world goals, study sessions, workouts, and self-care routines into an immersive fantasy-tech RPG progression system.

---

## 🌟 Key Systems & Features

### 1. Interactive Fantasy-Tech Game World
- **Dynamic 2.5D Layered World Canvas:** Featuring celestial skyboxes, stardust particle systems, floating islands, and glowing Leyline bridges.
- **Three Founding Realms:**
  - **Career Kingdom (The Grand Citadel):** Largest floating realm. Upgrades with software engineering milestones and technical mastery.
  - **Fitness Grounds (The Colosseum of Vitality):** Fortified obsidian athletic plateau that glows with radiant flame as physical training is logged.
  - **Self-Care Sanctuary (The Celestial Grove):** Tranquil haven blooming with bioluminescent flora as restorative routines are maintained.
- **World Progression:** Completing quests illuminates pathways, upgrades architectural monuments (Ruin $\to$ Workshop $\to$ Guildhall $\to$ Celestial Citadel), and completing a Main Quest triggers world-wide Ascension.

### 2. Quest Hierarchy & Dependency Graph (DAG)
- **Main Quests:** The overarching life goal (e.g. *"Land a Software Engineering Job"*). Exactly **one** Main Quest is active at any time. Players can pause and switch journeys without losing XP, milestones, or history.
- **Sub Quests:** Meaningful milestones with configurable completion conditions (`allTasksCompleted`, `numericalTarget`, `milestoneReached`, `deliverableCompleted`, `manualConfirmation`).
- **Prerequisite Validation:** Directed Acyclic Graph (DAG) dependency graph with **cycle detection** preventing circular dependencies.
- **Side Quests:** Simple recurring daily habits and secondary quest chains.

### 3. Smart Daily Planning Engine
- **Deterministic & Explainable:** Allocates daily focus time based on user-configured priority weights (Default: **80% Career / 10% Fitness / 10% Self-Care**).
- **Two Synchronized Views:**
  - **Timeline View:** Chronological schedule with start/end times, durations, and restorative breaks.
  - **Checklist View:** Actionable task checklist. Both views read and write the exact same underlying state without data loss.
- **Smart Non-Destructive Replanning:** If scheduled sessions fall behind, the engine proposes an adjusted schedule (compressing flexible blocks, shifting tasks, protecting fixed goals). Never overwrites without explicit player approval.
- **Integrated Focus Chamber (Timer):** Built-in focus timer with start/pause/resume/stop, manual time adjustment, and automatic effort logging.
- **Evening Reflection (Daily Recap):** Non-punitive summary of completed work, effort XP, and tomorrow prep with zero guilt mechanics.

### 4. 3-Tier XP Engine & Anti-Exploit Rules
- **Effort XP:** 1 XP per minute of focused work, capped at a healthy daily threshold (default 360 XP/day = 6 hours) to prevent burnout farming. Effort tracking continues even after the XP cap is reached.
- **Achievement XP:** Discrete milestone accomplishments, strictly deduplicated by key.
- **Completion Bonus XP:** One-off rewards for completing Sub Quests and Main Quests. Toggling completion on and off never re-awards bonus XP.
- **Mathematical Level Curve:** Cumulative XP curve $\text{XP}(L) = \lfloor 100 \times (L - 1)^{1.6} \rfloor$ with exact integer synchronization.
- **Auditable Transaction Log:** Every XP event is permanently recorded with timestamp, category, and source.

### 5. Future-Self Identity System
- **Identity Roadmaps:** Long-term future vision coupled with intermediate evolution stages (e.g. *The Initiate $\to$ The Artisan Builder $\to$ The Resolute Contender $\to$ The Breakthrough Self*).
- **Milestone-Gated:** XP alone cannot unlock major Future-Self transformations. Tangible SubQuest milestones must be verified.
- **Cosmetic Rewards:** Unlocks majestic titles, visual auras, and ceremonial equipment.

### 6. Interactive Skill Trees
- Categorized skill trees for **Career**, **Fitness**, and **Self-Care**.
- Visual node graph displaying locked, available, in-progress, and mastered states.
- Quest completion directly attributes progression points to linked skills.

### 7. Evidence Vault & Achievements
- Trust-based daily progress with optional evidence attachment (URLs, notes, screenshots, documents) for major achievements.
- Permanent Achievement Archive preserving accomplishments across all completed journeys.

### 8. Privacy & Offline-First Architecture
- 100% functional without an active network connection.
- Zero analytics, zero ad SDKs, zero hidden tracking.
- Complete JSON export and import for seamless personal data ownership and backup.

---

## 🛠 Project Structure

```
ASCEND-iOS/
├── ASCEND.xcodeproj/                   # Standard Xcode Project (iOS 17.0+)
│   ├── project.pbxproj
│   └── xcshareddata/xcschemes/ASCEND.xcscheme
├── ASCEND/
│   ├── App/
│   │   ├── ASCENDApp.swift             # @main App entry point
│   │   └── ContentView.swift           # Root coordinator (Onboarding vs MainTabView)
│   ├── Models/                         # Clean Domain Models
│   │   ├── QuestModels.swift           # MainQuest, SubQuest, DailyQuest, SideQuest
│   │   ├── CharacterModels.swift       # AvatarProfile, CosmeticItem, Equipment
│   │   ├── SkillModels.swift           # SkillNode, SkillCategory, Presets
│   │   ├── FutureSelfModels.swift      # FutureSelfStage, FutureSelfRoadmap
│   │   ├── WorldModels.swift           # WorldState, WorldRegion, WorldStructure
│   │   ├── PlanningModels.swift        # DailyPlan, TimeSlot, FocusSession, ReplanProposal
│   │   ├── XPModels.swift              # XPTransaction, XPRewardCategory, LevelCurve
│   │   └── AchievementModels.swift     # Achievement, EvidenceAttachment
│   ├── Services/
│   │   ├── Persistence/
│   │   │   └── AppDataStore.swift      # High-reliability Codable JSON store with atomic saves
│   │   ├── Engines/
│   │   │   ├── QuestEngine.swift       # Exclusivity, DAG prerequisites, cycle detection
│   │   │   ├── PlanningEngine.swift    # Priority allocation, timeline generator, smart replanner
│   │   │   ├── XPEngine.swift          # 3-tier rewards, anti-exploit caps, level curves
│   │   │   ├── SkillEngine.swift       # Skill tree graph, prerequisites, mastery
│   │   │   ├── FutureSelfEngine.swift  # Milestone validation & transformation triggers
│   │   │   └── WorldEngine.swift       # Region progression & structure illumination
│   │   ├── AI/
│   │   │   └── PlanningAIService.swift # AI abstraction protocol with deterministic fallback
│   │   └── Utilities/
│   │       └── HapticService.swift     # Sensory feedback for iOS
│   ├── DesignSystem/
│   │   ├── Theme.swift                 # Midnight Navy, Electric Blue, Violet, Cyan, Gold
│   │   └── Components/                 # GlassCard, GlowingButton, XPBadge, StatRing, Particles
│   ├── Views/
│   │   ├── Navigation/MainTabView.swift # 5 Core Tabs (World, Quests, Plan, Skills, Character)
│   │   ├── World/                      # Interactive Canvas World & Region Inspector
│   │   ├── Quests/                     # Quest tree, editor, detail sheet, archive
│   │   ├── DailyPlan/                  # Timeline & Checklist views, Focus Timer, Recap
│   │   ├── Skills/                     # Interactive skill matrix & node details
│   │   ├── Character/                  # Stylized avatar customizer & cosmetics wardrobe
│   │   ├── Onboarding/                 # Guided setup with Career 80/10/10 preset
│   │   └── Settings/                   # Privacy, JSON export/import, sound/haptic toggles
│   └── Resources/
│       ├── Info.plist                  # iOS Bundle metadata
│       └── Assets.xcassets/            # AppIcon and asset catalog
├── ASCENDTests/                        # Comprehensive Automated Unit Test Suite
│   ├── QuestEngineTests.swift          # Exclusivity, DAG, cycles, completion conditions
│   ├── XPEngineTests.swift             # Caps, deduplication, one-off bonus, curves
│   ├── PlanningEngineTests.swift       # Scheduling, budgets, replan detection & approval
│   ├── SkillEngineTests.swift          # Node states, leveling, quest attribution
│   ├── FutureSelfEngineTests.swift     # Milestone gating, identity transformations
│   ├── PersistenceTests.swift          # Save/load, export/import roundtrip, wipe
│   └── TestRunnerMain.swift            # Standalone test runner entry point
├── Scripts/
│   └── run_tests.sh                    # Automated test runner script
├── ARCHITECTURE.md                     # Detailed system architecture document
├── GAME_RULES.md                       # Comprehensive game rules, XP formulas & anti-cheat
└── PROGRESS.md                         # Milestone tracking & changelog
```

---

## 🚀 How to Open and Run in Xcode

1. **Requirements:**
   - macOS Sonoma 14.0 or macOS Sequoia 15.0+
   - Xcode 15.0 or Xcode 16.0+
   - Target Platform: **iOS 17.0+** (iPhone & iPad)
2. **Open the Project:**
   ```bash
   open ASCEND.xcodeproj
   ```
3. **Select Scheme and Destination:**
   - In Xcode's toolbar, choose the **ASCEND** scheme.
   - Choose any iOS Simulator (e.g., iPhone 15 Pro, iPhone 16 Pro) or a connected physical iOS device.
4. **Build and Run:**
   - Press **Cmd + R** to build and launch the application.

---

## 🧪 Running Automated Unit Tests

You can run the full automated test suite directly from the command line:

```bash
./Scripts/run_tests.sh
```

**Test Coverage Summary:**
- ✅ **QuestEngineTests:** Single active Main Quest invariant, pausing without progress loss, DAG prerequisite checks, circular dependency cycle detection, numerical target completion, archiving.
- ✅ **XPEngineTests:** Level calculation curve, daily effort XP cap enforcement, achievement XP deduplication, one-off completion bonus rule, auditable transaction log.
- ✅ **PlanningEngineTests:** Priority weight budgeting, prerequisite filtering in scheduling, smart replan detection and approval flow, schedule preservation on dismissal.
- ✅ **SkillEngineTests:** Node state transitions (locked, available, in progress, mastered), level progression, quest completion attribution.
- ✅ **FutureSelfEngineTests:** Milestone gating (XP alone cannot trigger major evolutions), intermediate stage unlocking, title cosmetic rewards.
- ✅ **PersistenceTests:** JSON encoding/decoding roundtrip, export/import data restoration, reset all data.

---

## 🛡 Anti-Exploit & Fairness Guarantee

1. **Anti-Toggling Protection:** Toggling a quest between completed and uncompleted never grants bonus XP a second time.
2. **Daily Effort Cap:** Focused work awards up to the configurable daily cap (360 XP/day) to encourage consistent, healthy progress rather than binge-burnout farming.
3. **Milestone Integrity:** Future-Self transformations strictly require verified SubQuest deliverables. XP alone will not advance identity stages.
4. **Anti-Guilt Mechanic:** Days off or missed target dates never strip away earned XP, never demote levels, and never break streaks punitive fashion.


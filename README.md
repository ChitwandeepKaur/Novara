# Novara: A Real-Life RPG for iOS

> *"Your avatar represents who you are becoming. Your world represents the life you are building."*

**Novara** is a native iOS single-player, goal-driven life RPG built with **Swift** and **SwiftUI**. Unlike conventional habit trackers or to-do lists, Novara transforms real-world goals, study sessions, workouts, and self-care routines into an immersive fantasy-tech RPG progression system.

---

## 🌟 Key Systems & Features

### Weekly plan upload
- In **Daily Plan → Week**, upload a UTF-8 text/Markdown file or a PDF containing selectable text, or paste your plan.
- Use Monday through Sunday headings with timed task headings, for example `Python: Collections (60 min)`. Review task names, days, durations, optional work, and outside-core commitments before import.
- Imported tasks are dated. The Plan date selector shows the right checklist and schedule; reimporting the same heading/date skips duplicates.
- The November 9–15, 2026 plan is installed once from the verified shared chat, using only the six main subject headings per day: Python, CLI, DSA, system design, systems/Linux, and AI. See [the imported heading list](Artifacts/Week-1-Nov9-15-2026.md).
- Daily non-negotiables are always included for all seven days of every opened or imported week: **DSA Practice**, **PHC QA**, **Sahota Services**, **Portfolio Work**. DSA and CLI topics link to DSA Practice and Portfolio Work without duplicating tasks or completion credit.
- Default durations are 120, 120, 60, and 90 minutes respectively. PHC QA and Sahota Services sit outside the core focus budget. Each date has its own completion record.
- Week 1 retains its 42 subject headings, with DSA and CLI headings attached to their non-negotiables and PHC QA/Sahota Services added daily. Nested exercises remain excluded. Optional DSA durations stay in the topic notes.
- Weekly plans participate in local saves and JSON backups. The application does not use em dashes in display text; see [the writing convention](AGENTS.md).

### 75-day challenge
- Open **75 Days** to activate the tracker using the default November 9, 2026 start date or a new date.
- Dashboard, Daily, Weekly, and Trends reproduce the supplied Google Sheet's tasks, log fields, formulas, and charts. See [the source mapping](CHALLENGE_TRACKER.md).
- Today's five challenge goals also appear in **Daily Plan** and share the same editable log.
- Track nutrition, optional calories, treat meals, ratings, weekly body measurements, and reflections; explicitly reuse recorded focus time when appropriate.
- Challenge XP contributes to character levels and cosmetics: 10 per goal, 15 for all five, 10 per daily rating, 50 per weekly reflection, plus rated-day milestone bonuses. Rewards are awarded once, including previously saved qualifying logs.
- Data stays offline and participates in JSON backups. There is no live write-back to Google Sheets.

### Personal fairy themes
- Choose Bloom, Stella, Flora, Musa, Tecna, or Aisha in **Settings → Your fairy affinity**. Flora is the initial palette.
- Jewel-toned backgrounds, warm metallic borders, softer particles, and serif headings coordinate across the app.
- Original native wing illustrations appear in onboarding, the daily-plan banner, and the world. The character sigil reflects skin, hair, and outfit choices.
- Palette selection is saved locally on the device and updates immediately. Decorative artwork does not intercept taps or add VoiceOver noise.

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

### Mini Main Quests (temporary goals)
- In **Quests → Add Mini Main Quest**, enter a title, target date, and one outcome per line.
- Review and edit the planning, focused work, and verification sessions generated for each outcome.
- Sessions join the Plan checklist immediately. Existing appointments are preserved; a session is appended when there is room.
- Generate a daily schedule to reserve up to 25% of focus time for mini quests, earliest deadline first, with one next session per quest per day.
- Completing sessions automatically completes milestones and the mini quest, awarding one-time bonuses. Missed deadlines preserve progress.
- Breakdowns use local templates and can be customized before saving.

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


### Fairy journey

Flora is the starting fairy. Lifetime character XP unlocks Aisha at 10,000 XP, Tecna at 20,000 XP, Musa at 30,000 XP, Stella at 40,000 XP, and Bloom at 50,000 XP. All existing XP sources count, including the 75 day challenge. Crossing a milestone automatically equips the newly unlocked fairy and updates the app palette. Settings shows progress and allows switching to any unlocked fairy. The selected fairy is saved in JSON backups; older backups unlock fairies from their existing lifetime XP. Resetting progress returns to Flora.

The selected fairy also controls original elemental artwork throughout the UI: botanical vines and petals (Flora), waves and ripples (Aisha), circuits and facets (Tecna), musical staves and sound waves (Musa), sunbursts and lunar arcs (Stella), and flame contours (Bloom). Each fairy has a distinct wing silhouette, realm greeting, background, card ornaments, navigation emblem, and ambient particles. Ambient motion respects Reduce Motion. These native vector designs render offline without external image requests.

Visual references: official Winx character profiles for [Flora](https://www.winxclub.com/en-us/blogs/discover-the-winx/flora), [Aisha](https://www.winxclub.com/en-us/blogs/discover-the-winx/aisha), [Tecna](https://www.winxclub.com/en-us/blogs/discover-the-winx/tecna), [Musa](https://www.winxclub.com/en-us/blogs/discover-the-winx/musa), [Stella](https://www.winxclub.com/en-us/blogs/discover-the-winx/stella), and [Bloom](https://www.winxclub.com/en-us/blogs/discover-the-winx/bloom). Artwork in Novara is original vector interpretation of these elemental references.

The app is branded Novara on the Home Screen, in onboarding, Settings, and built app products. The existing bundle identifier and saved-data filename are preserved so updating the app keeps existing progress. The Xcode project and scheme remain named ASCEND for compatibility with current development commands.

### Personal device, recovery, and online services

See [PERSONAL_SETUP.md](PERSONAL_SETUP.md) for personal iPhone installation, Supabase cloud setup, secure online AI configuration, local recovery, and the physical-phone verification checklist. Automatic signing is enabled; selecting your Apple team and connecting a trusted device are still required.

Novara is configured for free-only personal use: on-device template planning and optional Supabase Free cloud sync. No paid AI API, API key, subscription, or automatic service upgrade is used.

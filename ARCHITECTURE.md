# ASCEND iOS — System Architecture & Design Documentation

## 1. Overview & Vision

**ASCEND** is a native iOS single-player, goal-driven life RPG. It bridges real-life self-actualization with modern fantasy-tech RPG progression mechanics:
> *"Your avatar represents who you are becoming. Your world represents the life you are building."*

The architecture is built from the ground up to support:
- Highly personalized goals (not hardcoded to one journey).
- Offline-first operation with zero tracking, zero mandatory cloud dependencies, and zero private credential leakage.
- Deterministic, explainable daily planning engine with clean abstraction for optional AI enrichment.
- Multi-tier anti-exploit XP economy.
- Visual world and character evolution reflecting real accomplishments.

---

## 2. Technology Stack & Platform Targets

- **Language:** Swift 6.0+ (with modern Concurrency, `@Observable` / Observation framework, Swift standard library).
- **UI Framework:** SwiftUI (iOS 17.0+ deployment target) featuring Canvas, modern NavigationStack, sheets, and materials.
- **Visuals:** Native SwiftUI Canvas 2.5D layered rendering with particle systems, dynamic atmospheric gradients, and glow shaders.
- **Persistence:** High-reliability `AppDataStore` with JSON atomic persistence, schema versioning, automated backup, and JSON export/import.
- **Platform:** Native iOS 17.0+ (Universal iPhone & iPad support, Dark-Mode-First, Dynamic Type, Reduce Motion friendly).

---

## 3. Core Architectural Layers

The codebase follows a clean, modular, feature-oriented architecture:

```
ASCEND-iOS/
├── ASCEND/
│   ├── App/
│   │   ├── ASCENDApp.swift             # App entry point, lifecycle, root environment setup
│   │   └── ContentView.swift           # Root coordinator (Onboarding vs MainTabView)
│   ├── Models/
│   │   ├── QuestModels.swift           # MainQuest, SubQuest, DailyQuest, SideQuest, QuestStatus
│   │   ├── CharacterModels.swift       # AvatarProfile, CosmeticItem, Equipment, EvolutionStage
│   │   ├── SkillModels.swift           # SkillTree, SkillNode, SkillCategory, Mastery
│   │   ├── FutureSelfModels.swift      # FutureSelfGoal, FutureSelfStage, Milestones
│   │   ├── WorldModels.swift           # WorldState, WorldRegion, WorldStructure
│   │   ├── PlanningModels.swift        # DailyPlan, ScheduleItem, FocusSession, ReplanProposal
│   │   ├── XPModels.swift              # XPTransaction, XPRewardCategory, LevelProgression
│   │   └── AchievementModels.swift     # Achievement, EvidenceAttachment, AchievementArchive
│   ├── Services/
│   │   ├── Persistence/
│   │   │   ├── AppDataStore.swift      # Thread-safe persistent storage with atomic writes
│   │   │   └── StorageKeys.swift       # Stable file paths and user default keys
│   │   ├── Engines/
│   │   │   ├── QuestEngine.swift       # Quest state machine, prerequisites, DAG validation
│   │   │   ├── PlanningEngine.swift    # Deterministic daily scheduler, replanner, timeline generator
│   │   │   ├── XPEngine.swift          # 3-tier rewards, anti-cheat limits, level curves
│   │   │   ├── SkillEngine.swift       # Skill graph traversal, dependency checks, XP allocation
│   │   │   ├── FutureSelfEngine.swift  # Milestone verification, evolution triggers
│   │   │   └── WorldEngine.swift       # Region progression, structure unlocks, world lighting
│   │   ├── AI/
│   │   │   └── PlanningAIService.swift # AI assistant protocol with deterministic fallback
│   │   └── Utilities/
│   │       ├── HapticService.swift     # Sensory feedback for iOS
│   │       └── SoundService.swift      # Synthesized/system audio cues
│   ├── DesignSystem/
│   │   ├── Theme.swift                 # Cinematic palette (Midnight, Cyan, Gold, Violet)
│   │   └── Components/                 # GlassCard, GlowingButton, XPBadge, StatRing, Particles
│   └── Views/
│       ├── Navigation/
│       │   └── MainTabView.swift       # 5 Primary Destinations (World, Quests, Plan, Skills, Character)
│       ├── World/                      # Interactive Canvas world, regions, structures, avatar
│       ├── Quests/                     # Quest tree, prerequisites, side quests, quest editor
│       ├── DailyPlan/                  # Timeline, Checklist, Focus Timer, Replan banner, Recap
│       ├── Skills/                     # Skill tree interactive graph, mastery detail sheets
│       ├── Character/                  # Avatar visualizer, customization, cosmetics inventory
│       ├── Onboarding/                 # Guided setup with presets (e.g. Career 80/10/10)
│       └── Settings/                   # Export/import, sound/haptic toggles, privacy & wipe
└── ASCENDTests/                        # Comprehensive unit tests for all engines and models
```

---

## 4. Key Design Patterns & Invariants

1. **Single Source of Truth:**
   - `AppDataStore` holds the application's root state (`AppState`), marked `@Observable`.
   - Modifying actions are routed through dedicated domain engines (`QuestEngine`, `XPEngine`, `PlanningEngine`, etc.), ensuring validation, invariant preservation, and auditable transaction logging.

2. **Single Active Main Quest Invariant:**
   - Exactly one `MainQuest` can be active (`status == .active`) at any given time.
   - Pausing a Main Quest transitions its status to `.paused` without mutating any earned XP, milestones, or history.
   - Another Main Quest can then be activated or created.
   - When completed, a Main Quest is `.archived`. Archived quests and their historical milestones are permanent.

3. **Directed Acyclic Graph (DAG) for Prerequisites:**
   - `QuestEngine` validates all SubQuest dependencies using cycle-detection (Depth-First Search graph traversal).
   - If a proposed prerequisite creates a loop, the engine rejects it and preserves the previous valid state.

4. **Multi-tier XP Separation:**
   - Effort XP (continuous, capped per day, logs focused time).
   - Achievement XP (discrete milestones and problem solving, strictly deduplicated by key).
   - Completion Bonus XP (one-off reward when a quest's criteria are satisfied).
   - Character level uses cumulative XP, but Future-Self evolution requires milestone proof. XP alone cannot trigger major transformations.

5. **Non-destructive Replanning:**
   - When users fall behind their scheduled timeline, `PlanningEngine` produces a *proposed* revised schedule.
   - The user must explicitly approve or edit the revision before it replaces the active schedule. Unfinished work is carried forward without erasing past effort.

6. **Offline Autonomy:**
   - All engines are self-contained and execute locally without requiring network connectivity.
   - Optional AI integration conforms to `AIPlanningServiceProtocol`, gracefully falling back to deterministic algorithms when no API key or network is present.

# ASCEND — Game Rules & Economy Specification

## 1. Core Philosophical Rule

> *"Your avatar represents who you are becoming. Your world represents the life you are building."*

Progression is driven by genuine, verifiable, or high-intent real-world actions. The game is anti-guilt: missing a day never strips away earned XP, never resets hard-earned levels, and never punishes the player with shame-based streak breaks.

---

## 2. Quest Hierarchy Rules

### Main Quests
- **Exclusivity:** Exactly **one** Main Quest can be `.active` at any time.
- **Switching & Pausing:** A player may pause the active Main Quest at any time. Pausing preserves 100% of accumulated progress, XP transactions, milestones, and unlocked skills.
- **Archiving:** When all primary completion conditions of a Main Quest are met and confirmed, the player triggers a major celebration. The Main Quest transitions to `.archived` in the Hall of Journeys. The player can then select or create their next life journey (e.g. "Master a New Hobby in 30 Days").

### Sub Quests
- Contribute directly to the active Main Quest.
- Can have 0, 1, or multiple **prerequisites** (must be completed before this quest can be started).
- Circular prerequisites (e.g., A requires B, B requires A) are strictly prevented via cycle detection.
- Supported completion condition types:
  1. `allTasksCompleted`: Every linked daily quest is completed.
  2. `numericalTarget`: e.g. "Solve 100 DSA Problems", "Log 20 Workouts" (progress / target).
  3. `milestoneReached`: e.g. "Deploy Live Application on Vercel/AppStore".
  4. `deliverableCompleted`: User attaches evidence or signs off on final product.
  5. `manualConfirmation`: Player marks achievement verified.

### Daily Quests
- Actionable units of daily work (15 to 120 minutes typically).
- Can be linked to Sub Quests, Side Quests, or standalone routines.
- Statuses: `.notStarted`, `.inProgress`, `.paused`, `.completed`, `.blocked`, `.skipped`.
- Rescheduling a quest carries forward recorded partial effort without wiping historical logs.

### Side Quests
- **Simple Habits:** Recurring daily or weekly routines (e.g., Skincare, Hydration, Morning Walk).
- **Secondary Quest Chains:** Independent parallel journeys with their own skill branches and milestones.

---

## 3. XP Engine & Economic Balance

### Three XP Reward Tiers:
1. **Effort XP:**
   - Awarded for focused time spent (1 XP per minute of focused work via Focus Timer or manual logging).
   - **Daily Effort Cap:** Configured to a healthy default (e.g., 360 XP/day = 6 hours of high-focus work).
   - Effort continues to be logged after the XP cap is reached for personal metrics, but additional XP is halted to prevent burnout farming.
2. **Achievement XP:**
   - Awarded for discrete accomplishments (e.g., solving a difficult problem: 30-50 XP, finishing a project module: 75-100 XP).
   - Deduplicated using unique `achievementKey`. Re-logging the same achievement does not multiply XP.
3. **Completion Bonus XP:**
   - Awarded upon full completion of a Sub Quest (150 - 500 XP) or Main Quest (2,000 - 5,000 XP).
   - Granted once per unique quest identifier.

### Anti-Exploit Rules:
- Toggling a quest between `.completed` and `.inProgress` **does not** re-grant completion XP.
- Arbitrary micro-splitting of tasks does not yield exponential bonuses.
- No penalty for missed days or rescheduling.

### Character Leveling Formula:
Cumulative XP required for level $L$:
$$\text{XP}(L) = 100 \times (L - 1)^{1.6}$$
Level formula derived from total cumulative XP:
$$\text{Level} = \lfloor ( \text{TotalXP} / 100 )^{1 / 1.6} \rfloor + 1$$
This creates an engaging early progression (Level 1 $\to$ 2 requires 100 XP, Level 2 $\to$ 3 requires ~200 XP) while maintaining long-term prestige for master levels (50+).

---

## 4. Character & Future-Self Evolution

### Evolution Types:
1. **Small Evolution (Level-based):**
   - Unlocked every 5 levels.
   - Rewards cosmetic titles, visual auras, new apparel, accessories, and subtle visual effects.
2. **Major Evolution (Milestone-based):**
   - Distinct from XP! XP alone cannot unlock a Future-Self stage.
   - Requires verified Sub Quest milestones (e.g. "Portfolio Deployed", "50 DSA problems solved", "First Mock Interview").
   - Stages:
     - Stage 1: **The Initiate** (Beginning)
     - Stage 2: **The Builder** (Foundations laid, project built)
     - Stage 3: **The Contender** (Interview ready, advanced knowledge)
     - Stage 4: **The Breakthrough Self** (Fully realized career transition)

---

## 5. World Evolution Rules

Three foundational regions evolve in sync with real player accomplishments:
1. **Career Kingdom (The Grand Citadel):**
   - Largest floating island.
   - Buildings upgrade (from ruins $\to$ stone workshop $\to$ glowing glass laboratory $\to$ celestial tech citadel) as career sub-quests complete.
2. **Fitness Grounds (The Colosseum of Vitality):**
   - Upgrades training rings, lighting torches, and energy conduits with fitness side quest completions.
3. **Self-Care Sanctuary (The Celestial Grove):**
   - Blooms with bioluminescent flora, crystal springs, and tranquil mist as wellness routines are maintained.
- Completing daily quests powers **Leyline Bridges** connecting the islands.

---

## 6. Smart Daily Planning Rules

- **Priority Allocation:** Weights (e.g. 80% Career / 10% Fitness / 10% Self-care) dictate task recommendation density.
- **Explainability:** Every scheduled block presents a clear rationale (e.g. *"High priority career milestone with imminent target deadline"*).
- **Graceful Replanning:** If tasks run over or start late, the engine suggests a revised schedule. It never overwrites without player approval.

#!/bin/bash
set -e

echo "Compiling and running ASCEND Core Test Suite..."
mkdir -p /tmp/ModuleCache /tmp/ascend_build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc \
    -module-cache-path /tmp/ModuleCache \
    -parse-as-library \
    ASCEND/Models/QuestModels.swift \
    ASCEND/Models/WeeklyPlanModels.swift \
    ASCEND/Services/Engines/WeeklyPlanEngine.swift \
    ASCEND/Models/ChallengeModels.swift \
    ASCEND/Services/Engines/ChallengeEngine.swift \
    ASCEND/Models/CharacterModels.swift \
    ASCEND/Models/SkillModels.swift \
    ASCEND/Models/FutureSelfModels.swift \
    ASCEND/Models/WorldModels.swift \
    ASCEND/Models/PlanningModels.swift \
    ASCEND/Models/XPModels.swift \
    ASCEND/Models/AchievementModels.swift \
    ASCEND/Services/Persistence/AppDataStore.swift \
    ASCEND/Services/Engines/QuestEngine.swift \
    ASCEND/Services/Engines/XPEngine.swift \
    ASCEND/Services/Engines/PlanningEngine.swift \
    ASCEND/Services/Engines/FocusSessionEngine.swift \
    ASCEND/Services/Engines/SkillEngine.swift \
    ASCEND/Services/Engines/FutureSelfEngine.swift \
    ASCEND/Services/Engines/WorldEngine.swift \
    ASCEND/Services/AI/PlanningAIService.swift \
    ASCEND/Services/AI/OnlinePlanningService.swift \
    ASCEND/Services/Cloud/CloudSyncService.swift \
    ASCENDTests/QuestEngineTests.swift \
    ASCENDTests/ChallengeEngineTests.swift \
    ASCENDTests/WeeklyPlanEngineTests.swift \
    ASCENDTests/XPEngineTests.swift \
    ASCENDTests/PlanningEngineTests.swift \
    ASCENDTests/SkillEngineTests.swift \
    ASCENDTests/FutureSelfEngineTests.swift \
    ASCENDTests/PersistenceTests.swift \
    ASCENDTests/FocusSessionEngineTests.swift \
    ASCENDTests/OnlineServicesTests.swift \
    ASCENDTests/TestRunnerMain.swift \
    -o /tmp/ascend_build/AscendUnitTests

/tmp/ascend_build/AscendUnitTests

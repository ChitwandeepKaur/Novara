# 75-day challenge source mapping

Source: [75-Day Challenge Tracker](https://docs.google.com/spreadsheets/d/1BVxgXNfHQ8Df8WbR9VStG6ucLBfQ-qrhFWeElWWlA-o/edit).
Inspected all four tabs, daily rows 5–79, weekly rows 5–15, dashboard formulas through row 45, and trend helper formulas/chart titles. The source's manual daily and weekly entries were blank. This implementation imports its structure, targets, statistics, and default start date; it does not establish live Google Sheets synchronization.

## Daily Tracker → Daily log and Plan

| Source field | App behavior |
| --- | --- |
| Day #, Date, Week # | Calendar-derived from start date; 75 days and 11 weeks (last week has 5 days) |
| Learning Hours | Numeric log, target >= 8 |
| Steps | Numeric log, target >= 7,000 |
| 30+ Min Movement | Not logged / Yes / No |
| Calories (Optional) | Optional numeric log |
| Nutrition Status | Not logged / On Track / Mostly On Track / Off Track |
| Treat Meal | Not logged / Yes / No |
| Water (L) | Numeric log, target >= 2 |
| Sleep (Hours) | Numeric log, target >= 7 |
| Overall Day Rating | Not rated / Green / Yellow / Red; user-selected |
| Daily Goals Completed | Sum of the five threshold checks above; blank until any core goal has a value |
| Completion % | Goals completed / 5 |
| Notes | Free-text reflection |

Plan and Challenge show the same persisted daily entry. Logging totals changes checkmarks in both places. Recorded Career focus sessions may be explicitly reused as learning hours and 30+ Fitness minutes as movement. This does not duplicate tasks or focused-minute XP, or put sleep/hydration into the focus timetable as work blocks.

## Dashboard

- App default start date: November 9, 2026; selectable before activation. The source sheet originally started October 28, 2026. Existing saved challenge dates are preserved.
- Current day: calendar days since start + 1, clamped 0–75 in the dashboard.
- Days completed: days with a Green/Yellow/Red rating, independently of threshold completion.
- Days remaining: 75 minus rated days; challenge completion progress is rated days / 75.
- Averages: learning, steps, water, sleep; calories also shown for weekly parity.
- Nutrition consistency: (On Track + Mostly On Track) / nonblank nutrition entries.
- Movement completion: Yes / nonblank movement entries.
- Overall goal completion: mean of nonblank daily completion percentages.
- Total treat meals and counts of Green, Yellow, Red days.
- Current and longest streaks for learning, steps, movement, water, sleep, and Green ratings.
- Streak blanks break the next day's chain; current shows the latest explicitly logged result, matching source helper formulas.
- Highest learning hours and step count; longest learning, step, movement, and Green-day streaks.
- Last 7 versus prior 7 calendar-day averages for learning, steps, water, sleep; available from day 14 when each window has data.
- Calendar milestones: days 7, 14, 21, 30, 45, 60, 75.

## Weekly Check-In

- Weight (kg); waist, chest, arm, leg (inches).
- Weekly average steps, learning, calories, water, sleep; movement days; treat meals; each rating count; mean daily goal completion.
- Gym progress / personal bests, weekly reflection, what went well, what needs improvement.

## Progress & Trends

- Four daily-versus-7-day-average charts with target lines: learning, steps, water, sleep.
- Daily rating breakdown and challenge completion charts.
- Weekly body measurement trend, with a selector to keep kg and inches on separate scales. Includes leg measurements as well as the source chart's weight, waist, chest, arm.
- Daily goal completion chart additionally exposes the source's completion series.

All averages exclude blanks and retain explicit zero values. Days off never reset the challenge. Entries cannot be logged ahead of the selected challenge calendar. Challenge state is part of JSON save/export/import; older backups without it remain readable.

## Character rewards

- 10 achievement XP once per daily core goal; 15 bonus once for all five; 10 once for a Green, Yellow, or Red daily rating.
- 50 XP once per week with a nonblank gym-progress note or reflection. Measurements alone do not earn XP.
- Milestone bonuses count uniquely rated days, not elapsed calendar days: 100 at 7, 14, 21, 30, 45, 60; 500 at 75.
- All rewards use the existing XP transaction engine, contributing to character level, current XP, and level-based cosmetic unlocks. They do not re-award learning or movement minutes.
- Stable reward keys survive saves and JSON backups. Repeated saves, edits, reopening, and corrections cannot award the same reward again or subtract earned XP.
- Existing qualifying logs receive their previously unawarded bonuses when the challenge is opened or a log is saved. Future logs do not earn rewards early.

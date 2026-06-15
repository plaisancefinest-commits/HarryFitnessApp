# HarryFitnessApp

Flutter workout tracking app. Mobile-first, iOS + Android.

## Exemplars
Before debugging non-trivial bugs or making architecture decisions, check the exemplar index for prior art:
- Index: `C:\Users\cchar\Harry's WorkShop\Atlas\AI\Claude\Exemplars.md`
- Relevant exemplars for this codebase:
  - **Canonical Unit Storage** — weight stored in lbs always, convert at display/input boundary only
  - **Workout Save Resume** — auto-save full state on every action, resume with graceful timer degradation
- Load the matching exemplar file before writing code.

## Key Architecture Decisions
- Weights are **canonical lbs** in `_SetDraft.weight` — never store display units
- `getDisplayWeight()` converts for UI, `updateDraftWeight()` converts back on input
- Save/resume serializes full state as JSON blob on every state change, not on a timer
- Rest timer expired while app closed → resume as `active`, not stale countdown

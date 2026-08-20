# Challenge Spend Forecasting

## Problem
Predict how much a brand will spend on creator challenges in a given week, so the team can pace budgets, catch overspend early, and design better challenges. The current dashboard estimate is a rough formula and misses in ways that matter for budgeting.

## Target
Predict total challenge spend per brand per calendar week.

Total spend = locked-in completed-but-unpaid spend + expected spend from creators still mid-challenge.

## Method (how we get the total)
Bottom-up. We predict each active creator's expected payout, then sum those predictions to the brand-week total. Expected payout per creator is built in two stages, because the data is zero-inflated (most creators earn $0, some earn a real amount):
1. Classifier: probability the creator earns anything at all.
2. Regressor: predicted amount, trained only on creators who did earn.
3. Expected payout = probability of earning * predicted amount.

We grade the model on the aggregate (the summed total), not on any single creator, because the budget decision is made at the total level.

## Metrics
- **Total-spend error** (primary): for a held-out week, how close is the summed prediction to the real total spend. Beat the dashboard baseline by >= 25% relative.
- **Bias**: keep the summed prediction within +/- 5% of actual, so we don't systematically over- or under-forecast the budget.
- **MAE** (operational, per-creator): absolute dollar error at the row level, for diagnostics.
- Evaluation uses a **forward time split** (train on earlier weeks, predict a later week), never a random split, to avoid leaking the future into the past.

## Baseline (what we're beating)
The dashboard formula: `active_in_challenge * completion_rate * avg_payout`

Two known defects:
1. `avg_payout` is depressed by CPM challenges because it's computed on base-before-bonus.
2. A single pooled `completion_rate` is used across all challenges instead of per-challenge rates.

## Why it matters
- Budget pacing across the week.
- Catch overspend early instead of after the fact.
- Inform challenge design (payout structure, duration, caps).

## Scope
- Start with **Sweetgreen + Buoy** (clean new-product data).
- Out of scope for v1: causal claims, intra-day forecasting.

## Known data risks
- `challenge_enrollments` payout vs `transactions` challenge-tagged rows must be reconciled, and one declared canonical.
- Null `message_type` corrupts the "still in challenge" active-creator count.
- Historical pre-migration quirks in older data.
- Small sample of positive earners (~200) means per-creator dollar estimates are wobbly. The aggregate is more stable than any single prediction.

## Candidate features
- Challenge structure: fixed vs CPM, base, CPM cap, duration.
- Creator: follower count (via `instagram_user_info`, `tiktok_user_info`), post history, prior completion rate.
- Brand desirability: Sweetgreen > Buoy.
- `affiliate_metrics`.

## Definition of done (v1)
On a forward time split, beat the dashboard formula's total-spend error by >= 25% relative, with aggregate bias within +/- 5%, on Sweetgreen + Buoy.
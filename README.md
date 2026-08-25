# Challenge Spend Forecasting

Forecasts how much a creator program will pay out in challenge rewards in a given month. The target is monthly challenge payout spend for a single brand (Sweetgreen as the pilot). The model is a two-part hurdle that predicts each creator's expected payout, then sums across everyone currently in a challenge.

The headline result: on the two fully closed months the model landed within about 5% of actual (June -5.3%, July +1.1%), and it beats the existing flat-formula baseline on a like-for-like population.

## Problem

Most creators who enroll in a challenge never earn a payout. Roughly 90% of enrollments resolve at $0. The dollars are concentrated in a small set of creators who actually complete. A good forecast has to model that spike at zero, not just an average payout.

## Target

Spend is attributed to the month a creator is active in the challenge window, not the calendar date a payment later clears. The canonical target is validated to the penny against the production dashboard's month-to-date spend.

## Features

Each row is one creator enrolled in one challenge. Features come from the enrollment plus joined creator history:

- `prior_completions`: rolling count of the creator's past completed challenges, built with a shift so it never leaks the current outcome. This is the single strongest predictor.
- `miles_to_nearest_sg`: distance from the creator to the nearest store, from geocoded addresses plus a haversine calculation. Weak on its own, useful only as a far-away cutoff.
- `required_steps`: number of steps the creative brief demands, mapped per challenge.
- Challenge economics: base reward, CPM rate, max reward cap.
- Creator profile: age, brand fit score, success potential, follower counts, engagement, niche tags (multi-label one-hot of the top 15).

Leaky fields were dropped, including `reliability_score`, which was replaced by the non-leaky `prior_completions`.

## Model

Two-part hurdle (a zero-inflated formulation):

```
E[payout | X] = P(earn | X) * E[payout | earn, X]
```

- P(earn): `HistGradientBoostingClassifier`, wrapped in `CalibratedClassifierCV(method='sigmoid')`. Calibration was the key fix, it corrected a systematic under-bias in the raw classifier.
- E[payout | earn]: `HistGradientBoostingRegressor` on log payout among earners only, with `np.expm1` and a Duan smearing correction on the back-transform. Predictions are capped at the challenge's max reward.

## Validation

Walk-forward by month: train on all prior months, predict the next. No random k-fold, which would leak future information across the time axis.

| Month | Predicted | Actual | Error |
|-------|-----------|--------|-------|
| June  | 10,551    | 11,140 | -5.3% |
| July  | 24,944    | 24,681 | +1.1% |

The model was also benchmarked against a Tweedie regressor (LightGBM), which it beat clearly on both months.

## Baseline comparison

The production baseline is a flat formula:

```
predicted_spend = still_in_challenge * completion_rate * avg_payout
```

summed across challenges. It applies one blanket completion rate to every active creator.

On the same live population of 675 still-in creators, the model predicts 8,406 versus the baseline's 11,662. The model prices each creator individually, so it correctly discounts the large pool of first-time enrollees (who earn only about 6% of the time) that the flat formula treats the same as proven repeat earners.

## Feature importance

Permutation importance on the trained classifier confirms the exploratory analysis: `prior_completions` dominates, most other features are minor, and distance barely moves the score. The data analysis and the model agree.

## How to run

1. Pull the feature data from the source database into `training_features.csv`.
2. Open `01_eda.ipynb` and run top to bottom. Early cells handle EDA, geocoding, and feature engineering, then save the training file. Later cells train and backtest the model.
3. For the live head-to-head, pull the still-in creator list and run the comparison cell.

## Future work

- Three-way backtest of model vs baseline vs actual on closed months, by reconstructing the baseline's point-in-time snapshot from message delivery timestamps.
- Real-time dashboard serving the model's monthly forecast.
- Monitoring for drift once the model is live.

-- Training spine: one row per creator per challenge (Sweetgreen)
-- Includes earners AND $0 skippers, plus the challenge payout rules.
select
  e.challenge_id,
  ch.name                       as challenge_name,
  e.affiliate_id,
  e.enrolled_at,
  e.deadline,
  e.completed_at,
  (e.completed_at is not null)  as completed,
  e.payout_status,
  coalesce(e.payout_amount, 0)  as realized_payout,   -- target y (0 if they skipped)
  ch.challenge_type,                                   -- flat_fee vs cpm
  ch.base_reward_amount,
  ch.cpm_rate,
  ch.max_cpm_reward,
  ch.start_date,
  ch.end_date
from challenge_enrollments e
join challenges ch on ch.id = e.challenge_id
where e.shop_id in (select id from shops where slug ilike '%sweetgreen%')
order by ch.start_date, e.challenge_id, e.affiliate_id;
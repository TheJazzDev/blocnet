# Blocnet Investor Financial Model Spec

Last updated: March 8, 2026

This file defines the exact spreadsheet structure for a Google Sheets investor model.
Use these tabs and only these tabs.

## General Rules

1. Currency is USD
2. All assumptions live in the `Assumptions` tab first
3. No hard-coded duplicated values across tabs unless explicitly noted
4. Unknown prices must be marked `assumption to verify`
5. Funding scenarios are exactly:
- `$1,000`
- `$5,000`
- `$10,000`
- `$20,000`
6. Founder is not modeled like a standard salaried hire
7. Optional support is modeled only as part-time contractor or community support in higher funding scenarios
8. Token investor upside is provisional and non-final

## Tab 1: Assumptions

Purpose:
- central source of truth for all variable inputs

Columns:

1. `Category`
2. `Item`
3. `Value`
4. `Unit`
5. `Status`
6. `Notes`

Required rows:

1. planning start month
2. planning end month
3. current Railway monthly cost = `5`
4. first Railway scale step monthly cost = `20`
5. Supabase current monthly cost = `0`
6. Supabase paid tier cost = `assumption to verify`
7. Resend current monthly cost = `0`
8. Resend paid tier cost = `assumption to verify`
9. Firebase cost model = `usage based`
10. GitHub organization cost = `assumption to verify`
11. Vercel seat cost = `assumption to verify`
12. domain annual cost = `17`
13. custom email annual cost = `45`
14. Play Console org fee = `25`
15. Apple Developer annual fee = `100`
16. Apple org-specific extra cost = `assumption to verify`
17. tipping take rate = `assumption to verify`
18. withdrawal fee take = `assumption to verify`
19. featured project monthly demand assumption = `assumption to verify`
20. premium placement monthly demand assumption = `assumption to verify`
21. hunter onboarding fee = `assumption to verify`
22. investor token allocation assumption low = `draft`
23. investor token allocation assumption base = `draft`
24. investor token allocation assumption high = `draft`

Status values allowed:

1. `confirmed`
2. `founder assumption`
3. `assumption to verify`
4. `draft`

## Tab 2: Current Costs

Purpose:
- show the current monthly operating baseline before new funding

Columns:

1. `Cost Type`
2. `Vendor / Item`
3. `Current Monthly Cost`
4. `Current Status`
5. `Scale Trigger`
6. `Notes`

Required rows:

1. Railway backend hosting
2. Supabase database
3. Resend email
4. Firebase
5. GitHub organization
6. Vercel seat

Bottom rows:

1. `Total Current Monthly Baseline`
2. `Total Confirmed Monthly Baseline`
3. `Total Monthly Costs Pending Verification`

## Tab 3: Recurring Costs

Purpose:
- show recurring monthly costs at low/base/high operating scale

Columns:

1. `Category`
2. `Item`
3. `Low`
4. `Base`
5. `High`
6. `Status`
7. `Notes`

Required rows:

1. backend hosting
2. database
3. email delivery
4. messaging / notifications
5. source control / org tooling
6. deployment / frontend ops
7. contractor support
8. community support

Bottom rows:

1. `Total Low Monthly`
2. `Total Base Monthly`
3. `Total High Monthly`

Rules:

1. If a cost is unknown, leave value blank and mark `assumption to verify`
2. Do not invent vendor pricing
3. Contractor and community support should be `0` in low scenario unless explicitly used

## Tab 4: Annual and One-Time Costs

Purpose:
- separate non-monthly spend from operating burn

Columns:

1. `Cost Type`
2. `Item`
3. `Amount`
4. `Frequency`
5. `Status`
6. `Notes`

Required rows:

1. domain
2. custom email
3. Apple Developer annual fee
4. Play Console organization fee
5. Apple organization-specific setup fee

Frequency values:

1. `annual`
2. `one-time`

Bottom rows:

1. `Total Annual Costs`
2. `Total One-Time Costs`
3. `Total Annualized Non-Monthly Costs`

## Tab 5: Funding Scenarios

Purpose:
- show exact use of funds for the four funding bands

Columns:

1. `Spend Category`
2. `$1,000`
3. `$5,000`
4. `$10,000`
5. `$20,000`
6. `Notes`

Required rows:

1. app/account setup
2. annual operating costs
3. infrastructure reserve
4. launch hardening / release ops
5. marketing / awareness
6. contractor support
7. community support
8. token / liquidity execution reserve
9. contingency

Exact values to enter:

| Spend Category | $1,000 | $5,000 | $10,000 | $20,000 |
| --- | ---: | ---: | ---: | ---: |
| app/account setup | 125 | 100 | 100 | 100 |
| annual operating costs | 162 | 150 | 150 | 150 |
| infrastructure reserve | 300 | 1000 | 1500 | 3000 |
| launch hardening / release ops | 0 | 1000 | 2000 | 3000 |
| marketing / awareness | 250 | 2000 | 4000 | 8000 |
| contractor support | 0 | 0 | 1000 | 2000 |
| community support | 0 | 0 | 500 | 1000 |
| token / liquidity execution reserve | 0 | 0 | 0 | 2000 |
| contingency | 163 | 750 | 750 | 750 |

Bottom rows:

1. `Total`
2. `Difference vs Scenario Target`

Validation:

1. each total must equal the scenario label exactly
2. difference row must be `0`

## Tab 6: 6-Month Plan

Purpose:
- monthly execution plan tied to spend and outcomes

Columns:

1. `Month`
2. `Primary Objective`
3. `Key Milestone`
4. `Expected Spend`
5. `Funding Dependency`
6. `Notes`

Required rows:

1. Month 1 - accounts, planning, ops setup
2. Month 2 - app store readiness
3. Month 3 - launch hardening
4. Month 4 - token and monetization prep
5. Month 5 - growth and partner activation
6. Month 6 - first monetization and operating review

Funding Dependency values:

1. `base ops`
2. `$1k+`
3. `$5k+`
4. `$10k+`
5. `$20k+`

## Tab 7: 12-Month Plan

Purpose:
- quarter-based operating summary

Columns:

1. `Quarter`
2. `Primary Goal`
3. `Key Outputs`
4. `Major Spend Areas`
5. `Expected Operating Shift`

Required rows:

1. Q2 2026
2. Q3 2026
3. Q4 2026
4. Q1 2027

## Tab 8: Revenue Model

Purpose:
- tie monetization lines to operational drivers

Columns:

1. `Revenue Stream`
2. `Description`
3. `Activation Timing`
4. `Leading Metric`
5. `Low Case`
6. `Base Case`
7. `High Case`
8. `Status`
9. `Notes`

Required rows:

1. tipping take rate
2. withdrawal / transaction fees
3. paid project featuring
4. premium project placement
5. hunter onboarding fee
6. premium intelligence / subscription

Rules:

1. Do not invent hard revenue figures unless founder provides them
2. If numbers are unknown, leave values blank and describe the metric logic
3. Status should usually be `future`, `draft`, or `assumption to verify`

## Tab 9: Investor Upside Model

Purpose:
- give an illustrative upside framework without promise language

Columns:

1. `Upside Path`
2. `Mechanism`
3. `Current Status`
4. `Illustrative Assumption`
5. `Risk Note`
6. `Notes`

Required rows:

1. token upside
2. business revenue upside

Rules:

1. token row must explicitly say `draft tokenomics`
2. no guaranteed return language
3. no IRR, payback, or fixed-multiple promise unless legal and financial counsel approve later

## Tab 10: Runway Summary

Purpose:
- show what each funding level buys in time and capability

Columns:

1. `Scenario`
2. `Primary Use`
3. `Approximate Runway Impact`
4. `What It Unlocks`
5. `What Remains Unfunded`

Required rows:

1. $1,000
2. $5,000
3. $10,000
4. $20,000

Approximate Runway Impact guidance:

1. describe in words if exact monthly burn remains partially unknown
2. use phrases like:
- `unblocks core setup`
- `supports lean launch prep`
- `supports launch plus first growth experiments`
- `supports launch, growth testing, and part-time support`

## Validation Checklist

Before considering the model complete:

1. every cost appears in exactly one of:
- Current Costs
- Recurring Costs
- Annual and One-Time Costs
2. scenario totals are exact
3. unknown vendor pricing is not invented
4. revenue rows are tied to real product behaviors
5. investor upside language is clearly provisional
6. founder salary is not modeled as a standard payroll line

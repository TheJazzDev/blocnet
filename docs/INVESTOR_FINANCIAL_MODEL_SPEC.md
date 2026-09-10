# Blocnet Investor Financial Model Spec

Last updated: March 11, 2026

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

## Google Sheets Formula Quick Reference

**Named Ranges (recommended):**
- Create named ranges for frequently referenced cells (e.g., `Assumptions!B3` → name it `PlanningEndMonth`)
- Access via: Insert → Named ranges in Google Sheets

**Cross-tab references:**
- Format: `'Tab Name'!CellReference`
- Example: `='Assumptions'!B5` or `='Annual and One-Time Costs'!B8`

**Common formulas used in this model:**
- `SUM()` - Add up ranges
- `SUMIF(range, criteria, sum_range)` - Conditional sum
- `=A1/12` - Convert annual to monthly
- `=IF(condition, value_if_true, value_if_false)` - Conditional logic

**Cell references in formulas:**
- Absolute reference: `$A$1` (locks row and column)
- Mixed reference: `$A1` (locks column) or `A$1` (locks row)
- Relative reference: `A1` (adjusts when copied)

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

Required rows (with categories):

**Timeline**
1. planning start month = `March 2026`
2. planning end month = `February 2027`

**Infrastructure**
3. current Railway monthly cost = `5`
4. first Railway scale step monthly cost = `20`
5. Supabase current monthly cost = `0`
6. Supabase paid tier cost = `assumption to verify`
7. Resend current monthly cost = `0`
8. Resend paid tier cost = `assumption to verify`
9. Firebase cost model = `usage based`
10. estimated Firebase monthly at scale = `assumption to verify`

**Development Tools**
11. GitHub organization cost = `assumption to verify`
12. Vercel seat cost = `assumption to verify`

**Domains & Services**
13. domain annual cost = `17` (includes privacy protection)
14. custom email annual cost = `45`

**App Store Fees**
15. Play Console org fee = `25`
16. Apple Developer annual fee = `100`
17. Apple Enterprise Program fee (if needed) = `assumption to verify`

**Revenue Model**
18. tipping take rate = `assumption to verify`
19. withdrawal fee take = `assumption to verify`
20. featured project monthly demand assumption = `assumption to verify`
21. premium placement monthly demand assumption = `assumption to verify`
22. hunter onboarding fee = `assumption to verify`

**Token & Investment**
23. investor token allocation assumption low = `draft`
24. investor token allocation assumption base = `draft`
25. investor token allocation assumption high = `draft`

**Team & Support**
26. contractor hourly rate = `assumption to verify`
27. estimated contractor hours per month (base) = `assumption to verify`
28. community support monthly budget (high scenario) = `assumption to verify`

Status values allowed:

1. `confirmed`
2. `founder assumption`
3. `assumption to verify`
4. `draft`

## Tab 2: Current Costs

Purpose:
- show the current monthly operating baseline **before new funding** (as of March 2026)
- this is a snapshot of current state, not a projection
- use Tab 3 for post-funding projections

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

1. `Total Current Monthly Baseline` - Formula: `=SUM(C2:C7)` (sum all current monthly costs)
2. `Total Confirmed Monthly Baseline` - Formula: `=SUMIF(D2:D7,"confirmed",C2:C7)` (sum only confirmed costs)
3. `Total Monthly Costs Pending Verification` - Formula: `=SUMIF(D2:D7,"assumption to verify",C2:C7)` (sum only unverified costs)

**Note**: Mark status as "confirmed" if pricing is verified from vendor, otherwise "assumption to verify"

## Tab 3: Recurring Costs

Purpose:
- show recurring monthly costs at low/base/high operating scale **after funding**
- these are forward-looking projections based on growth
- contrast with Tab 2 which shows current pre-funding baseline

Columns:

1. `Category`
2. `Item`
3. `Low`
4. `Base`
5. `High`
6. `Status`
7. `Notes`

Required rows:

1. backend hosting (Railway)
2. database (Supabase)
3. email delivery (Resend)
4. messaging / notifications (Firebase)
5. source control / org tooling (GitHub)
6. deployment / frontend ops (Vercel)
7. contractor support
8. community support

Bottom rows:

1. `Annualized Annual Costs (monthly equivalent)` - Formula: `=('Annual and One-Time Costs'!B8)/12` (converts annual costs to monthly burn)
2. `Total Low Monthly` - Formula: `=SUM(C2:C8)+C10` (includes infrastructure + annualized annual costs)
3. `Total Base Monthly` - Formula: `=SUM(D2:D8)+D10` (includes infrastructure + annualized annual costs)
4. `Total High Monthly` - Formula: `=SUM(E2:E8)+E10` (includes infrastructure + annualized annual costs)

Rules:

1. If a cost is unknown, leave value blank and mark `assumption to verify`
2. Do not invent vendor pricing
3. Contractor and community support should be `0` in low scenario unless explicitly used
4. **Infrastructure reserve in Tab 5** should cover 3-12 months of these recurring costs depending on scenario

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

**Expected Spend calculation guidance:**
- For Month 1-2: Primarily one-time costs (app/account setup from Tab 5 + monthly recurring from Tab 3)
- For Month 3-6: Primarily monthly recurring costs (Tab 3) + allocated portions of:
  - Launch hardening (Tab 5, row 4) spread over months 3-4
  - Marketing (Tab 5, row 5) spread over months 4-6
  - Contractor/community support (Tab 5, rows 6-7) spread as needed
- Formula suggestion: Reference specific Tab 5 allocations divided by relevant months + Tab 3 monthly burn
- Example for Month 3: `=(Tab3!D11) + (Tab5!D4)/2` (monthly burn + half of launch hardening budget)

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
3. `Activation Timing` (format: "Q2 2026" or "Month 4" or "TBD")
4. `Leading Metric` (what drives this revenue: e.g., "active projects", "monthly transactions")
5. `Low Case` (monthly revenue estimate)
6. `Base Case` (monthly revenue estimate)
7. `High Case` (monthly revenue estimate)
8. `Status`
9. `Notes`

Required rows:

1. tipping take rate
2. withdrawal / transaction fees
3. paid project featuring
4. premium project placement
5. hunter onboarding fee
6. premium intelligence / subscription

Bottom rows:

1. `Total Low Monthly Revenue` - Formula: `=SUM(E2:E7)`
2. `Total Base Monthly Revenue` - Formula: `=SUM(F2:F7)`
3. `Total High Monthly Revenue` - Formula: `=SUM(G2:G7)`

Rules:

1. Do not invent hard revenue figures unless founder provides them
2. If numbers are unknown, leave values blank and describe the metric logic
3. Status should usually be `future`, `draft`, or `assumption to verify`
4. Activation Timing format: Use "Q2 2026", "Month 4", or "TBD" for consistency

## Tab 9: Investor Upside Model

Purpose:
- give an illustrative upside framework without promise language
- clarify potential return paths and liquidity expectations

Columns:

1. `Upside Path`
2. `Mechanism`
3. `Current Status`
4. `Illustrative Assumption`
5. `Expected Timeline`
6. `Risk Note`
7. `Notes`

Required rows:

1. token upside
2. token liquidity path
3. business revenue upside
4. platform valuation upside (if equity component exists)

**Example values:**

| Upside Path | Expected Timeline | Risk Note |
|------------|-------------------|-----------|
| Token upside | TBD - pending tokenomics finalization | No guarantee of token value appreciation; draft tokenomics subject to change |
| Token liquidity path | TBD - pending DEX listing or liquidity events | No guarantee of liquidity availability; regulatory restrictions may apply |
| Business revenue upside | Q3 2026+ (first monetization) | Revenue projections are estimates; actual results may vary significantly |
| Platform valuation upside | 12-18 months (post-revenue) | Valuation is speculative; no guarantee of exit or acquisition opportunity |

Rules:

1. token row must explicitly say `draft tokenomics` in Current Status
2. no guaranteed return language anywhere
3. no IRR, payback, or fixed-multiple promise unless legal and financial counsel approve later
4. Expected Timeline should use qualitative ranges (TBD, Q2 2026, 12-18 months) not hard dates
5. All Risk Notes must acknowledge uncertainty

## Tab 10: Runway Summary

Purpose:
- show what each funding level buys in time and capability

Columns:

1. `Scenario`
2. `Primary Use`
3. `Calculated Runway (months)` (formula-based)
4. `Approximate Runway Impact` (qualitative description)
5. `What It Unlocks`
6. `What Remains Unfunded`

Required rows:

1. $1,000
2. $5,000
3. $10,000
4. $20,000

**Calculated Runway formula guidance:**

For each scenario, calculate runway as:
```
Runway (months) =
  (Scenario Amount - One-Time Costs) /
  (Monthly Burn + (Annual Costs / 12))
```

Google Sheets formula example for $1,000 scenario:
```
=(1000 - 'Annual and One-Time Costs'!B9) /
 ('Recurring Costs'!D11 + ('Annual and One-Time Costs'!B8/12))
```

Where:
- `1000` = scenario funding amount
- `'Annual and One-Time Costs'!B9` = Total One-Time Costs
- `'Recurring Costs'!D11` = Total Base Monthly (use Base for all scenarios)
- `'Annual and One-Time Costs'!B8` = Total Annual Costs

Approximate Runway Impact guidance:

1. describe in words if exact monthly burn remains partially unknown
2. use phrases like:
- `unblocks core setup`
- `supports lean launch prep`
- `supports launch plus first growth experiments`
- `supports launch, growth testing, and part-time support`
3. this column provides context for the calculated runway number

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

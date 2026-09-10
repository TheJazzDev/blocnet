# Blocnet Financial Model - Google Sheets Setup Guide

Last updated: March 11, 2026

This guide provides step-by-step instructions to create the Blocnet investor financial model in Google Sheets based on INVESTOR_FINANCIAL_MODEL_SPEC.md.

## Quick Start

1. Create a new Google Sheet: https://sheets.google.com
2. Name it: "Blocnet Financial Model - [Your Name]"
3. Create 10 tabs using the names below
4. Follow the detailed instructions for each tab

---

## Tab Setup Order

Create tabs in this order (right-click on tab → Rename):

1. Assumptions
2. Current Costs
3. Recurring Costs
4. Annual and One-Time Costs
5. Funding Scenarios
6. 6-Month Plan
7. 12-Month Plan
8. Revenue Model
9. Investor Upside Model
10. Runway Summary

---

# Tab 1: Assumptions

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Category | Item | Value | Unit | Status | Notes |

## Data Rows (starting Row 2):

### Timeline
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Timeline | Planning start month | March 2026 | month | confirmed | - |
| Timeline | Planning end month | February 2027 | month | confirmed | 12-month planning window |

### Infrastructure
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Infrastructure | Current Railway monthly cost | 5 | USD | confirmed | Starter plan |
| Infrastructure | First Railway scale step monthly cost | 20 | USD | confirmed | Pro plan |
| Infrastructure | Supabase current monthly cost | 0 | USD | confirmed | Free tier |
| Infrastructure | Supabase paid tier cost | 25 | USD | assumption to verify | Estimated Pro tier |
| Infrastructure | Resend current monthly cost | 0 | USD | confirmed | Free tier |
| Infrastructure | Resend paid tier cost | 20 | USD | assumption to verify | Estimated paid tier |
| Infrastructure | Firebase cost model | usage based | - | confirmed | Pay-as-you-go |
| Infrastructure | Estimated Firebase monthly at scale | 15 | USD | assumption to verify | Rough estimate for notifications |

### Development Tools
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Development Tools | GitHub organization cost | 0 | USD | confirmed | Currently free |
| Development Tools | Vercel seat cost | 0 | USD | confirmed | Hobby plan |

### Domains & Services
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Domains & Services | Domain annual cost | 17 | USD | confirmed | Includes privacy protection |
| Domains & Services | Custom email annual cost | 45 | USD | confirmed | Google Workspace single user |

### App Store Fees
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| App Store Fees | Play Console org fee | 25 | USD | confirmed | One-time |
| App Store Fees | Apple Developer annual fee | 100 | USD | confirmed | Standard program |
| App Store Fees | Apple Enterprise Program fee (if needed) | 0 | USD | assumption to verify | Not needed for public app store |

### Revenue Model
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Revenue Model | Tipping take rate | 5 | % | founder assumption | Platform fee on tips |
| Revenue Model | Withdrawal fee take | 2 | % | founder assumption | Fee on wallet withdrawals |
| Revenue Model | Featured project monthly demand | 10 | projects | assumption to verify | Estimated monthly demand |
| Revenue Model | Premium placement monthly demand | 5 | projects | assumption to verify | Estimated monthly demand |
| Revenue Model | Hunter onboarding fee | 50 | USD | founder assumption | One-time per hunter |

### Token & Investment
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Token & Investment | Investor token allocation low | 5 | % | draft | Subject to tokenomics design |
| Token & Investment | Investor token allocation base | 10 | % | draft | Subject to tokenomics design |
| Token & Investment | Investor token allocation high | 15 | % | draft | Subject to tokenomics design |

### Team & Support
| Category | Item | Value | Unit | Status | Notes |
|----------|------|-------|------|--------|-------|
| Team & Support | Contractor hourly rate | 50 | USD/hr | assumption to verify | Part-time technical support |
| Team & Support | Estimated contractor hours per month (base) | 20 | hours | founder assumption | ~5 hours/week |
| Team & Support | Community support monthly budget (high scenario) | 500 | USD | founder assumption | Bounties and stipends |

---

# Tab 2: Current Costs

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Cost Type | Vendor / Item | Current Monthly Cost | Current Status | Scale Trigger | Notes |

## Data Rows (starting Row 2):

| Cost Type | Vendor / Item | Current Monthly Cost | Current Status | Scale Trigger | Notes |
|-----------|--------------|---------------------|----------------|---------------|-------|
| Infrastructure | Railway backend hosting | 5 | confirmed | >100 active users | Currently on Starter |
| Infrastructure | Supabase database | 0 | confirmed | >500MB or >50k requests | Free tier |
| Infrastructure | Resend email | 0 | confirmed | >3k emails/month | Free tier |
| Infrastructure | Firebase | 0 | confirmed | >10k notifications/month | Pay-as-you-go |
| Development Tools | GitHub organization | 0 | confirmed | Private repos needed | Public repos only |
| Development Tools | Vercel seat | 0 | confirmed | Team collaboration | Hobby plan |

## Bottom Rows:

| A | B | C |
|---|---|---|
| **Total Current Monthly Baseline** | | =SUM(C2:C7) |
| **Total Confirmed Monthly Baseline** | | =SUMIF(D2:D7,"confirmed",C2:C7) |
| **Total Monthly Costs Pending Verification** | | =SUMIF(D2:D7,"assumption to verify",C2:C7) |

**Format these bottom rows in bold with light gray background**

---

# Tab 3: Recurring Costs

## Column Headers (Row 1):

| A | B | C | D | E | F | G |
|---|---|---|---|---|---|---|
| Category | Item | Low | Base | High | Status | Notes |

## Data Rows (starting Row 2):

| Category | Item | Low | Base | High | Status | Notes |
|----------|------|-----|------|------|--------|-------|
| Infrastructure | Backend hosting (Railway) | 5 | 20 | 50 | confirmed | Starter → Pro → Custom |
| Infrastructure | Database (Supabase) | 0 | 25 | 75 | assumption to verify | Free → Pro → Team |
| Infrastructure | Email delivery (Resend) | 0 | 20 | 50 | assumption to verify | Based on volume |
| Infrastructure | Messaging / notifications (Firebase) | 0 | 15 | 40 | assumption to verify | Usage-based estimate |
| Development Tools | Source control / org (GitHub) | 0 | 0 | 20 | assumption to verify | May need private repos |
| Development Tools | Deployment / frontend (Vercel) | 0 | 0 | 20 | assumption to verify | May upgrade for team |
| Team | Contractor support | 0 | 0 | 1000 | founder assumption | 20 hrs/month @ $50/hr |
| Team | Community support | 0 | 0 | 500 | founder assumption | Bounties and stipends |

## Bottom Rows (starting Row 10):

| A | B | C | D | E |
|---|---|---|---|---|
| | **Annualized Annual Costs (monthly equivalent)** | =('Annual and One-Time Costs'!C8)/12 | =('Annual and One-Time Costs'!C8)/12 | =('Annual and One-Time Costs'!C8)/12 |
| | **Total Low Monthly** | =SUM(C2:C9)+C10 | | |
| | **Total Base Monthly** | | =SUM(D2:D9)+D10 | |
| | **Total High Monthly** | | | =SUM(E2:E9)+E10 |

**Format bottom rows in bold with light gray background**

**Note:** Adjust the 'Annual and One-Time Costs'!C8 reference after creating Tab 4

---

# Tab 4: Annual and One-Time Costs

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Cost Type | Item | Amount | Frequency | Status | Notes |

## Data Rows (starting Row 2):

| Cost Type | Item | Amount | Frequency | Status | Notes |
|-----------|------|--------|-----------|--------|-------|
| Domains & Services | Domain registration | 17 | annual | confirmed | .com + privacy |
| Domains & Services | Custom email | 45 | annual | confirmed | Google Workspace |
| App Store Fees | Apple Developer annual fee | 100 | annual | confirmed | Standard program |
| App Store Fees | Play Console organization fee | 25 | one-time | confirmed | One-time setup |
| App Store Fees | Apple organization-specific setup | 0 | one-time | confirmed | Not needed for standard program |

## Bottom Rows (starting Row 7):

| A | B | C |
|---|---|---|
| | **Total Annual Costs** | =SUMIF(D2:D6,"annual",C2:C6) |
| | **Total One-Time Costs** | =SUMIF(D2:D6,"one-time",C2:C6) |
| | **Total Annualized Non-Monthly Costs** | =C7+(C8*0) |

**Note:** Row 9 formula is: Annual costs + (one-time costs * 0) because one-time costs don't recur

**Format bottom rows in bold with light gray background**

---

# Tab 5: Funding Scenarios

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Spend Category | $1,000 | $5,000 | $10,000 | $20,000 | Notes |

## Data Rows (starting Row 2) - EXACT VALUES:

| Spend Category | $1,000 | $5,000 | $10,000 | $20,000 | Notes |
|----------------|--------|--------|---------|---------|-------|
| App/account setup | 125 | 100 | 100 | 100 | Play Console + Apple Developer + misc |
| Annual operating costs | 162 | 150 | 150 | 150 | Domain, email, annual fees |
| Infrastructure reserve | 300 | 1000 | 1500 | 3000 | Covers 3-12 months of Tab 3 recurring costs |
| Launch hardening / release ops | 0 | 1000 | 2000 | 3000 | Testing, security, deployment automation |
| Marketing / awareness | 250 | 2000 | 4000 | 8000 | Community building, content, campaigns |
| Contractor support | 0 | 0 | 1000 | 2000 | Part-time technical assistance |
| Community support | 0 | 0 | 500 | 1000 | Bounties, moderators, ambassadors |
| Token / liquidity execution reserve | 0 | 0 | 0 | 2000 | DEX listing, liquidity provision |
| Contingency | 163 | 750 | 750 | 750 | Buffer for unknowns |

## Bottom Rows (starting Row 11):

| A | B | C | D | E |
|---|---|---|---|---|
| **Total** | =SUM(B2:B10) | =SUM(C2:C10) | =SUM(D2:D10) | =SUM(E2:E10) |
| **Difference vs Scenario Target** | =B11-1000 | =C11-5000 | =D11-10000 | =E11-20000 |

**Format bottom rows in bold**
**Apply conditional formatting to Row 12:** If value ≠ 0, fill cell RED

---

# Tab 6: 6-Month Plan

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Month | Primary Objective | Key Milestone | Expected Spend | Funding Dependency | Notes |

## Data Rows (starting Row 2):

### Example for $5,000 scenario (adjust based on actual scenario):

| Month | Primary Objective | Key Milestone | Expected Spend | Funding Dependency | Notes |
|-------|------------------|---------------|----------------|-------------------|-------|
| Month 1 (Mar 2026) | Accounts, planning, ops setup | Apple + Google accounts live | ='Funding Scenarios'!C2+'Recurring Costs'!D11 | $1k+ | One-time setup costs |
| Month 2 (Apr 2026) | App store readiness | App submitted for review | ='Recurring Costs'!D11 | base ops | Monthly burn only |
| Month 3 (May 2026) | Launch hardening | Public launch complete | ='Recurring Costs'!D11+('Funding Scenarios'!C4/2) | $5k+ | Launch hardening begins |
| Month 4 (Jun 2026) | Token and monetization prep | Smart contracts deployed | ='Recurring Costs'!D11+('Funding Scenarios'!C5/3) | $5k+ | Marketing begins |
| Month 5 (Jul 2026) | Growth and partner activation | First 1,000 users | ='Recurring Costs'!D11+('Funding Scenarios'!C5/3) | $5k+ | Marketing continues |
| Month 6 (Aug 2026) | First monetization review | First revenue tracked | ='Recurring Costs'!D11+('Funding Scenarios'!C5/3) | $5k+ | Marketing continues |

**Note:** Formulas in Expected Spend column are examples - adjust based on your scenario and allocation strategy

---

# Tab 7: 12-Month Plan

## Column Headers (Row 1):

| A | B | C | D | E |
|---|---|---|---|---|
| Quarter | Primary Goal | Key Outputs | Major Spend Areas | Expected Operating Shift |

## Data Rows (starting Row 2):

| Quarter | Primary Goal | Key Outputs | Major Spend Areas | Expected Operating Shift |
|---------|-------------|-------------|-------------------|-------------------------|
| Q2 2026 (Mar-May) | Platform launch | App live on iOS/Android, initial user onboarding | Setup costs, launch hardening, initial marketing | Free tier → paid infrastructure as users grow |
| Q3 2026 (Jun-Aug) | User growth & token activation | 1,000+ users, smart contracts deployed, first tips | Marketing, community building, token execution | Scaling infrastructure, activating revenue streams |
| Q4 2026 (Sep-Nov) | Monetization & scaling | First meaningful revenue, 5,000+ users, hunter program | Continued marketing, contractor support | Move toward revenue sustainability |
| Q1 2027 (Dec-Feb) | Optimization & sustainability | Positive unit economics, 10,000+ users, profitable features | Optimization, product development | Aim for break-even on key features |

---

# Tab 8: Revenue Model

## Column Headers (Row 1):

| A | B | C | D | E | F | G | H | I |
|---|---|---|---|---|---|---|---|---|
| Revenue Stream | Description | Activation Timing | Leading Metric | Low Case | Base Case | High Case | Status | Notes |

## Data Rows (starting Row 2):

| Revenue Stream | Description | Activation Timing | Leading Metric | Low Case | Base Case | High Case | Status | Notes |
|----------------|-------------|-------------------|----------------|----------|-----------|-----------|--------|-------|
| Tipping take rate | 5% fee on user-to-user tips | Q3 2026 | Monthly tip volume | | | | draft | Need user behavior data |
| Withdrawal / transaction fees | 2% fee on wallet withdrawals | Q3 2026 | Monthly withdrawal volume | | | | draft | Competitive with exchanges |
| Paid project featuring | $50-200/month for featured spot | Q4 2026 | Active projects | 100 | 500 | 2000 | assumption to verify | 2-10 featured projects/month |
| Premium project placement | $25-50/month for premium spot | Q4 2026 | Active projects | 50 | 250 | 1000 | assumption to verify | 1-20 premium spots/month |
| Hunter onboarding fee | $50 one-time fee per hunter | Q3 2026 | Hunter signups | 50 | 150 | 500 | assumption to verify | 1-10 hunters/month |
| Premium intelligence / subscription | $10-30/month for analytics | Q1 2027 | Power users | | | | future | Product-market fit TBD |

## Bottom Rows (starting Row 8):

| A | B | C | D | E | F | G |
|---|---|---|---|---|---|---|
| | | | **Total Low Monthly Revenue** | =SUM(E2:E7) | | |
| | | | **Total Base Monthly Revenue** | | =SUM(F2:F7) | |
| | | | **Total High Monthly Revenue** | | | =SUM(G2:G7) |

**Note:** Fill in Low/Base/High cases with actual monthly revenue estimates as you gather data

---

# Tab 9: Investor Upside Model

## Column Headers (Row 1):

| A | B | C | D | E | F | G |
|---|---|---|---|---|---|---|
| Upside Path | Mechanism | Current Status | Illustrative Assumption | Expected Timeline | Risk Note | Notes |

## Data Rows (starting Row 2):

| Upside Path | Mechanism | Current Status | Illustrative Assumption | Expected Timeline | Risk Note | Notes |
|-------------|-----------|----------------|------------------------|-------------------|-----------|-------|
| Token upside | Investor allocation of native token | Draft tokenomics | 5-15% of total supply based on funding level | TBD - pending tokenomics finalization | No guarantee of token value appreciation; draft tokenomics subject to change | Token design in progress |
| Token liquidity path | DEX listing or secondary trading | Not yet launched | Initial liquidity provision from token reserve | TBD - pending DEX listing or liquidity events | No guarantee of liquidity availability; regulatory restrictions may apply | Subject to legal review |
| Business revenue upside | Revenue share or profit participation | Not yet active | Potential for revenue share after break-even | Q3 2026+ (first monetization) | Revenue projections are estimates; actual results may vary significantly | Depends on revenue model adoption |
| Platform valuation upside | Future equity raise or acquisition | Pre-revenue | Platform valuation tied to user growth and revenue | 12-18 months (post-revenue) | Valuation is speculative; no guarantee of exit or acquisition opportunity | Not an equity offering |

**Format:** Make sure all Risk Note cells clearly state uncertainty and no guarantees

---

# Tab 10: Runway Summary

## Column Headers (Row 1):

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| Scenario | Primary Use | Calculated Runway (months) | Approximate Runway Impact | What It Unlocks | What Remains Unfunded |

## Data Rows (starting Row 2):

| Scenario | Primary Use | Calculated Runway (months) | Approximate Runway Impact | What It Unlocks | What Remains Unfunded |
|----------|-------------|---------------------------|---------------------------|-----------------|----------------------|
| $1,000 | Setup + minimal ops | =(1000-'Annual and One-Time Costs'!C9)/('Recurring Costs'!D11+('Annual and One-Time Costs'!C8/12)) | Unblocks core setup | App store accounts, domain, basic infrastructure | Marketing, contractor support, launch hardening |
| $5,000 | Launch prep | =(5000-'Annual and One-Time Costs'!C9)/('Recurring Costs'!D11+('Annual and One-Time Costs'!C8/12)) | Supports lean launch prep | Setup + launch hardening + initial marketing | Significant marketing, team support, token execution |
| $10,000 | Launch + growth testing | =(10000-'Annual and One-Time Costs'!C9)/('Recurring Costs'!D11+('Annual and One-Time Costs'!C8/12)) | Supports launch plus growth experiments | Setup + hardening + marketing + contractor support | Full-time team, aggressive marketing, token liquidity |
| $20,000 | Full launch + scaled ops | =(20000-'Annual and One-Time Costs'!C9)/('Recurring Costs'!D11+('Annual and One-Time Costs'!C8/12)) | Supports launch, growth, and part-time support | All core activities + token execution + community program | Full-time team, enterprise infrastructure |

**Note:** The Calculated Runway formulas will auto-update when you fill in costs in other tabs

---

## Formatting Recommendations

### Color Scheme:
- **Headers (Row 1 all tabs):** Dark blue background (#4A86E8), white text, bold
- **Bottom row totals:** Light gray background (#F3F3F3), bold
- **Status column:** Use data validation with dropdown:
  - confirmed ✓
  - founder assumption
  - assumption to verify
  - draft
  - future

### Data Validation:
1. **Tab 1 - Status column (E):** Create dropdown with: confirmed, founder assumption, assumption to verify, draft
2. **Tab 2 - Current Status column (D):** Create dropdown with: confirmed, assumption to verify
3. **Tab 4 - Frequency column (D):** Create dropdown with: annual, one-time
4. **Tab 5:** Lock all data cells (except Notes) after validation to prevent accidental changes
5. **Tab 6 - Funding Dependency column (E):** Create dropdown with: base ops, $1k+, $5k+, $10k+, $20k+
6. **Tab 8 - Status column (H):** Create dropdown with: draft, assumption to verify, future, active

### Conditional Formatting:
1. **Tab 5 - Row 12 (Difference):** If value ≠ 0, fill RED
2. **Tab 1 - Status column:** Color-code statuses:
   - confirmed = green
   - assumption to verify = yellow
   - draft = orange

### Number Formatting:
- All currency values: Currency format with $ and 0 decimals
- All percentages: Percentage format with 0-1 decimals
- Months: Text format

---

## Validation Checklist

After building the spreadsheet, verify:

- [ ] All formulas calculate without errors
- [ ] Tab 5 totals equal exactly $1,000, $5,000, $10,000, $20,000
- [ ] Tab 5 Difference row shows $0 for all scenarios
- [ ] Tab 3 includes annualized annual costs in monthly burn
- [ ] Tab 10 runway formulas reference correct cells
- [ ] All tabs have proper headers and formatting
- [ ] Status dropdowns work correctly
- [ ] No hard-coded duplicate values (all reference Assumptions tab where possible)

---

## Next Steps After Creation

1. **Fill in unknown values:** Research and verify all "assumption to verify" items
2. **Get founder input:** Review all "founder assumption" values
3. **Test scenarios:** Try different funding levels and see runway impact
4. **Share with stakeholders:** Get feedback on assumptions and structure
5. **Update regularly:** Track actual costs vs. projections

---

## Support

For questions about this model or the spec:
- Reference: `/Users/jazzdev/Documents/Programming/blocnet/INVESTOR_FINANCIAL_MODEL_SPEC.md`
- Updates: Document any deviations from spec in tab notes

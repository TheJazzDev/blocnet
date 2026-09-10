/**
 * Blocnet Financial Model Auto-Setup Script
 *
 * IMPORTANT: This script must be run FROM WITHIN the Google Sheet itself
 *
 * Instructions:
 * 1. Open your Google Sheet: https://docs.google.com/spreadsheets/d/1uqic9AzmV3wmnbn2jWRz6bCf4uFbHCQUNaaeCdrA1H4/edit
 * 2. Click: Extensions → Apps Script
 * 3. Delete any existing code in the editor
 * 4. Paste this entire script
 * 5. Click Save (💾) - Name it "FinancialModelSetup"
 * 6. From the dropdown at top, select: step1_CreateTabs
 * 7. Click Run (▶️)
 * 8. Grant permissions when prompted (this is normal)
 * 9. Wait for "Step 1 complete" alert
 * 10. Select: step2_PopulateAllTabs from dropdown
 * 11. Click Run (▶️)
 * 12. Wait for "Setup complete" alert
 * 13. Close Apps Script tab and refresh your sheet
 */

function step1_CreateTabs() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    if (!ss) {
      throw new Error('Could not access spreadsheet. Make sure you opened Apps Script from Extensions menu within the sheet.');
    }

    // Clear existing sheets except the first one
    const sheets = ss.getSheets();
    for (let i = sheets.length - 1; i > 0; i--) {
      ss.deleteSheet(sheets[i]);
    }

    // Rename first sheet
    sheets[0].setName('Assumptions');

    // Create all tabs
    const tabNames = [
      'Current Costs',
      'Recurring Costs',
      'Annual and One-Time Costs',
      'Funding Scenarios',
      '6-Month Plan',
      '12-Month Plan',
      'Revenue Model',
      'Investor Upside Model',
      'Runway Summary'
    ];

    tabNames.forEach(name => ss.insertSheet(name));

    SpreadsheetApp.getUi().alert('✅ Step 1 complete!\n\nAll tabs created.\n\nNow select "step2_PopulateAllTabs" from the dropdown and click Run.');

  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Error: ' + error.message + '\n\nMake sure you:\n1. Opened Apps Script from within the Google Sheet\n2. Granted permissions when prompted');
  }
}

function step2_PopulateAllTabs() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    if (!ss) {
      throw new Error('Could not access spreadsheet.');
    }

    setupAssumptions(ss.getSheetByName('Assumptions'));
    setupCurrentCosts(ss.getSheetByName('Current Costs'));
    setupRecurringCosts(ss.getSheetByName('Recurring Costs'));
    setupAnnualCosts(ss.getSheetByName('Annual and One-Time Costs'));
    setupFundingScenarios(ss.getSheetByName('Funding Scenarios'));
    setup6MonthPlan(ss.getSheetByName('6-Month Plan'));
    setup12MonthPlan(ss.getSheetByName('12-Month Plan'));
    setupRevenueModel(ss.getSheetByName('Revenue Model'));
    setupInvestorUpside(ss.getSheetByName('Investor Upside Model'));
    setupRunwaySummary(ss.getSheetByName('Runway Summary'));

    SpreadsheetApp.getUi().alert('✅ Setup complete!\n\nAll tabs populated and formatted.\n\nClose this window and refresh your sheet to see the results.');

  } catch (error) {
    SpreadsheetApp.getUi().alert('❌ Error: ' + error.message);
  }
}

function setupAssumptions(sheet) {
  sheet.clear();
  const headers = [['Category', 'Item', 'Value', 'Unit', 'Status', 'Notes']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Timeline', 'Planning start month', 'March 2026', 'month', 'confirmed', ''],
    ['Timeline', 'Planning end month', 'February 2027', 'month', 'confirmed', '12-month planning window'],
    ['Infrastructure', 'Current Railway monthly cost', 5, 'USD', 'confirmed', 'Starter plan'],
    ['Infrastructure', 'First Railway scale step monthly cost', 20, 'USD', 'confirmed', 'Pro plan'],
    ['Infrastructure', 'Supabase current monthly cost', 0, 'USD', 'confirmed', 'Free tier'],
    ['Infrastructure', 'Supabase paid tier cost', 25, 'USD', 'assumption to verify', 'Estimated Pro tier'],
    ['Infrastructure', 'Resend current monthly cost', 0, 'USD', 'confirmed', 'Free tier'],
    ['Infrastructure', 'Resend paid tier cost', 20, 'USD', 'assumption to verify', 'Estimated paid tier'],
    ['Infrastructure', 'Firebase cost model', 'usage based', '-', 'confirmed', 'Pay-as-you-go'],
    ['Infrastructure', 'Estimated Firebase monthly at scale', 15, 'USD', 'assumption to verify', 'Rough estimate for notifications'],
    ['Development Tools', 'GitHub organization cost', 0, 'USD', 'confirmed', 'Currently free'],
    ['Development Tools', 'Vercel seat cost', 0, 'USD', 'confirmed', 'Hobby plan'],
    ['Domains & Services', 'Domain annual cost', 17, 'USD', 'confirmed', 'Includes privacy protection'],
    ['Domains & Services', 'Custom email annual cost', 45, 'USD', 'confirmed', 'Google Workspace single user'],
    ['App Store Fees', 'Play Console org fee', 25, 'USD', 'confirmed', 'One-time'],
    ['App Store Fees', 'Apple Developer annual fee', 100, 'USD', 'confirmed', 'Standard program'],
    ['App Store Fees', 'Apple Enterprise Program fee (if needed)', 0, 'USD', 'assumption to verify', 'Not needed for public app store'],
    ['Revenue Model', 'Tipping take rate', 5, '%', 'founder assumption', 'Platform fee on tips'],
    ['Revenue Model', 'Withdrawal fee take', 2, '%', 'founder assumption', 'Fee on wallet withdrawals'],
    ['Revenue Model', 'Featured project monthly demand', 10, 'projects', 'assumption to verify', 'Estimated monthly demand'],
    ['Revenue Model', 'Premium placement monthly demand', 5, 'projects', 'assumption to verify', 'Estimated monthly demand'],
    ['Revenue Model', 'Hunter onboarding fee', 50, 'USD', 'founder assumption', 'One-time per hunter'],
    ['Token & Investment', 'Investor token allocation low', 5, '%', 'draft', 'Subject to tokenomics design'],
    ['Token & Investment', 'Investor token allocation base', 10, '%', 'draft', 'Subject to tokenomics design'],
    ['Token & Investment', 'Investor token allocation high', 15, '%', 'draft', 'Subject to tokenomics design'],
    ['Team & Support', 'Contractor hourly rate', 50, 'USD/hr', 'assumption to verify', 'Part-time technical support'],
    ['Team & Support', 'Estimated contractor hours per month (base)', 20, 'hours', 'founder assumption', '~5 hours/week'],
    ['Team & Support', 'Community support monthly budget (high scenario)', 500, 'USD', 'founder assumption', 'Bounties and stipends']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);

  const statusRange = sheet.getRange('E2:E' + (data.length + 1));
  const statusRule = SpreadsheetApp.newDataValidation().requireValueInList(['confirmed', 'founder assumption', 'assumption to verify', 'draft', 'future']).build();
  statusRange.setDataValidation(statusRule);

  sheet.autoResizeColumns(1, 6);
}

function setupCurrentCosts(sheet) {
  sheet.clear();
  const headers = [['Cost Type', 'Vendor / Item', 'Current Monthly Cost', 'Current Status', 'Scale Trigger', 'Notes']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Infrastructure', 'Railway backend hosting', 5, 'confirmed', '>100 active users', 'Currently on Starter'],
    ['Infrastructure', 'Supabase database', 0, 'confirmed', '>500MB or >50k requests', 'Free tier'],
    ['Infrastructure', 'Resend email', 0, 'confirmed', '>3k emails/month', 'Free tier'],
    ['Infrastructure', 'Firebase', 0, 'confirmed', '>10k notifications/month', 'Pay-as-you-go'],
    ['Development Tools', 'GitHub organization', 0, 'confirmed', 'Private repos needed', 'Public repos only'],
    ['Development Tools', 'Vercel seat', 0, 'confirmed', 'Team collaboration', 'Hobby plan']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);

  const lastRow = data.length + 1;
  sheet.getRange(lastRow + 2, 1, 3, 1).setValues([['Total Current Monthly Baseline'], ['Total Confirmed Monthly Baseline'], ['Total Monthly Costs Pending Verification']]).setFontWeight('bold');
  sheet.getRange(lastRow + 2, 3).setFormula('=SUM(C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 3, 3).setFormula('=SUMIF(D2:D' + lastRow + ',"confirmed",C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 4, 3).setFormula('=SUMIF(D2:D' + lastRow + ',"assumption to verify",C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 2, 1, 3, 3).setBackground('#F3F3F3');

  sheet.autoResizeColumns(1, 6);
}

function setupRecurringCosts(sheet) {
  sheet.clear();
  const headers = [['Category', 'Item', 'Low', 'Base', 'High', 'Status', 'Notes']];
  sheet.getRange('A1:G1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Infrastructure', 'Backend hosting (Railway)', 5, 20, 50, 'confirmed', 'Starter → Pro → Custom'],
    ['Infrastructure', 'Database (Supabase)', 0, 25, 75, 'assumption to verify', 'Free → Pro → Team'],
    ['Infrastructure', 'Email delivery (Resend)', 0, 20, 50, 'assumption to verify', 'Based on volume'],
    ['Infrastructure', 'Messaging / notifications (Firebase)', 0, 15, 40, 'assumption to verify', 'Usage-based estimate'],
    ['Development Tools', 'Source control / org (GitHub)', 0, 0, 20, 'assumption to verify', 'May need private repos'],
    ['Development Tools', 'Deployment / frontend (Vercel)', 0, 0, 20, 'assumption to verify', 'May upgrade for team'],
    ['Team', 'Contractor support', 0, 0, 1000, 'founder assumption', '20 hrs/month @ $50/hr'],
    ['Team', 'Community support', 0, 0, 500, 'founder assumption', 'Bounties and stipends']
  ];

  sheet.getRange(2, 1, data.length, 7).setValues(data);

  const lastRow = data.length + 1;
  sheet.getRange(lastRow + 2, 2, 4, 1).setValues([['Annualized Annual Costs (monthly equivalent)'], ['Total Low Monthly'], ['Total Base Monthly'], ['Total High Monthly']]).setFontWeight('bold');
  sheet.getRange(lastRow + 2, 3).setFormula('=\'Annual and One-Time Costs\'!C8/12');
  sheet.getRange(lastRow + 2, 4).setFormula('=\'Annual and One-Time Costs\'!C8/12');
  sheet.getRange(lastRow + 2, 5).setFormula('=\'Annual and One-Time Costs\'!C8/12');
  sheet.getRange(lastRow + 3, 3).setFormula('=SUM(C2:C' + lastRow + ')+C' + (lastRow + 2));
  sheet.getRange(lastRow + 4, 4).setFormula('=SUM(D2:D' + lastRow + ')+D' + (lastRow + 2));
  sheet.getRange(lastRow + 5, 5).setFormula('=SUM(E2:E' + lastRow + ')+E' + (lastRow + 2));
  sheet.getRange(lastRow + 2, 2, 4, 4).setBackground('#F3F3F3');

  sheet.autoResizeColumns(1, 7);
}

function setupAnnualCosts(sheet) {
  sheet.clear();
  const headers = [['Cost Type', 'Item', 'Amount', 'Frequency', 'Status', 'Notes']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Domains & Services', 'Domain registration', 17, 'annual', 'confirmed', '.com + privacy'],
    ['Domains & Services', 'Custom email', 45, 'annual', 'confirmed', 'Google Workspace'],
    ['App Store Fees', 'Apple Developer annual fee', 100, 'annual', 'confirmed', 'Standard program'],
    ['App Store Fees', 'Play Console organization fee', 25, 'one-time', 'confirmed', 'One-time setup'],
    ['App Store Fees', 'Apple organization-specific setup', 0, 'one-time', 'confirmed', 'Not needed for standard program']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);

  const lastRow = data.length + 1;
  sheet.getRange(lastRow + 2, 2, 3, 1).setValues([['Total Annual Costs'], ['Total One-Time Costs'], ['Total Annualized Non-Monthly Costs']]).setFontWeight('bold');
  sheet.getRange(lastRow + 2, 3).setFormula('=SUMIF(D2:D' + lastRow + ',"annual",C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 3, 3).setFormula('=SUMIF(D2:D' + lastRow + ',"one-time",C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 4, 3).setFormula('=C' + (lastRow + 2) + '+(C' + (lastRow + 3) + '*0)');
  sheet.getRange(lastRow + 2, 2, 3, 2).setBackground('#F3F3F3');

  const freqRange = sheet.getRange('D2:D' + lastRow);
  const freqRule = SpreadsheetApp.newDataValidation().requireValueInList(['annual', 'one-time']).build();
  freqRange.setDataValidation(freqRule);

  sheet.autoResizeColumns(1, 6);
}

function setupFundingScenarios(sheet) {
  sheet.clear();
  const headers = [['Spend Category', '$1,000', '$5,000', '$10,000', '$20,000', 'Notes']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['App/account setup', 125, 100, 100, 100, 'Play Console + Apple Developer + misc'],
    ['Annual operating costs', 162, 150, 150, 150, 'Domain, email, annual fees'],
    ['Infrastructure reserve', 300, 1000, 1500, 3000, 'Covers 3-12 months of Tab 3 recurring costs'],
    ['Launch hardening / release ops', 0, 1000, 2000, 3000, 'Testing, security, deployment automation'],
    ['Marketing / awareness', 250, 2000, 4000, 8000, 'Community building, content, campaigns'],
    ['Contractor support', 0, 0, 1000, 2000, 'Part-time technical assistance'],
    ['Community support', 0, 0, 500, 1000, 'Bounties, moderators, ambassadors'],
    ['Token / liquidity execution reserve', 0, 0, 0, 2000, 'DEX listing, liquidity provision'],
    ['Contingency', 163, 750, 750, 750, 'Buffer for unknowns']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);

  const lastRow = data.length + 1;
  sheet.getRange(lastRow + 2, 1).setValue('Total').setFontWeight('bold');
  sheet.getRange(lastRow + 3, 1).setValue('Difference vs Scenario Target').setFontWeight('bold');
  sheet.getRange(lastRow + 2, 2).setFormula('=SUM(B2:B' + lastRow + ')');
  sheet.getRange(lastRow + 2, 3).setFormula('=SUM(C2:C' + lastRow + ')');
  sheet.getRange(lastRow + 2, 4).setFormula('=SUM(D2:D' + lastRow + ')');
  sheet.getRange(lastRow + 2, 5).setFormula('=SUM(E2:E' + lastRow + ')');
  sheet.getRange(lastRow + 3, 2).setFormula('=B' + (lastRow + 2) + '-1000');
  sheet.getRange(lastRow + 3, 3).setFormula('=C' + (lastRow + 2) + '-5000');
  sheet.getRange(lastRow + 3, 4).setFormula('=D' + (lastRow + 2) + '-10000');
  sheet.getRange(lastRow + 3, 5).setFormula('=E' + (lastRow + 2) + '-20000');

  const diffRange = sheet.getRange(lastRow + 3, 2, 1, 4);
  const rule = SpreadsheetApp.newConditionalFormatRule().whenNumberNotEqualTo(0).setBackground('#FF0000').setRanges([diffRange]).build();
  sheet.setConditionalFormatRules([rule]);

  sheet.autoResizeColumns(1, 6);
}

function setup6MonthPlan(sheet) {
  sheet.clear();
  const headers = [['Month', 'Primary Objective', 'Key Milestone', 'Expected Spend', 'Funding Dependency', 'Notes']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Month 1 (Mar 2026)', 'Accounts, planning, ops setup', 'Apple + Google accounts live', '=\'Funding Scenarios\'!C2+\'Recurring Costs\'!D11', '$1k+', 'One-time setup costs'],
    ['Month 2 (Apr 2026)', 'App store readiness', 'App submitted for review', '=\'Recurring Costs\'!D11', 'base ops', 'Monthly burn only'],
    ['Month 3 (May 2026)', 'Launch hardening', 'Public launch complete', '=\'Recurring Costs\'!D11+(\'Funding Scenarios\'!C4/2)', '$5k+', 'Launch hardening begins'],
    ['Month 4 (Jun 2026)', 'Token and monetization prep', 'Smart contracts deployed', '=\'Recurring Costs\'!D11+(\'Funding Scenarios\'!C5/3)', '$5k+', 'Marketing begins'],
    ['Month 5 (Jul 2026)', 'Growth and partner activation', 'First 1,000 users', '=\'Recurring Costs\'!D11+(\'Funding Scenarios\'!C5/3)', '$5k+', 'Marketing continues'],
    ['Month 6 (Aug 2026)', 'First monetization review', 'First revenue tracked', '=\'Recurring Costs\'!D11+(\'Funding Scenarios\'!C5/3)', '$5k+', 'Marketing continues']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);

  const depRange = sheet.getRange('E2:E' + (data.length + 1));
  const depRule = SpreadsheetApp.newDataValidation().requireValueInList(['base ops', '$1k+', '$5k+', '$10k+', '$20k+']).build();
  depRange.setDataValidation(depRule);

  sheet.autoResizeColumns(1, 6);
}

function setup12MonthPlan(sheet) {
  sheet.clear();
  const headers = [['Quarter', 'Primary Goal', 'Key Outputs', 'Major Spend Areas', 'Expected Operating Shift']];
  sheet.getRange('A1:E1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Q2 2026 (Mar-May)', 'Platform launch', 'App live on iOS/Android, initial user onboarding', 'Setup costs, launch hardening, initial marketing', 'Free tier → paid infrastructure as users grow'],
    ['Q3 2026 (Jun-Aug)', 'User growth & token activation', '1,000+ users, smart contracts deployed, first tips', 'Marketing, community building, token execution', 'Scaling infrastructure, activating revenue streams'],
    ['Q4 2026 (Sep-Nov)', 'Monetization & scaling', 'First meaningful revenue, 5,000+ users, hunter program', 'Continued marketing, contractor support', 'Move toward revenue sustainability'],
    ['Q1 2027 (Dec-Feb)', 'Optimization & sustainability', 'Positive unit economics, 10,000+ users, profitable features', 'Optimization, product development', 'Aim for break-even on key features']
  ];

  sheet.getRange(2, 1, data.length, 5).setValues(data);
  sheet.autoResizeColumns(1, 5);
}

function setupRevenueModel(sheet) {
  sheet.clear();
  const headers = [['Revenue Stream', 'Description', 'Activation Timing', 'Leading Metric', 'Low Case', 'Base Case', 'High Case', 'Status', 'Notes']];
  sheet.getRange('A1:I1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Tipping take rate', '5% fee on user-to-user tips', 'Q3 2026', 'Monthly tip volume', '', '', '', 'draft', 'Need user behavior data'],
    ['Withdrawal / transaction fees', '2% fee on wallet withdrawals', 'Q3 2026', 'Monthly withdrawal volume', '', '', '', 'draft', 'Competitive with exchanges'],
    ['Paid project featuring', '$50-200/month for featured spot', 'Q4 2026', 'Active projects', 100, 500, 2000, 'assumption to verify', '2-10 featured projects/month'],
    ['Premium project placement', '$25-50/month for premium spot', 'Q4 2026', 'Active projects', 50, 250, 1000, 'assumption to verify', '1-20 premium spots/month'],
    ['Hunter onboarding fee', '$50 one-time fee per hunter', 'Q3 2026', 'Hunter signups', 50, 150, 500, 'assumption to verify', '1-10 hunters/month'],
    ['Premium intelligence / subscription', '$10-30/month for analytics', 'Q1 2027', 'Power users', '', '', '', 'future', 'Product-market fit TBD']
  ];

  sheet.getRange(2, 1, data.length, 9).setValues(data);

  const lastRow = data.length + 1;
  sheet.getRange(lastRow + 2, 4, 3, 1).setValues([['Total Low Monthly Revenue'], ['Total Base Monthly Revenue'], ['Total High Monthly Revenue']]).setFontWeight('bold');
  sheet.getRange(lastRow + 2, 5).setFormula('=SUM(E2:E' + lastRow + ')');
  sheet.getRange(lastRow + 3, 6).setFormula('=SUM(F2:F' + lastRow + ')');
  sheet.getRange(lastRow + 4, 7).setFormula('=SUM(G2:G' + lastRow + ')');

  const statusRange = sheet.getRange('H2:H' + lastRow);
  const statusRule = SpreadsheetApp.newDataValidation().requireValueInList(['draft', 'assumption to verify', 'future', 'active']).build();
  statusRange.setDataValidation(statusRule);

  sheet.autoResizeColumns(1, 9);
}

function setupInvestorUpside(sheet) {
  sheet.clear();
  const headers = [['Upside Path', 'Mechanism', 'Current Status', 'Illustrative Assumption', 'Expected Timeline', 'Risk Note', 'Notes']];
  sheet.getRange('A1:G1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['Token upside', 'Investor allocation of native token', 'Draft tokenomics', '5-15% of total supply based on funding level', 'TBD - pending tokenomics finalization', 'No guarantee of token value appreciation; draft tokenomics subject to change', 'Token design in progress'],
    ['Token liquidity path', 'DEX listing or secondary trading', 'Not yet launched', 'Initial liquidity provision from token reserve', 'TBD - pending DEX listing or liquidity events', 'No guarantee of liquidity availability; regulatory restrictions may apply', 'Subject to legal review'],
    ['Business revenue upside', 'Revenue share or profit participation', 'Not yet active', 'Potential for revenue share after break-even', 'Q3 2026+ (first monetization)', 'Revenue projections are estimates; actual results may vary significantly', 'Depends on revenue model adoption'],
    ['Platform valuation upside', 'Future equity raise or acquisition', 'Pre-revenue', 'Platform valuation tied to user growth and revenue', '12-18 months (post-revenue)', 'Valuation is speculative; no guarantee of exit or acquisition opportunity', 'Not an equity offering']
  ];

  sheet.getRange(2, 1, data.length, 7).setValues(data);
  sheet.autoResizeColumns(1, 7);
}

function setupRunwaySummary(sheet) {
  sheet.clear();
  const headers = [['Scenario', 'Primary Use', 'Calculated Runway (months)', 'Approximate Runway Impact', 'What It Unlocks', 'What Remains Unfunded']];
  sheet.getRange('A1:F1').setValues(headers).setFontWeight('bold').setBackground('#4A86E8').setFontColor('#FFFFFF');

  const data = [
    ['$1,000', 'Setup + minimal ops', '=(1000-\'Annual and One-Time Costs\'!C9)/(\'Recurring Costs\'!D11+(\'Annual and One-Time Costs\'!C8/12))', 'Unblocks core setup', 'App store accounts, domain, basic infrastructure', 'Marketing, contractor support, launch hardening'],
    ['$5,000', 'Launch prep', '=(5000-\'Annual and One-Time Costs\'!C9)/(\'Recurring Costs\'!D11+(\'Annual and One-Time Costs\'!C8/12))', 'Supports lean launch prep', 'Setup + launch hardening + initial marketing', 'Significant marketing, team support, token execution'],
    ['$10,000', 'Launch + growth testing', '=(10000-\'Annual and One-Time Costs\'!C9)/(\'Recurring Costs\'!D11+(\'Annual and One-Time Costs\'!C8/12))', 'Supports launch plus growth experiments', 'Setup + hardening + marketing + contractor support', 'Full-time team, aggressive marketing, token liquidity'],
    ['$20,000', 'Full launch + scaled ops', '=(20000-\'Annual and One-Time Costs\'!C9)/(\'Recurring Costs\'!D11+(\'Annual and One-Time Costs\'!C8/12))', 'Supports launch, growth, and part-time support', 'All core activities + token execution + community program', 'Full-time team, enterprise infrastructure']
  ];

  sheet.getRange(2, 1, data.length, 6).setValues(data);
  sheet.autoResizeColumns(1, 6);
}

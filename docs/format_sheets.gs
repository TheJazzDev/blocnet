/**
 * Auto-Format All Sheets - Resize columns and style headers
 *
 * Instructions:
 * 1. Open your Google Sheet
 * 2. Extensions → Apps Script
 * 3. Create new file or paste in existing
 * 4. Paste this code
 * 5. Save
 * 6. Run: formatAllSheets
 */

function formatAllSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheets = ss.getSheets();

  sheets.forEach(sheet => {
    Logger.log('Formatting: ' + sheet.getName());

    // Auto-resize all columns to fit content
    const lastCol = sheet.getLastColumn();
    if (lastCol > 0) {
      for (let i = 1; i <= lastCol; i++) {
        sheet.autoResizeColumn(i);
      }
    }

    // Format header row (row 1)
    const headerRange = sheet.getRange(1, 1, 1, lastCol);
    headerRange.setBackground('#4A86E8');  // Blue background
    headerRange.setFontColor('#FFFFFF');   // White text
    headerRange.setFontWeight('bold');
    headerRange.setHorizontalAlignment('left');

    // Freeze header row
    sheet.setFrozenRows(1);

    Logger.log('✓ ' + sheet.getName() + ' formatted');
  });

  SpreadsheetApp.getUi().alert('✅ All sheets formatted!\n\nColumns auto-resized and headers styled.');
}

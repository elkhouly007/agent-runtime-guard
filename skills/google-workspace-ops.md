# Skill: Google Workspace Ops

## Trigger

Use when automating Google Workspace tasks: reading/writing Google Sheets, managing Google Drive files, sending Gmail, creating Google Docs/Slides programmatically, or setting up Apps Script automations.

## Authentication

```typescript
// Node.js with googleapis
import { google } from 'googleapis';

// Service account (for server-side, no user interaction)
const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_KEY_FILE,
    // or:
    credentials: JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON!),
    scopes: [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive',
        'https://www.googleapis.com/auth/gmail.send',
    ],
});

const authClient = await auth.getClient();
```

## Google Sheets

```typescript
const sheets = google.sheets({ version: 'v4', auth: authClient });

// Read a range
const response = await sheets.spreadsheets.values.get({
    spreadsheetId: SPREADSHEET_ID,
    range: 'Sheet1!A1:E100',
});
const rows = response.data.values || [];

// Write data
await sheets.spreadsheets.values.update({
    spreadsheetId: SPREADSHEET_ID,
    range: 'Sheet1!A1',
    valueInputOption: 'USER_ENTERED',
    requestBody: {
        values: [
            ['Name', 'Email', 'Status'],
            ['Alice', 'alice@example.com', 'Active'],
        ],
    },
});

// Append rows
await sheets.spreadsheets.values.append({
    spreadsheetId: SPREADSHEET_ID,
    range: 'Sheet1!A:Z',
    valueInputOption: 'USER_ENTERED',
    requestBody: {
        values: [['New Row', 'data', 'here']],
    },
});

// Create a new spreadsheet
const newSheet = await sheets.spreadsheets.create({
    requestBody: {
        properties: { title: 'My Report' },
        sheets: [{ properties: { title: 'Data' } }],
    },
});
```

## Google Drive

```typescript
const drive = google.drive({ version: 'v3', auth: authClient });

// List files
const files = await drive.files.list({
    q: "mimeType='application/vnd.google-apps.spreadsheet' and name contains 'Report'",
    fields: 'files(id, name, createdTime)',
});

// Upload a file
const { Readable } = require('stream');
await drive.files.create({
    requestBody: {
        name: 'report.csv',
        parents: [FOLDER_ID],
    },
    media: {
        mimeType: 'text/csv',
        body: Readable.from(['col1,col2\nval1,val2']),
    },
});

// Share a file
await drive.permissions.create({
    fileId: FILE_ID,
    requestBody: {
        role: 'reader',  // or 'writer', 'commenter'
        type: 'anyone',  // or 'user', 'group', 'domain'
    },
});
```

## Gmail

```typescript
import { Buffer } from 'buffer';

const gmail = google.gmail({ version: 'v1', auth: authClient });

// Send email (requires domain-wide delegation for service accounts)
const message = [
    'To: recipient@example.com',
    'Subject: Report Ready',
    'Content-Type: text/html; charset=utf-8',
    '',
    '<p>Your report is ready.</p>',
].join('\n');

const encodedMessage = Buffer.from(message).toString('base64url');

await gmail.users.messages.send({
    userId: 'me',
    requestBody: { raw: encodedMessage },
});
```

## Apps Script (for lightweight automations)

```javascript
// Runs inside Google Apps Script editor (script.google.com)
// No auth setup needed — runs as the script owner

function syncSheetToDoc() {
    const sheet = SpreadsheetApp.getActiveSheet();
    const data = sheet.getDataRange().getValues();

    const doc = DocumentApp.openById(DOC_ID);
    const body = doc.getBody();
    body.clear();

    data.forEach(row => {
        body.appendParagraph(row.join(' | '));
    });
}

// Trigger: run daily at 9 AM
function setupTrigger() {
    ScriptApp.newTrigger('syncSheetToDoc')
        .timeBased().atHour(9).everyDays(1).create();
}
```

## Constraints

- Service account keys are highly sensitive — store in Secret Manager, not in `.env` files committed to git.
- Service accounts need explicit sharing to access Drive files owned by humans — share the specific file/folder with the service account email.
- Gmail sending from a service account requires G Suite domain-wide delegation — not available on personal Gmail.
- Rate limits: Sheets API is 300 reads/minute, 60 writes/minute — batch writes when possible.

# SlipDee

SlipDee is a minimal iOS personal finance app designed for Thai users to record income and expenses from bank slip images, manual transaction entries, and clean spending insights.

The app focuses on a simple, friendly, privacy-first experience for everyday expense tracking.

---

## App Concept

SlipDee helps users track daily income and expenses by importing Thai bank payment slip screenshots or adding transactions manually.

The core idea is simple:

> Import a slip, review the transaction, and save it into your personal spending record.

SlipDee is designed to feel:

- Minimal
- Clean
- Friendly
- Trustworthy
- Privacy-first
- Suitable for Thai users
- Easy to use on iPhone

---

## Key Features

### Manual Income and Expense Entry

Users can manually add transactions without scanning a slip.

Supported fields include:

- Transaction type: Income, Expense, Transfer
- Amount
- Date
- Category
- Payment method
- Merchant or receiver name
- Note

---

### Transaction List

SlipDee provides a clean transaction list where users can review saved records.

The transaction list includes:

- Amount
- Transaction type
- Merchant or receiver name
- Category
- Payment method
- Date and time

---

### Secure Edit and Delete

Saved transactions can be edited or deleted only after authentication.

Supported protection flow:

- Face ID / Touch ID where available
- App passcode fallback
- Final confirmation before deletion

This helps prevent accidental or unauthorized changes to financial records.

---

### Dashboard

The Home dashboard provides a simple overview of the user’s financial activity.

The dashboard may include:

- Monthly balance
- Income summary
- Expense summary
- Quick actions
  - Scan Slip
  - Add Manually
- Recent transactions
- Dynamic greeting based on local time

Example greetings:

- Good morning ☀️
- Good afternoon 🌤️
- Good evening 🌙
- Good night 🌙

---

### Reports

SlipDee includes spending insights to help users understand where their money goes.

Planned or implemented report features include:

- Monthly spending summary
- Category breakdown
- Donut chart for spending by category
- Top spending categories
- Simple visual insights

---

### Privacy-First Design

SlipDee is designed with privacy in mind.

The app aims to:

- Store user data locally first
- Avoid unnecessary cloud dependency
- Protect edit and delete actions
- Avoid storing sensitive banking credentials
- Never ask for bank account passwords

---

## Design Direction

SlipDee uses a minimal light theme inspired by modern iOS finance apps.

### Visual Style

- Light background
- White rounded cards
- Mint and teal accents
- Soft shadows
- Clean typography
- Simple SF Symbols-style icons
- No dark neon style
- No cyberpunk design

### Color Palette

| Purpose | Color |
|---|---|
| Background | `#F8FAFC` |
| Card | `#FFFFFF` |
| Primary Teal | `#14B8A6` |
| Soft Mint | `#CCFBF1` |
| Primary Text | `#0F172A` |
| Secondary Text | `#64748B` |
| Border | `#E2E8F0` |
| Income | `#16A34A` |
| Expense | `#F97373` |
| Warning | `#F59E0B` |

---

## Planned Roadmap

### Phase 1: Core App

- [x] App rename from SlipWise to SlipDee
- [x] Light minimal UI redesign
- [x] Manual income and expense entry
- [x] Transaction list
- [x] Edit existing transactions
- [x] Secure delete flow
- [ ] Dashboard summary from real transaction data
- [ ] Category spending donut chart

---

### Phase 2: Slip Scanner

- [ ] Import slip image from Photos
- [ ] Slip preview screen
- [ ] OCR text extraction
- [ ] OCR result confirmation screen
- [ ] Save scanned slip as transaction
- [ ] Store raw OCR text
- [ ] Store slip image metadata

---

### Phase 3: Thai Bank Slip Intelligence

- [ ] Thai bank slip parser
- [ ] KBank parser
- [ ] SCB parser
- [ ] Bangkok Bank parser
- [ ] Krungthai parser
- [ ] Krungsri parser
- [ ] PromptPay slip parser
- [ ] Generic Thai slip parser
- [ ] Duplicate slip detection

---

### Phase 4: Reports and Budget

- [ ] Monthly report
- [ ] Category breakdown
- [ ] Donut chart
- [ ] Spending trend chart
- [ ] Budget tracking
- [ ] Budget warning
- [ ] Export CSV
- [ ] Export PDF report

---

### Phase 5: Privacy and Backup

- [ ] Face ID / Touch ID app lock
- [ ] Hide sensitive information
- [ ] App passcode settings
- [ ] iCloud backup
- [ ] Data export and restore

---

## Data Models

SlipDee uses SwiftData-friendly models.

Main data models include:

- `TransactionItem`
- `TransactionCategory`
- `SlipRecord`
- `Budget`
- `MerchantRule`
- `UserSettings`

Supporting structs and enums include:

- `ParsedSlip`
- `MonthlySummary`
- `CategoryBreakdown`
- `DailySpending`
- `TransactionType`
- `PaymentMethod`
- `SlipScanStatus`
- `AppLockTimeout`

---

## Suggested Project Structure

```text
SlipDee
├── App
│   ├── SlipDeeApp.swift
│   └── AppRouter.swift
│
├── Core
│   ├── Models
│   ├── Services
│   ├── Utilities
│   ├── Theme
│   └── Components
│
├── Features
│   ├── Dashboard
│   ├── Transactions
│   ├── SlipScanner
│   ├── Reports
│   ├── Budgets
│   └── Settings

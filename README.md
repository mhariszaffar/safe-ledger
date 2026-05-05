this is my updated jira and task assignment, make changes in the readme only where required where jira tasks are swapped and for committs too keep everything else same


# 🏦 Safe Ledger — P2P Financial Transaction System

![Project](https://img.shields.io/badge/Project-DBMS%20CS--232-blue)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)
![University](https://img.shields.io/badge/University-GIKI-green)
![Jira](https://img.shields.io/badge/Tracked%20on-Jira-0052CC?logo=jira)
![Language](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)
![Database](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql)

A peer-to-peer financial transaction system built with a fully normalized relational database, ACID-compliant stored procedures, row-level locking, audit triggers, fraud detection views, and a live frontend UI.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
- [Architecture](#architecture)
- [Database Design](#database-design)
- [SQL Modules](#sql-modules)
- [Backend Modules](#backend-modules)
- [Performance Analysis](#performance-analysis)
- [File Structure](#file-structure)
- [Jira Task Tracking](#jira-task-tracking)
- [Git Workflow](#git-workflow)
- [Team](#team)

---

## Project Overview

Safe Ledger is a full-stack P2P financial transaction system developed as the semester project for **CS-232 Database Management Systems** at GIKI. The system demonstrates practical implementation of core DBMS concepts including schema normalization, ACID transactions, stored procedures, triggers, views, and fraud detection — all connected to a Node.js backend and a live frontend UI.

**Course Information:**
- Course: CS-232 — Database Management Systems
- Institution: Ghulam Ishaq Khan Institute of Engineering Sciences and Technology
- Semester: 4th Semester — Spring 2026

---

## Features

### Core Database Features
- Fully normalized relational schema (3NF)
- ACID-compliant `transfer_money()` stored procedure
- Row-level locking for concurrent UPDATE operations
- Audit log triggers on every transaction
- ROLLBACK logic for failed or invalid transactions
- Transaction history and wallet summary views
- Complex SQL queries for fraud detection
- Currency exchange with seeded exchange rates table
- P2P transfer flow integrated with stored procedures

### Backend Features
- RESTful API built with Node.js and Express.js
- Session-based user authentication
- Modular controller architecture
- Environment-based configuration via `.env`

### Frontend Features
- Core UI to demonstrate all database operations
- P2P transfer flow interface
- Currency exchange interface
- Built with HTML and Tailwind CSS

---

## System Requirements

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Node.js | v18.0 or higher |
| MySQL | 8.0 or higher |
| npm | 9.0 or higher |
| Git | 2.20 or higher |

### Recommended Tools
- IDE: Visual Studio Code
- Database Client: MySQL Workbench or DBeaver
- API Testing: Postman
- Terminal: PowerShell (Windows), Bash (Linux/macOS)

---

### Installation

### Step 1: Clone and Navigate
```bash
git clone [https://github.com/mhariszaffar/safe-ledger.git](https://github.com/mhariszaffar/safe-ledger.git)
cd SafeLedger2.0

cd backend
npm install
# Configure your .env based on .env.example
node server.js

---

## Usage Guide

### Main Operations

**Register a User**
- Navigate to the registration page
- Enter name, email, and password
- System creates wallet automatically

**Deposit Funds**
- Go to wallet section
- Enter deposit amount
- Transaction recorded with timestamp

**P2P Transfer**
- Enter recipient username or ID
- Enter amount to transfer
- System calls `transfer_money()` stored procedure with ACID compliance
- Both wallets update atomically — either both update or neither does

**View Transaction History**
- Dashboard shows full transaction history via `views.sql`
- Filter by date, type, or amount

**Currency Exchange**
- Select source and target currency
- System fetches live rate from exchange rates table
- Converts and records transaction

---

## Architecture

```
┌─────────────────────────────────────────┐
│           Frontend Layer                │
│         (frontend/index.html)           │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│           API / Routes Layer            │
│            (server.js)                  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│         Controllers Layer               │
│       (controllers/*.js)                │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│          Database Layer                 │
│    (MySQL + Stored Procedures)          │
└─────────────────────────────────────────┘
```

### Module Descriptions

| Module | File | Responsibility |
|--------|------|----------------|
| Schema | `schema.sql` | Table definitions, constraints, normalization |
| Transactions | `transactions.sql`, `transfer.sql` | ACID procedures, P2P logic |
| Integrity | `triggers.sql`, `locks.sql` | Audit logs, row-level locking |
| Analytics | `views.sql`, `queries.sql`, `fraud_detection.sql` | Reporting, fraud queries |
| Server | `server.js` | Express setup, route mounting |
| Auth | `authController.js` | Login, session, access control |
| Admin | `adminController.js` | System-level controls |
| Transactions | `transactionController.js` | Transaction API handlers |
| Wallet | `walletController.js`, `depositController.js`, `withdrawalController.js` | Wallet operations |
| Analytics | `fraudDetection.js`, `exchangeController.js` | Fraud API, exchange API |

---

## Database Design

### Normalization
The schema is normalized to **Third Normal Form (3NF)**:
- 1NF: All attributes are atomic, no repeating groups
- 2NF: No partial dependencies on composite keys
- 3NF: No transitive dependencies

### Tables
| Table | Description |
|-------|-------------|
| `users` | Registered user accounts |
| `wallets` | User wallet balances |
| `transactions` | All transaction records |
| `transfers` | P2P transfer logs |
| `exchange_rates` | Currency exchange rate data |
| `audit_log` | Trigger-generated audit trail |
| `sessions` | Active user sessions |
| `fraud_flags` | Flagged suspicious transactions |

### Risk & Integrity Rules
- All monetary operations wrapped in transactions with ROLLBACK on failure
- Row-level locks applied on wallet rows during UPDATE
- Every insert/update/delete on `transactions` fires an audit trigger
- Duplicate transfer detection via stored procedure checks

---

## SQL Modules

### ACID Transfer Procedure
```sql
-- transfer_money(sender_id, receiver_id, amount)
-- Atomically debits sender and credits receiver
-- Rolls back entirely if any step fails
```

### Audit Trigger
```sql
-- Fires on every INSERT into transactions table
-- Logs: user_id, action, timestamp, old_value, new_value
-- Written to audit_log table
```

### Fraud Detection Query
```sql
-- Flags transactions where:
-- Same user transfers > 3 times in 10 minutes
-- Transfer amount exceeds wallet balance threshold
-- IP mismatch detected on session
```

### Views
```sql
-- transaction_history_view: full log per user
-- wallet_summary_view: current balance + total in/out
```

---

## Backend Modules

### Controllers & Complexity

| Controller | Key Functions | Complexity |
|------------|--------------|------------|
| `userController.js` | `createUser`, `getUser` | O(1) DB lookup |
| `transactionController.js` | `getHistory`, `initiateTransfer` | O(n) for history |
| `depositController.js` | `deposit` | O(1) |
| `withdrawalController.js` | `withdraw` | O(1) |
| `walletController.js` | `getBalance`, `updateWallet` | O(1) |
| `authController.js` | `login`, `logout`, `validateSession` | O(1) |
| `adminController.js` | `getUsers`, `flagUser` | O(n) |
| `fraudDetection.js` | `checkFraud`, `getFlaggedTransactions` | O(n) |
| `exchangeController.js` | `getRate`, `convertCurrency` | O(1) |

---

## Performance Analysis

### Query Complexity

| Operation | Best Case | Average Case | Worst Case |
|-----------|-----------|--------------|------------|
| User lookup | O(1) | O(1) | O(log n) |
| Transfer | O(1) | O(1) | O(1) |
| Transaction history | O(1) | O(n) | O(n) |
| Fraud detection query | O(n) | O(n) | O(n²) |
| Exchange rate fetch | O(1) | O(1) | O(1) |
| Audit log insert | O(1) | O(1) | O(1) |

### Known Bottlenecks
- Fraud detection query scans full transaction table — index on `user_id` and `created_at` recommended for large datasets
- Transaction history view unoptimized for users with 10,000+ records — pagination required

---

## File Structure

```
SafeLedger2.0/
├── backend/                   # Core Logic Layer
│   ├── config/                # DB Configuration & SQL Scripts
│   │   ├── database.js
│   │   ├── schema.sql         # Table definitions
│   │   └── migrations.sql     # Seed data
│   ├── controllers/           # API Handlers
│   │   ├── authController.js
│   │   ├── transactionController.js
│   │   └── ... (wallet, deposit, etc.)
│   ├── middlewares/           # Auth & Fraud Logic
│   │   ├── auth.js
│   │   └── fraudDetection.js
│   ├── routes/                # Express Route Definitions
│   ├── scripts/               # Utility scripts (Reset Admin, etc.)
│   ├── utils/                 # Response helpers
│   ├── server.js              # Entry point
│   └── .env                   # Environment variables
├── dist/                      # Frontend Build Assets (Vite)
│   ├── assets/                # Optimized JS/CSS and Images
│   └── index.html
├── index.html                 # Main Frontend Entry
└── package.json
```

---

## Jira Task Tracking

All tasks tracked on Jira under project **KAN** — Safe Ledger: P2P Financial Transaction System.

| Phase | KAN Tasks | Description |
|-------|-----------|-------------|
| Phase 1 — Planning | KAN-26, KAN-27 | Project scope, ER diagram |
| Phase 2 — Schema | KAN-28, KAN-29, KAN-30 | Normalization, DDL, seeding |
| Phase 3 — Core SQL | KAN-31 to KAN-36 | ACID, deposit/withdrawal, locks, triggers, views, ROLLBACK |
| Phase 4 — Analytics | KAN-37 | Fraud detection queries |
| Phase 5 — Backend | KAN-38, KAN-39, KAN-40 | Constraints testing, server setup, auth |
| Phase 6 — Integration | KAN-41, KAN-42, KAN-43 | UI, P2P flow, currency exchange |
| Phase 7 — Testing | KAN-44, KAN-45, KAN-46 | API testing, bug fixes, documentation |

🔗 [View Jira Board](https://safeledger.atlassian.net/jira/software/projects/KAN/list)

---

## Git Workflow

Each member works on their own branch and opens a Pull Request for review before merging into main.

```
ibrahim-schema      → KAN-28, KAN-29  (schema, DDL)
naqi-transactions   → KAN-30, KAN-31  (seeding, ACID transfer)
gulzar-integrity    → KAN-32, KAN-36  (deposit/withdrawal, ROLLBACK)
gulzar-integrity-2  → KAN-42, KAN-45  (P2P flow, bug fixes)
naqi-controllers    → KAN-37, KAN-39  (fraud queries, backend)
ibrahim-backend     → KAN-38, KAN-40  (constraints testing, auth)
haris-analytics     → KAN-33, KAN-34, KAN-35 (locks, triggers, views)
haris-controllers   → KAN-43          (exchange controller)
haris-frontend      → KAN-41          (core UI)
haris-final         → KAN-44, KAN-46  (API testing, documentation)
```

**Rule: Never push directly to main. Always branch → commit with KAN number → pull request.**

---

## 👥 Group Members

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/mhariszaffar">
        <img src="https://github.com/mhariszaffar.png" width="100px;" alt="Haris"/>
        <br />
        <b>Muhammad Haris Zafar</b>
      </a>
      <br />
      <a href="https://github.com/mhariszaffar">github.com/mhariszaffar</a>
    </td>
    <td align="center">
      <a href="https://github.com/ibrahimcys">
        <img src="https://github.com/ibrahimcys.png" width="100px;" alt="Ibrahim"/>
        <br />
        <b>Muhammad Ibrahim</b>
      </a>
      <br />
      <a href="https://github.com/ibrahimcys">github.com/ibrahimcys</a>
    </td>
    <td align="center">
      <a href="https://github.com/naqi005">
        <img src="https://github.com/naqi005.png" width="100px;" alt="Naqi"/>
        <br />
        <b>Muhammad Naqi Afaq</b>
      </a>
      <br />
      <a href="https://github.com/naqi005">github.com/naqi005</a>
    </td>
    <td align="center">
      <a href="https://github.com/ibrahim-gulzar-11">
        <img src="https://github.com/ibrahim-gulzar-11.png" width="100px;" alt="Gulzar"/>
        <br />
        <b>Muhammad Ibrahim Gulzar</b>
      </a>
      <br />
      <a href="https://github.com/ibrahim-gulzar-11">github.com/ibrahim-gulzar-11</a>
    </td>
  </tr>
</table>
## Academic Information

- **Course**: CS-232 — Database Management Systems
- **Institution**: Ghulam Ishaq Khan Institute of Engineering Sciences and Technology (GIKI)
- **Semester**: 4th Semester — Spring 2026
- **Project**: Safe Ledger — P2P Financial Transaction System


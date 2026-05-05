# 🏦 Safe Ledger — P2P Financial Transaction System

![Project](https://img.shields.io/badge/Project-DBMS%20CS--232-blue)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)
![University](https://img.shields.io/badge/University-GIKI-green)
![Jira](https://img.shields.io/badge/Tracked%20on-Jira-0052CC?logo=jira)
![Language](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)
![Database](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql)

A peer-to-peer financial transaction system built with a fully normalized relational database, ACID-compliant stored procedures, row-level locking, audit triggers, fraud detection views, and a live frontend UI.

---

## Jira Task Tracking

All tasks tracked on Jira under project **KAN** — Safe Ledger: P2P Financial Transaction System.

| Phase | KAN Tasks | Description |
|-------|-----------|-------------|
| Phase 1 — Planning | KAN-26, KAN-27 | Project scope, ER diagram |
| Phase 2 — Schema | KAN-28, KAN-29 | Normalization, DDL |
| Phase 3 — Core SQL | KAN-31, KAN-32, KAN-33, KAN-34, KAN-35, KAN-36 | ACID, deposit/withdrawal, locks, triggers, views, ROLLBACK |
| Phase 4 — Analytics | KAN-37 | Fraud detection queries |
| Phase 5 — Backend | KAN-38, KAN-39, KAN-40 | Testing, server setup, authentication |
| Phase 6 — Integration | KAN-41, KAN-42, KAN-43 | UI, auth integration, currency exchange |
| Phase 7 — Testing | KAN-45, KAN-46 | Bug fixes, API testing |

---

## Git Workflow

Each member works on their own branch and opens a Pull Request for review before merging into main.

ibrahim-schema      → KAN-28, KAN-29  (schema, DDL)  
naqi-transactions   → KAN-31, KAN-32  (ACID transfer, deposit/withdrawal)  
gulzar-integrity    → KAN-33, KAN-34, KAN-36  (locks, triggers, rollback)  
haris-analytics     → KAN-35, KAN-37  (views, fraud queries)  
naqi-testing        → KAN-38          (account testing)  
ibrahim-backend     → KAN-39, KAN-40  (server setup, authentication)  
haris-frontend      → KAN-41          (core UI)  
gulzar-auth         → KAN-42          (authentication integration)  
haris-exchange      → KAN-43          (currency exchange)  
gulzar-bugfix       → KAN-45          (final bug fixes)  
haris-final         → KAN-46          (API testing/routes)  

**Rule: Never push directly to main. Always branch → commit with KAN number → pull request.**

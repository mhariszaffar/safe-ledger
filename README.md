# 🏦 Safe Ledger — P2P Financial Transaction System ![Project](https://img.shields.io/badge/Project-DBMS%20CS--232-blue) ![Status](https://img.shields.io/badge/Status-In%20Progress-yellow) ![University](https://img.shields.io/badge/University-GIKI-green) ![Jira](https://img.shields.io/badge/Tracked%20on-Jira-0052CC?logo=jira) ![Language](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js) ![Database](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql) A peer-to-peer financial transaction system built with a fully normalized relational database, ACID-compliant stored procedures, row-level locking, audit triggers, fraud detection views, and a live frontend UI. --- ## 📋 Table of Contents - [Project Overview](#project-overview) - [Features](#features) - [System Requirements](#system-requirements) - [Installation](#installation) - [Usage Guide](#usage-guide) - [Architecture](#architecture) - [Database Design](#database-design) - [SQL Modules](#sql-modules) - [Backend Modules](#backend-modules) - [Performance Analysis](#performance-analysis) - [File Structure](#file-structure) - [Jira Task Tracking](#jira-task-tracking) - [Git Workflow](#git-workflow) - [Team](#team) --- ## Project Overview Safe Ledger is a full-stack P2P financial transaction system developed as the semester project for **CS-232 Database Management Systems** at GIKI. The system demonstrates practical implementation of core DBMS concepts including schema normalization, ACID transactions, stored procedures, triggers, views, and fraud detection — all connected to a Node.js backend and a live frontend UI. **Course Information:** - Course: CS-232 — Database Management Systems - Institution: Ghulam Ishaq Khan Institute of Engineering Sciences and Technology - Semester: 4th Semester — Spring 2026 --- ## Features ### Core Database Features - Fully normalized relational schema (3NF) - ACID-compliant transfer_money() stored procedure - Row-level locking for concurrent UPDATE operations - Audit log triggers on every transaction - ROLLBACK logic for failed or invalid transactions - Transaction history and wallet summary views - Complex SQL queries for fraud detection - Currency exchange with seeded exchange rates table - P2P transfer flow integrated with stored procedures ### Backend Features - RESTful API built with Node.js and Express.js - Session-based user authentication - Modular controller architecture - Environment-based configuration via .env ### Frontend Features - Core UI to demonstrate all database operations - P2P transfer flow interface - Currency exchange interface - Built with HTML and Tailwind CSS --- ## System Requirements ### Prerequisites | Requirement | Version | |-------------|---------| | Node.js | v18.0 or higher | | MySQL | 8.0 or higher | | npm | 9.0 or higher | | Git | 2.20 or higher | ### Recommended Tools - IDE: Visual Studio Code - Database Client: MySQL Workbench or DBeaver - API Testing: Postman - Terminal: PowerShell (Windows), Bash (Linux/macOS) ---
## Jira Task Tracking

All tasks tracked on Jira under project **KAN** — Safe Ledger: P2P Financial Transaction System.

| Phase | KAN Tasks | Description |
|-------|-----------|-------------|
| Phase 1 | KAN-26, 27 | Planning & ER Diagrams |
| Phase 2 | KAN-28, 29 | Schema Normalization (3NF) |
| Phase 3 | KAN-31–36 | Core SQL (ACID, Triggers, Locks) |
| Phase 4 | KAN-37 | Fraud Detection Analytics |
| Phase 5 | KAN-38–40 | Backend Development & Auth |
| Phase 6 | KAN-41–43 | UI Integration & Currency Exchange |

---

## 👥 Group Members <table> <tr> <td align="center"> <a href="https://github.com/mhariszaffar"> <img src="https://github.com/mhariszaffar.png" width="100px;" alt="Haris"/> <br /> <b>Muhammad Haris Zafar</b> </a> <br /> <a href="https://github.com/mhariszaffar">github.com/mhariszaffar</a> </td> <td align="center"> <a href="https://github.com/ibrahimcys"> <img src="https://github.com/ibrahimcys.png" width="100px;" alt="Ibrahim"/> <br /> <b>Muhammad Ibrahim</b> </a> <br /> <a href="https://github.com/ibrahimcys">github.com/ibrahimcys</a> </td> <td align="center"> <a href="https://github.com/naqi005"> <img src="https://github.com/naqi005.png" width="100px;" alt="Naqi"/> <br /> <b>Muhammad Naqi Afaq</b> </a> <br /> <a href="https://github.com/naqi005">github.com/naqi005</a> </td> <td align="center"> <a href="https://github.com/ibrahim-gulzar-11"> <img src="https://github.com/ibrahim-gulzar-11.png" width="100px;" alt="Gulzar"/> <br /> <b>Muhammad Ibrahim Gulzar</b> </a> <br /> <a href="https://github.com/ibrahim-gulzar-11">github.com/ibrahim-gulzar-11</a> </td> </tr> </table>
---

### Final Steps to Push:
1. **Navigate to the root:** `cd "C:\Users\Hp\Desktop\STUDY\S-4\Projects\CS-232 (DBMS)\DBMS-Project\SafeLedger2.0"`
2. **Stage the update:** `git add .`
3. **Commit:** `git commit -m "Update README with new SafeLedger2.0 file structure"`
4. **Push:** `git push origin main`

I noticed you have a `resetAdmin.js` scriptBased on your project's new structure in **SafeLedger2.0**, I have updated your **README.md** to reflect the current file organization, specifically moving backend files into the `backend/` directory and including your Vite-based frontend assets.

You can copy and paste the updated content below:

---

# 🏦 Safe Ledger — P2P Financial Transaction System

![Project](https://img.shields.io/badge/Project-DBMS%20CS--232-blue)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)
![University](https://img.shields.io/badge/University-GIKI-green)
![Jira](https://img.shields.io/badge/Tracked%20on-Jira-0052CC?logo=jira)
![Backend](https://img.shields.io/badge/Backend-Node.js-339933?logo=node.js)
![Database](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql)

A peer-to-peer financial transaction system built with a fully normalized relational database, ACID-compliant stored procedures, row-level locking, audit triggers, fraud detection views, and a live frontend UI.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Installation](#installation)
- [System Architecture](#system-architecture)
- [New File Structure](#file-structure)
- [Jira Task Tracking](#jira-task-tracking)
- [Team](#team)

---

## Project Overview

Safe Ledger is a full-stack P2P financial transaction system developed as the semester project for **CS-232 Database Management Systems** at GIKI. The system demonstrates practical implementation of core DBMS concepts including schema normalization, ACID transactions, stored procedures, triggers, views, and fraud detection.

**Course Information:**
- Course: CS-232 — Database Management Systems
- Institution: Ghulam Ishaq Khan Institute of Engineering Sciences and Technology
- Semester: 4th Semester — Spring 2026

---

## Features

- **ACID Transfers:** atomic `transfer_money()` stored procedure ensures data integrity.
- **Security:** Row-level locking for concurrent updates and automated audit triggers.
- **Analytics:** Fraud detection queries and reporting views for transaction history.
- **Modern Backend:** Modular Node.js/Express architecture with session management.
- **Responsive UI:** Built with Vite and Tailwind CSS.

---


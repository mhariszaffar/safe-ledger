-- ============================================================
--  SafeLedger — Database Normalization Analysis
--  Owner: Muhammad Ibrahim (Schema & Normalization)
-- ============================================================
--  This file documents how the SafeLedger schema satisfies
--  1NF, 2NF, and 3NF normalization rules, and explains the
--  design decisions behind each table structure.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  FIRST NORMAL FORM (1NF)
--  Rule: Each column holds atomic (indivisible) values.
--        No repeating groups. Each row is unique.
--
--  How SafeLedger satisfies 1NF:
--
--  1. All currency values are stored as a single NUMERIC(20,8)
--     per wallet row — not as a comma-separated list.
--
--  2. Multiple currencies per user are separate rows in
--     wallets (one row per currency), not one row with
--     columns like balance_usd, balance_pkr, balance_eur.
--
--  3. Every table has a UUID primary key ensuring row uniqueness.
--
--  4. JSONB columns (metadata, details) store structured data
--     but are treated as a single atomic value per row.
--     They are read/written as a whole — not queried as
--     individual repeating columns.
-- ─────────────────────────────────────────────────────────────

-- Bad design (violates 1NF) — do NOT do this:
-- CREATE TABLE wallets_bad (
--     user_id       UUID,
--     balance_usd   NUMERIC,
--     balance_pkr   NUMERIC,
--     balance_eur   NUMERIC   -- adding currencies requires schema change
-- );

-- Good design (satisfies 1NF):
-- CREATE TABLE wallets (
--     wallet_id     UUID PRIMARY KEY,
--     user_id       UUID,
--     currency_type VARCHAR(10),
--     balance       NUMERIC(20,8)  -- one atomic value per row
-- );

-- ─────────────────────────────────────────────────────────────
--  SECOND NORMAL FORM (2NF)
--  Rule: Must be in 1NF. Every non-key attribute must depend
--        on the WHOLE primary key (relevant for composite PKs).
--
--  How SafeLedger satisfies 2NF:
--
--  All tables use a single-column UUID primary key, so 2NF
--  partial dependency cannot occur. Each non-key column
--  depends on the entire (single) primary key.
--
--  Example — wallets table:
--    PK: wallet_id
--    balance depends on wallet_id (not on user_id or currency alone)
--    status  depends on wallet_id
--    All columns depend fully on wallet_id ✓
-- ─────────────────────────────────────────────────────────────

-- Verify: wallets has a single UUID PK (no composite keys)
SELECT
    kcu.table_name,
    kcu.column_name,
    tc.constraint_type
FROM information_schema.key_column_usage kcu
JOIN information_schema.table_constraints tc
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND kcu.table_schema   = 'public'
ORDER BY kcu.table_name;

-- ─────────────────────────────────────────────────────────────
--  THIRD NORMAL FORM (3NF)
--  Rule: Must be in 2NF. No transitive dependencies —
--        non-key attributes must not depend on other
--        non-key attributes.
--
--  How SafeLedger satisfies 3NF:
--
--  1. User information (name, email, role) lives only in users.
--     wallets stores user_id (FK), not the user's name or email.
--     If a user changes their name, only users is updated.
--
--  2. Currency rates live only in exchange_rates.
--     transactions stores the rate at time of exchange in
--     metadata JSONB (for historical record), but never
--     stores a rate as a queryable foreign key.
--
--  3. Wallet status lives only in wallets.
--     transactions does not store the wallet's status at
--     the time of the transaction — that's enforced by
--     the stored procedure before the transaction records.
--
--  4. Session data (ip, device, expiry) lives in user_sessions,
--     separate from users — no transitive dependency.
-- ─────────────────────────────────────────────────────────────

-- Example of a 3NF violation (do NOT do this):
-- CREATE TABLE transactions_bad (
--     transaction_id UUID PRIMARY KEY,
--     from_wallet_id UUID,
--     sender_email   VARCHAR,  -- ← depends on from_wallet_id → users,
--     sender_name    VARCHAR,  --   not on transaction_id directly
--     amount         NUMERIC
-- );

-- Correct 3NF design (look up sender email via JOIN when needed):
-- SELECT t.*, u.email AS sender_email
-- FROM transactions t
-- JOIN wallets w ON w.wallet_id = t.from_wallet_id
-- JOIN users   u ON u.user_id   = w.user_id;

-- ─────────────────────────────────────────────────────────────
--  TABLE DEPENDENCY GRAPH
--
--  users
--    └─< wallets (user_id FK)
--          └─< transactions (from_wallet_id, to_wallet_id FK)
--          └─< deposits     (wallet_id FK)
--          └─< withdrawals  (wallet_id FK)
--    └─< user_sessions (user_id FK)
--    └─< audit_log     (user_id FK, optional)
--
--  transactions
--    └─< audit_log (transaction_id FK, optional)
--
--  exchange_rates (standalone — no FK dependencies)
-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
--  REFERENTIAL INTEGRITY SUMMARY
--  All FK relationships and their ON DELETE behaviour
-- ─────────────────────────────────────────────────────────────
SELECT
    tc.table_name               AS child_table,
    kcu.column_name             AS child_column,
    ccu.table_name              AS parent_table,
    ccu.column_name             AS parent_column,
    rc.delete_rule              AS on_delete
FROM information_schema.table_constraints    tc
JOIN information_schema.key_column_usage     kcu ON kcu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints rc ON rc.constraint_name = tc.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = rc.unique_constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema    = 'public'
ORDER BY tc.table_name;
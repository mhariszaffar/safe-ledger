-- ============================================================
--  SafeLedger — Transactions Table Definition
--  Owner: Naqi (Core Transactions & ACID)
-- ============================================================

-- The central ledger table. Every single movement of money
-- in the system creates one row here — transfers, exchanges,
-- deposits, and withdrawals. Rows are never deleted.

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_wallet_id   UUID REFERENCES wallets(wallet_id),
    to_wallet_id     UUID REFERENCES wallets(wallet_id),
    amount           NUMERIC(20,8) NOT NULL
                     CHECK (amount > 0),
    transaction_type VARCHAR(20)  NOT NULL
                     CHECK (transaction_type IN ('transfer','deposit','withdrawal','exchange')),
    status           VARCHAR(20)  NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','success','failed')),
    metadata         JSONB        NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_txn_from_wallet ON transactions(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_txn_to_wallet   ON transactions(to_wallet_id);
CREATE INDEX IF NOT EXISTS idx_txn_created_at  ON transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_txn_status      ON transactions(status);

-- ─────────────────────────────────────────────────────────────
--  ACID Guarantees on this table:
--
--  Atomicity   — every balance change + transaction insert
--                happens inside a stored procedure BEGIN/COMMIT
--
--  Consistency — CHECK constraints ensure amount > 0, status
--                and type are always valid values
--
--  Isolation   — FOR UPDATE locks in stored procedures prevent
--                concurrent reads of stale balances
--
--  Durability  — PostgreSQL WAL ensures committed rows survive
--                server restarts
-- ─────────────────────────────────────────────────────────────

-- Deposit records (from_wallet_id is NULL — money comes from outside)
-- Example:
-- INSERT INTO transactions (to_wallet_id, amount, transaction_type, status, metadata)
-- VALUES ('uuid...', 500.00, 'deposit', 'pending', '{"source": "manual"}');

-- Withdrawal records (to_wallet_id is NULL — money leaves the system)
-- Example:
-- INSERT INTO transactions (from_wallet_id, amount, transaction_type, status, metadata)
-- VALUES ('uuid...', 200.00, 'withdrawal', 'pending', '{"destination": "bank"}');

-- Transfer records (both wallets present, same currency)
-- Example:
-- INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, transaction_type, status)
-- VALUES ('uuid_a', 'uuid_b', 100.00, 'transfer', 'pending');

-- Exchange records (both wallets present, different currencies)
-- Metadata stores the rate and converted amount:
-- Example:
-- INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, transaction_type, status, metadata)
-- VALUES ('uuid_usd', 'uuid_pkr', 50.00, 'exchange', 'pending',
--         '{"exchange_rate": 278.5, "converted_amount": 13925.0, "from_currency": "USD", "to_currency": "PKR"}');

-- ============================================================
--  SafeLedger — Constraints Reference
--  Owner: Ibrahim Gulzar (Integrity, Locks, Triggers)
-- ============================================================
--  Documents all CHECK, UNIQUE, NOT NULL, and FK constraints
--  enforced at the database level across all 8 tables.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  TABLE: users
-- ─────────────────────────────────────────────────────────────
ALTER TABLE users
    ADD CONSTRAINT chk_users_role
        CHECK (role IN ('user', 'admin'));

-- NOT NULL: name, email, password_hash, role, is_active, created_at
-- UNIQUE:   email
-- DEFAULT:  role = 'user', is_active = true, created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: wallets
-- ─────────────────────────────────────────────────────────────
ALTER TABLE wallets
    ADD CONSTRAINT chk_wallets_balance
        CHECK (balance >= 0),
    ADD CONSTRAINT chk_wallets_status
        CHECK (status IN ('active', 'frozen', 'closed'));

-- NOT NULL: user_id, currency_type, balance, status, created_at
-- UNIQUE:   (user_id, currency_type) — one wallet per currency per user
-- FK:       user_id → users(user_id) ON DELETE CASCADE
-- DEFAULT:  balance = 0, status = 'active', created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: transactions
-- ─────────────────────────────────────────────────────────────
ALTER TABLE transactions
    ADD CONSTRAINT chk_txn_amount
        CHECK (amount > 0),
    ADD CONSTRAINT chk_txn_type
        CHECK (transaction_type IN ('transfer', 'deposit', 'withdrawal', 'exchange')),
    ADD CONSTRAINT chk_txn_status
        CHECK (status IN ('pending', 'success', 'failed'));

-- NOT NULL: amount, transaction_type, status, metadata, created_at
-- FK:       from_wallet_id → wallets(wallet_id) (nullable for deposits)
--           to_wallet_id   → wallets(wallet_id) (nullable for withdrawals)
-- DEFAULT:  status = 'pending', metadata = '{}', created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: exchange_rates
-- ─────────────────────────────────────────────────────────────
ALTER TABLE exchange_rates
    ADD CONSTRAINT chk_rates_positive
        CHECK (rate > 0);

-- NOT NULL: from_currency, to_currency, rate, updated_at
-- UNIQUE:   (from_currency, to_currency) — one rate per directional pair
-- DEFAULT:  updated_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: audit_log
-- ─────────────────────────────────────────────────────────────
-- NOT NULL: action, details, timestamp
-- FK:       transaction_id → transactions(transaction_id) (nullable)
--           user_id        → users(user_id) (nullable)
-- DEFAULT:  details = '{}', timestamp = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: user_sessions
-- ─────────────────────────────────────────────────────────────
-- NOT NULL: user_id, token_hash, is_active, created_at, expires_at
-- FK:       user_id → users(user_id) ON DELETE CASCADE
-- DEFAULT:  is_active = true, created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: deposits
-- ─────────────────────────────────────────────────────────────
ALTER TABLE deposits
    ADD CONSTRAINT chk_deposits_amount
        CHECK (amount > 0),
    ADD CONSTRAINT chk_deposits_status
        CHECK (status IN ('pending', 'completed', 'failed'));

-- NOT NULL: wallet_id, amount, method, status, metadata, created_at
-- FK:       wallet_id → wallets(wallet_id) ON DELETE CASCADE
-- DEFAULT:  method = 'manual', status = 'pending', metadata = '{}', created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  TABLE: withdrawals
-- ─────────────────────────────────────────────────────────────
ALTER TABLE withdrawals
    ADD CONSTRAINT chk_withdrawals_amount
        CHECK (amount > 0),
    ADD CONSTRAINT chk_withdrawals_status
        CHECK (status IN ('pending', 'completed', 'failed'));

-- NOT NULL: wallet_id, amount, method, status, metadata, created_at
-- FK:       wallet_id → wallets(wallet_id) ON DELETE CASCADE
-- DEFAULT:  method = 'manual', status = 'pending', metadata = '{}', created_at = NOW()

-- ─────────────────────────────────────────────────────────────
--  To verify all constraints in a running database:
--
--  SELECT table_name, constraint_name, constraint_type
--    FROM information_schema.table_constraints
--   WHERE table_schema = 'public'
--   ORDER BY table_name, constraint_type;
-- ─────────────────────────────────────────────────────────────
-- ============================================================
--  SafeLedger — Database Triggers
--  Owner: Ibrahim Gulzar (Integrity, Locks, Triggers)
-- ============================================================
--  3 triggers providing automatic data integrity enforcement:
--
--  1. trg_prevent_negative_balance  — blocks any balance < 0
--  2. trg_wallet_status_change      — auto-audits status changes
--  3. trg_transaction_failure       — auto-audits failed txns
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  TRIGGER 1: Prevent Negative Balance
--  Fires: BEFORE UPDATE OF balance ON wallets (per row)
--
--  Purpose: Last-resort failsafe on top of the CHECK constraint.
--  Even if application code somehow sends an UPDATE that would
--  produce a negative balance, this trigger catches it and
--  raises an exception, rolling back the entire transaction.
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_prevent_negative_balance()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.balance < 0 THEN
        RAISE EXCEPTION
            'NEGATIVE_BALANCE: wallet % cannot have balance %',
            NEW.wallet_id, NEW.balance;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_negative_balance ON wallets;
CREATE TRIGGER trg_prevent_negative_balance
    BEFORE UPDATE OF balance ON wallets
    FOR EACH ROW EXECUTE FUNCTION fn_prevent_negative_balance();

-- ─────────────────────────────────────────────────────────────
--  TRIGGER 2: Auto-Audit Wallet Status Changes
--  Fires: AFTER UPDATE OF status ON wallets (per row)
--
--  Purpose: Any time a wallet is frozen, unfrozen, or closed —
--  whether by the user or an admin — this trigger automatically
--  writes a record to audit_log. No controller needs to
--  remember to log this; the database enforces it.
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_log_wallet_status_change()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO audit_log (user_id, action, details)
        VALUES (
            NEW.user_id,
            'WALLET_STATUS_CHANGED',
            jsonb_build_object(
                'wallet_id',   NEW.wallet_id,
                'currency',    NEW.currency_type,
                'old_status',  OLD.status,
                'new_status',  NEW.status
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_wallet_status_change ON wallets;
CREATE TRIGGER trg_wallet_status_change
    AFTER UPDATE OF status ON wallets
    FOR EACH ROW EXECUTE FUNCTION fn_log_wallet_status_change();

-- ─────────────────────────────────────────────────────────────
--  TRIGGER 3: Auto-Audit Failed Transactions
--  Fires: AFTER UPDATE OF status ON transactions (per row)
--
--  Purpose: Whenever a transaction transitions from 'pending'
--  to 'failed', this trigger writes a record to audit_log.
--  Failed transactions are just as important to record as
--  successful ones — they may indicate attempted fraud or
--  bugs in the system.
-- ─────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_log_transaction_failure()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.status = 'pending' AND NEW.status = 'failed' THEN
        INSERT INTO audit_log (transaction_id, action, details)
        VALUES (
            NEW.transaction_id,
            'TRANSACTION_FAILED',
            jsonb_build_object(
                'type',   NEW.transaction_type,
                'amount', NEW.amount
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_transaction_failure ON transactions;
CREATE TRIGGER trg_transaction_failure
    AFTER UPDATE OF status ON transactions
    FOR EACH ROW EXECUTE FUNCTION fn_log_transaction_failure();

-- ─────────────────────────────────────────────────────────────
--  To verify triggers are installed:
--    SELECT trigger_name, event_manipulation, event_object_table
--    FROM information_schema.triggers
--    WHERE trigger_schema = 'public'
--    ORDER BY event_object_table;
-- ─────────────────────────────────────────────────────────────

-- ============================================================
--  SafeLedger — transfer_money() Stored Procedure
--  Owner: Naqi (Core Transactions & ACID)
-- ============================================================
--
--  Handles the complete ACID lifecycle of a peer-to-peer transfer:
--    BEGIN → lock rows (deadlock-safe order) → validate →
--    deduct → credit → mark success → audit → COMMIT
--    On any error: automatic ROLLBACK
-- ============================================================

CREATE OR REPLACE FUNCTION transfer_money(
    p_from_wallet_id  UUID,
    p_to_wallet_id    UUID,
    p_amount          NUMERIC(20,8),
    p_initiated_by    UUID
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_txn_id        UUID;
    v_from_balance  NUMERIC(20,8);
    v_from_status   VARCHAR(20);
    v_to_status     VARCHAR(20);
    v_from_currency VARCHAR(10);
    v_to_currency   VARCHAR(10);
BEGIN
    -- ─────────────────────────────────────────────────────────
    --  DEADLOCK PREVENTION:
    --  Always acquire locks in UUID sort order regardless of
    --  which wallet is sender/receiver.
    --
    --  Without this: Transfer A→B and Transfer B→A arriving
    --  simultaneously could each hold one lock and wait for
    --  the other → deadlock.
    --
    --  With this: both transactions try to lock the
    --  smaller UUID first → one waits → no deadlock.
    -- ─────────────────────────────────────────────────────────
    IF p_from_wallet_id < p_to_wallet_id THEN
        SELECT balance, status, currency_type
          INTO v_from_balance, v_from_status, v_from_currency
          FROM wallets WHERE wallet_id = p_from_wallet_id FOR UPDATE;

        SELECT status, currency_type
          INTO v_to_status, v_to_currency
          FROM wallets WHERE wallet_id = p_to_wallet_id FOR UPDATE;
    ELSE
        SELECT status, currency_type
          INTO v_to_status, v_to_currency
          FROM wallets WHERE wallet_id = p_to_wallet_id FOR UPDATE;

        SELECT balance, status, currency_type
          INTO v_from_balance, v_from_status, v_from_currency
          FROM wallets WHERE wallet_id = p_from_wallet_id FOR UPDATE;
    END IF;

    -- ─────────────────────────────────────────────────────────
    --  VALIDATIONS
    -- ─────────────────────────────────────────────────────────
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Wallet not found';
    END IF;

    IF p_from_wallet_id = p_to_wallet_id THEN
        RAISE EXCEPTION 'Cannot transfer to the same wallet';
    END IF;

    IF v_from_status <> 'active' THEN
        RAISE EXCEPTION 'Source wallet is not active (status: %)', v_from_status;
    END IF;

    IF v_to_status <> 'active' THEN
        RAISE EXCEPTION 'Destination wallet is not active (status: %)', v_to_status;
    END IF;

    IF v_from_currency <> v_to_currency THEN
        RAISE EXCEPTION 'Currency mismatch — use /exchange for cross-currency transfers';
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance: available %, required %',
            v_from_balance, p_amount;
    END IF;

    -- ─────────────────────────────────────────────────────────
    --  INSERT PENDING TRANSACTION RECORD
    -- ─────────────────────────────────────────────────────────
    INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, transaction_type, status)
    VALUES (p_from_wallet_id, p_to_wallet_id, p_amount, 'transfer', 'pending')
    RETURNING transaction_id INTO v_txn_id;

    -- ─────────────────────────────────────────────────────────
    --  EXECUTE BALANCE CHANGES
    --  The trg_prevent_negative_balance trigger fires here
    --  as a last-resort safety net.
    -- ─────────────────────────────────────────────────────────
    UPDATE wallets SET balance = balance - p_amount WHERE wallet_id = p_from_wallet_id;
    UPDATE wallets SET balance = balance + p_amount WHERE wallet_id = p_to_wallet_id;

    -- ─────────────────────────────────────────────────────────
    --  MARK SUCCESS + WRITE AUDIT LOG
    -- ─────────────────────────────────────────────────────────
    UPDATE transactions SET status = 'success' WHERE transaction_id = v_txn_id;

    INSERT INTO audit_log (transaction_id, user_id, action, details)
    VALUES (
        v_txn_id,
        p_initiated_by,
        'TRANSFER_SUCCESS',
        jsonb_build_object(
            'from_wallet', p_from_wallet_id,
            'to_wallet',   p_to_wallet_id,
            'currency',    v_from_currency,
            'amount',      p_amount
        )
    );

    RETURN v_txn_id;

    -- Any RAISE EXCEPTION above causes automatic ROLLBACK.
    -- No explicit EXCEPTION block needed — PostgreSQL rolls
    -- back the entire transaction including balance updates.
END;
$$;

-- ─────────────────────────────────────────────────────────────
--  USAGE EXAMPLE (called from Node.js backend):
--
--  SELECT transfer_money(
--      'from-wallet-uuid',
--      'to-wallet-uuid',
--      100.00,
--      'initiating-user-uuid'
--  );
--
--  Returns the new transaction_id on success.
--  Raises an exception (caught by Node.js) on failure.
-- ─────────────────────────────────────────────────────────────

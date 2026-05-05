-- ============================================================
--  SafeLedger — All Stored Procedures
--  Owner: Naqi (Core Transactions & ACID)
-- ============================================================
--  4 procedures: transfer_money, exchange_currency,
--                process_deposit, process_withdrawal
--
--  All procedures follow the same pattern:
--    1. Acquire FOR UPDATE row lock(s)
--    2. Validate state and amounts
--    3. Modify balances
--    4. Record in transactions table
--    5. Update deposit/withdrawal record (if applicable)
--    6. Write to audit_log
--    7. Return transaction_id
--
--  Any RAISE EXCEPTION causes full automatic ROLLBACK.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  1. transfer_money
--     Moves amount from one wallet to another (same currency)
-- ─────────────────────────────────────────────────────────────
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

    IF NOT FOUND THEN RAISE EXCEPTION 'Wallet not found'; END IF;
    IF p_from_wallet_id = p_to_wallet_id THEN RAISE EXCEPTION 'Cannot transfer to the same wallet'; END IF;
    IF v_from_status <> 'active' THEN RAISE EXCEPTION 'Source wallet is not active (status: %)', v_from_status; END IF;
    IF v_to_status   <> 'active' THEN RAISE EXCEPTION 'Destination wallet is not active (status: %)', v_to_status; END IF;
    IF v_from_currency <> v_to_currency THEN RAISE EXCEPTION 'Currency mismatch — use /exchange for cross-currency transfers'; END IF;
    IF v_from_balance < p_amount THEN RAISE EXCEPTION 'Insufficient balance: available %, required %', v_from_balance, p_amount; END IF;

    INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, transaction_type, status)
    VALUES (p_from_wallet_id, p_to_wallet_id, p_amount, 'transfer', 'pending')
    RETURNING transaction_id INTO v_txn_id;

    UPDATE wallets SET balance = balance - p_amount WHERE wallet_id = p_from_wallet_id;
    UPDATE wallets SET balance = balance + p_amount WHERE wallet_id = p_to_wallet_id;
    UPDATE transactions SET status = 'success' WHERE transaction_id = v_txn_id;

    INSERT INTO audit_log (transaction_id, user_id, action, details)
    VALUES (v_txn_id, p_initiated_by, 'TRANSFER_SUCCESS',
        jsonb_build_object('from_wallet', p_from_wallet_id, 'to_wallet', p_to_wallet_id,
                           'currency', v_from_currency, 'amount', p_amount));
    RETURN v_txn_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────
--  2. exchange_currency
--     Converts amount between two different-currency wallets
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION exchange_currency(
    p_from_wallet_id  UUID,
    p_to_wallet_id    UUID,
    p_amount          NUMERIC(20,8),
    p_exchange_rate   NUMERIC(20,8),
    p_initiated_by    UUID
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_txn_id          UUID;
    v_converted       NUMERIC(20,8);
    v_from_balance    NUMERIC(20,8);
    v_from_status     VARCHAR(20);
    v_to_status       VARCHAR(20);
    v_from_currency   VARCHAR(10);
    v_to_currency     VARCHAR(10);
BEGIN
    v_converted := ROUND(p_amount * p_exchange_rate, 8);

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

    IF v_from_status <> 'active' THEN RAISE EXCEPTION 'Source wallet is not active'; END IF;
    IF v_to_status   <> 'active' THEN RAISE EXCEPTION 'Destination wallet is not active'; END IF;
    IF v_from_currency = v_to_currency THEN RAISE EXCEPTION 'Source and destination currencies must be different'; END IF;
    IF v_from_balance < p_amount THEN RAISE EXCEPTION 'Insufficient balance: available %, required %', v_from_balance, p_amount; END IF;

    INSERT INTO transactions (from_wallet_id, to_wallet_id, amount, transaction_type, status, metadata)
    VALUES (p_from_wallet_id, p_to_wallet_id, p_amount, 'exchange', 'pending',
        jsonb_build_object('exchange_rate', p_exchange_rate, 'converted_amount', v_converted,
                           'from_currency', v_from_currency, 'to_currency', v_to_currency))
    RETURNING transaction_id INTO v_txn_id;

    UPDATE wallets SET balance = balance - p_amount    WHERE wallet_id = p_from_wallet_id;
    UPDATE wallets SET balance = balance + v_converted WHERE wallet_id = p_to_wallet_id;
    UPDATE transactions SET status = 'success' WHERE transaction_id = v_txn_id;

    INSERT INTO audit_log (transaction_id, user_id, action, details)
    VALUES (v_txn_id, p_initiated_by, 'EXCHANGE_SUCCESS',
        jsonb_build_object('from_wallet', p_from_wallet_id, 'to_wallet', p_to_wallet_id,
                           'from_currency', v_from_currency, 'to_currency', v_to_currency,
                           'amount', p_amount, 'rate', p_exchange_rate, 'converted', v_converted));
    RETURN v_txn_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────
--  3. process_deposit
--     Credits a wallet and records the deposit lifecycle
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION process_deposit(
    p_deposit_id UUID,
    p_wallet_id  UUID,
    p_amount     NUMERIC(20,8),
    p_user_id    UUID
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_txn_id   UUID;
    v_currency VARCHAR(10);
    v_status   VARCHAR(20);
BEGIN
    SELECT currency_type, status INTO v_currency, v_status
      FROM wallets WHERE wallet_id = p_wallet_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Wallet not found'; END IF;
    IF v_status <> 'active' THEN RAISE EXCEPTION 'Wallet is not active (status: %)', v_status; END IF;

    UPDATE wallets SET balance = balance + p_amount WHERE wallet_id = p_wallet_id;

    INSERT INTO transactions (to_wallet_id, amount, transaction_type, status, metadata)
    VALUES (p_wallet_id, p_amount, 'deposit', 'success',
        jsonb_build_object('deposit_id', p_deposit_id, 'currency', v_currency))
    RETURNING transaction_id INTO v_txn_id;

    UPDATE deposits SET status = 'completed', completed_at = NOW() WHERE deposit_id = p_deposit_id;

    INSERT INTO audit_log (transaction_id, user_id, action, details)
    VALUES (v_txn_id, p_user_id, 'DEPOSIT_SUCCESS',
        jsonb_build_object('wallet_id', p_wallet_id, 'amount', p_amount, 'currency', v_currency));

    RETURN v_txn_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────
--  4. process_withdrawal
--     Debits a wallet after balance validation
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION process_withdrawal(
    p_withdrawal_id UUID,
    p_wallet_id     UUID,
    p_amount        NUMERIC(20,8),
    p_user_id       UUID
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_txn_id   UUID;
    v_currency VARCHAR(10);
    v_status   VARCHAR(20);
    v_balance  NUMERIC(20,8);
BEGIN
    SELECT currency_type, status, balance INTO v_currency, v_status, v_balance
      FROM wallets WHERE wallet_id = p_wallet_id FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'Wallet not found'; END IF;
    IF v_status  <> 'active' THEN RAISE EXCEPTION 'Wallet is not active (status: %)', v_status; END IF;
    IF v_balance < p_amount  THEN RAISE EXCEPTION 'Insufficient balance: available %, required %', v_balance, p_amount; END IF;

    UPDATE wallets SET balance = balance - p_amount WHERE wallet_id = p_wallet_id;

    INSERT INTO transactions (from_wallet_id, amount, transaction_type, status, metadata)
    VALUES (p_wallet_id, p_amount, 'withdrawal', 'success',
        jsonb_build_object('withdrawal_id', p_withdrawal_id, 'currency', v_currency))
    RETURNING transaction_id INTO v_txn_id;

    UPDATE withdrawals SET status = 'completed', completed_at = NOW() WHERE withdrawal_id = p_withdrawal_id;

    INSERT INTO audit_log (transaction_id, user_id, action, details)
    VALUES (v_txn_id, p_user_id, 'WITHDRAWAL_SUCCESS',
        jsonb_build_object('wallet_id', p_wallet_id, 'amount', p_amount, 'currency', v_currency));

    RETURN v_txn_id;
END;
$$;
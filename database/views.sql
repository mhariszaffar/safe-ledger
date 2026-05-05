-- ============================================================
--  SafeLedger — SQL Views
--  Owner: Haris (Views, Queries, Analytics)
-- ============================================================
--  Reusable query abstractions for reporting and analytics.
--  Views are read-only and do not affect the underlying tables.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  VIEW 1: vw_user_wallet_summary
--  Shows each user with their wallet count and total USD-equivalent balance.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_user_wallet_summary AS
SELECT
    u.user_id,
    u.name,
    u.email,
    u.role,
    u.is_active,
    u.created_at                              AS registered_at,
    COUNT(w.wallet_id)                        AS wallet_count,
    COALESCE(SUM(
        CASE w.currency_type
            WHEN 'USD' THEN w.balance
            WHEN 'PKR' THEN w.balance * 0.003590
            WHEN 'EUR' THEN w.balance * 1.08700
            WHEN 'GBP' THEN w.balance * 1.26580
            WHEN 'AED' THEN w.balance * 0.27230
            WHEN 'SAR' THEN w.balance * 0.26670
            ELSE             w.balance * 0.001     -- fallback
        END
    ), 0)                                     AS total_balance_usd
FROM users u
LEFT JOIN wallets w ON w.user_id = u.user_id
GROUP BY u.user_id, u.name, u.email, u.role, u.is_active, u.created_at;

-- Usage: SELECT * FROM vw_user_wallet_summary ORDER BY total_balance_usd DESC;

-- ─────────────────────────────────────────────────────────────
--  VIEW 2: vw_transaction_detail
--  Full transaction history with sender/receiver names and emails.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_transaction_detail AS
SELECT
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.status,
    t.created_at,
    fw.currency_type                          AS from_currency,
    fu.name                                   AS sender_name,
    fu.email                                  AS sender_email,
    tw.currency_type                          AS to_currency,
    tu.name                                   AS receiver_name,
    tu.email                                  AS receiver_email,
    t.metadata
FROM transactions t
LEFT JOIN wallets fw  ON fw.wallet_id = t.from_wallet_id
LEFT JOIN users   fu  ON fu.user_id   = fw.user_id
LEFT JOIN wallets tw  ON tw.wallet_id = t.to_wallet_id
LEFT JOIN users   tu  ON tu.user_id   = tw.user_id;

-- Usage: SELECT * FROM vw_transaction_detail WHERE sender_email = 'user@example.com';

-- ─────────────────────────────────────────────────────────────
--  VIEW 3: vw_exchange_rate_matrix
--  All available currency pairs with rates and last updated time.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_exchange_rate_matrix AS
SELECT
    from_currency,
    to_currency,
    rate,
    ROUND(1.0 / rate, 8)                      AS inverse_rate,
    updated_at,
    EXTRACT(EPOCH FROM (NOW() - updated_at)) / 3600
                                              AS hours_since_update
FROM exchange_rates
ORDER BY from_currency, to_currency;

-- Usage: SELECT * FROM vw_exchange_rate_matrix WHERE from_currency = 'USD';

-- ─────────────────────────────────────────────────────────────
--  VIEW 4: vw_daily_transaction_volumes
--  Aggregate transaction counts and volumes per day per type.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_daily_transaction_volumes AS
SELECT
    DATE(created_at)                          AS txn_date,
    transaction_type,
    status,
    COUNT(*)                                  AS txn_count,
    SUM(amount)                               AS total_amount,
    AVG(amount)                               AS avg_amount,
    MAX(amount)                               AS max_amount
FROM transactions
GROUP BY DATE(created_at), transaction_type, status
ORDER BY txn_date DESC, transaction_type;

-- Usage: SELECT * FROM vw_daily_transaction_volumes WHERE txn_date = CURRENT_DATE;

-- ─────────────────────────────────────────────────────────────
--  VIEW 5: vw_audit_summary
--  Aggregated audit log grouped by action type and date.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_audit_summary AS
SELECT
    DATE(timestamp)                           AS audit_date,
    action,
    COUNT(*)                                  AS event_count,
    COUNT(DISTINCT user_id)                   AS unique_users
FROM audit_log
GROUP BY DATE(timestamp), action
ORDER BY audit_date DESC, event_count DESC;

-- Usage: SELECT * FROM vw_audit_summary WHERE action = 'TRANSACTION_FAILED';

-- ─────────────────────────────────────────────────────────────
--  VIEW 6: vw_active_sessions
--  All currently active, non-expired user sessions.
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_active_sessions AS
SELECT
    s.session_id,
    u.name,
    u.email,
    s.ip_address,
    s.device_info,
    s.created_at                              AS login_time,
    s.expires_at,
    EXTRACT(EPOCH FROM (s.expires_at - NOW())) / 60
                                              AS minutes_remaining
FROM user_sessions s
JOIN users u ON u.user_id = s.user_id
WHERE s.is_active = true
  AND s.expires_at > NOW()
ORDER BY s.created_at DESC;

-- Usage: SELECT * FROM vw_active_sessions;

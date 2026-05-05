-- ============================================================
--  SafeLedger — Analytical Queries
--  Owner: Haris (Views, Queries, Analytics)
-- ============================================================
--  Reusable queries for admin reporting and data analysis.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  1. Platform Overview Statistics
-- ─────────────────────────────────────────────────────────────
SELECT
    (SELECT COUNT(*) FROM users WHERE role = 'user')          AS total_users,
    (SELECT COUNT(*) FROM users WHERE is_active = false)      AS suspended_users,
    (SELECT COUNT(*) FROM wallets)                            AS total_wallets,
    (SELECT COUNT(*) FROM wallets WHERE status = 'frozen')    AS frozen_wallets,
    (SELECT COUNT(*) FROM transactions WHERE status = 'success')    AS successful_txns,
    (SELECT COUNT(*) FROM transactions WHERE status = 'failed')     AS failed_txns,
    (SELECT COUNT(*) FROM transactions WHERE status = 'pending')    AS pending_txns,
    (SELECT COALESCE(SUM(amount), 0) FROM transactions
      WHERE status = 'success'
        AND transaction_type = 'transfer')                    AS total_transferred,
    (SELECT COALESCE(SUM(amount), 0) FROM transactions
      WHERE status = 'success'
        AND transaction_type = 'deposit')                     AS total_deposited;

-- ─────────────────────────────────────────────────────────────
--  2. Top 10 Users by Transaction Volume (last 30 days)
-- ─────────────────────────────────────────────────────────────
SELECT
    u.name,
    u.email,
    COUNT(t.transaction_id)                   AS txn_count,
    SUM(t.amount)                             AS total_volume
FROM transactions t
JOIN wallets w  ON w.wallet_id = t.from_wallet_id
JOIN users   u  ON u.user_id   = w.user_id
WHERE t.created_at >= NOW() - INTERVAL '30 days'
  AND t.status = 'success'
GROUP BY u.user_id, u.name, u.email
ORDER BY total_volume DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
--  3. Transaction History for a Specific User
--     Replace 'user-uuid-here' with an actual user_id
-- ─────────────────────────────────────────────────────────────
SELECT
    t.transaction_id,
    t.transaction_type,
    t.amount,
    w.currency_type,
    t.status,
    t.created_at
FROM transactions t
JOIN wallets w ON w.wallet_id = COALESCE(t.from_wallet_id, t.to_wallet_id)
WHERE w.user_id = 'user-uuid-here'
ORDER BY t.created_at DESC
LIMIT 50;

-- ─────────────────────────────────────────────────────────────
--  4. Daily Active Users (last 7 days)
-- ─────────────────────────────────────────────────────────────
SELECT
    DATE(t.created_at)                        AS activity_date,
    COUNT(DISTINCT w.user_id)                 AS active_users,
    COUNT(t.transaction_id)                   AS total_transactions,
    SUM(t.amount)                             AS total_volume
FROM transactions t
JOIN wallets w ON w.wallet_id = COALESCE(t.from_wallet_id, t.to_wallet_id)
WHERE t.created_at >= NOW() - INTERVAL '7 days'
  AND t.status = 'success'
GROUP BY DATE(t.created_at)
ORDER BY activity_date DESC;

-- ─────────────────────────────────────────────────────────────
--  5. Most Popular Currency Pairs for Exchange
-- ─────────────────────────────────────────────────────────────
SELECT
    (t.metadata->>'from_currency')            AS from_currency,
    (t.metadata->>'to_currency')              AS to_currency,
    COUNT(*)                                  AS exchange_count,
    SUM(t.amount)                             AS total_source_amount,
    SUM((t.metadata->>'converted_amount')::NUMERIC) AS total_converted_amount
FROM transactions t
WHERE t.transaction_type = 'exchange'
  AND t.status = 'success'
GROUP BY t.metadata->>'from_currency', t.metadata->>'to_currency'
ORDER BY exchange_count DESC;

-- ─────────────────────────────────────────────────────────────
--  6. Wallet Balance Distribution by Currency
-- ─────────────────────────────────────────────────────────────
SELECT
    currency_type,
    COUNT(*)                                  AS wallet_count,
    SUM(balance)                              AS total_balance,
    AVG(balance)                              AS avg_balance,
    MAX(balance)                              AS max_balance,
    MIN(balance)                              AS min_balance
FROM wallets
WHERE status = 'active'
GROUP BY currency_type
ORDER BY wallet_count DESC;

-- ─────────────────────────────────────────────────────────────
--  7. Failed Transactions in the Last 24 Hours
-- ─────────────────────────────────────────────────────────────
SELECT
    t.transaction_id,
    t.transaction_type,
    t.amount,
    t.created_at,
    u.email                                   AS initiated_by
FROM transactions t
LEFT JOIN wallets  w ON w.wallet_id = t.from_wallet_id
LEFT JOIN users    u ON u.user_id   = w.user_id
WHERE t.status = 'failed'
  AND t.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY t.created_at DESC;

-- ─────────────────────────────────────────────────────────────
--  8. Users With No Transactions (possibly inactive accounts)
-- ─────────────────────────────────────────────────────────────
SELECT
    u.user_id,
    u.name,
    u.email,
    u.created_at
FROM users u
WHERE u.role = 'user'
  AND NOT EXISTS (
      SELECT 1 FROM wallets w
      JOIN transactions t ON t.from_wallet_id = w.wallet_id
                          OR t.to_wallet_id   = w.wallet_id
      WHERE w.user_id = u.user_id
  )
ORDER BY u.created_at DESC;

-- ─────────────────────────────────────────────────────────────
--  9. Admin Actions Audit (last 30 days)
-- ─────────────────────────────────────────────────────────────
SELECT
    a.timestamp,
    u.name                                    AS admin_name,
    u.email                                   AS admin_email,
    a.action,
    a.details,
    a.ip_address
FROM audit_log a
JOIN users u ON u.user_id = a.user_id
WHERE a.action IN ('ADMIN_SUSPEND_USER', 'ADMIN_REACTIVATE_USER',
                   'WALLET_STATUS_CHANGED')
  AND a.timestamp >= NOW() - INTERVAL '30 days'
ORDER BY a.timestamp DESC;

-- ─────────────────────────────────────────────────────────────
--  10. Full Ledger Balance Check (sum of all wallet balances)
--      Used to verify the system is balanced.
-- ─────────────────────────────────────────────────────────────
SELECT
    currency_type,
    SUM(balance)                              AS total_in_system,
    COUNT(*)                                  AS number_of_wallets
FROM wallets
GROUP BY currency_type
ORDER BY currency_type;

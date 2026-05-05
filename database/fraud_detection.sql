-- ============================================================
--  SafeLedger — Fraud Detection SQL Logic
--  Owner: Haris (Views, Queries, Analytics)
-- ============================================================
--  The fraud detection system has two layers:
--
--  Layer 1 — Rapid-Fire Check (handled in Node.js memory)
--             Blocks > 5 transactions per user per minute.
--             No SQL needed — uses an in-memory Map.
--
--  Layer 2 — Daily Volume Limit (SQL query, run per request)
--             Sums outgoing transactions in the last 24 hours,
--             converts all currencies to USD, blocks if > $5000.
-- ============================================================

-- ─────────────────────────────────────────────────────────────
--  DAILY VOLUME CHECK QUERY
--  Run before any transfer or withdrawal is processed.
--  Replace :userId with the actual user UUID.
-- ─────────────────────────────────────────────────────────────
SELECT
    COALESCE(SUM(
        t.amount * COALESCE(
            (SELECT rate FROM exchange_rates
              WHERE from_currency = w.currency_type
                AND to_currency   = 'USD'),
            1.0
        )
    ), 0) AS total_outgoing_usd_24h

FROM transactions t
JOIN wallets w ON w.wallet_id = t.from_wallet_id
WHERE w.user_id      = :userId
  AND t.status       = 'success'
  AND t.created_at  >= NOW() - INTERVAL '24 hours'
  AND t.transaction_type IN ('transfer', 'withdrawal', 'exchange');

-- If total_outgoing_usd_24h >= 5000 → reject the request (HTTP 429)

-- ─────────────────────────────────────────────────────────────
--  RAPID-FIRE DETECTION QUERY (alternative DB-backed version)
--  Counts transactions initiated by a user in the last 60 seconds.
--  The Node.js middleware uses in-memory tracking instead,
--  but this query could replace it for a multi-server setup.
-- ─────────────────────────────────────────────────────────────
SELECT COUNT(*) AS recent_txn_count
FROM transactions t
JOIN wallets w ON w.wallet_id = t.from_wallet_id
WHERE w.user_id     = :userId
  AND t.created_at >= NOW() - INTERVAL '60 seconds';

-- If recent_txn_count >= 5 → reject with HTTP 429 Too Many Requests

-- ─────────────────────────────────────────────────────────────
--  SUSPICIOUS ACTIVITY REPORT
--  Users who have triggered high transaction volumes in 24h
--  (useful for admin monitoring)
-- ─────────────────────────────────────────────────────────────
SELECT
    u.user_id,
    u.name,
    u.email,
    COUNT(t.transaction_id)                   AS txn_count_24h,
    COALESCE(SUM(
        t.amount * COALESCE(
            (SELECT rate FROM exchange_rates
              WHERE from_currency = w.currency_type
                AND to_currency   = 'USD'),
            1.0
        )
    ), 0)                                     AS volume_usd_24h
FROM transactions t
JOIN wallets w ON w.wallet_id = t.from_wallet_id
JOIN users   u ON u.user_id   = w.user_id
WHERE t.status      = 'success'
  AND t.created_at >= NOW() - INTERVAL '24 hours'
  AND t.transaction_type IN ('transfer', 'withdrawal', 'exchange')
GROUP BY u.user_id, u.name, u.email
HAVING COUNT(t.transaction_id) >= 3
    OR SUM(t.amount * COALESCE(
           (SELECT rate FROM exchange_rates
             WHERE from_currency = w.currency_type AND to_currency = 'USD'), 1.0
       )) >= 1000
ORDER BY volume_usd_24h DESC;

-- ─────────────────────────────────────────────────────────────
--  FAILED TRANSACTION SPIKE DETECTION
--  Flags users with multiple failed transactions (possible
--  brute force or insufficient-balance spamming)
-- ─────────────────────────────────────────────────────────────
SELECT
    u.user_id,
    u.name,
    u.email,
    COUNT(t.transaction_id)                   AS failed_txn_count,
    MIN(t.created_at)                         AS first_failure,
    MAX(t.created_at)                         AS last_failure
FROM transactions t
JOIN wallets w ON w.wallet_id = t.from_wallet_id
JOIN users   u ON u.user_id   = w.user_id
WHERE t.status      = 'failed'
  AND t.created_at >= NOW() - INTERVAL '1 hour'
GROUP BY u.user_id, u.name, u.email
HAVING COUNT(t.transaction_id) >= 3
ORDER BY failed_txn_count DESC;

-- ─────────────────────────────────────────────────────────────
--  LARGE SINGLE TRANSACTION ALERT
--  Flags any single transaction above $1000 USD equivalent
-- ─────────────────────────────────────────────────────────────
SELECT
    t.transaction_id,
    t.transaction_type,
    t.amount,
    w.currency_type,
    t.amount * COALESCE(
        (SELECT rate FROM exchange_rates
          WHERE from_currency = w.currency_type AND to_currency = 'USD'), 1.0
    )                                         AS amount_usd,
    u.name                                    AS sender,
    u.email,
    t.created_at
FROM transactions t
JOIN wallets w ON w.wallet_id = t.from_wallet_id
JOIN users   u ON u.user_id   = w.user_id
WHERE t.status = 'success'
  AND t.amount * COALESCE(
        (SELECT rate FROM exchange_rates
          WHERE from_currency = w.currency_type AND to_currency = 'USD'), 1.0
      ) >= 1000
ORDER BY t.created_at DESC
LIMIT 50;

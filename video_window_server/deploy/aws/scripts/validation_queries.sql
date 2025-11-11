-- Database Recovery Validation Queries
-- Story: 03-3 Data Retention & Backup Procedures
-- Purpose: Validate data integrity after recovery

\echo '========================================='
\echo 'DATABASE RECOVERY VALIDATION'
\echo '========================================='
\echo ''

-- Connection info
\echo 'Database Connection:'
SELECT current_database() as database_name, version() as postgres_version;
\echo ''

-- User data validation
\echo 'User Data Validation:'
SELECT 
  'users' as table_name,
  COUNT(*) as row_count,
  MIN(created_at) as oldest_record,
  MAX(created_at) as newest_record,
  COUNT(DISTINCT email) as unique_emails
FROM users;
\echo ''

-- Transaction validation (if table exists)
\echo 'Transaction Validation:'
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'transactions') THEN
    PERFORM 
      'transactions' as table_name,
      COUNT(*) as row_count,
      SUM(amount) as total_amount,
      MAX(created_at) as latest_transaction
    FROM transactions;
  ELSE
    RAISE NOTICE 'transactions table not found - skipping';
  END IF;
END $$;
\echo ''

-- Check for orphaned records
\echo 'Data Integrity Checks:'
\echo 'Checking for orphaned video records...'
SELECT 
  'orphaned_videos' as check_name,
  COUNT(*) as issue_count
FROM videos v
LEFT JOIN users u ON v.user_id = u.id
WHERE u.id IS NULL AND v.user_id IS NOT NULL;
\echo ''

-- Index validation
\echo 'Index Validation:'
SELECT 
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
\echo ''

-- Table sizes
\echo 'Table Sizes:'
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
\echo ''

-- Database size
\echo 'Database Size:'
SELECT 
  pg_database.datname as database_name,
  pg_size_pretty(pg_database_size(pg_database.datname)) as database_size
FROM pg_database
WHERE datname = current_database();
\echo ''

-- Active connections
\echo 'Active Connections:'
SELECT 
  COUNT(*) as connection_count,
  state,
  application_name
FROM pg_stat_activity
WHERE datname = current_database()
GROUP BY state, application_name;
\echo ''

-- Last vacuum/analyze
\echo 'Last Maintenance Operations:'
SELECT 
  schemaname,
  tablename,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY tablename
LIMIT 10;
\echo ''

-- Foreign key constraints
\echo 'Foreign Key Constraints:'
SELECT 
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
\echo ''

-- Table row counts
\echo 'Table Row Counts:'
SELECT 
  schemaname,
  tablename,
  n_live_tup as estimated_rows
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;
\echo ''

\echo '========================================='
\echo 'VALIDATION COMPLETE'
\echo '========================================='


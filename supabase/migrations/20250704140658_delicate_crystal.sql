-- Mi3AD Database Cleanup Script
-- Phase 1: Remove Friends and Posts Features

-- =============================================
-- STEP 1: CREATE BACKUP TABLES
-- =============================================

-- Backup friends data
CREATE TABLE IF NOT EXISTS archived_friends AS 
SELECT *, CURRENT_TIMESTAMP as archived_at 
FROM friends;

-- Backup friend requests
CREATE TABLE IF NOT EXISTS archived_friend_requests AS 
SELECT *, CURRENT_TIMESTAMP as archived_at 
FROM friend_requests;

-- Backup user posts
CREATE TABLE IF NOT EXISTS archived_user_posts AS 
SELECT *, CURRENT_TIMESTAMP as archived_at 
FROM user_posts;

-- Backup stories
CREATE TABLE IF NOT EXISTS archived_stories AS 
SELECT *, CURRENT_TIMESTAMP as archived_at 
FROM user_stories;

-- =============================================
-- STEP 2: REMOVE FOREIGN KEY CONSTRAINTS
-- =============================================

-- Drop constraints that reference tables we're about to remove
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS fk_notifications_friend_request;
ALTER TABLE audit_logs DROP CONSTRAINT IF EXISTS fk_audit_logs_post;
ALTER TABLE user_activities DROP CONSTRAINT IF EXISTS fk_activities_friend;

-- =============================================
-- STEP 3: DROP FRIEND-RELATED TABLES
-- =============================================

DROP TABLE IF EXISTS story_viewers CASCADE;
DROP TABLE IF EXISTS user_stories CASCADE;
DROP TABLE IF EXISTS friend_requests CASCADE;
DROP TABLE IF EXISTS friends CASCADE;

-- =============================================
-- STEP 4: DROP POST-RELATED TABLES
-- =============================================

DROP TABLE IF EXISTS post_shares CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS saved_posts CASCADE;
DROP TABLE IF EXISTS user_posts CASCADE;

-- =============================================
-- STEP 5: CLEAN UP USER TABLE
-- =============================================

-- Remove friend and post related columns from users table
ALTER TABLE users DROP COLUMN IF EXISTS friends_count;
ALTER TABLE users DROP COLUMN IF EXISTS posts_count;
ALTER TABLE users DROP COLUMN IF EXISTS total_likes;
ALTER TABLE users DROP COLUMN IF EXISTS mutual_friends_count;
ALTER TABLE users DROP COLUMN IF EXISTS last_post_date;
ALTER TABLE users DROP COLUMN IF EXISTS story_privacy_setting;
ALTER TABLE users DROP COLUMN IF EXISTS friend_visibility;

-- =============================================
-- STEP 6: CLEAN UP NOTIFICATIONS
-- =============================================

-- Remove friend and post related notifications
DELETE FROM notifications 
WHERE type IN (
  'friend_request', 
  'friend_accepted', 
  'post_like', 
  'post_comment', 
  'story_view',
  'post_share'
);

-- =============================================
-- STEP 7: CLEAN UP AUDIT LOGS
-- =============================================

-- Remove friend and post related audit logs
DELETE FROM audit_logs 
WHERE action IN (
  'friend_request_sent',
  'friend_request_accepted', 
  'friend_request_rejected',
  'friend_removed',
  'post_created',
  'post_updated',
  'post_deleted',
  'story_created',
  'story_viewed'
);

-- =============================================
-- STEP 8: UPDATE INDEXES
-- =============================================

-- Drop indexes that are no longer needed
DROP INDEX IF EXISTS idx_friends_user_id;
DROP INDEX IF EXISTS idx_friend_requests_from_user;
DROP INDEX IF EXISTS idx_friend_requests_to_user;
DROP INDEX IF EXISTS idx_posts_user_id;
DROP INDEX IF EXISTS idx_posts_created_at;
DROP INDEX IF EXISTS idx_stories_user_id;
DROP INDEX IF EXISTS idx_story_viewers_story_id;

-- =============================================
-- STEP 9: VACUUM AND ANALYZE
-- =============================================

-- Reclaim space and update statistics
VACUUM FULL;
ANALYZE;

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Verify tables are removed
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('friends', 'friend_requests', 'user_posts', 'user_stories');

-- Verify user table cleanup
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('friends_count', 'posts_count', 'total_likes');

-- Check remaining notification types
SELECT DISTINCT type, COUNT(*) 
FROM notifications 
GROUP BY type;

-- Verify backup tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'archived_%';

COMMIT;
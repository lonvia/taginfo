-- ============================================================================
--
--  Taginfo
--
--  history_update.sql
--
-- ============================================================================

.bail ON

ATTACH DATABASE '__DIR__/taginfo-master.db' AS master;

INSERT INTO history_stats (udate, key, value) SELECT substr(datetime('now'), 1, 10), key, value FROM master.master_stats;


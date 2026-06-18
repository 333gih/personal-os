-- One reading_progress row per user + story (latest chapter only)

DELETE FROM reading_progress rp
USING reading_progress newer
WHERE rp.user_id = newer.user_id
  AND rp.story_id = newer.story_id
  AND rp.last_read_at < newer.last_read_at;

DROP INDEX IF EXISTS idx_reading_progress_user_story_chapter;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reading_progress_user_story
    ON reading_progress (user_id, story_id);

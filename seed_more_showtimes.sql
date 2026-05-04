USE gold_screen_db;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_new_showtimes;

CREATE TEMPORARY TABLE tmp_new_showtimes (
    candidate_id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id INT NOT NULL,
    room_number INT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT 1
);

/*
  Generate a larger schedule window with fuller coverage:
    - Date range: 2026-05-07 through 2026-05-10
    - 8 shows/day for EVERY movie
  - Room assignment rotates through existing auditoriums
*/
INSERT INTO tmp_new_showtimes (movie_id, room_number, date, start_time, end_time, is_active)
WITH RECURSIVE date_series AS (
    SELECT DATE('2026-05-07') AS show_date
    UNION ALL
    SELECT DATE_ADD(show_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE show_date < DATE('2026-05-10')
),
slots AS (
    SELECT 1 AS slot_no, TIME('09:00:00') AS start_time, TIME('10:45:00') AS end_time
    UNION ALL
    SELECT 2, TIME('11:30:00'), TIME('13:15:00')
    UNION ALL
    SELECT 3, TIME('14:00:00'), TIME('15:50:00')
    UNION ALL
    SELECT 4, TIME('16:30:00'), TIME('18:20:00')
    UNION ALL
    SELECT 5, TIME('19:00:00'), TIME('20:55:00')
    UNION ALL
    SELECT 6, TIME('21:30:00'), TIME('23:20:00')
    UNION ALL
    SELECT 7, TIME('08:00:00'), TIME('09:40:00')
    UNION ALL
    SELECT 8, TIME('06:00:00'), TIME('07:45:00')
),
aud AS (
    SELECT
        room_number,
        ROW_NUMBER() OVER (ORDER BY room_number) AS room_rank
    FROM Auditoriums
),
aud_meta AS (
    SELECT COUNT(*) AS room_count FROM aud
),
sched AS (
    SELECT
        m.movie_id,
        a.room_number,
        ds.show_date AS date,
        sl.start_time,
        sl.end_time,
        1 AS is_active
    FROM date_series ds
    CROSS JOIN Movies m
    CROSS JOIN slots sl
    CROSS JOIN aud_meta am
    JOIN aud a
      ON a.room_rank = ((TO_DAYS(ds.show_date) + m.movie_id + sl.slot_no) % am.room_count) + 1
)
SELECT
    sc.movie_id,
    sc.room_number,
    sc.date,
    sc.start_time,
    sc.end_time,
    sc.is_active
FROM sched sc
JOIN Movies m ON m.movie_id = sc.movie_id
JOIN Auditoriums a ON a.room_number = sc.room_number;

SET @max_showtime_id := (SELECT COALESCE(MAX(showtime_id), 0) FROM Showtimes);

/*
  Safe insert:
  - New ids start above current max
  - Existing (movie, room, date, start_time) slots are skipped
*/
INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active)
SELECT
    @max_showtime_id + t.candidate_id AS showtime_id,
    t.movie_id,
    t.room_number,
    t.date,
    t.start_time,
    t.end_time,
    t.is_active
FROM tmp_new_showtimes t
WHERE NOT EXISTS (
    SELECT 1
    FROM Showtimes s
    WHERE s.movie_id = t.movie_id
      AND s.room_number = t.room_number
      AND s.date = t.date
      AND s.start_time = t.start_time
);

SELECT ROW_COUNT() AS inserted_showtimes;

/* Quick coverage check: number of showtimes per movie per date in seeded window */
SELECT
    s.date,
    s.movie_id,
    COUNT(*) AS show_count
FROM Showtimes s
WHERE s.date BETWEEN DATE('2026-05-07') AND DATE('2026-05-10')
GROUP BY s.date, s.movie_id
ORDER BY s.date, s.movie_id;

COMMIT;

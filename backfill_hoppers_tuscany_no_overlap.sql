USE gold_screen_db;

START TRANSACTION;

/*
  Targeted backfill for:
    - Hoppers
    - You, Me & Tuscany

  Goal:
    - Ensure each target movie has at least @target_per_day showtimes per day
      in [@start_date, @end_date]
    - Never overlap room/time with any existing showtime
    - Never overlap time for the same movie
*/
SET @start_date := DATE('2026-05-04');
SET @end_date := DATE('2026-05-15');
SET @target_per_day := 2;

SET @max_showtime_id := (SELECT COALESCE(MAX(showtime_id), 0) FROM Showtimes);

INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active)
WITH RECURSIVE date_series AS (
    SELECT @start_date AS show_date
    UNION ALL
    SELECT DATE_ADD(show_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE show_date < @end_date
),
target_movies AS (
    SELECT movie_id
    FROM Movies
    WHERE title IN ('Hoppers', 'You, Me & Tuscany')
),
slots AS (
    /* Non-overlapping candidate slots */
    SELECT 1 AS slot_no, TIME('08:30:00') AS start_time, TIME('10:15:00') AS end_time
    UNION ALL SELECT 2, TIME('10:45:00'), TIME('12:30:00')
    UNION ALL SELECT 3, TIME('13:00:00'), TIME('14:45:00')
    UNION ALL SELECT 4, TIME('15:15:00'), TIME('17:00:00')
    UNION ALL SELECT 5, TIME('17:30:00'), TIME('19:15:00')
    UNION ALL SELECT 6, TIME('19:45:00'), TIME('21:30:00')
    UNION ALL SELECT 7, TIME('22:00:00'), TIME('23:45:00')
),
aud AS (
    SELECT room_number, ROW_NUMBER() OVER (ORDER BY room_number) AS room_rank
    FROM Auditoriums
),
movie_day_counts AS (
    SELECT
        ds.show_date AS date,
        tm.movie_id,
        COUNT(s.showtime_id) AS current_count
    FROM date_series ds
    CROSS JOIN target_movies tm
    LEFT JOIN Showtimes s
      ON s.date = ds.show_date
     AND s.movie_id = tm.movie_id
    GROUP BY ds.show_date, tm.movie_id
),
needs AS (
    SELECT
        date,
        movie_id,
        current_count,
        GREATEST(@target_per_day - current_count, 0) AS need_count
    FROM movie_day_counts
    WHERE GREATEST(@target_per_day - current_count, 0) > 0
),
candidates AS (
    SELECT
        n.date,
        n.movie_id,
        a.room_number,
        sl.slot_no,
        sl.start_time,
        sl.end_time,
        n.current_count,
        n.need_count,
        ROW_NUMBER() OVER (
            PARTITION BY n.date, n.movie_id
            ORDER BY sl.slot_no, a.room_rank
        ) AS pref_rank
    FROM needs n
    CROSS JOIN slots sl
    CROSS JOIN aud a
    WHERE NOT EXISTS (
        /* No overlap with anything already scheduled in this room/date */
        SELECT 1
        FROM Showtimes s
        WHERE s.room_number = a.room_number
          AND s.date = n.date
          AND s.start_time < sl.end_time
          AND s.end_time > sl.start_time
    )
      AND NOT EXISTS (
        /* No overlap with this movie's own schedule on that date */
        SELECT 1
        FROM Showtimes s
        WHERE s.movie_id = n.movie_id
          AND s.date = n.date
          AND s.start_time < sl.end_time
          AND s.end_time > sl.start_time
    )
),
room_slot_dedup AS (
    /* Avoid collisions among new inserts themselves by keeping one movie per room/date/start */
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY c.date, c.room_number, c.start_time
            ORDER BY c.current_count ASC, c.pref_rank, c.movie_id DESC
        ) AS room_slot_pick
    FROM candidates c
),
movie_day_limited AS (
    SELECT
        r.date,
        r.movie_id,
        r.room_number,
        r.start_time,
        r.end_time,
        r.need_count,
        ROW_NUMBER() OVER (
            PARTITION BY r.date, r.movie_id
            ORDER BY r.slot_no, r.room_number
        ) AS movie_pick
    FROM room_slot_dedup r
    WHERE r.room_slot_pick = 1
),
chosen AS (
    SELECT
        date,
        movie_id,
        room_number,
        start_time,
        end_time,
        1 AS is_active
    FROM movie_day_limited
    WHERE movie_pick <= need_count
)
SELECT
    @max_showtime_id + ROW_NUMBER() OVER (ORDER BY date, movie_id, start_time, room_number) AS showtime_id,
    movie_id,
    room_number,
    date,
    start_time,
    end_time,
    is_active
FROM chosen;

/* Verification: coverage for the two target movies */
SELECT
    s.date,
    m.title,
    COUNT(*) AS show_count
FROM Showtimes s
JOIN Movies m ON m.movie_id = s.movie_id
WHERE m.title IN ('Hoppers', 'You, Me & Tuscany')
  AND s.date BETWEEN @start_date AND @end_date
GROUP BY s.date, m.title
ORDER BY s.date, m.title;

/* Verification: no room overlaps in the window */
SELECT
    a.room_number,
    a.date,
    a.showtime_id AS showtime_a,
    a.start_time AS a_start,
    a.end_time AS a_end,
    b.showtime_id AS showtime_b,
    b.start_time AS b_start,
    b.end_time AS b_end
FROM Showtimes a
JOIN Showtimes b
  ON a.room_number = b.room_number
 AND a.date = b.date
 AND a.showtime_id < b.showtime_id
 AND a.start_time < b.end_time
 AND a.end_time > b.start_time
WHERE a.date BETWEEN @start_date AND @end_date
ORDER BY a.date, a.room_number, a.start_time;

COMMIT;

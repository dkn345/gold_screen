USE gold_screen_db;

START TRANSACTION;

/*
    Ensure May 4..May 6 also have showtimes for every movie.
      Adds missing rows only (no overwrite).
    Prevents room/date/time collisions across different movies.
*/
SET @max_showtime_id := (SELECT COALESCE(MAX(showtime_id), 0) FROM Showtimes);

INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active)
WITH RECURSIVE date_series AS (
    SELECT DATE('2026-05-04') AS show_date
    UNION ALL
    SELECT DATE_ADD(show_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE show_date < DATE('2026-05-06')
),
slots AS (
    SELECT 1 AS slot_no, TIME('10:00:00') AS start_time, TIME('11:45:00') AS end_time
    UNION ALL
    SELECT 2, TIME('13:00:00'), TIME('14:45:00')
    UNION ALL
    SELECT 3, TIME('16:00:00'), TIME('17:45:00')
    UNION ALL
    SELECT 4, TIME('19:00:00'), TIME('20:45:00')
),
movies_ranked AS (
    SELECT
        movie_id,
        ROW_NUMBER() OVER (ORDER BY movie_id) AS movie_rank
    FROM Movies
),
movie_meta AS (
    SELECT COUNT(*) AS movie_count FROM movies_ranked
),
aud AS (
    SELECT room_number, ROW_NUMBER() OVER (ORDER BY room_number) AS room_rank
    FROM Auditoriums
),
aud_meta AS (
    SELECT COUNT(*) AS room_count FROM aud
),
candidates AS (
    SELECT
        mr.movie_id,
        a.room_number,
        ds.show_date AS date,
        sl.start_time,
        sl.end_time,
        1 AS is_active
    FROM date_series ds
    CROSS JOIN slots sl
    CROSS JOIN movie_meta mm
    CROSS JOIN aud_meta am
    JOIN aud a
      ON a.room_rank <= LEAST(mm.movie_count, am.room_count)
    JOIN movies_ranked mr
      ON mr.movie_rank = ((a.room_rank + TO_DAYS(ds.show_date) + sl.slot_no - 2) % mm.movie_count) + 1
),
missing AS (
    SELECT c.*
    FROM candidates c
    WHERE NOT EXISTS (
        SELECT 1
        FROM Showtimes s
        WHERE s.room_number = c.room_number
          AND s.date = c.date
          AND s.start_time = c.start_time
    )
)
SELECT
    @max_showtime_id + ROW_NUMBER() OVER (ORDER BY date, movie_id, start_time, room_number) AS showtime_id,
    movie_id,
    room_number,
    date,
    start_time,
    end_time,
    is_active
FROM missing;

/* Summary after insert-only run */
SELECT
    s.date,
    s.movie_id,
    COUNT(*) AS show_count
FROM Showtimes s
WHERE s.date BETWEEN DATE('2026-05-04') AND DATE('2026-05-15')
GROUP BY s.date, s.movie_id
ORDER BY s.date, s.movie_id;

COMMIT;

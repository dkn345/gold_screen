USE gold_screen_db;

START TRANSACTION;

/*
  Backfill missing showtimes so each movie has at least N showtimes per day
  in the selected window, without room/time collisions.

  Adjust this value if you want denser or lighter schedules per movie/day.
*/
SET @min_showtimes_per_movie_day := 2;
SET @start_date := DATE('2026-05-04');
SET @end_date := DATE('2026-05-15');

SET @max_showtime_id := (SELECT COALESCE(MAX(showtime_id), 0) FROM Showtimes);

INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active)
WITH RECURSIVE date_series AS (
    SELECT @start_date AS show_date
    UNION ALL
    SELECT DATE_ADD(show_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE show_date < @end_date
),
slots AS (
    SELECT 1 AS slot_no, TIME('09:30:00') AS start_time, TIME('11:15:00') AS end_time
    UNION ALL SELECT 2, TIME('12:00:00'), TIME('13:45:00')
    UNION ALL SELECT 3, TIME('14:30:00'), TIME('16:20:00')
    UNION ALL SELECT 4, TIME('17:00:00'), TIME('18:50:00')
    UNION ALL SELECT 5, TIME('19:30:00'), TIME('21:20:00')
    UNION ALL SELECT 6, TIME('22:00:00'), TIME('23:50:00')
),
aud AS (
    SELECT room_number, ROW_NUMBER() OVER (ORDER BY room_number) AS room_rank
    FROM Auditoriums
),
movies_ranked AS (
    SELECT movie_id, ROW_NUMBER() OVER (ORDER BY movie_id) AS movie_rank
    FROM Movies
),
movie_day_counts AS (
    SELECT
        ds.show_date AS date,
        m.movie_id,
        COUNT(s.showtime_id) AS current_count
    FROM date_series ds
    CROSS JOIN Movies m
    LEFT JOIN Showtimes s
      ON s.date = ds.show_date
     AND s.movie_id = m.movie_id
    GROUP BY ds.show_date, m.movie_id
),
needs AS (
    SELECT
        date,
        movie_id,
        GREATEST(@min_showtimes_per_movie_day - current_count, 0) AS need_count
    FROM movie_day_counts
    WHERE GREATEST(@min_showtimes_per_movie_day - current_count, 0) > 0
),
candidates AS (
    SELECT
        n.date,
        n.movie_id,
        a.room_number,
        sl.start_time,
        sl.end_time,
        n.need_count,
        ROW_NUMBER() OVER (
            PARTITION BY n.date, n.movie_id
            ORDER BY sl.slot_no, a.room_rank
        ) AS rn
    FROM needs n
    CROSS JOIN slots sl
    CROSS JOIN aud a
    WHERE NOT EXISTS (
        SELECT 1
        FROM Showtimes s
        WHERE s.room_number = a.room_number
          AND s.date = n.date
                    AND s.start_time < sl.end_time
                    AND s.end_time > sl.start_time
    )
      AND NOT EXISTS (
        SELECT 1
        FROM Showtimes s
        WHERE s.movie_id = n.movie_id
          AND s.date = n.date
                    AND s.start_time < sl.end_time
                    AND s.end_time > sl.start_time
    )
),
chosen AS (
    SELECT
        date,
        movie_id,
        room_number,
        start_time,
        end_time,
        1 AS is_active
    FROM candidates
    WHERE rn <= need_count
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

/* Post-checks */
SELECT
    s.date,
    s.movie_id,
    COUNT(*) AS show_count
FROM Showtimes s
WHERE s.date BETWEEN @start_date AND @end_date
GROUP BY s.date, s.movie_id
ORDER BY s.date, s.movie_id;

SELECT
    room_number,
    date,
    start_time,
    COUNT(*) AS rows_per_room_slot
FROM Showtimes
GROUP BY room_number, date, start_time
HAVING COUNT(*) > 1
ORDER BY date, start_time, room_number;

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
ORDER BY a.date, a.room_number, a.start_time;

COMMIT;

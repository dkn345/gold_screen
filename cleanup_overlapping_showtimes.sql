USE gold_screen_db;

START TRANSACTION;

/*
  Remove overlapping showtimes in the same auditorium on the same date.
  Keeps the earliest showtime_id and deletes later overlapping rows.

  Adjust date window as needed.
*/
SET @start_date := DATE('2026-05-04');
SET @end_date := DATE('2026-05-15');

/*
  Delete any row that overlaps an earlier row in the same room/date.
  Overlap condition:
    existing.start_time < candidate.end_time
    existing.end_time   > candidate.start_time
*/
DELETE s
FROM Showtimes s
JOIN Showtimes k
  ON k.room_number = s.room_number
 AND k.date = s.date
 AND k.showtime_id < s.showtime_id
 AND k.start_time < s.end_time
 AND k.end_time > s.start_time
WHERE s.date BETWEEN @start_date AND @end_date;

/* Verification: should return zero rows after cleanup */
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

/* Optional summary counts */
SELECT
    date,
    movie_id,
    COUNT(*) AS show_count
FROM Showtimes
WHERE date BETWEEN @start_date AND @end_date
GROUP BY date, movie_id
ORDER BY date, movie_id;

COMMIT;

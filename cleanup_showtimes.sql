USE gold_screen_db;

START TRANSACTION;

/*
  1) Optional window cleanup: remove anything after May 15, 2026.
     Safe-update friendly because delete targets key column showtime_id.
*/
DELETE s
FROM Showtimes s
JOIN (
    SELECT showtime_id
    FROM Showtimes
    WHERE date > DATE('2026-05-15')
) x ON x.showtime_id = s.showtime_id;

/*
  2) Collision cleanup:
     Keep exactly one row per (room_number, date, start_time),
     preserving the earliest showtime_id and deleting the rest.
*/
DELETE s
FROM Showtimes s
JOIN (
    SELECT s2.showtime_id
    FROM Showtimes s2
    JOIN (
        SELECT room_number, date, start_time, MIN(showtime_id) AS keep_showtime_id
        FROM Showtimes
        GROUP BY room_number, date, start_time
        HAVING COUNT(*) > 1
    ) k
      ON k.room_number = s2.room_number
     AND k.date = s2.date
     AND k.start_time = s2.start_time
    WHERE s2.showtime_id <> k.keep_showtime_id
) d ON d.showtime_id = s.showtime_id;

/*
  3) Optional movie/date duplicate cleanup:
     If a movie was duplicated in the exact same date/start_time in different rows,
     keep the earliest showtime_id for that movie/date/start_time.
*/
DELETE s
FROM Showtimes s
JOIN (
    SELECT s2.showtime_id
    FROM Showtimes s2
    JOIN (
        SELECT movie_id, date, start_time, MIN(showtime_id) AS keep_showtime_id
        FROM Showtimes
        GROUP BY movie_id, date, start_time
        HAVING COUNT(*) > 1
    ) k
      ON k.movie_id = s2.movie_id
     AND k.date = s2.date
     AND k.start_time = s2.start_time
    WHERE s2.showtime_id <> k.keep_showtime_id
) d ON d.showtime_id = s.showtime_id;

/* Reports */
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
    movie_id,
    date,
    start_time,
    COUNT(*) AS rows_per_movie_slot
FROM Showtimes
GROUP BY movie_id, date, start_time
HAVING COUNT(*) > 1
ORDER BY date, start_time, movie_id;

SELECT
    date,
    movie_id,
    COUNT(*) AS show_count
FROM Showtimes
WHERE date BETWEEN DATE('2026-05-04') AND DATE('2026-05-15')
GROUP BY date, movie_id
ORDER BY date, movie_id;

COMMIT;

require('dotenv').config();
const mysql = require('mysql2/promise');

(async () => {
  const db = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'gold_screen_db'
  });

  await db.query(`
    INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active)
    WITH RECURSIVE date_series AS (
      SELECT DATE('2026-05-04') AS show_date
      UNION ALL
      SELECT DATE_ADD(show_date, INTERVAL 1 DAY)
      FROM date_series
      WHERE show_date < DATE('2026-05-15')
    ),
    slots AS (
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
    day_counts AS (
      SELECT ds.show_date AS date, COUNT(s.showtime_id) AS current_count
      FROM date_series ds
      LEFT JOIN Showtimes s
        ON s.date = ds.show_date
       AND s.movie_id = 7
      GROUP BY ds.show_date
    ),
    needs AS (
      SELECT date, GREATEST(2 - current_count, 0) AS need_count
      FROM day_counts
      WHERE GREATEST(2 - current_count, 0) > 0
    ),
    candidates AS (
      SELECT
        n.date,
        7 AS movie_id,
        a.room_number,
        sl.slot_no,
        sl.start_time,
        sl.end_time,
        n.need_count,
        ROW_NUMBER() OVER (
          PARTITION BY n.date
          ORDER BY sl.slot_no, a.room_rank
        ) AS pick_rank
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
        WHERE s.movie_id = 7
          AND s.date = n.date
          AND s.start_time < sl.end_time
          AND s.end_time > sl.start_time
      )
    ),
    chosen AS (
      SELECT date, movie_id, room_number, start_time, end_time, 1 AS is_active
      FROM candidates
      WHERE pick_rank <= need_count
    ),
    max_id AS (
      SELECT COALESCE(MAX(showtime_id),0) AS mx FROM Showtimes
    )
    SELECT
      (SELECT mx FROM max_id) + ROW_NUMBER() OVER (ORDER BY date, start_time, room_number) AS showtime_id,
      movie_id, room_number, date, start_time, end_time, is_active
    FROM chosen;
  `);

  const [rows] = await db.query(`
    SELECT DATE_FORMAT(s.date,'%Y-%m-%d') AS d, m.title, COUNT(*) AS cnt
    FROM Showtimes s
    JOIN Movies m ON m.movie_id = s.movie_id
    WHERE m.title IN ('Hoppers','You, Me & Tuscany')
      AND s.date BETWEEN '2026-05-04' AND '2026-05-15'
    GROUP BY d, m.title
    ORDER BY d, m.title;
  `);

  console.log(rows);
  await db.end();
})();

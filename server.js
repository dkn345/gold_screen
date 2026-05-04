const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Database connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gold_screen_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Example endpoint: Get all movies
app.get('/api/movies', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [movies] = await connection.query('SELECT * FROM Movies');
    connection.release();
    res.json(movies);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Example endpoint: Get movie by ID
app.get('/api/movies/:id', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [movie] = await connection.query('SELECT * FROM Movies WHERE movie_id = ?', [req.params.id]);
    connection.release();
    res.json(movie);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Example endpoint: Get all customers
app.get('/api/customers', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [customers] = await connection.query('SELECT * FROM Customers');
    connection.release();
    res.json(customers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Example endpoint: Get customer by ID
app.get('/api/customers/:id', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [customer] = await connection.query('SELECT * FROM Customers WHERE customer_id = ?', [req.params.id]);
    connection.release();
    res.json(customer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Example endpoint: Get all concessions
app.get('/api/concessions', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [concessions] = await connection.query('SELECT * FROM Concessions');
    connection.release();
    res.json(concessions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get auditorium by room number
app.get('/api/auditoriums/:roomNumber', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [auditorium] = await connection.query(
      'SELECT room_number, max_capacity FROM Auditoriums WHERE room_number = ?',
      [req.params.roomNumber]
    );
    connection.release();

    if (!auditorium.length) {
      res.status(404).json({ error: 'Auditorium not found' });
      return;
    }

    res.json(auditorium[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Example endpoint: Add item to cart
app.post('/api/cart', async (req, res) => {
  try {
    const { customer_id, item_id, quantity } = req.body;
    const connection = await pool.getConnection();
    const [result] = await connection.query(
      'INSERT INTO Cart (customer_id, item_id, quantity) VALUES (?, ?, ?)',
      [customer_id, item_id, quantity]
    );
    connection.release();
    res.json({ success: true, cartId: result.insertId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all shows (using Movies table)
app.get('/api/shows', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [shows] = await connection.query('SELECT * FROM Movies ORDER BY movie_id ASC');
    connection.release();
    res.json(shows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get distinct show dates from Showtimes
app.get('/api/show-dates', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [dates] = await connection.query(
      'SELECT DISTINCT DATE_FORMAT(date, "%Y-%m-%d") AS show_date FROM Showtimes WHERE is_active = 1 ORDER BY show_date ASC'
    );
    connection.release();
    res.json(dates.map((row) => row.show_date));
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get showtimes for a movie on a specific date
app.get('/api/showtimes/:movieId', async (req, res) => {
  try {
    const selectedDate = req.query.date || new Date().toISOString().slice(0, 10);
    const connection = await pool.getConnection();
    const [showtimes] = await connection.query(
      'SELECT * FROM Showtimes WHERE movie_id = ? AND DATE_FORMAT(date, "%Y-%m-%d") = ? ORDER BY start_time ASC',
      [req.params.movieId, selectedDate]
    );
    connection.release();
    res.json(showtimes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

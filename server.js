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
    const [customer] = await connection.query(`
      SELECT c.*, m.tier_level, m.discount_pct 
      FROM Customers c 
      LEFT JOIN Memberships m ON c.membership_id = m.membership_id 
      WHERE c.customer_id = ?
    `, [req.params.id]);
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
      'SELECT DISTINCT DATE_FORMAT(date, "%Y-%m-%d") AS show_date FROM Showtimes WHERE is_active = 1 AND date >= CURDATE() ORDER BY show_date ASC'
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

app.get('/api/occupied-seats/:showtimeId', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [books] = await connection.query(`
      SELECT s.row_letter, s.seat_number 
      FROM Books b
      JOIN Seats s ON b.seat_id = s.seat_id
      WHERE b.showtime_id = ?
    `, [req.params.showtimeId]);
    connection.release();
    
    const occupied = books.map(b => `${b.row_letter}${b.seat_number}`);
    res.json(occupied);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/checkout', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const { cart, customerId, redeemedTickets = 0, redeemedConcessions = 0 } = req.body;
    
    let baseSubtotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    let ticketPrices = [];
    let concessionPrices = [];
    cart.forEach(item => {
        const isTicket = item.seats && item.seats.length > 0;
        for(let i=0; i<item.quantity; i++) {
            if (isTicket) ticketPrices.push(item.price);
            else concessionPrices.push(item.price);
        }
    });
    ticketPrices.sort((a,b) => b-a);
    concessionPrices.sort((a,b) => b-a);
    
    let discountFromPoints = 0;
    for(let i=0; i<redeemedTickets; i++) {
        if(i < ticketPrices.length) discountFromPoints += ticketPrices[i];
    }
    for(let i=0; i<redeemedConcessions; i++) {
        if(i < concessionPrices.length) discountFromPoints += concessionPrices[i];
    }
    
    let totalAmount = Math.max(0, baseSubtotal - discountFromPoints);
    let pointsToDeduct = (redeemedTickets * 100) + (redeemedConcessions * 50);
    
    let discountPct = 0;
    let pointsPerDollar = 1; // default for non-members
    
    if (customerId) {
      const [customers] = await connection.query(`
        SELECT c.reward_points, m.discount_pct, m.points_per_dollar 
        FROM Customers c 
        LEFT JOIN Memberships m ON c.membership_id = m.membership_id 
        WHERE c.customer_id = ?
      `, [customerId]);
      
      if (customers.length > 0) {
        if (customers[0].reward_points < pointsToDeduct) {
             throw new Error('Not enough reward points');
        }
        
        if (customers[0].discount_pct) {
          discountPct = customers[0].discount_pct;
          totalAmount = totalAmount * (1 - (discountPct / 100));
        }
        if (customers[0].points_per_dollar) {
          pointsPerDollar = customers[0].points_per_dollar;
        }
      } else if (pointsToDeduct > 0) {
          throw new Error('Customer not found for point redemption');
      }
    } else if (pointsToDeduct > 0) {
        throw new Error('Must be logged in to redeem points');
    }
    
    const [payRows] = await connection.query('SELECT IFNULL(MAX(payment_id), 0) + 1 as nextId FROM Payments');
    const paymentId = payRows[0].nextId;

    await connection.query(
      'INSERT INTO Payments (payment_id, total_amount, payment_method) VALUES (?, ?, ?)',
      [paymentId, totalAmount, 'Credit Card']
    );

    let [tickRows] = await connection.query('SELECT IFNULL(MAX(ticket_id), 0) + 1 as nextId FROM Tickets');
    let nextTicketId = tickRows[0].nextId;

    for (const item of cart) {
      if (item.seats && item.seats.length > 0) {
        for (const seatStr of item.seats) {
          const rowLetter = seatStr.charAt(0);
          const seatNum = parseInt(seatStr.substring(1));
          
          const [seats] = await connection.query(
            'SELECT seat_id FROM Seats WHERE room_number = ? AND row_letter = ? AND seat_number = ?',
            [item.room, rowLetter, seatNum]
          );
          
          if (seats.length > 0) {
            const seatId = seats[0].seat_id;
            const ticketId = nextTicketId++;
            
            await connection.query(
              'INSERT INTO Tickets (ticket_id, payment_id, ticket_category, price) VALUES (?, ?, ?, ?)',
              [ticketId, paymentId, 'Standard', item.price] 
            );

            await connection.query(
              'INSERT INTO Books (ticket_id, seat_id, showtime_id) VALUES (?, ?, ?)',
              [ticketId, seatId, item.id] 
            );
          }
        }
      } else if (item.isConcession) {
        // It's a concession item
        await connection.query(
          'INSERT INTO Pays_for (payment_id, item_id, quantity) VALUES (?, ?, ?)',
          [paymentId, item.id, item.quantity]
        );
        
        // Deduct from stock level
        await connection.query(
          'UPDATE Concessions SET stock_level = GREATEST(0, stock_level - ?) WHERE item_id = ?',
          [item.quantity, item.id]
        );
      }
    }
    
    // Award reward points and link payment to customer
    if (customerId) {
      const pointsEarned = Math.floor(totalAmount * pointsPerDollar);
      await connection.query(
        'UPDATE Customers SET reward_points = reward_points + ? - ? WHERE customer_id = ?',
        [pointsEarned, pointsToDeduct, customerId]
      );
      
      // Link payment to customer in Makes table
      console.log(`Inserting into Makes: customer=${customerId}, payment=${paymentId}`);
      await connection.query(
        'INSERT INTO Makes (customer_id, employee_id, payment_id) VALUES (?, 101, ?)',
        [customerId, paymentId]
      );
      console.log('Makes insert successful');
    }
    
    await connection.commit();
    connection.release();
    res.json({ success: true });
  } catch (error) {
    await connection.rollback();
    connection.release();
    res.status(500).json({ error: error.message });
  }
});

// Auth endpoints (Email only mock login)
app.post('/api/login', async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email is required' });

  try {
    const connection = await pool.getConnection();
    const [users] = await connection.query('SELECT * FROM Customers WHERE email = ?', [email]);
    connection.release();

    if (users.length > 0) {
      res.json({ success: true, customer: users[0], message: 'Magic link sent! (Mocked: logged in)' });
    } else {
      res.status(404).json({ error: 'No account found with that email.' });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/signup', async (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) return res.status(400).json({ error: 'Name and email are required' });

  try {
    const connection = await pool.getConnection();
    
    // Check if exists
    const [existing] = await connection.query('SELECT * FROM Customers WHERE email = ?', [email]);
    if (existing.length > 0) {
      connection.release();
      return res.status(400).json({ error: 'Email already registered.' });
    }

    // Get next ID
    const [idRows] = await connection.query('SELECT IFNULL(MAX(customer_id), 0) + 1 as nextId FROM Customers');
    const newId = idRows[0].nextId;

    await connection.query(
      'INSERT INTO Customers (customer_id, name, email, reward_points) VALUES (?, ?, ?, 0)',
      [newId, name, email]
    );
    
    const [newUser] = await connection.query('SELECT * FROM Customers WHERE customer_id = ?', [newId]);
    connection.release();

    res.json({ success: true, customer: newUser[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Admin endpoint for raw queries
// Order history for a customer
app.get('/api/customers/:id/orders', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [orders] = await connection.query(`
      SELECT p.payment_id, p.total_amount, p.payment_method, p.timestamp
      FROM Makes mk
      JOIN Payments p ON mk.payment_id = p.payment_id
      WHERE mk.customer_id = ?
      ORDER BY p.timestamp DESC
    `, [req.params.id]);
    connection.release();
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/admin/query', async (req, res) => {
  const { passcode, query } = req.body;
  
  if (passcode !== 'goldadmin') {
    return res.status(401).json({ error: 'Unauthorized: Invalid passcode' });
  }
  
  if (!query) {
    return res.status(400).json({ error: 'Query is required' });
  }

  try {
    const connection = await pool.getConnection();
    const [results] = await connection.query(query);
    connection.release();
    res.json({ success: true, results });
  } catch (error) {
    res.status(400).json({ error: error.message }); // 400 for bad SQL syntax
  }
});

// Membership endpoints
app.get('/api/memberships', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [memberships] = await connection.query('SELECT * FROM Memberships ORDER BY monthly_cost ASC');
    connection.release();
    res.json(memberships);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/customers/:id/upgrade', async (req, res) => {
  const { membership_id } = req.body;
  const customerId = req.params.id;

  if (!membership_id) {
    return res.status(400).json({ error: 'membership_id is required' });
  }

  try {
    const connection = await pool.getConnection();
    await connection.query(
      'UPDATE Customers SET membership_id = ? WHERE customer_id = ?',
      [membership_id, customerId]
    );
    const [updated] = await connection.query(`
      SELECT c.*, m.tier_level, m.discount_pct 
      FROM Customers c 
      LEFT JOIN Memberships m ON c.membership_id = m.membership_id 
      WHERE c.customer_id = ?
    `, [customerId]);
    connection.release();
    res.json({ success: true, customer: updated[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

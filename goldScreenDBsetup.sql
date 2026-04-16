/*
CREATE DATABASE gold_screen_db;
USE gold_screen_db;

-- Parent Tables (No dependencies)
CREATE TABLE Movies (
    movie_id INT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(50),
    age_rating VARCHAR(10),
    runtime INT
);

CREATE TABLE Memberships (
    membership_id INT PRIMARY KEY,
    tier_level VARCHAR(20),
    monthly_cost DECIMAL(10,2),
    discount_pct INT,
    points_per_dollar INT
);

CREATE TABLE Auditoriums (
    room_number INT PRIMARY KEY,
    max_capacity INT
);

CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50)
);

CREATE TABLE Concessions (
    item_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_level INT
);

-- Child Tables (Rely on parents)
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    membership_id INT,
    reward_points INT DEFAULT 0,
    FOREIGN KEY (membership_id) REFERENCES Memberships(membership_id)
);

CREATE TABLE Seats (
    seat_id INT PRIMARY KEY,
    room_number INT,
    row_letter CHAR(1),
    seat_number INT,
    type VARCHAR(20),
    status VARCHAR(20),
    FOREIGN KEY (room_number) REFERENCES Auditoriums(room_number)
);

CREATE TABLE Showtimes (
    showtime_id INT PRIMARY KEY,
    movie_id INT,
    room_number INT,
    date DATE,
    start_time TIME,
    end_time TIME,
    is_active BOOLEAN,
    FOREIGN KEY (movie_id) REFERENCES Movies(movie_id),
    FOREIGN KEY (room_number) REFERENCES Auditoriums(room_number)
);

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY,
    total_amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transaction/Link Tables
CREATE TABLE Tickets (
    ticket_id INT PRIMARY KEY,
    payment_id INT,
    ticket_category VARCHAR(20),
    price DECIMAL(10,2),
    FOREIGN KEY (payment_id) REFERENCES Payments(payment_id)
);

CREATE TABLE Books (
    ticket_id INT,
    seat_id INT,
    showtime_id INT,
    PRIMARY KEY (ticket_id, seat_id, showtime_id),
    FOREIGN KEY (ticket_id) REFERENCES Tickets(ticket_id),
    FOREIGN KEY (seat_id) REFERENCES Seats(seat_id),
    FOREIGN KEY (showtime_id) REFERENCES Showtimes(showtime_id)
);

CREATE TABLE Pays_for (
    payment_id INT,
    item_id INT,
    quantity INT,
    PRIMARY KEY (payment_id, item_id),
    FOREIGN KEY (payment_id) REFERENCES Payments(payment_id),
    FOREIGN KEY (item_id) REFERENCES Concessions(item_id)
);

CREATE TABLE Makes (
    customer_id INT,
    employee_id INT,
    payment_id INT,
    PRIMARY KEY (customer_id, employee_id, payment_id),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (payment_id) REFERENCES Payments(payment_id)
);

*/

-- Movies
INSERT INTO Movies VALUES (1, 'The Super Mario Galaxy Movie', 'Animation', 'PG', 105);
INSERT INTO Movies VALUES (2, 'Project Hail Mary', 'Sci-Fi', 'PG-13', 135);
INSERT INTO Movies VALUES (3, 'Scream 7', 'Horror', 'R', 118);
INSERT INTO Movies VALUES (4, 'Greenland 2: Migration', 'Action', 'PG-13', 122);

-- Membership Tiers 
INSERT INTO Memberships VALUES (1, 'Silver Screen', 10.00, 10, 1);
INSERT INTO Memberships VALUES (2, 'Golden Ticket', 20.00, 20, 2);

-- Auditoriums
INSERT INTO Auditoriums VALUES (1, 100);
INSERT INTO Auditoriums VALUES (2, 100);

-- Employees
INSERT INTO Employees VALUES (101, 'Alice Smith', 'Manager');
INSERT INTO Employees VALUES (102, 'Bob Jones', 'Concessions');
INSERT INTO Employees VALUES (103, 'Charlie Brown', 'Ticket Booth');

-- Concessions
INSERT INTO Concessions VALUES (1, 'Large Popcorn', 'Food', 8.50, 500);
INSERT INTO Concessions VALUES (2, 'Nachos', 'Food', 7.00, 200);
INSERT INTO Concessions VALUES (3, 'Large Icee', 'Beverage', 6.50, 300);

-- Customers 
INSERT INTO Customers VALUES (1, 'John Doe', 'john@email.com', 2, 25);
INSERT INTO Customers VALUES (2, 'Jane Miller', 'jane@email.com', 1, 10);
INSERT INTO Customers VALUES (3, 'Guest User', 'guest@none.com', NULL, 0);

-- Seats for Auditorium 1
INSERT INTO Seats VALUES (1, 1, 'A', 1, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (2, 1, 'A', 2, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (3, 1, 'B', 1, 'Disabled', 'Vacant');

-- Scheduled Showtimes for Today 
INSERT INTO Showtimes VALUES (1, 1, 1, '2026-04-12', '14:00:00', '15:45:00', 1);
INSERT INTO Showtimes VALUES (2, 2, 2, '2026-04-12', '19:00:00', '21:15:00', 1);

-- Payment Records [cite: 26, 54]
INSERT INTO Payments VALUES (5001, 25.50, 'Credit Card', '2026-04-12 13:30:00');
INSERT INTO Payments VALUES (5002, 15.00, 'Cash', '2026-04-12 14:00:00');

-- Individual Tickets [cite: 23, 46, 47, 48]
INSERT INTO Tickets VALUES (1001, 5001, 'Adult', 15.00);
INSERT INTO Tickets VALUES (1002, 5002, 'Senior', 12.00);

-- Books (Assigning Seats/Showtimes to Tickets) 
INSERT INTO Books VALUES (1001, 1, 1);
INSERT INTO Books VALUES (1002, 2, 2);

-- Pays_for (Concessions linked to Payments) 
INSERT INTO Pays_for VALUES (5001, 1, 1); -- Large Popcorn
INSERT INTO Pays_for VALUES (5001, 3, 1); -- Large Icee

-- Makes (Linking Customer, Employee, and Payment)
INSERT INTO Makes VALUES (1, 103, 5001);
INSERT INTO Makes VALUES (2, 102, 5002);
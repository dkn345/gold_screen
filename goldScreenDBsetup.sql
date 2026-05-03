CREATE DATABASE gold_screen_db;
USE gold_screen_db;

-- Parent Tables
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

-- Child Tables
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

-- Updates
-- 1. Increase title length for long titles
ALTER TABLE Movies MODIFY COLUMN title VARCHAR(500);

-- 2. Add a constraint so staff can't type random text in the Seat Status
ALTER TABLE Seats ADD CONSTRAINT chk_status 
CHECK (status IN ('Vacant', 'Occupied', 'Maintenance', 'Reserved'));

-- 3. Ensure stock never accidentally becomes 'NULL'
ALTER TABLE Concessions MODIFY COLUMN stock_level INT DEFAULT 0;

-- Movies
INSERT INTO Movies VALUES (1, 'The Super Mario Galaxy Movie', 'Animation', 'PG', 105);
INSERT INTO Movies VALUES (2, 'Project Hail Mary', 'Sci-Fi', 'PG-13', 135);
INSERT INTO Movies VALUES (3, 'Scream 7', 'Horror', 'R', 118);
INSERT INTO Movies VALUES (4, 'Greenland 2: Migration', 'Action', 'PG-13', 122);
INSERT INTO Movies VALUES (5, 'The Drama', 'Comedy/Drama', 'R', 105);
INSERT INTO Movies VALUES (6, 'Hoppers', 'Animation', 'PG', 100);
INSERT INTO Movies VALUES (7, 'You, Me & Tuscany', 'Rom-Com', 'PG-13', 104);

-- Membership Tiers 
INSERT INTO Memberships VALUES (1, 'Silver Screen', 10.00, 10, 1);
INSERT INTO Memberships VALUES (2, 'Golden Ticket', 20.00, 20, 2);

-- Auditoriums
INSERT INTO Auditoriums VALUES (1, 100);
INSERT INTO Auditoriums VALUES (2, 100);
INSERT INTO Auditoriums VALUES (3, 60);
INSERT INTO Auditoriums VALUES (4, 80);
INSERT INTO Auditoriums VALUES (5, 120);

-- Employees
INSERT INTO Employees VALUES (101, 'Alice Smith', 'Manager');
INSERT INTO Employees VALUES (102, 'Bob Jones', 'Concessions');
INSERT INTO Employees VALUES (103, 'Charlie Brown', 'Ticket Booth');
INSERT INTO Employees VALUES (104, 'Tim Apple', 'Concessions');
INSERT INTO Employees VALUES (105, 'Sarah Connor', 'Security');
INSERT INTO Employees VALUES (106, 'Peter Parker', 'Concessions');

-- Concessions
INSERT INTO Concessions VALUES (1, 'Large Popcorn', 'Food', 8.50, 500);
INSERT INTO Concessions VALUES (2, 'Nachos', 'Food', 7.00, 200);
INSERT INTO Concessions VALUES (3, 'Large Icee', 'Beverage', 6.50, 300);
INSERT INTO Concessions VALUES (4, 'Sour Patch Kids', 'Candy', 4.50, 250);
INSERT INTO Concessions VALUES (5, 'Hot Dog', 'Food', 6.00, 100);
INSERT INTO Concessions VALUES (6, 'Bottled Water', 'Beverage', 4.00, 1000);
INSERT INTO Concessions VALUES (7, 'M&Ms', 'Candy', 4.50, 400);


-- Customers 
INSERT INTO Customers VALUES (1, 'John Doe', 'john@email.com', 2, 25);
INSERT INTO Customers VALUES (2, 'Jane Miller', 'jane@email.com', 1, 10);
INSERT INTO Customers VALUES (3, 'Guest User', 'guest@none.com', NULL, 0);
INSERT INTO Customers VALUES (4, 'Leon Kennedy', 'leonk@dso.org', 1, 150);
INSERT INTO Customers VALUES (5, 'Temoc Rats', 'txr100000@utdallas.edu', 1, 45);
INSERT INTO Customers VALUES (6, 'Bruce Wayne', 'bruce@wayneent.com', 2, 500);


-- Seats for Auditorium 1
INSERT INTO Seats VALUES (1, 1, 'A', 1, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (2, 1, 'A', 2, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (3, 1, 'B', 1, 'Disabled', 'Vacant');

-- Seats for Auditorium 2
INSERT INTO Seats VALUES (4, 2, 'A', 1, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (5, 2, 'A', 2, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (6, 2, 'B', 1, 'VIP', 'Vacant');

-- Seats for Auditorium 5
INSERT INTO Seats VALUES (7, 5, 'J', 10, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (8, 5, 'J', 11, 'Standard', 'Vacant');
INSERT INTO Seats VALUES (9, 5, 'K', 1, 'Disabled', 'Vacant');

-- Scheduled Showtimes
INSERT INTO Showtimes VALUES (1, 1, 1, '2026-04-12', '14:00:00', '15:45:00', 1);
INSERT INTO Showtimes VALUES (2, 2, 2, '2026-04-12', '19:00:00', '21:15:00', 1);
INSERT INTO Showtimes VALUES (3, 3, 4, '2026-04-21', '21:30:00', '23:30:00', 1);
INSERT INTO Showtimes VALUES (4, 7, 5, '2026-04-21', '22:00:00', '23:55:00', 1);
INSERT INTO Showtimes VALUES (5, 1, 1, '2026-04-21', '10:00:00', '11:45:00', 1);
INSERT INTO Showtimes VALUES (10, 2, 1, '2026-04-21', '13:00:00', '14:45:00', 1);
INSERT INTO Showtimes VALUES (11, 5, 1, '2026-04-21', '16:00:00', '17:45:00', 1);
INSERT INTO Showtimes VALUES (12, 2, 5, '2026-04-21', '19:00:00', '21:15:00', 1);
INSERT INTO Showtimes VALUES (13, 6, 2, '2026-04-21', '21:30:00', '23:30:00', 1);
INSERT INTO Showtimes VALUES (14, 7, 4, '2026-04-21', '18:30:00', '20:20:00', 1);
INSERT INTO Showtimes VALUES (15, 4, 3, '2026-04-21', '20:00:00', '22:30:00', 1);

-- Payment Records
INSERT INTO Payments VALUES (5001, 25.50, 'Credit Card', '2026-04-12 13:30:00');
INSERT INTO Payments VALUES (5002, 15.00, 'Cash', '2026-04-12 14:00:00');

-- Individual Tickets
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

-- Transaction: Bruce Wayne buys 2 VIP tickets and lots of snacks
INSERT INTO Payments VALUES (5003, 85.00, 'Credit Card', '2026-04-12 18:45:00');
INSERT INTO Tickets VALUES (1003, 5003, 'Adult', 25.00);
INSERT INTO Tickets VALUES (1004, 5003, 'Adult', 25.00);
INSERT INTO Books VALUES (1003, 6, 3); -- Seat 6, Showtime 3
INSERT INTO Books VALUES (1004, 4, 3); -- Seat 4, Showtime 3
INSERT INTO Pays_for VALUES (5003, 1, 2); -- 2 Large Popcorns
INSERT INTO Pays_for VALUES (5003, 6, 2); -- 2 Waters
INSERT INTO Makes VALUES (6, 101, 5003); -- Managed by Alice Smith (Manager)

-- Transaction: Guest User buys a Hot Dog and a Movie Ticket
INSERT INTO Payments VALUES (5004, 21.00, 'Cash', '2026-04-12 21:45:00');
INSERT INTO Tickets VALUES (1005, 5004, 'Adult', 15.00);
INSERT INTO Books VALUES (1005, 7, 4);
INSERT INTO Pays_for VALUES (5004, 5, 1); -- 1 Hot Dog
INSERT INTO Makes VALUES (3, 106, 5004); -- Assisted by Peter Parker


-- ============================================================
-- SECTION 1: SEATS GENERATION
-- ============================================================
DROP PROCEDURE IF EXISTS generate_seats;

DELIMITER $$

CREATE PROCEDURE generate_seats()
BEGIN
    DECLARE v_room        INT;
    DECLARE v_row_idx     INT;
    DECLARE v_seat_num    INT;
    DECLARE v_seat_id     INT DEFAULT 100;
    DECLARE v_row_letter  CHAR(1);
    DECLARE v_type        VARCHAR(20);
    DECLARE v_rows        INT;

    SET v_room = 1;
    WHILE v_room <= 5 DO

        -- Corrected Row Counts to match your specifications
        CASE v_room
            WHEN 1 THEN SET v_rows = 10; -- 100 seats (IDs 100-199)
            WHEN 2 THEN SET v_rows = 10; -- 100 seats (IDs 200-299)
            WHEN 3 THEN SET v_rows = 6;  -- 60 seats  (IDs 300-359)
            WHEN 4 THEN SET v_rows = 8;  -- 80 seats  (IDs 360-439)
            WHEN 5 THEN SET v_rows = 12; -- 120 seats (IDs 440-559)
        END CASE;

        SET v_row_idx = 1;
        WHILE v_row_idx <= v_rows DO
            SET v_row_letter = CHAR(64 + v_row_idx);
            SET v_seat_num = 1;
            
            WHILE v_seat_num <= 10 DO
                -- Assign seat type
                IF v_row_idx = 1 THEN
                    SET v_type = 'VIP';
                ELSEIF v_row_idx = v_rows THEN
                    SET v_type = 'Disabled';
                ELSE
                    SET v_type = 'Standard';
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM Seats
                    WHERE room_number = v_room
                      AND row_letter  = v_row_letter
                      AND seat_number = v_seat_num
                ) THEN
                    INSERT INTO Seats (seat_id, room_number, row_letter, seat_number, type, status)
                    VALUES (v_seat_id, v_room, v_row_letter, v_seat_num, v_type, 'Vacant');
                    SET v_seat_id = v_seat_id + 1;
                END IF;

                SET v_seat_num = v_seat_num + 1;
            END WHILE;
            SET v_row_idx = v_row_idx + 1;
        END WHILE;
        SET v_room = v_room + 1;
    END WHILE;
END$$

DELIMITER ;

CALL generate_seats();
DROP PROCEDURE IF EXISTS generate_seats;

-- ============================================================
-- SECTION 2: CUSTOMERS
-- ============================================================
INSERT INTO Customers VALUES (7, 'Rishabh Patel','rishpatel@email.com',2,180);
INSERT INTO Customers VALUES (8, 'Carlos Garza','carlos@email.com',1,5);
INSERT INTO Customers VALUES (9, 'Priya Senthil','priya@email.com',NULL, 0);
INSERT INTO Customers VALUES (10, 'James Wu','jameswu@email.com',1, 30);
INSERT INTO Customers VALUES (11, 'Aaliyah Brooks','aaliyah@email.com', 2, 200);
INSERT INTO Customers VALUES (12, 'Ethan Nguyen','ethan@email.com', NULL, 0);
INSERT INTO Customers VALUES (13, 'Sofia Delgado','sofia@email.com', 1, 15);
INSERT INTO Customers VALUES (14, 'Noah Kim','noah@email.com', 2, 90);
INSERT INTO Customers VALUES (15, 'Lena Miller','lena@email.com', NULL, 0);

-- ============================================================
-- SECTION 3: TRANSACTIONS (Corrected Seat ID Mapping)
-- ============================================================

-- Transaction 5: Rishabh Patel (Room 5 starts at ID 440)
INSERT INTO Payments  VALUES (5005, 58.00, 'Credit Card', '2026-04-21 18:15:00');
INSERT INTO Tickets   VALUES (1006, 5005, 'Adult', 15.00);
INSERT INTO Tickets   VALUES (1007, 5005, 'Adult', 15.00);
INSERT INTO Books     VALUES (1006, 440, 12);  
INSERT INTO Books     VALUES (1007, 441, 12);
INSERT INTO Pays_for  VALUES (5005, 1, 2);      
INSERT INTO Pays_for  VALUES (5005, 3, 2);      
INSERT INTO Makes     VALUES (7, 103, 5005);

-- Transaction 6: Carlos Garza (Room 1 starts at 100)
INSERT INTO Payments  VALUES (5006, 16.50, 'Cash', '2026-04-21 09:45:00');
INSERT INTO Tickets   VALUES (1008, 5006, 'Senior', 12.00);
INSERT INTO Books     VALUES (1008, 102, 5);
INSERT INTO Pays_for  VALUES (5006, 4, 1);      
INSERT INTO Makes     VALUES (8, 103, 5006);

-- Transaction 7: Guest (Room 4 starts at 360)
INSERT INTO Payments  VALUES (5007, 15.00, 'Cash', '2026-04-21 18:00:00');
INSERT INTO Tickets   VALUES (1009, 5007, 'Adult', 15.00);
INSERT INTO Books     VALUES (1009, 360, 14);
INSERT INTO Makes     VALUES (3, 103, 5007);

-- Transaction 8: Priya Senthil (Room 3 starts at 300)
INSERT INTO Payments  VALUES (5008, 22.00, 'Debit Card', '2026-04-21 21:00:00');
INSERT INTO Tickets   VALUES (1010, 5008, 'Adult', 15.00);
INSERT INTO Books     VALUES (1010, 300, 3);
INSERT INTO Pays_for  VALUES (5008, 2, 1);      
INSERT INTO Makes     VALUES (9, 106, 5008);

-- Transaction 9: James Wu (Room 1)
INSERT INTO Payments  VALUES (5009, 45.00, 'Credit Card', '2026-04-21 12:30:00');
INSERT INTO Tickets   VALUES (1011, 5009, 'Adult', 15.00);
INSERT INTO Tickets   VALUES (1012, 5009, 'Child', 10.00);
INSERT INTO Books     VALUES (1011, 105, 10);
INSERT INTO Books     VALUES (1012, 106, 10);
INSERT INTO Pays_for  VALUES (5009, 5, 1);      
INSERT INTO Pays_for  VALUES (5009, 6, 2);      
INSERT INTO Makes     VALUES (10, 104, 5009);

-- Transaction 10: Aaliyah Brooks (Room 2 starts at 200)
INSERT INTO Payments  VALUES (5010, 95.00, 'Credit Card', '2026-04-21 21:00:00');
INSERT INTO Tickets   VALUES (1013, 5010, 'Adult', 25.00);
INSERT INTO Tickets   VALUES (1014, 5010, 'Adult', 25.00);
INSERT INTO Tickets   VALUES (1015, 5010, 'Adult', 25.00);
INSERT INTO Books     VALUES (1013, 200, 13);
INSERT INTO Books     VALUES (1014, 201, 13);
INSERT INTO Books     VALUES (1015, 202, 13);
INSERT INTO Pays_for  VALUES (5010, 7, 3);      
INSERT INTO Makes     VALUES (11, 101, 5010);

-- Transaction 11: Ethan Nguyen (Room 1)
INSERT INTO Payments  VALUES (5011, 23.50, 'Cash', '2026-04-21 15:45:00');
INSERT INTO Tickets   VALUES (1016, 5011, 'Adult', 15.00);
INSERT INTO Books     VALUES (1016, 110, 11);
INSERT INTO Pays_for  VALUES (5011, 1, 1);      
INSERT INTO Makes     VALUES (12, 102, 5011);

-- Transaction 12: Sofia Delgado (Room 3)
INSERT INTO Payments  VALUES (5012, 19.00, 'Debit Card', '2026-04-21 19:45:00');
INSERT INTO Tickets   VALUES (1017, 5012, 'Senior', 12.00);
INSERT INTO Books     VALUES (1017, 311, 15);
INSERT INTO Pays_for  VALUES (5012, 4, 1);      
INSERT INTO Makes     VALUES (13, 105, 5012);

-- Transaction 13: Noah Kim (Room 2)
INSERT INTO Payments  VALUES (5013, 72.00, 'Credit Card', '2026-04-12 18:30:00');
INSERT INTO Tickets   VALUES (1018, 5013, 'Adult', 25.00);
INSERT INTO Tickets   VALUES (1019, 5013, 'Adult', 25.00);
INSERT INTO Books     VALUES (1018, 212, 2);
INSERT INTO Books     VALUES (1019, 213, 2);
INSERT INTO Pays_for  VALUES (5013, 1, 1);
INSERT INTO Makes     VALUES (14, 101, 5013);

-- Transaction 14: Leon Kennedy (Room 1)
INSERT INTO Payments  VALUES (5014, 19.50, 'Cash', '2026-04-21 21:45:00');
INSERT INTO Tickets   VALUES (1020, 5014, 'Adult', 15.00);
INSERT INTO Books     VALUES (1020, 114, 4);
INSERT INTO Pays_for  VALUES (5014, 7, 1);
INSERT INTO Makes     VALUES (4, 106, 5014);

-- Transaction 15: Lena Miller (Room 1)
INSERT INTO Payments  VALUES (5015, 19.00, 'Debit Card', '2026-04-12 13:45:00');
INSERT INTO Tickets   VALUES (1021, 5015, 'Adult', 15.00);
INSERT INTO Books     VALUES (1021, 115, 1);
INSERT INTO Pays_for  VALUES (5015, 6, 1);
INSERT INTO Makes     VALUES (15, 103, 5015);

-- ============================================================
-- SECTION 4: UPDATE SEAT STATUSES
-- ============================================================
UPDATE Seats SET status = 'Occupied' WHERE seat_id IN (
    1, 2, 4, 6, 7,  -- Existing
    440, 441,       -- Rishabh (Room 5)
    102,            -- Carlos (Room 1)
    360,            -- Guest (Room 4)
    300,            -- Priya (Room 3)
    105, 106,       -- James (Room 1)
    200, 201, 202,  -- Aaliyah (Room 2)
    110,            -- Ethan (Room 1)
    311,            -- Sofia (Room 3)
    212, 213,       -- Noah (Room 2)
    114,            -- Leon (Room 1)
    115             -- Lena (Room 1)
);

-- ============================================================
-- SECTION 5 & 6 (Stock and Points) - These look good!
-- ============================================================
UPDATE Concessions SET stock_level = stock_level - 8  WHERE item_id = 1;
UPDATE Concessions SET stock_level = stock_level - 2  WHERE item_id = 2;
UPDATE Concessions SET stock_level = stock_level - 3  WHERE item_id = 3;
UPDATE Concessions SET stock_level = stock_level - 2  WHERE item_id = 4;
UPDATE Concessions SET stock_level = stock_level - 2  WHERE item_id = 5;
UPDATE Concessions SET stock_level = stock_level - 3  WHERE item_id = 6;
UPDATE Concessions SET stock_level = stock_level - 4  WHERE item_id = 7;

UPDATE Customers SET reward_points = reward_points + 60 WHERE customer_id = 7;
UPDATE Customers SET reward_points = reward_points + 12 WHERE customer_id = 8;
UPDATE Customers SET reward_points = reward_points + 25 WHERE customer_id = 10;
UPDATE Customers SET reward_points = reward_points + 150 WHERE customer_id = 11;
UPDATE Customers SET reward_points = reward_points + 12 WHERE customer_id = 13;
UPDATE Customers SET reward_points = reward_points + 100 WHERE customer_id = 14;
UPDATE Customers SET reward_points = reward_points + 15 WHERE customer_id = 4;


-- ============================================================
-- SECTION 3.5: FILLING THE GAPS (New Transactions)
-- ============================================================

-- ── Transaction 16: Priya Senthil (Customer 9) brings a group of 4
-- Showtime 11 (Movie 5, Room 1) - May 1st, 2026
INSERT INTO Payments VALUES (5016, 85.00, 'Credit Card', '2026-05-01 15:30:00');
INSERT INTO Tickets VALUES 
(1022, 5016, 'Adult', 15.00), (1023, 5016, 'Adult', 15.00),
(1024, 5016, 'Child', 10.00), (1025, 5016, 'Child', 10.00);

INSERT INTO Books VALUES 
(1022, (SELECT seat_id FROM Seats WHERE room_number=1 AND row_letter='F' AND seat_number=1), 11),
(1023, (SELECT seat_id FROM Seats WHERE room_number=1 AND row_letter='F' AND seat_number=2), 11),
(1024, (SELECT seat_id FROM Seats WHERE room_number=1 AND row_letter='F' AND seat_number=3), 11),
(1025, (SELECT seat_id FROM Seats WHERE room_number=1 AND row_letter='F' AND seat_number=4), 11);

-- Big snack order for the kids
INSERT INTO Pays_for VALUES (5016, 1, 2), (5016, 7, 2), (5016, 6, 4);
INSERT INTO Makes VALUES (9, 105, 5016); -- Finally a sale for Sarah Connor


-- ── Transaction 17: Ethan Nguyen (Customer 12) - Last minute Late Night
-- Showtime 3 (Movie 3, Room 4) - April 21st
INSERT INTO Payments VALUES (5017, 21.50, 'Apple Pay', '2026-04-21 21:10:00');
INSERT INTO Tickets VALUES (1026, 5017, 'Adult', 15.00);
INSERT INTO Books   VALUES (1026, (SELECT seat_id FROM Seats WHERE room_number=4 AND row_letter='C' AND seat_number=5), 3);
INSERT INTO Pays_for VALUES (5017, 3, 1); -- Large Icee
INSERT INTO Makes VALUES (12, 106, 5017);


-- ── Transaction 18: Lena Miller (Customer 15) - Afternoon Matinee
-- Showtime 10 (Movie 2, Room 1) - May 2nd, 2026
INSERT INTO Payments VALUES (5018, 12.00, 'Debit Card', '2026-05-02 12:45:00');
INSERT INTO Tickets VALUES (1027, 5018, 'Senior', 12.00);
INSERT INTO Books   VALUES (1027, (SELECT seat_id FROM Seats WHERE room_number=1 AND row_letter='G' AND seat_number=10), 10);
INSERT INTO Makes VALUES (15, 102, 5018);


-- ============================================================
-- SECTION 4.5: UPDATE STATUS & STOCK
-- ============================================================

-- Mark these new seats as Occupied
UPDATE Seats SET status = 'Occupied' WHERE seat_id IN (SELECT seat_id FROM Books);

-- Deduct the new snacks sold
UPDATE Concessions SET stock_level = stock_level - 2 WHERE item_id = 1; -- Popcorn
UPDATE Concessions SET stock_level = stock_level - 1 WHERE item_id = 3; -- Icee
UPDATE Concessions SET stock_level = stock_level - 4 WHERE item_id = 6; -- Water
UPDATE Concessions SET stock_level = stock_level - 2 WHERE item_id = 7; -- M&Ms

-- Filling out the schedule for Room 1 (April 12 - April 21)
-- Matinees and Evenings
INSERT INTO Showtimes (showtime_id, movie_id, room_number, date, start_time, end_time, is_active) VALUES 
-- April 12
(30, 6, 1, '2026-04-12', '11:00:00', '12:40:00', 1),
(31, 2, 1, '2026-04-12', '17:30:00', '19:45:00', 1),
-- April 13 (A Monday)
(32, 1, 1, '2026-04-13', '13:00:00', '14:45:00', 1),
(33, 5, 1, '2026-04-13', '16:00:00', '17:45:00', 1),
(34, 2, 1, '2026-04-13', '19:30:00', '21:45:00', 1),
-- April 14
(35, 1, 1, '2026-04-14', '14:00:00', '15:45:00', 1),
(36, 7, 1, '2026-04-14', '17:00:00', '18:45:00', 1),
-- April 15
(37, 2, 1, '2026-04-15', '12:00:00', '14:15:00', 1),
(38, 4, 1, '2026-04-15', '15:30:00', '17:35:00', 1),
(39, 3, 1, '2026-04-15', '19:00:00', '21:00:00', 1),
-- April 16
(40, 6, 1, '2026-04-16', '10:00:00', '11:40:00', 1),
(41, 1, 1, '2026-04-16', '16:30:00', '18:15:00', 1),
-- April 17 (Friday Night)
(42, 1, 1, '2026-04-17', '11:30:00', '13:15:00', 1),
(43, 2, 1, '2026-04-17', '14:30:00', '16:45:00', 1),
(44, 3, 1, '2026-04-17', '21:00:00', '23:00:00', 1),
-- April 18
(45, 5, 1, '2026-04-18', '12:00:00', '13:45:00', 1),
(46, 1, 1, '2026-04-18', '15:00:00', '16:45:00', 1),
-- April 19
(47, 7, 1, '2026-04-19', '13:00:00', '14:45:00', 1),
(48, 2, 1, '2026-04-19', '17:00:00', '19:15:00', 1),
(49, 4, 1, '2026-04-19', '20:00:00', '22:05:00', 1),
-- April 20
(50, 6, 1, '2026-04-20', '14:00:00', '15:40:00', 1),
(51, 3, 1, '2026-04-20', '18:00:00', '20:00:00', 1);
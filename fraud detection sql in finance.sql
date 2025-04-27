-- Create and use database
CREATE DATABASE IF NOT EXISTS sql_surya;
USE sql_surya;

-- Step 1: Create Schema
-- Create Users table
CREATE TABLE IF NOT EXISTS Users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    signup_date DATE NOT NULL
);

-- Create Transactions table
CREATE TABLE IF NOT EXISTS Transactions (
    trans_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    trans_date TIMESTAMP NOT NULL,
    location VARCHAR(100) NOT NULL,
    device_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Create Flagged_Transactions table
CREATE TABLE IF NOT EXISTS Flagged_Transactions (
    flag_id INT PRIMARY KEY AUTO_INCREMENT,
    trans_id INT NOT NULL,
    flag_reason VARCHAR(200) NOT NULL,
    flag_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (trans_id) REFERENCES Transactions(trans_id)
);

-- Step 2: Data Generation
-- 2.1: Populate Users Table (500 users)
INSERT IGNORE INTO Users (user_id, name, email, signup_date)
SELECT 
    n AS user_id,
    CONCAT('User_', n) AS name,
    CONCAT('user_', n, '@example.com') AS email,
    DATE_SUB('2025-04-01', INTERVAL FLOOR(RAND() * 1825) DAY) AS signup_date
FROM (
    SELECT a.N + b.N * 10 + 1 AS n
    FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    ORDER BY n
    LIMIT 500
) numbers;

-- 2.2: Populate Transactions Table (10,000 transactions)
-- Drop temporary table if it exists
DROP TEMPORARY TABLE IF EXISTS Locations;

-- Create temporary table for locations
CREATE TEMPORARY TABLE Locations (
    location VARCHAR(100)
);
INSERT INTO Locations (location)
VALUES ('New York, USA'), ('London, UK'), ('Tokyo, Japan'), ('Sydney, Australia'), ('Mumbai, India'), ('Moscow, Russia'), ('Sao Paulo, Brazil');

-- Insert 9,500 normal transactions
INSERT IGNORE INTO Transactions (trans_id, user_id, amount, trans_date, location, device_id)
SELECT 
    n AS trans_id,
    FLOOR(1 + RAND() * 500) AS user_id,
    ROUND(10 + RAND() * 9990, 2) AS amount,
    DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * (465 * 86400)) SECOND) AS trans_date,
    (SELECT location FROM Locations ORDER BY RAND() LIMIT 1) AS location,
    CONCAT('device_', FLOOR(1 + RAND() * 100)) AS device_id
FROM (
    SELECT a.N + b.N * 10 + c.N * 100 + d.N * 1000 + 1 AS n
    FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) c,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) d
    ORDER BY n
    LIMIT 9500
) numbers;

-- Insert 500 suspicious transactions
INSERT IGNORE INTO Transactions (trans_id, user_id, amount, trans_date, location, device_id)
SELECT 
    9501 + n AS trans_id,
    FLOOR(1 + RAND() * 500) AS user_id,
    CASE 
        WHEN n % 3 = 0 THEN ROUND(5000 + RAND() * 5000, 2)
        ELSE ROUND(10 + RAND() * 500, 2)
    END AS amount,
    CASE 
        WHEN n % 5 = 0 THEN DATE_ADD('2025-04-01', INTERVAL FLOOR(RAND() * 60) SECOND)
        ELSE DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * (465 * 86400)) SECOND)
    END AS trans_date,
    CASE 
        WHEN n % 4 = 0 THEN 'Unknown Location'
        ELSE (SELECT location FROM Locations ORDER BY RAND() LIMIT 1)
    END AS location,
    CASE 
        WHEN n % 6 = 0 THEN 'unknown_device'
        ELSE CONCAT('device_', FLOOR(1 + RAND() * 100))
    END AS device_id
FROM (
    SELECT a.N + b.N * 10 + 1 AS n
    FROM 
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
        (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
    ORDER BY n
    LIMIT 500
) numbers;

-- Drop temporary table
DROP TEMPORARY TABLE IF EXISTS Locations;

-- Step 3: Fraud Detection Queries
-- 3.1: Rapid Transactions (Within 5 Minutes)
INSERT INTO Flagged_Transactions (trans_id, flag_reason)
SELECT 
    trans_id,
    'Rapid transactions within 5 minutes' AS flag_reason
FROM (
    SELECT 
        trans_id,
        user_id,
        trans_date,
        LAG(trans_date) OVER (PARTITION BY user_id ORDER BY trans_date) AS prev_trans_date,
        TIMESTAMPDIFF(SECOND, LAG(trans_date) OVER (PARTITION BY user_id ORDER BY trans_date), trans_date) AS time_diff
    FROM Transactions
) t
WHERE time_diff IS NOT NULL AND time_diff <= 300;

-- 3.2: High Amount Transactions
INSERT INTO Flagged_Transactions (trans_id, flag_reason)
SELECT 
    trans_id,
    'Transaction amount exceeds $5000' AS flag_reason
FROM Transactions
WHERE amount > 5000;

-- 3.3: Unusual Locations
-- Flag Unknown Location
INSERT INTO Flagged_Transactions (trans_id, flag_reason)
SELECT 
    trans_id,
    'Transaction from unknown location' AS flag_reason
FROM Transactions
WHERE location = 'Unknown Location';

-- Flag Rapid Location Changes
INSERT INTO Flagged_Transactions (trans_id, flag_reason)
SELECT 
    trans_id,
    'Rapid location change' AS flag_reason
FROM (
    SELECT 
        trans_id,
        user_id,
        trans_date,
        location,
        LAG(location) OVER (PARTITION BY user_id ORDER BY trans_date) AS prev_location,
        TIMESTAMPDIFF(HOUR, LAG(trans_date) OVER (PARTITION BY user_id ORDER BY trans_date), trans_date) AS time_diff
    FROM Transactions
) t
WHERE time_diff IS NOT NULL AND time_diff <= 1 AND location != prev_location;

-- 3.4: Suspicious Devices
INSERT INTO Flagged_Transactions (trans_id, flag_reason)
SELECT 
    trans_id,
    'Transaction from unknown device' AS flag_reason
FROM Transactions
WHERE device_id = 'unknown_device';

-- Step 4: Reporting Query
SELECT 
    ft.flag_id,
    ft.trans_id,
    ft.flag_reason,
    ft.flag_date,
    t.user_id,
    u.name AS user_name,
    t.amount,
    t.trans_date,
    t.location,
    t.device_id
FROM Flagged_Transactions ft
JOIN Transactions t ON ft.trans_id = t.trans_id
JOIN Users u ON t.user_id = u.user_id
ORDER BY ft.flag_date DESC;

-- Step 5: Optional Enhancements
-- 5.1: Indexes
CREATE INDEX idx_user_id ON Transactions(user_id);
CREATE INDEX idx_trans_date ON Transactions(trans_date);

-- 5.2: Stored Procedure
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS RunFraudDetection()
BEGIN
    -- Clear existing flags for re-run
    TRUNCATE TABLE Flagged_Transactions;

    -- Run all detection queries
    INSERT INTO Flagged_Transactions (trans_id, flag_reason)
    SELECT 
        trans_id,
        'Rapid transactions within 5 minutes'
    FROM (
        SELECT 
            trans_id,
            user_id,
            trans_date,
            TIMESTAMPDIFF(SECOND, LAG(trans_date) OVER (PARTITION BY user_id ORDER BY trans_date), trans_date) AS time_diff
        FROM Transactions
    ) t
    WHERE time_diff IS NOT NULL AND time_diff <= 300;

    INSERT INTO Flagged_Transactions (trans_id, flag_reason)
    SELECT 
        trans_id,
        'Transaction amount exceeds $5000'
    FROM Transactions
    WHERE amount > 5000;

    INSERT INTO Flagged_Transactions (trans_id, flag_reason)
    SELECT 
        trans_id,
        'Transaction from unknown location'
    FROM Transactions
    WHERE location = 'Unknown Location';

    INSERT INTO Flagged_Transactions (trans_id, flag_reason)
    SELECT 
        trans_id,
        'Rapid location change'
    FROM (
        SELECT 
            trans_id,
            user_id,
            trans_date,
            location,
            LAG(location) OVER (PARTITION BY user_id ORDER BY trans_date) AS prev_location,
            TIMESTAMPDIFF(HOUR, LAG(trans_date) OVER (PARTITION BY user_id ORDER BY trans_date), trans_date) AS time_diff
        FROM Transactions
    ) t
    WHERE time_diff IS NOT NULL AND time_diff <= 1 AND location != prev_location;

    INSERT INTO Flagged_Transactions (trans_id, flag_reason)
    SELECT 
        trans_id,
        'Transaction from unknown device'
    FROM Transactions
    WHERE device_id = 'unknown_device';
END //

DELIMITER ;

-- Call the stored procedure
CALL RunFraudDetection();
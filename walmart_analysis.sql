-- Create database and use it
CREATE DATABASE IF NOT EXISTS walmartSales;
USE walmartSales;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Walmart_Sales_Data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- Create table if not exists
CREATE TABLE IF NOT EXISTS sales (
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12,4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12,4),
    rating FLOAT(2,1)
);

-- Add time_of_day column if not exists
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS 
                WHERE TABLE_NAME = 'sales' AND COLUMN_NAME = 'time_of_day');
SET @sql := IF(@exists = 0, 'ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);', 'SELECT "Column exists";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update time_of_day values
UPDATE sales
SET time_of_day = CASE
    WHEN `time` BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
    WHEN `time` BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
    ELSE 'Evening'
END;

-- Add day_name column if not exists
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS 
                WHERE TABLE_NAME = 'sales' AND COLUMN_NAME = 'day_name');
SET @sql := IF(@exists = 0, 'ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);', 'SELECT "Column exists";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update day_name values
UPDATE sales
SET day_name = DAYNAME(date);

-- Add month_name column if not exists
SET @exists := (SELECT COUNT(*) FROM information_schema.COLUMNS 
                WHERE TABLE_NAME = 'sales' AND COLUMN_NAME = 'month_name');
SET @sql := IF(@exists = 0, 'ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);', 'SELECT "Column exists";');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Update month_name values
UPDATE sales
SET month_name = MONTHNAME(date);

-- ---------------------------- Analysis ----------------------------

-- Unique cities
SELECT DISTINCT city FROM sales;

-- City per branch
SELECT DISTINCT city, branch FROM sales;

-- Unique product lines
SELECT DISTINCT product_line FROM sales;

-- Most selling product line
SELECT product_line, SUM(quantity) AS qty
FROM sales
GROUP BY product_line
ORDER BY qty DESC;

-- Total revenue by month
SELECT month_name AS month, SUM(total) AS total_revenue
FROM sales
GROUP BY month_name
ORDER BY total_revenue DESC;

-- Month with largest COGS
SELECT month_name AS month, SUM(cogs) AS total_cogs
FROM sales
GROUP BY month_name
ORDER BY total_cogs DESC;

-- Product line with largest revenue
SELECT product_line, SUM(total) AS total_revenue
FROM sales
GROUP BY product_line
ORDER BY total_revenue DESC;

-- City with largest revenue
SELECT city, branch, SUM(total) AS total_revenue
FROM sales
GROUP BY city, branch
ORDER BY total_revenue DESC;

-- Product line with highest VAT
SELECT product_line, AVG(tax_pct) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY avg_tax DESC;

-- Product line performance: Good/Bad
SELECT product_line,
       CASE WHEN AVG(quantity) > (SELECT AVG(quantity) FROM sales) THEN 'Good' ELSE 'Bad' END AS remark
FROM sales
GROUP BY product_line;

-- Branches selling above average
SELECT branch, SUM(quantity) AS total_quantity
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- Most common product line by gender
SELECT gender, product_line, COUNT(*) AS total_count
FROM sales
GROUP BY gender, product_line
ORDER BY total_count DESC;

-- Average rating per product line
SELECT product_line, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;

-- Unique customer types
SELECT DISTINCT customer_type FROM sales;

-- Unique payment methods
SELECT DISTINCT payment FROM sales;

-- Most common customer type
SELECT customer_type, COUNT(*) AS count
FROM sales
GROUP BY customer_type
ORDER BY count DESC;

-- Customer type buying most
SELECT customer_type, COUNT(*) AS count
FROM sales
GROUP BY customer_type
ORDER BY count DESC;

-- Gender distribution
SELECT gender, COUNT(*) AS gender_count
FROM sales
GROUP BY gender
ORDER BY gender_count DESC;

-- Gender distribution per branch
SELECT branch, gender, COUNT(*) AS gender_count
FROM sales
GROUP BY branch, gender
ORDER BY branch, gender_count DESC;

-- Ratings by time of day
SELECT time_of_day, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;

-- Ratings by time of day per branch
SELECT branch, time_of_day, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY branch, time_of_day
ORDER BY branch, avg_rating DESC;

-- Ratings by day of week
SELECT day_name, ROUND(AVG(rating), 2) AS avg_rating
FROM sales
GROUP BY day_name
ORDER BY avg_rating DESC;

-- Sales count per day for branch C
SELECT day_name, COUNT(*) AS total_sales
FROM sales
WHERE branch = 'C'
GROUP BY day_name
ORDER BY total_sales DESC;

-- Sales by time of day on Sunday
SELECT time_of_day, COUNT(*) AS total_sales
FROM sales
WHERE day_name = 'Sunday'
GROUP BY time_of_day
ORDER BY total_sales DESC;

-- Revenue by customer type
SELECT customer_type, SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- City with highest VAT
SELECT city, ROUND(AVG(tax_pct), 2) AS avg_tax_pct
FROM sales
GROUP BY city
ORDER BY avg_tax_pct DESC;

-- Customer type paying most VAT
SELECT customer_type, ROUND(AVG(tax_pct), 2) AS avg_tax
FROM sales
GROUP BY customer_type
ORDER BY avg_tax DESC;
-- Create database
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- Drop tables if they exist
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- USERS
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50),
    email VARCHAR(100),
    created_at DATE
);

-- PRODUCTS
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    category_id INT,
    price DECIMAL(10,2)
);

-- ORDERS
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    order_date DATE,
    total DECIMAL(10,2),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ORDER_ITEMS
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    qty INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- repeat for products, orders, order_items


USE ecommerce;

-- 1. Basic listing: last 20 orders since Jan 2024
SELECT order_id, user_id, order_date, total
FROM orders
WHERE order_date >= '2024-01-01'
ORDER BY order_date DESC
LIMIT 20;

-- 2. Monthly revenue + active users
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       SUM(total)        AS revenue,
       COUNT(DISTINCT user_id) AS active_users
FROM orders
GROUP BY month
ORDER BY month;

-- 3. Top 10 products by revenue
SELECT p.product_id, p.name,
       SUM(oi.qty * oi.price) AS revenue
FROM order_items oi
JOIN products p  ON oi.product_id = p.product_id
JOIN orders   o  ON oi.order_id   = o.order_id
GROUP BY p.product_id, p.name
ORDER BY revenue DESC
LIMIT 10;

-- 4. Products never sold (LEFT JOIN)
SELECT p.product_id, p.name,
       COALESCE(SUM(oi.qty),0) AS units_sold
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name
HAVING units_sold = 0;

-- 5. Subqueries
-- (a) Products above overall avg price
SELECT product_id, name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- (b) Correlated subquery: price > category avg
SELECT p.product_id, p.name, p.category_id, p.price
FROM products p
WHERE p.price > (
        SELECT AVG(price)
        FROM products p2
        WHERE p2.category_id = p.category_id
      );

-- 6. ARPU overall & by month
SELECT SUM(total)/COUNT(DISTINCT user_id) AS ARPU FROM orders;

SELECT DATE_FORMAT(order_date,'%Y-%m') AS month,
       SUM(total)/COUNT(DISTINCT user_id) AS ARPU
FROM orders
GROUP BY month
ORDER BY month;

-- 7. Create a view
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT DATE_FORMAT(order_date,'%Y-%m') AS month,
       SUM(total) AS revenue
FROM orders
GROUP BY month;

-- 8. Optimization: add indexes
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_orders_userid     ON orders(user_id);
CREATE INDEX idx_orderitems_prod   ON order_items(product_id);

-- 9. Show execution plan (run before/after indexes)
EXPLAIN
SELECT p.product_id, p.name,
       SUM(oi.qty * oi.price) AS revenue
FROM order_items oi
JOIN products p  ON oi.product_id = p.product_id
GROUP BY p.product_id, p.name;

-- 10. Handling NULLs example
SELECT product_id, COALESCE(price,0) AS price_nonnull
FROM products;

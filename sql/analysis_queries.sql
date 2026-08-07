SELECT * FROM customers
SELECT * FROM orders
SELECT * FROM order_items
SELECT * FROM order_payments
SELECT * FROM order_reviews limit 10
SELECT * FROM products limit 50
SELECT * FROM product_category_name_translation limit 30
SELECT * FROM sellers
SELECT * FROM geolocation


SELECT COUNT(DISTINCT customer_id)
FROM customers;

--table data/schema validation query format

SELECT * FROM order_reviews

SELECT COUNT(*)
FROM 

SELECT COUNT(*) FROM sellers;

SELECT COUNT(DISTINCT seller_id)
FROM sellers

SELECT order_id, COUNT(*) FROM order_payments
GROUP BY order_id
ORDER BY order_id DESC

---------------------------------------

SELECT * FROM orders

SELECT COUNT(*)
FROM orders;

SELECT COUNT(DISTINCT order_id)
FROM orders;

---------------------------------------

SELECT * FROM order_items

SELECT COUNT(*)
FROM order_items;

SELECT COUNT(DISTINCT order_id)
FROM order_items;


------------------------------------ business queries ------------------------------------


---------- "What kinds of orders exist in the business?" ----------

SELECT 
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

---------- "What is the average delivery time?" ----------

SELECT
    AVG(order_delivered_customer_date - order_purchase_timestamp) AS avg_interval
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

SELECT
order_id,
(order_delivered_customer_date - order_purchase_timestamp) AS delivery_time
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
ORDER BY
LIMIT 100;


---------- JOIN QUERIES ----------
-- "What products were ordered by customers,
-- where are those customers located,
-- what is the order status,
-- and how much did the products cost?"

-- we can add/remove "ORDER BY RANDOM()" above "LIMIT 20" and change order of outputs)--

SELECT
    o.order_id,
    c.customer_city,
    o.order_status,
    oi.product_id,
    oi.price
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
LIMIT 20;

-- RANDOM() --

SELECT
    o.order_id,
    c.customer_city,
    o.order_status,
    oi.product_id,
    oi.price
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
ORDER BY RANDOM()
LIMIT 20;

---------- "Which states generate the most revenue?" ----------

SELECT * FROM customers
SELECT * FROM orders
SELECT * FROM order_items

SELECT
    c.customer_state,
    SUM(oi.price) AS total_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

---------- "Which product categories generate the most sales and revenue?" ----------

SELECT
    p.product_category_name,
    COUNT(*) AS total_items_sold,
    SUM(oi.price) AS total_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 15;



---------- "Who are our highest-value customers?" ----------

SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_unique_id,
    c.customer_state
ORDER BY total_spent DESC
LIMIT 20

---------- "Which regions generate the most customer value?"  ----------


SELECT
    c.customer_state,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS avg_purchase_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


---------- "Which states experience the slowest deliveries?" ----------

SELECT
    c.customer_state,
    AVG(
        o.order_delivered_customer_date
        - o.order_purchase_timestamp
    ) AS avg_delivery_time
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_time DESC;

---------- "What is the total revenue ranking of each product category?"----------

SELECT
    p.product_category_name,
    SUM(oi.price) AS total_revenue,
    RANK() OVER (
        ORDER BY SUM(oi.price) DESC
    ) AS revenue_rank
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
JOIN products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
LIMIT 15;

---------- "What are the highest-value individual orders?" ----------

SELECT
    o.order_id,
    c.customer_state,
    SUM(oi.price) AS total_order_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    o.order_id,
    c.customer_state
ORDER BY total_order_value DESC
LIMIT 20;

---------- CTE / "Which states contain the most high-value customers?" ----------
--- now: we first calculate customer spending, THEN analyze it separately.

WITH customer_spending AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        SUM(oi.price) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        c.customer_unique_id,
        c.customer_state
)

SELECT
    customer_state,
    COUNT(*) AS high_value_customers
FROM customer_spending
WHERE total_spent > 5000
GROUP BY customer_state
ORDER BY high_value_customers DESC;


---------- testing the Translation Join ----------

SELECT
    p.product_id,
    p.product_category_name,
    ct.product_category_name_english
FROM products p
LEFT JOIN product_category_name_translation ct
    ON p.product_category_name = ct.product_category_name
LIMIT 20;

---------- "Which products failed to find a translation match?" ----------

SELECT
    p.product_id
FROM products p
LEFT JOIN product_category_name_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE ct.product_category_name IS NULL;

---------- Checking payment record count ----------
WITH payment_SELECT
    order_id,
    COUNT(*) AS payment_records
FROM order_payments
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY payment_records DESC;

---------- Payment analytics query ----------

SELECT
    payment_type,
    COUNT(*) AS transactions,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM order_payments
GROUP BY payment_type
ORDER BY transactions DESC;

---------- payment_reviews validation ----------
SELECT COUNT(*) FROM order_reviews;

SELECT COUNT(DISTINCT review_id) FROM order_reviews;

SELECT COUNT(DISTINCT order_id) FROM order_reviews;


SELECT
    review_score,
    COUNT(*)
FROM order_reviews
GROUP BY review_score
ORDER BY review_score;

SELECT
    order_id,
    COUNT(*)
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

---------- "Do customers who wait longer give worse reviews?" ----------

SELECT
    review_score,
    AVG(o.order_delivered_customer_date - o.order_purchase_timestamp) AS avg_delivery_time
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
GROUP BY review_score
ORDER BY review_score;

---------- Orders with more than 1 review count ----------

SELECT
    order_id,
    COUNT(*) AS review_count
FROM order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY review_count DESC;


----------
SELECT * FROM customers
SELECT * FROM orders
SELECT * FROM order_items
SELECT * FROM order_payments
SELECT * FROM order_reviews limit 10
SELECT * FROM products limit 50
SELECT * FROM product_category_name_translation limit 30
SELECT * FROM sellers
SELECT * FROM geolocation

--- finding the top spender and amount spent in our database

SELECT
	C.CUSTOMER_ID,
	SUM(PAYMENT_VALUE) AS TOTAL_SPENT
FROM
	CUSTOMERS C
	JOIN ORDERS O ON O.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN ORDER_PAYMENTS OP ON OP.ORDER_ID = O.ORDER_ID
GROUP BY
	C.CUSTOMER_ID
ORDER BY
	TOTAL_SPENT DESC
LIMIT 1

---

SELECT
	C.CUSTOMER_ID,
	SUM(PAYMENT_VALUE) AS TOTAL_SPENT
FROM
	CUSTOMERS C
	JOIN ORDERS O ON O.CUSTOMER_ID = C.CUSTOMER_ID
	JOIN ORDER_PAYMENTS OP ON OP.ORDER_ID = O.ORDER_ID
GROUP BY
	C.CUSTOMER_ID
ORDER BY
	TOTAL_SPENT DESC
LIMIT 20


---

SELECT COUNT(DISTINCT customer_id)
FROM vw_sales;

SELECT COUNT(DISTINCT customer_id)
FROM vw_delivery_reviews;


---

SELECT COUNT(DISTINCT order_id)
FROM vw_sales;

SELECT COUNT(DISTINCT order_id)
FROM vw_delivery_reviews;

SELECT *
FROM vw_sales
LIMIT 5;

SELECT *
FROM vw_delivery_reviews
LIMIT 5;





---------- table masterlist

SELECT * FROM customers limit 50 
SELECT * FROM orders limit 50
SELECT * FROM order_items limit 50
SELECT * FROM order_payments limit 50
SELECT * FROM order_reviews limit 50
SELECT * FROM products limit 50
SELECT * FROM product_category_name_translation limit 50
SELECT * FROM sellers limit 50
SELECT * FROM geolocation limit 50

------------------------------ views ------------------------------
---------- SELECT views ----------

SELECT * FROM vw_sales ORDER BY order_purchase_timestamp ASC
SELECT * FROM vw_delivery_reviews
SELECT * FROM vw_order_summary
SELECT * FROM 

SELECT *
FROM review_dedup;

SELECT COUNT(*) FROM vw_sales
SELECT COUNT(*) FROM vw_delivery_reviews

SELECT COUNT(*)
FROM vw_order_summary;

SELECT COUNT(DISTINCT order_id)
FROM vw_order_summary;

SELECT
SUM(order_value)
FROM vw_order_summary;

SELECT
SUM(price)
FROM vw_sales;

SELECT
AVG(product_count)
FROM vw_order_summary;

SELECT *
FROM vw_order_summary
LIMIT 500;

---------- sales view ----------

CREATE OR REPLACE VIEW vw_sales AS
SELECT
    oi.order_id,
    o.order_purchase_timestamp,
    o.order_status,

    c.customer_id,
    c.customer_city,
    c.customer_state,

    oi.product_id,
    pct.product_category_name_english,

    s.seller_id,
    s.seller_city,
    s.seller_state,

    oi.price,
    oi.freight_value

FROM order_items oi

JOIN orders o
    ON oi.order_id = o.order_id

JOIN customers c
    ON o.customer_id = c.customer_id

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

JOIN sellers s
    ON oi.seller_id = s.seller_id;

---------- delivery reviews view ----------

CREATE OR REPLACE VIEW vw_delivery_reviews AS
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,

    c.customer_id,
    c.customer_city,
    c.customer_state,

    r.review_score,
    r.review_comment_title,
    r.review_comment_message,

    (
        o.order_delivered_customer_date
        - o.order_purchase_timestamp
    ) AS delivery_time

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN order_reviews r
    ON o.order_id = r.order_id;

---------- delivery reviews view v2 (remove duplicates) ----------

CREATE OR REPLACE VIEW vw_delivery_reviews AS

WITH review_dedup AS (
    SELECT
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,

        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY review_creation_date ASC
        ) AS rn

    FROM order_reviews
)

SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,

    c.customer_id,
    c.customer_city,
    c.customer_state,

    rd.review_score,
    rd.review_comment_title,
    rd.review_comment_message,

    (
        o.order_delivered_customer_date
        - o.order_purchase_timestamp
    ) AS delivery_time

FROM orders o

JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN review_dedup rd
    ON o.order_id = rd.order_id
    AND rd.rn = 1;

---------- category reviews view ----------

SELECT COUNT(*) FROM vw_category_reviews LIMIT 5;
SELECT COUNT(*) FROM 

CREATE OR REPLACE VIEW vw_category_reviews AS

SELECT
    o.order_id,
    p.product_category_name,

    pct.product_category_name_english,

    dr.review_score

FROM orders o

JOIN order_items oi
    ON o.order_id = oi.order_id

JOIN products p
    ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation pct
    ON p.product_category_name =
       pct.product_category_name

LEFT JOIN vw_delivery_reviews dr
    ON o.order_id = dr.order_id;

---------- order summary view ----------

CREATE OR REPLACE VIEW vw_order_summary AS

SELECT
    order_id,
    MIN(order_purchase_timestamp) AS order_purchase_timestamp,
    MIN(order_status) AS order_status,

    MIN(customer_id) AS customer_id,
    MIN(customer_city) AS customer_city,
    MIN(customer_state) AS customer_state,

    SUM(price) AS order_value,
    SUM(freight_value) AS total_freight,

    COUNT(product_id) AS product_count

FROM vw_sales

GROUP BY order_id;






-------------------------------------------------- analysis --------------------------------------------------

---------- revenue per product ----------

SELECT
    product_category_name_english,
    SUM(price) AS revenue
FROM vw_sales
GROUP BY product_category_name_english
ORDER BY revenue DESC;

---------- revenue per state ----------

SELECT
    customer_state,
    SUM(price) AS revenue
FROM vw_sales
GROUP BY customer_state
ORDER BY revenue DESC;


SELECT COUNT(*)
FROM vw_delivery_reviews;
z
SELECT * FROM vw_del

---

SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'canceled' THEN 1
            ELSE 0
        END
    ) AS cancelled_orders
FROM vw_order_summary;



SELECT
COUNT(total_orders)/
	(SELECT order_status
	FROM vw_order_summary
	WHERE order_status = 'canceled'
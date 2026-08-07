/*
Olist Brazilian E-Commerce Analysis
Author: Waqar Younas Ghumman
Database: MySQL 8.0

Purpose
-------
Analyze order volume, product revenue, customers, products, sellers,
payments, delivery performance, and customer reviews.

Important definition
--------------------
Product revenue in this project is SUM(order_items.price). Freight is kept
separate and is not included in product revenue.
*/

USE olist_ecommerce;


/* ================================================================
   0. DATA VALIDATION
   Confirm that every imported business table contains records.
   ================================================================ */

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL
SELECT 'category_translation', COUNT(*) FROM category_translation;


/* ================================================================
   1. ORDER STATUS DISTRIBUTION
   Business question: How many orders are in each status?
   Skill demonstrated: GROUP BY, COUNT, ORDER BY.
   ================================================================ */

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


/* ================================================================
   2. DELIVERED ORDERS AND PRODUCT REVENUE
   Business question: How many orders were delivered and how much product
   revenue did they generate?

   Join explanation: One order can contain multiple item rows. The join
   connects each delivered order to its products. COUNT(DISTINCT order_id)
   prevents an order from being counted once for every item.

   Saved result: 96,478 delivered orders and $13,221,498.11 in product
   revenue.
   ================================================================ */

SELECT
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


/* ================================================================
   3. ORDER-ITEM JOIN PREVIEW
   Business question: What does the relationship between orders and their
   individual products look like?

   An order can repeat because one order may contain multiple products.
   ================================================================ */

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    oi.product_id,
    oi.seller_id,
    oi.price,
    oi.freight_value
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
LIMIT 10;


/* ================================================================
   4. MONTHLY PRODUCT REVENUE TREND
   Business question: How did delivered product revenue change by month?
   Skill demonstrated: date transformation, aggregation, chronological sort.
   ================================================================ */

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;


/* ================================================================
   5. HIGHEST-REVENUE MONTH
   Business question: Which month generated the most delivered product
   revenue?
   ================================================================ */

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY product_revenue DESC
LIMIT 1;


/* ================================================================
   6. REVENUE BY CUSTOMER STATE
   Business question: Which customer states generated the most delivered
   product revenue?

   Join path: orders -> order_items and orders -> customers.
   ================================================================ */

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY product_revenue DESC
LIMIT 10;


/* ================================================================
   7. TOP PRODUCT CATEGORIES
   Business question: Which product categories generated the most delivered
   product revenue?

   Join path: orders -> order_items -> products -> category_translation.
   LEFT JOIN keeps products even when an English translation is missing.
   COALESCE labels those rows as Unknown.

   Saved result: Health & Beauty ranked first at approximately $1.23M.
   ================================================================ */

SELECT
    COALESCE(ct.product_category_name_english, 'Unknown') AS product_category,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN products AS p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation AS ct
    ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(ct.product_category_name_english, 'Unknown')
ORDER BY product_revenue DESC
LIMIT 10;


/* ================================================================
   8. TOP SELLERS
   Business question: Which sellers generated the most delivered product
   revenue?
   ================================================================ */

SELECT
    oi.seller_id,
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue
FROM orders AS o
INNER JOIN order_items AS oi
    ON o.order_id = oi.order_id
INNER JOIN sellers AS s
    ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id, s.seller_state
ORDER BY product_revenue DESC
LIMIT 10;


/* ================================================================
   9. DELIVERY PERFORMANCE
   Business question: What was the average delivery time, and how many
   delivered orders arrived after their estimated delivery date?

   CASE returns 1 for a late delivery and 0 otherwise, allowing SUM to count
   late orders.
   ================================================================ */

SELECT
    ROUND(
        AVG(DATEDIFF(order_delivered_customer_date,
                     order_purchase_timestamp)),
        2
    ) AS average_delivery_days,
    SUM(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1
            ELSE 0
        END
    ) AS late_deliveries
FROM orders
WHERE order_status = 'delivered';


/* ================================================================
   10. PAYMENT METHODS
   Business question: Which payment methods were used most frequently, and
   what was their total recorded payment value?

   Saved result: Credit cards dominated with 76,795 payment records and
   approximately $12.54M in recorded payment value.
   ================================================================ */

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM order_payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


/* ================================================================
   11. REVIEW SCORE DISTRIBUTION
   Business question: How were customer review scores distributed?

   Saved result: Five-star reviews were most common (57,327), while 11,424
   reviews received one star.
   ================================================================ */

SELECT
    review_score,
    COUNT(*) AS total_reviews
FROM order_reviews
GROUP BY review_score
ORDER BY review_score DESC;


/* ================================================================
   12. DELIVERY TIMING AND REVIEW SCORES
   Business question: Do late deliveries receive lower customer ratings?

   Join explanation: Each delivered order is matched to its review through
   order_id. CASE creates two delivery groups for comparison.

   Saved result: On-time or early deliveries averaged 4.29 stars, compared
   with 2.57 stars for late deliveries.
   ================================================================ */

SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On Time or Early'
    END AS delivery_status,
    COUNT(*) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM orders AS o
INNER JOIN order_reviews AS r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY delivery_status
ORDER BY average_review_score DESC;


/* ================================================================
   13. LATE-DELIVERY RATE BY STATE
   Business question: Which states had the highest percentage of late
   delivered orders?

   Saved result: AL had the highest displayed rate at 23.93%. RJ had the
   largest late-delivery count among the displayed states with 1,664.
   ================================================================ */

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1
            ELSE 0
        END
    ) AS late_deliveries,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_rate
FROM orders AS o
INNER JOIN customers AS c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY late_delivery_rate DESC
LIMIT 10;


/* ================================================================
   14. REPEAT CUSTOMERS
   Business question: Which customers placed more than one delivered order?

   Skill demonstrated: CTE, multi-table joins, aggregation, outer filtering.
   customer_unique_id is used because one real customer can have multiple
   customer_id values in the Olist dataset.
   ================================================================ */

WITH customer_order_summary AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_orders,
        ROUND(SUM(oi.price), 2) AS lifetime_product_revenue
    FROM customers AS c
    INNER JOIN orders AS o
        ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    delivered_orders,
    lifetime_product_revenue
FROM customer_order_summary
WHERE delivered_orders > 1
ORDER BY delivered_orders DESC, lifetime_product_revenue DESC
LIMIT 20;


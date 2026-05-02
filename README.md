# Analyzing Large-Scale Apple Retail Sales Data Using SQL

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/Advanced%20SQL-Window%20Functions%20%7C%20CTEs%20%7C%20Joins-4A90D9?style=flat-square)
![Scale](https://img.shields.io/badge/Scale-1M%2B%20Rows-FF3B30?style=flat-square)
![Queries](https://img.shields.io/badge/Queries-21-34C759?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-14B8A6?style=flat-square)

> Analyzing over **1 million Apple retail sales records** using advanced SQL — joins, aggregations, window functions, CTEs, and date arithmetic — to answer 21 real business questions across stores, products, and warranty claims globally.

---

## 📌 Project Overview

This project showcases advanced SQL querying through the analysis of Apple's retail sales data at scale. The dataset spans multiple years and countries, covering products, stores, sales transactions, and warranty claims.

The project is structured into **three difficulty tiers** — from foundational aggregations to multi-CTE window function queries — demonstrating the full range of SQL skills expected of a professional data analyst.

---

## 🗂️ Entity Relationship Diagram

![ERD](https://github.com/najirh/Apple-Retail-Sales-SQL-Project---Analyzing-Millions-of-Sales-Rows/blob/main/erd.png)

---

## 🧱 Database Schema — 5 Tables

```sql
-- 1. Stores
stores (store_id PK, store_name, city, country)

-- 2. Category
category (category_id PK, category_name)

-- 3. Products
products (product_id PK, product_name, category_id FK, launch_date, price)

-- 4. Sales
sales (sale_id PK, sale_date, store_id FK, product_id FK, quantity)

-- 5. Warranty
warranty (claim_id PK, claim_date, sale_id FK, repair_status)
```

---

## 🛠️ SQL Skills Applied

| Skill | Used In |
|---|---|
| `JOIN` (INNER, LEFT, RIGHT) | Q2, Q6, Q8, Q12–Q15, Q17, Q19, Q20 |
| `GROUP BY` + Aggregations | Q1–Q3, Q8–Q9, Q14–Q15 |
| `HAVING` | Q13, Q14 |
| `RANK()` Window Function | Q10, Q11 |
| `LAG()` Window Function | Q17 |
| `SUM() OVER()` Running Total | Q20 |
| CTEs (`WITH` clause) | Q11, Q17, Q19, Q20 |
| `CASE` segmentation | Q10, Q18, Q21 |
| `EXTRACT` / `TO_CHAR` | Q3, Q9, Q10, Q14, Q20 |
| `INTERVAL` date arithmetic | Q6, Q7, Q12–Q15 |
| Subqueries | Q4, Q5 |
| Percentage calculations | Q5, Q16, Q19 |

---

## 📋 21 Business Questions & Queries

---

### 🟢 TIER 1 — Foundational

---

**Q1 · Number of stores per country**

```sql
SELECT
    country,
    COUNT(store_id) AS total_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC;
```

---

**Q2 · Total units sold by each store**

```sql
SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_unit_sold
FROM sales AS s
JOIN stores AS st ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```

---

**Q3 · Sales that occurred in December 2023**

```sql
SELECT
    COUNT(sale_id) AS total_sale
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023';
```

---

**Q4 · Stores that have never had a warranty claim**

```sql
SELECT COUNT(*)
FROM stores
WHERE store_id NOT IN (
    SELECT DISTINCT store_id
    FROM sales AS s
    RIGHT JOIN warranty AS w ON s.sale_id = w.sale_id
);
```

---

**Q5 · Percentage of claims marked as Warranty Void**

```sql
SELECT
    ROUND(
        COUNT(claim_id) /
        (SELECT COUNT(*) FROM warranty)::numeric * 100,
    2) AS warranty_void_percentage
FROM warranty
WHERE repair_status = 'Warranty Void';
```

---

**Q6 · Store with highest units sold in the last year**

```sql
SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units
FROM sales AS s
JOIN stores AS st ON s.store_id = st.store_id
WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year')
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;
```

---

**Q7 · Unique products sold in the last year**

```sql
SELECT COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (CURRENT_DATE - INTERVAL '1 year');
```

---

**Q8 · Average product price per category**

```sql
SELECT
    p.category_id,
    c.category_name,
    AVG(p.price) AS avg_price
FROM products AS p
JOIN category AS c ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```

---

**Q9 · Warranty claims filed in 2020**

```sql
SELECT COUNT(*) AS warranty_claims
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2020;
```

---

### 🟡 TIER 2 — Intermediate

---

**Q10 · Best-selling day per store using RANK()**

```sql
SELECT *
FROM (
    SELECT
        store_id,
        TO_CHAR(sale_date, 'Day') AS day_name,
        SUM(quantity)             AS total_unit_sold,
        RANK() OVER (
            PARTITION BY store_id
            ORDER BY SUM(quantity) DESC
        ) AS rank
    FROM sales
    GROUP BY 1, 2
) AS t1
WHERE rank = 1;
```

> `RANK()` partitioned by `store_id` ensures each store independently gets its top day.

---

**Q11 · Least selling product per country using CTE + RANK()**

```sql
WITH product_rank AS (
    SELECT
        st.country,
        p.product_name,
        SUM(s.quantity) AS total_qty_sold,
        RANK() OVER (
            PARTITION BY st.country
            ORDER BY SUM(s.quantity) ASC
        ) AS rank
    FROM sales AS s
    JOIN stores   AS st ON s.store_id   = st.store_id
    JOIN products AS p  ON s.product_id = p.product_id
    GROUP BY 1, 2
)
SELECT *
FROM product_rank
WHERE rank = 1;
```

> Ascending `ORDER BY` inside `RANK()` surfaces the lowest-selling product per country.

---

**Q12 · Warranty claims filed within 180 days of sale**

```sql
SELECT COUNT(*)
FROM warranty AS w
LEFT JOIN sales AS s ON s.sale_id = w.sale_id
WHERE w.claim_date - s.sale_date <= 180;
```

---

**Q13 · Claims for products launched in the last 2 years**

```sql
SELECT
    p.product_name,
    COUNT(w.claim_id) AS claim_count,
    COUNT(s.sale_id)  AS total_sales
FROM warranty AS w
RIGHT JOIN sales     AS s ON s.sale_id    = w.sale_id
JOIN       products  AS p ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
HAVING COUNT(w.claim_id) > 0;
```

---

**Q14 · USA months with 5,000+ units sold in last 3 years**

```sql
SELECT
    TO_CHAR(sale_date, 'MM-YYYY') AS month,
    SUM(s.quantity)               AS total_unit_sold
FROM sales AS s
JOIN stores AS st ON s.store_id = st.store_id
WHERE st.country = 'USA'
  AND s.sale_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY 1
HAVING SUM(s.quantity) > 5000;
```

---

**Q15 · Category with most warranty claims in last 2 years**

```sql
SELECT
    c.category_name,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
LEFT JOIN sales    AS s ON w.sale_id     = s.sale_id
JOIN      products AS p ON p.product_id  = s.product_id
JOIN      category AS c ON c.category_id = p.category_id
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
ORDER BY 2 DESC;
```

---

**Q16 · Warranty claim probability by country**

```sql
SELECT
    st.country,
    COUNT(s.sale_id)  AS total_sales,
    COUNT(w.claim_id) AS total_claims,
    ROUND(
        COUNT(w.claim_id)::numeric /
        COUNT(s.sale_id)::numeric * 100,
    2) AS claim_probability_pct
FROM sales AS s
JOIN stores       AS st ON s.store_id  = st.store_id
LEFT JOIN warranty AS w ON w.sale_id   = s.sale_id
GROUP BY 1
ORDER BY claim_probability_pct DESC;
```

> ⚠️ **Bug fixed:** Original Q16 was a duplicate of Q15. This is the correct query — warranty claim rate per country calculated as `claims / sales * 100`.

---

### 🔴 TIER 3 — Advanced

---

**Q17 · Year-over-year revenue growth per store using LAG()**

```sql
WITH yearly_sales AS (
    SELECT
        s.store_id,
        st.store_name,
        EXTRACT(YEAR FROM sale_date) AS year,
        SUM(s.quantity * p.price)    AS total_sale
    FROM sales AS s
    JOIN products AS p  ON s.product_id = p.product_id
    JOIN stores   AS st ON st.store_id  = s.store_id
    GROUP BY 1, 2, 3
),
growth_ratio AS (
    SELECT
        store_name,
        year,
        LAG(total_sale, 1) OVER (
            PARTITION BY store_name ORDER BY year
        )          AS last_year_sale,
        total_sale AS current_year_sale
    FROM yearly_sales
)
SELECT
    store_name,
    year,
    last_year_sale,
    current_year_sale,
    ROUND(
        (current_year_sale - last_year_sale)::numeric /
        last_year_sale::numeric * 100,
    3) AS growth_ratio_pct
FROM growth_ratio
WHERE last_year_sale IS NOT NULL
  AND year <> EXTRACT(YEAR FROM CURRENT_DATE);
```

> `LAG()` retrieves the previous year's value within each store's partition. Two CTEs cleanly separate yearly totals from growth calculation.

---

**Q18 · Warranty claims by product price segment**

```sql
SELECT
    CASE
        WHEN p.price < 500             THEN 'Budget (<$500)'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid-Range ($500–$1000)'
        ELSE                               'Premium (>$1000)'
    END           AS price_segment,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
LEFT JOIN sales    AS s ON w.sale_id    = s.sale_id
JOIN      products AS p ON p.product_id = s.product_id
WHERE claim_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY 1
ORDER BY 2 DESC;
```

---

**Q19 · Store with highest Paid Repaired % using dual CTEs**

```sql
WITH paid_repair AS (
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS paid_repaired
    FROM sales AS s
    RIGHT JOIN warranty AS w ON w.sale_id = s.sale_id
    WHERE w.repair_status = 'Paid Repaired'
    GROUP BY 1
),
total_repaired AS (
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS total_repaired
    FROM sales AS s
    RIGHT JOIN warranty AS w ON w.sale_id = s.sale_id
    GROUP BY 1
)
SELECT
    tr.store_id,
    st.store_name,
    pr.paid_repaired,
    tr.total_repaired,
    ROUND(
        pr.paid_repaired::numeric /
        tr.total_repaired::numeric * 100,
    2) AS pct_paid_repaired
FROM paid_repair    AS pr
JOIN total_repaired AS tr ON pr.store_id = tr.store_id
JOIN stores         AS st ON tr.store_id = st.store_id
ORDER BY pct_paid_repaired DESC;
```

---

**Q20 · Monthly running total of sales per store using SUM() OVER()**

```sql
WITH monthly_sales AS (
    SELECT
        store_id,
        EXTRACT(YEAR  FROM sale_date) AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        SUM(p.price * s.quantity)     AS total_revenue
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 2, 3
)
SELECT
    store_id,
    year,
    month,
    total_revenue,
    SUM(total_revenue) OVER (
        PARTITION BY store_id
        ORDER BY year, month
    ) AS running_total
FROM monthly_sales;
```

> `SUM() OVER()` computes a cumulative total per store ordered chronologically. Running total resets for each store independently.

---

**Q21 · Product lifecycle sales segmentation**

```sql
SELECT
    p.product_name,
    CASE
        WHEN s.sale_date BETWEEN p.launch_date
             AND p.launch_date + INTERVAL '6 months'  THEN '0–6 months'
        WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 months'
             AND p.launch_date + INTERVAL '12 months' THEN '6–12 months'
        WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 months'
             AND p.launch_date + INTERVAL '18 months' THEN '12–18 months'
        ELSE '18+ months'
    END           AS lifecycle_stage,
    SUM(s.quantity) AS total_qty_sold
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
```

> ⚠️ **Bug fixed:** Original had `'6-12'` repeated for the 12–18 month bracket. Corrected to `'12–18 months'`.

---

## 📁 Project Structure

```
Analyzing-Large-Scale-Apple-Retail-Sales-Data-Using-SQL/
│
├── queries/
│   ├── tier1_foundational.sql     ← Q1–Q9
│   ├── tier2_intermediate.sql     ← Q10–Q16
│   └── tier3_advanced.sql         ← Q17–Q21
│
├── apple-img.webp
└── README.md
```

---

## 💼 What This Project Demonstrates

```txt
✅  Advanced SQL across 12 distinct techniques in one project
✅  Scale — 1M+ rows, not sample data
✅  Window Functions — RANK(), LAG(), SUM() OVER()
✅  Multi-CTE query design for complex logic
✅  Date arithmetic with INTERVAL for time-based analysis
✅  Bug identification and query correction (Q16, Q21)
✅  Business framing — every query answers a real operational question
```

---

**Pournima Kamble** — MS Computer Science @ Cleveland State University (2026)
Seeking Data Analyst & Data Engineer roles · Available June 2026

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/pournimakamble)
[![GitHub](https://img.shields.io/badge/GitHub-pournima2413-333333?style=flat-square&logo=github&logoColor=white)](https://github.com/pournima2413)
[![Email](https://img.shields.io/badge/Email-pournima2413@gmail.com-EA4335?style=flat-square&logo=gmail&logoColor=white)](mailto:pournima2413@gmail.com)

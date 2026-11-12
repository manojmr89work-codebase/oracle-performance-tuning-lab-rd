--------------------------------------------------------------------------------
-- Enterprise Oracle SQL Performance Tuning & Partitioning Lab
-- Script 03: Optimized Queries (Best Practices & Solutions)
-- Description: Contains the optimized counterparts to unoptimized_queries.sql,
--              leveraging partition pruning, index range scans, hash joins, 
--              scalar subquery elimination via JOINs, and analytic solutions.
--------------------------------------------------------------------------------

-- =============================================================================
-- Query 1 Solution: Range Predicate Without Wrapper Function
-- Optimization: Removed TRUNC() on the partitioned column (allocation_date), 
--              allowing Oracle to perform partition pruning and index range scans.
-- =============================================================================

SELECT 
    allocation_id,
    project_id,
    customer_id,
    total_cost,
    status
FROM inventory_allocations
WHERE allocation_date >= TO_DATE('2025-05-15', 'YYYY-MM-DD')
  AND allocation_date <  TO_DATE('2025-05-16', 'YYYY-MM-DD')
  AND customer_id BETWEEN 1000 AND 15000;


-- =============================================================================
-- Query 2 Solution: Eliminating Scalar Subqueries via Hash Join
-- Optimization: Replaced the row-by-row scalar subquery in the SELECT projection 
--              with an efficient JOIN and selective filtering.
-- =============================================================================

SELECT 
    a.allocation_id,
    a.project_id,
    a.customer_id,
    a.allocated_qty,
    a.total_cost,
    p.client_name
FROM inventory_allocations a
JOIN client_projects p 
  ON a.project_id = p.project_id 
 AND a.customer_id = p.customer_id
WHERE a.allocation_date >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
  AND a.status = 'DISPATCHED';


-- =============================================================================
-- Query 3 Solution: Suffix/Exact Search or Functional Index
-- Optimization: Avoided leading wildcard '%...'. Replaced with a prefix search 
--              ('DESIGNER COMPONENT%') or created a functional index if substring 
--              matching is mandatory.
-- =============================================================================

SELECT 
    item_id,
    sku_code,
    item_name,
    category,
    unit_price,
    stock_qty
FROM design_inventories
WHERE item_name LIKE 'DESIGNER COMPONENT%';


-- =============================================================================
-- Query 4 Solution: Explicit Join Criteria & Partition Key Alignment
-- Optimization: Explicitly structured ANSI JOINs with partition-aware predicates 
--              so the CBO eliminates unnecessary partitions across all three tables.
-- =============================================================================

SELECT 
    p.client_name,
    p.project_type,
    i.sku_code,
    i.item_name,
    a.allocated_qty,
    a.total_cost,
    a.allocation_date
FROM inventory_allocations a
JOIN client_projects p 
  ON a.project_id = p.project_id 
 AND a.customer_id = p.customer_id
JOIN design_inventories i 
  ON a.item_id = i.item_id
WHERE a.status = 'INSTALLED'
  AND i.category = 'WOODWORK'
  AND a.allocation_date BETWEEN TO_DATE('2025-01-01', 'YYYY-MM-DD') 
                            AND TO_DATE('2025-12-31', 'YYYY-MM-DD');


-- =============================================================================
-- Query 5 Solution: Safe ANTI-JOIN via NOT EXISTS
-- Optimization: Replaced NOT IN with NOT EXISTS (or LEFT ANTI JOIN), which correctly 
--              handles potential NULL values in subqueries and avoids full scans.
-- =============================================================================

SELECT 
    cp.project_id,
    cp.customer_id,
    cp.client_name,
    cp.budget_amount
FROM client_projects cp
WHERE NOT EXISTS (
    SELECT 1 
    FROM inventory_allocations ia 
    WHERE ia.project_id = cp.project_id
      AND ia.customer_id = cp.customer_id
      AND ia.status = 'RETURNED'
);

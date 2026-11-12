--------------------------------------------------------------------------------
-- Enterprise Oracle SQL Performance Tuning & Partitioning Lab
-- Script 02: Sample Unoptimized Queries (Anti-Patterns)
-- Description: Contains common unoptimized query patterns on partitioned 
--              interior design tables (TAB_CLIENT_PROJECTS and tab_inventory_alloc) 
--              such as implicit data type conversions, scalar subquery bottlenecks, 
--              functions on partitioned columns, and unindexed joins.
--------------------------------------------------------------------------------

-- =============================================================================
-- Query 1: Implicit Conversion on Partition Key & Date Truncation Trap
-- Description: Applying TRUNC() or string-to-date casting on allocation_date 
--              prevents partition pruning, causing full table scans across all daily partitions.
-- =============================================================================

SELECT 
    allocation_id,
    project_id,
    customer_id,
    total_cost,
    status
FROM tab_inventory_alloc
WHERE TRUNC(allocation_date) = TO_DATE('2025-05-15', 'YYYY-MM-DD')
  AND customer_id BETWEEN 1000 AND 15000;


-- =============================================================================
-- Query 2: Scalar Subquery Bottleneck in Projection List
-- Description: Executing a scalar subquery row-by-row for every single allocation 
--              to fetch the client name causes massive context switching and CPU spikes.
-- =============================================================================

SELECT 
    a.allocation_id,
    a.project_id,
    a.customer_id,
    a.allocated_qty,
    a.total_cost,
    (SELECT p.client_name 
     FROM TAB_CLIENT_PROJECTS p 
     WHERE p.project_id = a.project_id 
       AND p.customer_id = a.customer_id) AS client_name
FROM tab_inventory_alloc a
WHERE a.allocation_date >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
  AND a.status = 'DISPATCHED';


-- =============================================================================
-- Query 3: Leading Wildcard LIKE Causing Full Index/Table Scan
-- Description: Searching item names with a leading wildcard prevents the optimizer 
--              from utilizing B-Tree indexes on TAB_DESIGN_INVENTORIES.
-- =============================================================================

SELECT 
    item_id,
    sku_code,
    item_name,
    category,
    unit_price,
    stock_qty
FROM TAB_DESIGN_INVENTORIES
WHERE UPPER(item_name) LIKE '%DESIGNER COMPONENT%';


-- =============================================================================
-- Query 4: Unoptimized Multi-Table Join Without Partition Pruning Alignment
-- Description: Joins inventory allocations, projects, and inventories without 
--              leveraging partition keys properly, leading to expensive hash joins 
--              over unconstrained date ranges.
-- =============================================================================

SELECT 
    p.client_name,
    p.project_type,
    i.sku_code,
    i.item_name,
    a.allocated_qty,
    a.total_cost,
    a.allocation_date
FROM tab_inventory_alloc a,
     TAB_CLIENT_PROJECTS p,
     TAB_DESIGN_INVENTORIES i
WHERE a.project_id = p.project_id
  AND a.customer_id = p.customer_id
  AND a.item_id = i.item_id
  AND a.status = 'INSTALLED'
  AND i.category = 'WOODWORK'
  AND a.allocation_date BETWEEN TO_DATE('2025-01-01', 'YYYY-MM-DD') 
                            AND TO_DATE('2025-12-31', 'YYYY-MM-DD');


-- =============================================================================
-- Query 5: Inefficient NOT IN Subquery with Potential NULL Vulnerability
-- Description: Using NOT IN with a subquery that can return NULL values 
--              results in zero rows returned or full table scans in Oracle.
-- =============================================================================

SELECT 
    project_id,
    customer_id,
    client_name,
    budget_amount
FROM TAB_CLIENT_PROJECTS
WHERE project_id NOT IN (
    SELECT project_id 
    FROM tab_inventory_alloc 
    WHERE status = 'RETURNED'
);

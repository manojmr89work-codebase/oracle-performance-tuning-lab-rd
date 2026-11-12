# Enterprise Oracle SQL Performance Tuning & Composite Partitioning Lab

An enterprise-grade Oracle database architecture and performance optimization project demonstrating advanced **Composite Partitioning (Interval Partitioning by Date + Range Subpartitioning by Customer ID)** for high-volume interior design and multi-tenant inventory allocation workloads.

---

## Architecture Overview

In high-throughput enterprise applications (such as supply chain systems, financial ledgers, and multi-tenant platforms), querying massive historical tables leads to severe performance degradation and high I/O bottlenecks. 

This repository implements a robust partitioning strategy designed specifically for reporting queries filtered by **Date** and **Customer ID**.

### Key Architectural Features:
1. **Daily Interval Partitioning (`allocation_date`):** Automatically creates a physical partition for every single calendar day as new transaction loads arrive, eliminating manual partition maintenance.
2. **Tenant-Based Subpartitioning (`customer_id`):** Subpartitions each daily partition into tiered customer segments (`Tier 1`, `Tier 2`, `Tier 3`, and `Enterprise`), ensuring clean data segregation and lightning-fast tenant-level audits.
3. **Two-Level Partition Pruning:** Enables the Oracle Cost-Based Optimizer (CBO) to prune both time and tenant boundaries simultaneously, bypassing 99%+ of table blocks during execution.

---

## Schema Structure

* **`client_projects`:** Master project table range-partitioned by customer tiers.
* **`design_inventories`:** Master SKU and stock reference data across regional warehouses (`WH_CHENNAI`, `WH_BANGALORE`).
* **`inventory_allocations`:** High-volume transaction table utilizing **Interval Partitioning by Day** with **Range Subpartitions by Customer ID**.

---

## Performance Tuning & Query Pattern

### The Target Reporting Query:
```sql
SELECT p.client_name, i.item_name, a.allocated_qty, a.total_cost, a.status
FROM tab_inv_alloc a
JOIN client_projects p ON a.project_id = p.project_id AND a.customer_id = p.customer_id
JOIN design_inventories i ON a.item_id = i.item_id
WHERE a.allocation_date = TO_DATE('2025-05-12', 'YYYY-MM-DD')
  AND a.customer_id = 4500;
```

### Execution Impact:
* **Without Partitioning:** Full table scan across millions of historical rows; high CPU and disk I/O utilization.
* **With Composite Partitioning:** Instant partition pruning isolates execution directly to `p_alloc_2025_05_12` $\rightarrow$ `sp_tier2`, reducing logical reads by over **95%** and dropping execution times to milliseconds.

---

## Repository Structure

* **`/scripts/`**
  * `composite_partitioned_schema.sql` — Complete DDL script featuring table creation, interval-partition definition, and PL/SQL synthetic data generation loops.
* **`/docs/`**
  * `execution_plan_analysis.md` — Detailed breakdown of CBO access paths and pruning mechanics.

---

## Author
**Manoj M.R.**  
Senior Oracle Database & Performance Architect

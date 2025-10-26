USE WideWorldImporters;
GO

/* Case 1: The Vanishing Shipment
April 2016. The warehouse is bustling and in the haste, one order left the loading bay but never reached the customer.
The manifest shows it packed, yet no one marked it as completed. Time to dig through the records and see which shipment slipped into the shadows… */

/* Step 1: Search through entire order list for latest shipments. Notice most have a completion timestamp but some don't. */ 

SELECT OrderID, CustomerID, OrderDate, PickingCompletedWhen
FROM Sales.Orders
ORDER BY OrderDate DESC;

/*Step 2: Note the entries never checked off in a missing PickingCompletedWhen field */

SELECT OrderID, CustomerID, OrderDate
FROM Sales.Orders
WHERE PickingCompletedWhen IS NULL
ORDER BY OrderDate DESC;

/* Step 3: Cross-reference order numbers with the customer ledger for the final name that comes up. This is your latest lost shipment */

SELECT TOP 1
    o.OrderID,
    c.CustomerName,
    o.OrderDate
FROM Sales.Orders AS o
JOIN Sales.Customers AS c
    ON o.CustomerID = c.CustomerID
WHERE o.PickingCompletedWhen IS NULL
ORDER BY o.OrderDate DESC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 2: The Counterfeit Shipment. 
May 2016. A novelty vendor complains: a shipment of “USB missile launchers” arrived with cheap knockoffs inside. 
The store sold a lot of quirky gadgets that month — one salesperson handled most of them. 
Follow the paper trail and find who sold the most of these devices. */

/* Step 1: Look up the StockItemID and name for “USB missile launcher” products. */

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%USB missile launcher%'

/* Step 2: Find all invoices that included those items, along with the salesperson IDs. */

SELECT DISTINCT i.InvoiceID, i.SalespersonPersonID
FROM Sales.InvoiceLines AS il
JOIN Sales.Invoices AS i ON i.InvoiceID = il.InvoiceID
JOIN Warehouse.StockItems AS si ON si.StockItemID = il.StockItemID
WHERE si.StockItemName LIKE '%USB missile launcher%'

/* Step 3: Identify the salesperson who sold the most USB missile launchers. */

SELECT TOP 1
    p.FullName AS Salesperson,
    COUNT(DISTINCT i.InvoiceID) AS LauncherInvoiceCount
FROM Sales.InvoiceLines AS il
JOIN Sales.Invoices AS i ON i.InvoiceID = il.InvoiceID
JOIN Application.People AS p ON p.PersonID = i.SalespersonPersonID
JOIN Warehouse.StockItems AS si ON si.StockItemID = il.StockItemID
WHERE si.StockItemName LIKE '%USB missile launcher%'
GROUP BY p.FullName
ORDER BY LauncherInvoiceCount DESC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 3: Overdue Debtor.
The office lights hum quietly as the accountants pack up for the night.
One account has been problematic for months. Every payment reconciled except one.
Find the customer whose balance has been outstanding for over ninety days. */

/* Step 1: Review all customer transactions to see who still owes money. */

SELECT CustomerID, TransactionDate, OutstandingBalance
FROM Sales.CustomerTransactions
ORDER BY TransactionDate DESC;

/* Step 2: Filter for transactions with unpaid balances older than 90 days. */

SELECT CustomerID, TransactionDate, OutstandingBalance,
       DATEDIFF(DAY, TransactionDate, GETDATE()) AS DaysOutstanding
FROM Sales.CustomerTransactions
WHERE OutstandingBalance > 0
  AND DATEDIFF(DAY, TransactionDate, GETDATE()) > 90
ORDER BY OutstandingBalance DESC;

/* Step 3: Match the IDs to customer names and find the one who owes the most, longest. */

SELECT TOP 1
    c.CustomerName,
    ct.TransactionDate,
    ct.OutstandingBalance,
    DATEDIFF(DAY, ct.TransactionDate, GETDATE()) AS DaysOutstanding
FROM Sales.CustomerTransactions AS ct
JOIN Sales.Customers AS c
    ON ct.CustomerID = c.CustomerID
WHERE ct.OutstandingBalance > 0
  AND DATEDIFF(DAY, ct.TransactionDate, GETDATE()) > 90
ORDER BY OutstandingBalance DESC, DaysOutstanding DESC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 4: The Last Shipment Out
The warehouse is quiet now. The last truck of the night rolled out hours ago.
By morning, inventory numbers won’t add up — one shipment left astray in the haste.
The clerk swears they logged it, but the timestamp tells another story.
Find the last shipment ever recorded before the system went dark. */

/* Step 1: Review all completed shipments. 
List every order that left the dock, sorted by completion time. */

SELECT OrderID, CustomerID, PickingCompletedWhen
FROM Sales.Orders
WHERE PickingCompletedWhen IS NOT NULL
ORDER BY PickingCompletedWhen DESC;

/* Step 2: Verify the final completion timestamp.
Identify the most recent recorded shipment date. */

SELECT MAX(PickingCompletedWhen) AS LastShipmentDate
FROM Sales.Orders
WHERE PickingCompletedWhen IS NOT NULL;

/* Step 3: Expose the last shipment and the customer tied to it. */

SELECT TOP 1
    o.OrderID,
    c.CustomerName,
    o.PickingCompletedWhen AS LastShipmentDate
FROM Sales.Orders AS o
JOIN Sales.Customers AS c
    ON o.CustomerID = c.CustomerID
WHERE o.PickingCompletedWhen IS NOT NULL
ORDER BY o.PickingCompletedWhen DESC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 5: The First Payment Missing
The records are thick with dust. One payment was due but never came.
The books remember the first customer who never paid.
Find the earliest transaction that still has an outstanding balance greater than zero. */

/* Step 1: Review all customer transactions to see how far back the records go. */

SELECT CustomerID, TransactionDate, OutstandingBalance
FROM Sales.CustomerTransactions
ORDER BY TransactionDate ASC;

/* Step 2: Filter for open balances — the ones still unpaid. */

SELECT CustomerID, TransactionDate, OutstandingBalance
FROM Sales.CustomerTransactions
WHERE OutstandingBalance > 0
ORDER BY TransactionDate ASC;

/* Step 3: Identify the customer tied to the earliest unpaid transaction. */

SELECT TOP 1
    c.CustomerName,
    ct.TransactionDate AS EarliestUnpaidDate,
    ct.OutstandingBalance
FROM Sales.CustomerTransactions AS ct
JOIN Sales.Customers AS c
    ON ct.CustomerID = c.CustomerID
WHERE ct.OutstandingBalance > 0
ORDER BY ct.TransactionDate ASC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 6: The Missing Discount
March 2016. A regular customer claims they never received their usual discount.
Check who got charged above the average order total. */

/* Step 1: Find the average order total across all invoices. */

SELECT AVG(TotalDryItems) AS AverageTotal
FROM Sales.Invoices;

/* Step 2: Identify the customer whose invoice exceeded that average the most. */

SELECT TOP 1
    c.CustomerName,
    i.InvoiceDate,
    i.TotalDryItems
FROM Sales.Invoices AS i
JOIN Sales.Customers AS c
    ON i.CustomerID = c.CustomerID
ORDER BY i.TotalDryItems DESC;

/* ------------------------------------------------------------------------------------------------------------------------------------------------- */

/* Case 7: The Silent Vendor
November 2015. One supplier stopped sending goods but never closed their account.
Find the supplier who hasn’t had a purchase order in the longest time. */

/* Step 1: List all suppliers and their most recent order dates. */

SELECT s.SupplierName, MAX(po.OrderDate) AS LastOrderDate
FROM Purchasing.Suppliers AS s
JOIN Purchasing.PurchaseOrders AS po
    ON s.SupplierID = po.SupplierID
GROUP BY s.SupplierName
ORDER BY LastOrderDate ASC;

/* Step 2: Identify the supplier with the oldest last order. */

SELECT TOP 1
    s.SupplierName,
    MAX(po.OrderDate) AS LastOrderDate
FROM Purchasing.Suppliers AS s
JOIN Purchasing.PurchaseOrders AS po
    ON s.SupplierID = po.SupplierID
GROUP BY s.SupplierName
ORDER BY LastOrderDate ASC;


Use WideWorldImporters

--Mystery 1 – The Overpriced Orders
/*Story: Rumors have spread through headquarters: some suppliers are overcharging us. 
The job was to trace the trail of suspicious prices hidden in the purchase orders.*/

--Step 1: Look at purchase orders with suppliers
SELECT p.PurchaseOrderID, s.SupplierName, p.OrderDate
FROM Purchasing.PurchaseOrders p
JOIN Purchasing.Suppliers s ON p.SupplierID = s.SupplierID;

--Step 2: Add prices for each stock item
SELECT s.SupplierName, w.StockItemName, pol.ExpectedUnitPricePerOuter
FROM Purchasing.PurchaseOrderLines pol
JOIN Purchasing.PurchaseOrders p ON pol.PurchaseOrderID = p.PurchaseOrderID
JOIN Purchasing.Suppliers s ON p.SupplierID = s.SupplierID
JOIN Warehouse.StockItems w ON pol.StockItemID = w.StockItemID;

--Step 3: Find only those above $100
SELECT s.SupplierName, w.StockItemName, pol.ExpectedUnitPricePerOuter
FROM Purchasing.PurchaseOrderLines pol
JOIN Purchasing.PurchaseOrders p ON pol.PurchaseOrderID = p.PurchaseOrderID
JOIN Purchasing.Suppliers s ON p.SupplierID = s.SupplierID
JOIN Warehouse.StockItems w ON pol.StockItemID = w.StockItemID
WHERE pol.ExpectedUnitPricePerOuter > 100;

--Mystery 2 – The Vanishing Customer
/*Story: A client was ordering thousands in products but not a single invoice ever appeared. 
It was like they vanished into thin air — leaving debts behind.*/

--Step 1: Orders vs invoices
SELECT o.OrderID, o.CustomerID, i.InvoiceID
FROM Sales.Orders o
LEFT JOIN Sales.Invoices i ON o.OrderID = i.OrderID;

--Step 2: Customers with missing invoices
SELECT c.CustomerName, o.OrderID
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
LEFT JOIN Sales.Invoices i ON o.OrderID = i.OrderID
WHERE i.InvoiceID IS NULL;

--Mystery 3 – The Discount Dealer
/* Story: Discounts are supposed to encourage sales, but whispers in the office said 
one salesperson was being too generous. My mission was to expose the inside dealer.*/

--Step 1 – connect invoice lines to the salesperson
SELECT i.InvoiceID, p.FullName AS Salesperson, il.UnitPrice, il.Quantity, il.LineProfit
FROM Sales.InvoiceLines  AS il
JOIN Sales.Invoices      AS i  ON il.InvoiceID = i.InvoiceID
JOIN Application.People  AS p  ON i.SalespersonPersonID = p.PersonID;

--Step 2 – flag lines sold at a loss (negative profit)
SELECT p.FullName AS Salesperson, COUNT(*) AS LossLines
FROM Sales.InvoiceLines  AS il
JOIN Sales.Invoices      AS i  ON il.InvoiceID = i.InvoiceID
JOIN Application.People  AS p  ON i.SalespersonPersonID = p.PersonID
WHERE il.LineProfit < 0
GROUP BY p.FullName
ORDER BY LossLines DESC;

--Mystery 4- The Unshipped Invoice
/*  Story: Some invoices never triggered stock movements — was anything shipped? */
 
--Step 1 – invoices with their stock transactions
SELECT i.InvoiceID, st.StockItemTransactionID
FROM Sales.Invoices AS i
LEFT JOIN Warehouse.StockItemTransactions AS st
  ON st.InvoiceID = i.InvoiceID;

--Step 2 – invoices with no stock transaction (likely not shipped)
SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate
FROM Sales.Invoices AS i
LEFT JOIN Warehouse.StockItemTransactions AS st
  ON st.InvoiceID = i.InvoiceID
WHERE st.StockItemTransactionID IS NULL
ORDER BY i.InvoiceDate;


--Mystery 5 (New) – The Suspicious Bulk Orders
/*Story: Management believes some customers might be abusing the system by placing unusually large bulk 
orders. We need to find which customer is behind it.*/

--Step 1 – Look at all orders and quantities
SELECT o.OrderID, c.CustomerName, ol.StockItemID, ol.Quantity
FROM Sales.Orders o
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID;

--Step 2 – Find customers with unusually high single-line orders
SELECT c.CustomerName, ol.StockItemID, ol.Quantity
FROM Sales.OrderLines ol
JOIN Sales.Orders o ON ol.OrderID = o.OrderID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE ol.Quantity > 300
ORDER BY ol.Quantity DESC;

--Step 3 – Summarize total bulk activity per customer
SELECT c.CustomerName, COUNT(*) AS NumBulkOrders, SUM(ol.Quantity) AS TotalBulkQuantity
FROM Sales.OrderLines ol
JOIN Sales.Orders o ON ol.OrderID = o.OrderID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE ol.Quantity >300
GROUP BY c.CustomerName
ORDER BY TotalBulkQuantity DESC;

--Mystery 6 – The Warehouse Workhorse
/*Story: One warehouse employee seems to be editing far too many stock transactions. 
Are they overworked, or manipulating records?*/

--Step 1 – List all stock edits by person
SELECT t.StockItemTransactionID, p.FullName, t.LastEditedWhen
FROM Warehouse.StockItemTransactions t
JOIN Application.People p ON t.LastEditedBy = p.PersonID;

--Step 2 – Count edits per person
SELECT p.FullName, COUNT(*) AS NumTransactionsEdited
FROM Warehouse.StockItemTransactions t
JOIN Application.People p ON t.LastEditedBy = p.PersonID
GROUP BY p.FullName
ORDER BY NumTransactionsEdited DESC;

--Step 3 – Zoom in on the top editor
SELECT t.StockItemTransactionID, w.StockItemName, t.TransactionOccurredWhen, p.FullName
FROM Warehouse.StockItemTransactions t
JOIN Application.People p ON t.LastEditedBy = p.PersonID
JOIN Warehouse.StockItems w ON t.StockItemID = w.StockItemID
WHERE p.FullName = 'Isabella Rupp'
ORDER BY t.TransactionOccurredWhen DESC;


--Mystery 7 – The Loyal Customer

/*Story: Who’s our most loyal customer, and what exactly do they keep buying?*/

--Step 1 – Count orders per customer
SELECT c.CustomerID, c.CustomerName, COUNT(o.OrderID) AS NumOrders
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY NumOrders DESC;

--Step 2 – Inspect their order history
SELECT o.OrderID, o.OrderDate, c.CustomerName
FROM Sales.Orders o
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE c.CustomerID = 90 
ORDER BY o.OrderDate DESC;


--Step 3 – See what items they order most
SELECT w.StockItemName, COUNT(ol.OrderLineID) AS TimesOrdered
FROM Sales.OrderLines ol
JOIN Sales.Orders o ON ol.OrderID = o.OrderID
JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
JOIN Warehouse.StockItems w ON ol.StockItemID = w.StockItemID
WHERE c.CustomerID = 90 -- same ID as Step 2
GROUP BY w.StockItemName
ORDER BY TimesOrdered DESC;




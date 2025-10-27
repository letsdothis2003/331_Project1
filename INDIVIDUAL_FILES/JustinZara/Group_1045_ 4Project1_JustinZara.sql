USE WideWorldImporters; 

/*MYSTERY 1: A van delivering a set of goods suddenly went missing one night.The order was never finalized. 
 * The goods were delivered using the method of road freight.
 * Find the purchase orders that weren't finalized. 
 * Then find the items that were supposed to be shipped. 
 * Then finally search for the person who last edited and approved the order
 */

--First check the purchase orders that werent finalized:
SELECT dm.DeliveryMethodName ,po.IsOrderFinalized, po.PurchaseOrderID
FROM Purchasing.PurchaseOrders po
INNER JOIN Application.DeliveryMethods dm
ON po.DeliveryMethodID = dm.DeliveryMethodID
WHERE po.IsOrderFinalized = 0 AND po.DeliveryMethodID = 7;
-- 1 Purchase Order was found from the output. 
--Now we check the data of the items that were supposed to be shipped in this order, 
--using the Purchase order Lines table.

SELECT po.IsOrderFinalized, pol.*
FROM Purchasing.PurchaseOrders po
INNER JOIN Purchasing.PurchaseOrderLines pol
ON po.PurchaseOrderID  = pol.PurchaseOrderID 
WHERE po.IsOrderFinalized = 0 AND po.DeliveryMethodID = 7;

--6 rows were returned. 
--We can see that the all the unfinished orders were last edited and approved by the same person with an ID of 17.
 
--Now we check the person who last edited them:
SELECT p.FullName  
FROM Application.People p
WHERE p.PersonID = 17;
--The output shows that Piper Koch last edited and approved of these orders. 
--The evidence points to her being the culprit.



/*Mystery 2: There was a report of supplier and customer data being leaked recently. authorities suspect it might be a sales employee with access to the database who was involved. They also suspect them speaking arabic.
 * Check employees who recently edited supplier or customer data
 * Check if the employee speaks arabic/
 * 
 */

SELECT p.FullName 
FROM Application.People p
WHERE p.PersonID IN (
	SELECT DISTINCT s.LastEditedBy 
	FROM Purchasing.Suppliers s
	UNION
	SELECT DISTINCT c.LastEditedBy 
	FROM Sales.Customers c
);

--The output of the query returns 3 invididuals. Now we check if they speak arabic
SELECT P.FullName,p.OtherLanguages, p.PersonID 
FROM Application.People p
WHERE p.PersonID IN (
	SELECT DISTINCT s.LastEditedBy 
	FROM Purchasing.Suppliers s
	UNION
	SELECT DISTINCT c.LastEditedBy 
	FROM Sales.Customers c
) 

--In the output we see 2 employees that speak arabic, person with ID 15 and 20.Now we check wif theyre a system user
SELECT P.FullName,p.OtherLanguages, p.PersonID , p.IsSystemUser 
FROM Application.People p
WHERE p.PersonID IN (
	SELECT DISTINCT s.LastEditedBy
	FROM Purchasing.Suppliers s
	UNION
	SELECT DISTINCT c.LastEditedBy 
	FROM Sales.Customers c
) 
--the oputput indicates that both invidiuals are system users. We can conclude that they are the cuplrits
/*
 * Mystery 3: On January 12, 2013  Several customers complain about not receiving their orders, even thought the system records them as being invoiced.
 * Check which customer orders were made, but not invoiced.
 * Then check the salesperson that handled them.
 * Finally check the delivery method that went wrong.
 */

SELECT o.OrderID, o.OrderDate, i.OrderID as invoice_Order_id
FROM Sales.Orders o
FULL OUTER JOIN Sales.Invoices i
ON o.OrderID = i.OrderID 
WHERE i.OrderID IS NULL AND o.OrderDate  = '2013-01-12';

--The output shows 1 order with order id 694, being returned with no invoice order id.
--Now we check the salesperson responsible for handling the missing order

SELECT o.SalespersonPersonID, p.FullName 
FROM Sales.Orders o
FULL OUTER JOIN Application.People p 
ON o.SalespersonPersonID = p.PersonID 
WHERE o.OrderID = 694;

--the output returns the name Hudson Holliworth
--now we check the delivery method he used for all his orders
SELECT i.DeliveryMethodID, dm.DeliveryMethodName, i.OrderID 
fROM Sales.Orders o 
INNER JOIN Sales.Invoices i 
ON o.OrderID = i.OrderID 
INNER JOIN Application.DeliveryMethods dm 
ON i.DeliveryMethodID = dm.DeliveryMethodID 
WHERE o.SalespersonPersonID = 13 AND i.DeliveryMethodID = 3;

--We see that the delivery method the salesperson used is the same, delivery van.


/*Mystery 4: According to some reports, stock Item transactions were reported to have been falsely generated on january 26, 2013. 
 * As a result, certain items have not been ordered yet, and been lower than 130 in quantity.
 * Find the stock item transactions associated with the same date.
 * Find who last edited them.
 * Find the item with the lowest quantity.
 * 
 */

SELECT DISTINCT sit.StockItemTransactionID , sit.LastEditedBy 
fROm Warehouse.StockItemTransactions sit 
WHERE YEAR(sit.TransactionOccurredWhen) = '2013'
AND MONTH(sit.TransactionOccurredWhen) = '01' 
AND DAY (sit.TransactionOccurredWhen) = '26'

--The output of the query shows the data being edited by the same person. Now we will identify who edited them

SELECT DISTINCT p.FullName, p.PersonID 
fROm Warehouse.StockItemTransactions sit 
INNER JOIN Application.People p
ON sit.LastEditedBy = p.PersonID
WHERE YEAR(sit.TransactionOccurredWhen) = '2013'
AND MONTH(sit.TransactionOccurredWhen) = '01' 
AND DAY (sit.TransactionOccurredWhen) = '26'

--The person revealed to be editing them is Isabella Rupp. Now we will check the stock items with the lowest quantity

SELECT sit.StockItemTransactionID, sit.StockItemID, sit.Quantity, sit.LastEditedBy 
FROM Warehouse.StockItemTransactions sit
WHERE sit.LastEditedBy = 4 AND sit.Quantity < 130 AND sit.LastEditedBy = 4 AND sit.Quantity > 0;
ORDER BY sit.Quantity;

--The output reveals that Stock item with the ID 80 has a quantity lower than 130.

/*Mystery 5: Most invoices were considered tampered with in the month of January 2016.
*Identify these suspicious orders, check the customers associated with them, and find the employee responsible for editing them the most.
*/

SELECT OrderID, CustomerID, OrderDate, LastEditedBy
FROM Sales.Orders
WHERE YEAR(OrderDate) = 2016
AND MONTH(OrderDate) = 1
AND OrderID NOT IN (SELECT DISTINCT OrderID FROM Sales.Invoices);

-- The resulting query returned 131 rows of orders. Now we check the invoices of each customer

SELECT i.LastEditedBy, i.LastEditedWhen, i.*
FROM Sales.Invoices i
WHERE i.CustomerID IN(
	SELECT CustomerID
	FROM Sales.Orders
	WHERE YEAR(OrderDate) = 2016
	AND MONTH(OrderDate) = 1
	AND OrderID NOT IN (SELECT DISTINCT OrderID FROM Sales.Invoices)
) AND (YEAR(i.LastEditedWhen) = 2016 AND MONTH(i.LastEditedWhen) = 1)

--We get a list of names of individuals who edited the invoices table. Now check who edited the most

SELECT TOP (1) i.LastEditedBy, p.FullName, COUNT(i.InvoiceID) AS NumEdits
FROM Sales.Invoices i
INNER JOIN Application.People p ON i.LastEditedBy = p.PersonID
WHERE YEAR(i.InvoiceDate) = 2016
AND MONTH(i.InvoiceDate) = 1
GROUP BY i.LastEditedBy, p.FullName
ORDER BY NumEdits DESC;

--The resulting output shows that Isabella Rupp made the most edits. 
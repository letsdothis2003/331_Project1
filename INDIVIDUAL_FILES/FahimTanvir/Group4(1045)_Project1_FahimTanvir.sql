-- Fahim Tanvir
---CSCI 311 
-- 10:45 AM Group 4 Project 1
-- Mystery Prompts made by Fahim Tanvir
-- Solutions done by Yousuf Ahmed
/*INTRO: We were inspired by beginner and intermediate cases from SQL noir to create 7 mysteries using our knowledge
from chapters 1-6 from our textbook and previous assignmentes*/
USE AdventureWorks2022; -- we need this to run within the database
GO

--MYSTERY 1   
/* On November 30, 2013, an employee was working on in person offline orders at the store. Feeling tired during a long day, they decided to take a short nap
During his nap, he noticed his watch went missing. Unfortunately security was unable to capture the thief since they were gone by the time the employee noticed.
The employee remembers that the last order he made was actually the highest value order that day. It is believed that the customer of this order stole the watch 
Find the employee to punish them for sleeping on the job, and the customer alleged to be the thief.
 */

	-- Step 1: We gotta find the highest value offline order on November 30, 2013.
SELECT TOP 1
    soh.SalesOrderID,
    soh.SalesPersonID,
    soh.CustomerID,
    soh.TotalDue
FROM Sales.SalesOrderHeader soh
WHERE soh.OrderDate = '2013-11-30'
  AND soh.OnlineOrderFlag = 0
ORDER BY soh.TotalDue DESC;


/*OUTPUT:
 * I will note the SalesPersonID and CustomerID for this order
 */

	-- Step 2: Use the SalesPersonID to find the name of the employee
SELECT 
    p.BusinessEntityID AS SalesPersonID,
    p.FirstName,  p.LastName
FROM sales.SalesPerson sp  
JOIN Person.Person p ON p.BusinessEntityID = sp.BusinessEntityID 
WHERE sp.BusinessEntityID = 281
/*OUTPUT:
 * Shu Ito is sleeping on the job.
 */

	-- Step 3: Use the CustomerID to find the name of the alleged thief
SELECT 
    p.BusinessEntityID AS SalesPersonID,
    p.FirstName,  p.LastName
FROM sales.Customer c   
JOIN Person.Person p ON p.BusinessEntityID = c.PersonID   
WHERE c.CustomerID  = 29641
/*OUTPUT:
 * Raul Casts might have stolen the watch
 */

	
	
-- MYSTERY 2   
	
/* You have recieved a fraud notification from ColonialVoice telling you 
that a stolen card was used to purchase a total of $6692.55 in goods over 2 orders in Sunbury.
Find the customer responsible for this fraud
 */
	
	-- Step 1: Find all customers that have paid a total of $6692.55.
SELECT
soh.CustomerID,
	ROUND(SUM(soh.TotalDue), 2) AS TotalSpent,
	count(soh.CustomerID)
FROM
	Sales.SalesOrderHeader soh
GROUP BY
	soh.CustomerID
HAVING
	ROUND(SUM(soh.TotalDue), 2) = 6692.55;
/*OUTPUT: 
 * I see that there are 31 customers that have a total spendage of $6692.55
 * need to do more digging
 */
	
	-- Step 2: Filter those customers for ColonialVoice cards, with a billing address in Sunbury.
WITH step1 AS(
SELECT
soh.CustomerID
FROM
	Sales.SalesOrderHeader soh
GROUP BY
	soh.CustomerID
HAVING
	ROUND(SUM(soh.TotalDue), 2) = 6692.55
	)	
SELECT
	soh.CustomerID,
	soh.SalesOrderID,
	soh.BillToAddressID,
	a.City
FROM
	sales.SalesOrderHeader soh
JOIN step1 s1 ON
	s1.CustomerID = soh.CustomerID
JOIN sales.CreditCard cc ON
	cc.CreditCardID = soh.CreditCardID
JOIN Person.Address a ON
	soh.BillToAddressID = a.AddressID
WHERE
	cc.CardType = N'ColonialVoice'
	AND a.city = N'Sunbury';
/*OUTPUT: 
 * Now I have filtered out the customer who has paid with a ColonialVoice card in Sunbury.
 * All I need to do now is pull their information
 */
	
	-- Step 3: Pull Customer's Name
SELECT
	p.FirstName,
	p.LastName
FROM
	Person.Person p
WHERE
	p.BusinessEntityID = 19965;


	
--   MYSTERY 3  	
/* While reading the news, you see that a person from Houston was recently arrested for trying to smuggle fake goods in 2013.
They hid them into Large Long-Sleeve Logo Jerseys from your company. After looking into it, they also have been caught doing the same thing in 2012. 
You see that he was previously caught smuggling with Medium Full-Finger Gloves. You recall your employee Jillian Carson was arrested around the same time in 2012 for working under them.
Unfortunately their identity is kept secret by the news and you don't remember their name from the last time you encountered them.
Find out who this customer is, and which employee sold him the Large Long Sleeve Logo Jerseys in 2013.
 */
	

	-- Step 1: Find the Product IDs for the two items, and save them for later queries
SELECT
	ProductID,
	Name
FROM
	Production.Product
WHERE
	Name LIKE N'%Long-Sleeve Logo Jersey%'
	OR Name LIKE N'%Full-Finger Gloves%';
/*OUTPUT: 
 * This returns seven items, all sizes of Full-Finger Gloves and Long-Sleeve Logo Jerseys.
 * Note down both Product ID's of the items that are relevant to the mystery
 * 862 : Full-Finger Gloves, M
 * 715 : Long-Sleeve Logo Jersey, L
 */

	-- Step 2: Find out Jillian Carson's ID and customers from Houston that she has sold to

WITH accomplice2012 AS (
SELECT
	p.BusinessEntityID
FROM
	Person.Person p
WHERE
	p.FirstName = N'Jillian'
	AND p.LastName = N'Carson')
SELECT DISTINCT
	soh.CustomerID,
	p.FirstName,
	p.LastName,
	soh.SalesPersonID
FROM
	Sales.SalesOrderHeader soh
JOIN accomplice2012 a2012 ON
	a2012.BusinessEntityID = soh.SalesPersonID
JOIN Sales.Customer c 
    ON
	soh.CustomerID = c.CustomerID
JOIN Person.Person p 
    ON
	c.PersonID = p.BusinessEntityID
JOIN person.Address a ON
	soh.ShipToAddressID = a.AddressID
WHERE
	a.City = N'Houston';
/*OUTPUT: 
 * This query gives us three customers within Memphis who have worked with of Jillian Carson. It also provides Carson's ID which makes filtering her orders easier.
 * John Arthur, Michael Blythe, Sunil Uppal. I need to look through these customers and see which one has ordered Full-Finger Gloves, M in 2012.
 */

 	-- Step 3: Figure out which customer has bought Full-Finger Gloves, M in 2012 from Jillian Carson
SELECT
	soh.CustomerID,
	p.FirstName ,
	p.LastName ,
	soh.OrderDate,
	sod.OrderQty
FROM
	Sales.SalesOrderHeader soh
JOIN sales.SalesOrderDetail sod ON
	soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.Customer c 
    ON
	soh.CustomerID = c.CustomerID
JOIN Person.Person p 
    ON
	c.PersonID = p.BusinessEntityID
WHERE
	soh.SalesPersonID = 277
	AND YEAR(soh.OrderDate) = 2012
	AND soh.CustomerID IN (29523, 29570, 30095)
	AND sod.ProductID = 862;
/*OUTPUT: 
 * I found the criminal: John Arthur 
 * Maybe I should ban this guy from ordering more products
 */

	-- Step 4: find his orders with Long-Sleeve Logo Jersey, L and figure out who sold it to him.
SELECT
	soh.CustomerID,
	soh.OrderDate,
	soh.SalesPersonID,
	p.FirstName ,
	p.LastName,
	sod.OrderQty
FROM
	Sales.SalesOrderHeader soh
JOIN sales.SalesOrderDetail sod ON
	soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesPerson sp  
    ON
	soh.SalesPersonID = sp.BusinessEntityID
JOIN Person.Person p 
    ON
	sp.BusinessEntityID = p.BusinessEntityID
WHERE
	YEAR(soh.OrderDate) = 2013
	AND soh.CustomerID = 29523
	AND sod.ProductID = 715;
/*OUTPUT: 
 * I found the accomplice: Michael Blythe 
 * Maybe I should fire this guy
 */
	
	
	
--   MYSTERY 4  
/* A Florida Man was found dead by a defective product. This product was not sold much in bulk.
 The purchase was in May 2012 and happened to be the one of the top 5 lowest selling items of that year.
 */

	-- Step 1: Find the top 5 worst selling items of 2012
SELECT
	TOP 5
    sod.ProductID,
	p.Name AS ProductName,
	SUM(sod.OrderQty) AS TotalQuantitySold
FROM
	Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh 
    ON
	sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p 
    ON
	sod.ProductID = p.ProductID
WHERE
	YEAR(soh.OrderDate) = 2012
GROUP BY
	sod.ProductID,
	p.Name
ORDER BY
	TotalQuantitySold ASC;
/*OUTPUT:
 * 4 out of 5 of these items are bike frames. 
 * I can exclude the socks because who is gonna die beacasue of a pair of socks. If they are they must be very unlucky.
 */

	--Step 2: Find out which of these unpopular items were ordered by themselves in May 2012. 
SELECT
	soh.SalesOrderID,
	soh.CustomerID,
	soh.OrderDate,
	sod.ProductID,
	p.Name AS ProductName,
	a.City
FROM
	Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh 
    ON
	sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p 
    ON
	sod.ProductID = p.ProductID
JOIN person.Address a ON
	a.AddressID = soh.ShipToAddressID 
WHERE
	sod.ProductID IN (744, 733, 719, 839)
	AND soh.OrderDate BETWEEN '2012-05-01' AND '2012-05-31'
	AND sod.OrderQty = 1;
/*OUTPUT:
 * There are two customers who have ordered this item, and one specifically from Florida.
 * This matches our description of the Florida Man. 
 */
	
	-- Step 3: Find out the Florida Man's name
SELECT p.FirstName , p.LastName 
FROM sales.Customer c 
JOIN Person.Person p ON p.BusinessEntityID = c.PersonID 
WHERE c.CustomerID = 29704
/*OUTPUT:
 * The Victim was Shawn Demicell. RIP
 */

	
--   MYSTERY 5   

/*The London police have contacted you to find the owner of a stolen bike. They have included the following information about the bike:
Silver Women's Mountain Bike, size of 46 CM. Worn out marker shows the letters "ca Sa"
Find the customer's first and last name, alongside their email.
 */

	-- Step 1: Find the item number of the bike using the police's description
SELECT
	p.ProductID,
	p.Name
FROM
	Production.Product p
WHERE
	p.Color = N'Silver'
	AND p.Size = N'46'
	AND p.Style = N'W';
/*OUTPUT: 
 * There are two results with the following criteria. 
 * One is a full bike while the other is a frame. 
 * It is possible the customer has purchased the frame on it's own, so I have to note both ProductID's
 */
	
	-- Step 2: Find out who has ordered these products from London
SELECT
	soh.SalesOrderID,
	sod.ProductID,
	soh.CustomerID
FROM
	sales.SalesOrderDetail sod
JOIN sales.SalesOrderHeader soh ON
	soh.SalesOrderID = sod.SalesOrderID
JOIN person.Address a ON
	soh.ShipToAddressID = a.AddressID
WHERE
	(sod.ProductID = 906
		OR sod.ProductID = 983)
	AND a.City = N'London';
/*OUTPUT: 
 * There are six orders with the two products. 
 * Five people have ordered the full bike, and another person ordered a frame. 
 * I will use the CustomerID to pull the first and last names of the people who placed these orders
 */
	
	-- Step 3: Find out the names of the customers
WITH step2 AS(
SELECT soh.CustomerID 
FROM sales.SalesOrderDetail sod
JOIN sales.SalesOrderHeader soh ON
	soh.SalesOrderID = sod.SalesOrderID
JOIN person.Address a ON
	soh.ShipToAddressID = a.AddressID
WHERE(sod.ProductID = 906
	OR sod.ProductID = 983)
AND a.City = N'London'
)
SELECT
	p.FirstName,
	p.LastName ,
	c.CustomerID,
	p.BusinessEntityID
FROM
	Sales.Customer c
JOIN step2 lc ON
	c.CustomerID = lc.CustomerID
JOIN Person.Person p ON
	p.BusinessEntityID = c.PersonID
ORDER BY
	c.CustomerID;
/*OUTPUT: 
 * I see one name that sticks out: "Veronica Sai", which matches the partial "ca Sa" marking on the bike.
 * Noting the BusinessEntityID which can be used to retrieve her email.
 */
	
-- Step 4: Find the contact email
SELECT
	ea.EmailAddress
FROM
	Person.EmailAddress ea
WHERE
	ea.BusinessEntityID = 18975;

	/*output:veronica6@adventure-works.com*/


	--Mystery 6
/*A customer has filed a complaint about receiving a defective helmet. The helmet was purchased in July 2013 recently and
was part of a batch known for quality issues. The product is described as a Red Sport-100 Helmet.
Find the customer’s name and the city it was shipped to.
 */

    -- Step 1: Identify the product ID based on the description
SELECT
    p.ProductID,
    p.Name
FROM
    Production.Product p
WHERE
    p.Color = N'Red'
    AND p.Name = N'Sport-100 Helmet, Red';
/*OUTPUT:
 * Our ID for the red hat is 707
 */

    -- Step 2: Find orders for this product in July 2013
SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.OrderDate,
    a.City,
    sod.ProductID
FROM
    Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh ON
    soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON
    soh.ShipToAddressID = a.AddressID
WHERE
    sod.ProductID = 707
    AND soh.OrderDate BETWEEN '2013-07-01' AND '2013-07-31'
ORDER BY soh.OrderDate DESC;
/*OUTPUT:
 * This returns a few orders from July 2013 in recent to least recent. Looks like irving
 is our target location with customer id of 29637 and sales order id of 53616
 */

    -- Step 3: Get the customer’s name
SELECT
    p.FirstName,
    p.LastName,
    c.CustomerID
FROM
    Sales.Customer c
JOIN Person.Person p ON
    p.BusinessEntityID = c.PersonID
WHERE
    c.CustomerID = 29637;
/*OUTPUT: The customer is named Donna Carreras.
 */


 --MYSTER 7 

/*An internal audit revealed that a group of employees may have been issuing refunds to fake customers, so they can get the cash
back to themselves through separate accounts..
 The refunds were processed in THE last day of April 2014 and were all tied to orders with unusually high discount rates.
 Find the employee responsible and the list of phony customers to void them from our system after reporting the employees.
 */

    -- Step 1: Find orders with high discount rates in April 2014 in the last day
SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.SalesPersonID,
    sod.UnitPriceDiscount,
    soh.OrderDate
FROM
    Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON
    soh.SalesOrderID = sod.SalesOrderID
WHERE
    sod.UnitPriceDiscount > 0.3
    AND soh.OrderDate BETWEEN '2014-03-30' AND '2014-03-31';
/*OUTPUT:
90 transactions
 */

-- Step 2: Identify the employee
SELECT
    p.FirstName,
    p.LastName,
    sp.BusinessEntityID
FROM
    Sales.SalesPerson sp
JOIN Person.Person p ON
    p.BusinessEntityID = sp.BusinessEntityID
WHERE
    sp.BusinessEntityID IN (
        274, 275, 276, 277, 278, 279, 282, 283, 284, 288, 289, 290
    );

/*OUTPUT: We found 12 employees in this scheme.
 */

-- Step 3: List the affected customers
SELECT DISTINCT
    p.FirstName,
    p.LastName,
    c.CustomerID
FROM
    Sales.Customer c
JOIN Person.Person p ON
    p.BusinessEntityID = c.PersonID
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    WHERE soh.CustomerID = c.CustomerID
    AND sod.UnitPriceDiscount > 0.3
    AND soh.OrderDate BETWEEN '2014-03-30' AND '2014-03-31'
);
/*OUTPUT: We found 33 names which are fake customers.
 */

-- Yousuf Ahmed
---CSCI 311 
-- 10:45 AM Group 4 Project 1
-- Mystery Prompts made by Yousuf Ahmed
-- Solutions done by Fahim Tanvir
/**intro: These are 7 queries we made to root out problems(a lot go whcih is related to theft or other nefarious schemes) one might find in a company or manager role.
Inspired by SQL NOIR**/

USE AdventureWorks2022;--Its new, so I decided me and Fahim atleast can get accostumed to it.
GO
  
--MYSTERY 1

/*One of the employees committed commision fraud. It is proposed that they produced
a decent ammount of commissions and is one of the top 3 earning sales employees who made
a record sale.*/

-- Step 1:
/*Find all salespeople, and group from the highest sales of ALL sales orders. */
SELECT  p.FirstName + ' ' + p.LastName AS SalespersonName, 
    COUNT(soh.SalesOrderID) AS TotalOrdersCount
FROM   Person.Person AS p
JOIN Sales.SalesOrderHeader AS soh ON p.BusinessEntityID = soh.SalesPersonID 
WHERE  soh.SalesPersonID IS NOT NULL
GROUP BY p.FirstName, p.LastName
ORDER BY TotalOrdersCount DESC;

/**OUTPUT: The top 3 for this one is Jillian Carson, Michael Blythe and Tsvi Reiter. 
This is a false hering as we should be looking for highest earners, not busiest person. 
We can make sure by checking how much they got through the actual profit they make**/


-- Step 2: 
/*Calculates the highest single sale value for every salesperson. This shortens our list of suspects*/
SELECT
    soh.SalesPersonID,
    p.FirstName,
    p.LastName,

MAX(soh.SubTotal) AS HighestSaleValue
FROM Sales.SalesOrderHeader AS soh
JOIN  Person.Person AS p ON soh.SalesPersonID = p.BusinessEntityID 
WHERE soh.SalesPersonID IS NOT NULL
GROUP BY soh.SalesPersonID, p.FirstName, p.LastName
ORDER BY HighestSaleValue DESC;
/**OUTPUT: The top 3 for this one is Shu Ito, Jae Pak and Ranjit Varkey. 
We can make even more sure by seeing how much they made overall**/


-- Step 3 
/*Finds the salesperson with the highest average sale value*/
SELECT 
    p.FirstName + ' ' + p.LastName AS SalesPersonName,  ReturnData.AverageOrderValue
FROM
    Person.Person AS p
JOIN (
    SELECT SalesPersonID,
    AVG(SubTotal) AS AverageOrderValue
    FROM Sales.SalesOrderHeader
    WHERE SalesPersonID IS NOT NULL
    GROUP BY SalesPersonID
) AS ReturnData ON p.BusinessEntityID = ReturnData.SalesPersonID
ORDER BY
    ReturnData.AverageOrderValue DESC; 

    /**OUTPUT AND MAIN CULPRIT:Shu Ito is our main guy, he is 2nd highest earner**/



--Mystery 2
/*A customer is presumed to have shoplifted a lot of our merch. We know they frequented our 
store around the first week of october 2012 didn't spend that much overall. They weren't contacted 
a few months later from March to May due to them unsubscribing from our newsleter. 
They attempted to cover their trail by using legitamate purchases after May.*/

--Step 1
/*We gotta find the least spending customers*/
SELECT TOP 10 CustomerID, SUM(TotalDue) AS TotalSpent 
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2012-10-01' AND OrderDate <= '2012-10-07'
GROUP BY CustomerID
ORDER BY TotalSpent ASC;

/**OUTPUT: Our top 10 least spenders are
15388, 20598, 20716, 20859, 26436, 26439, 26442, 14239**/
 

--Step 2
/*Find customer that was contacted from May to March.*/
/* Find customers whose contact records were modified between March 1st and May 31st
WE MUST FIND SOMEONE WHO ISN'T PRESENT ON THE LIST*/
SELECT DISTINCT
    C.CustomerID,
    P.FirstName + ' ' + P.LastName AS CustomerName
FROM
    Sales.Customer AS C
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID
WHERE
    C.PersonID IS NOT NULL
    AND (
        EXISTS (
            SELECT 1
            FROM Person.EmailAddress AS E
            WHERE E.BusinessEntityID = P.BusinessEntityID
            AND E.ModifiedDate >= '2012-03-01' AND E.ModifiedDate <= '2012-05-31'
        )
        OR
        EXISTS (
            SELECT 1
            FROM Person.PersonPhone AS PP
            WHERE PP.BusinessEntityID = P.BusinessEntityID
            AND PP.ModifiedDate >= '2012-03-01' AND PP.ModifiedDate <= '2012-05-31'
        )
   )
ORDER BY CustomerID;
/**OUTPUT: A lot of customers who responded to their emails**/



--Step 3
/*Find customer who isn't present on the list from step 2*/
SELECT DISTINCT
    C.CustomerID,
    P.FirstName + ' ' + P.LastName AS CustomerName
FROM
    Sales.Customer AS C
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID
WHERE
    C.PersonID IS NOT NULL 
    AND NOT EXISTS (
        SELECT 1
        FROM Person.EmailAddress AS E
        WHERE E.BusinessEntityID = P.BusinessEntityID
        AND E.ModifiedDate >= '2012-03-01' AND E.ModifiedDate <= '2012-05-31'
    )
    AND NOT EXISTS (
        
        SELECT 1
        FROM Person.PersonPhone AS PP
        WHERE PP.BusinessEntityID = P.BusinessEntityID
        AND PP.ModifiedDate >= '2012-03-01' AND PP.ModifiedDate <= '2012-05-31'
    )
ORDER BY CustomerID;
/**OUTPUT: Customers that didn't respond in April, March or May 2012. 15388 
Or Victoria Smith is on that list!**/

--Step 4
/*Customers who bought something past May */
SELECT DISTINCT
    C.CustomerID,
    P.FirstName + ' ' + P.LastName AS CustomerName
FROM
    Sales.Customer AS C
JOIN
    Person.Person AS P ON C.PersonID = P.BusinessEntityID
WHERE
    C.PersonID IS NOT NULL 
    AND C.CustomerID IN (
        SELECT DISTINCT CustomerID
        FROM Sales.SalesOrderHeader
        WHERE OrderDate > '2012-05-31'
    )
ORDER BY
    CustomerID;
 /**OUTPUT AND MAIN CULPRIT:Victoria Smith did infact other something around a date after the month of 
 May. This fills our checkboxes**/




--Mystery 3
/*A employee is sabotaging us by causing delays and losing profits by consistently smuggling
products to shipping facilities not authorized by us and is choosing cheap shipping
territories but  using expensive shipping methods.
They also have many high value sales despite this. How can we find this person?.*/

--Step 1
/*Find the territory with lowest shipping cost*/

SELECT TOP 10 st.Name AS TerritoryName,
AVG(soh.Freight) AS AvgFreightCost
FROM
    Sales.SalesOrderHeader AS soh
JOIN
    Sales.SalesTerritory AS st ON soh.TerritoryID = st.TerritoryID
GROUP BY
    st.Name
ORDER BY
    AvgFreightCost ASC;
 /*OUTPUT: Australia, Germany, UK, France, NorthWest
 Southwest, CanADA, Southeast, Northeast, Central*/


--Step 2
/*Find seller who has most number of orders using  most pricey shipping methods.*/
WITH ExpensiveShippers AS (
    SELECT TOP 5
        ShipMethodID
    FROM
        Purchasing.ShipMethod
    ORDER BY
        ShipBase DESC
)
SELECT
    p.FirstName + ' ' + p.LastName AS EmployeeName,
    COUNT(soh.SalesOrderID) AS OrdersWithExpensiveShipping,
    AVG(soh.SubTotal) AS AvgSubtotalForExpensiveOrders
FROM
    Sales.SalesOrderHeader AS soh
JOIN
    Person.Person AS p ON soh.SalesPersonID = p.BusinessEntityID
WHERE
    soh.ShipMethodID IN (SELECT ShipMethodID FROM ExpensiveShippers)
    AND soh.SalesPersonID IS NOT NULL
GROUP BY
    p.FirstName, p.LastName
ORDER BY
    OrdersWithExpensiveShipping DESC;

/*Output: Jillian Carson, Michael Blythe, Tsvi Reiter, Linda Mitchell, Jae Pak
Jose Saraiva, Shu Ito(theif from mystery 1), Garret Vargas, David Campbell, Ranjit Varkey
Tete Mensa, Rachel Valdez, Lynn Tsoflias, Pamela Ansm, Stephen Jiang, Amy Alberts, Syed Abbas*/


--Step 3
/*Find who has the highest average ratio of Shipping Cost (Freight) to SubTotal,
indicating they are incurring high costs on low-value sales. */
SELECT TOP 1
    p.FirstName + ' ' + p.LastName AS SuspectName,
    AVG(soh.Freight / soh.SubTotal) AS AvgCostToValueRatio
FROM
    Sales.SalesOrderHeader AS soh
JOIN
    Person.Person AS p ON soh.SalesPersonID = p.BusinessEntityID
GROUP BY p.FirstName, p.LastName
ORDER BY AvgCostToValueRatio DESC;
/*Output: Lynn Tsoflias*/


--Step 4
/*Verify our suspect with location they ship in */
SELECT
    p.FirstName + ' ' + p.LastName AS SalespersonName,
    st.Name AS TerritoryName
FROM
    Person.Person AS p
JOIN
    Sales.SalesPerson AS sp ON p.BusinessEntityID = sp.BusinessEntityID
JOIN
    Sales.SalesTerritory AS st ON sp.TerritoryID = st.TerritoryID
WHERE
    p.FirstName = 'Lynn' AND p.LastName = 'Tsoflias';

    /*Main output:Lynn Tsoflias ships in Australian territories or the cheapest shipping area*/




--Mystery 4
/*An employee stole diamonds and  placed them within purchases. This was discovered in  the last week
0f December 2013 but could've happened earlier.It is a low selling item during that month, 
most likely for an accomplice to buy and  split the cost with the suspect. Who is that employee?
Who is that customer?*/

-- Step 1: 
/**Identify the lowest selling product by volume in the  month of december**/
SELECT TOP 1 sod.ProductID,  p.Name AS ConcealmentProductName,
 SUM(sod.OrderQty) AS TotalQuantitySold
FROM
Sales.SalesOrderDetail AS sod 
JOIN
Sales.SalesOrderHeader AS soh ON sod.SalesOrderID = soh.SalesOrderID
JOIN
 Production.Product AS p ON sod.ProductID = p.ProductID
WHERE
    soh.OrderDate >= '2013-12-01'
    AND soh.OrderDate <= '2013-12-31'
GROUP BY sod.ProductID, p.Name
ORDER BY TotalQuantitySold ASC;
/*Output is Road-650 Black, 52 with ProductID 770 and sold only once, helping us narrow thingds down*/

--Step 2
/*Find employee who sold it**/
SELECT TOP 1
    P.FirstName + ' ' + P.LastName AS SalespersonName,
    CAST(SOH.OrderDate AS DATE) AS SaleDate,
    sales.SalesOrderID
FROM Sales.SalesOrderDetail AS sales
JOIN  Sales.SalesOrderHeader AS SOH ON sales.SalesOrderID = SOH.SalesOrderID
JOIN Person.Person AS P ON SOH.SalesPersonID = P.BusinessEntityID
WHERE sales.ProductID = 770
ORDER BY SOH.OrderDate DESC;
/*OUTPUT AND MAIN CULPRIT: Rachel Valdes sold the item in 2013-12-31*/


--Step 3
/*Find customer associated with the sale*/
SELECT TOP 1
    P_Cust.FirstName + ' ' + P_Cust.LastName AS CustomerName,
    SOH.CustomerID,
    CAST(SOH.OrderDate AS DATE) AS SaleDate,
    sales.ProductID
FROM Sales.SalesOrderDetail AS sales
JOIN Sales.SalesOrderHeader AS SOH ON sales.SalesOrderID = SOH.SalesOrderID
JOIN Sales.Customer AS C ON SOH.CustomerID = C.CustomerID
JOIN Person.Person AS P_Cust ON C.PersonID = P_Cust.BusinessEntityID
WHERE sales.ProductID = 770
ORDER BY SOH.OrderDate DESC;

/*OUTPUT AND ACCOMPLICE: David Brink is our main accomplice as he bought the item on the same day*/




--Mystery 5
/*An employee was victim to a phishing email. It is known that they clicked on the email on the year 2013,
when the system has updated their email, and the email was promising a promotion, which gets us to believe
it was low earning. 6 accounts were compromised including the original person who was sent the phising email. Who is this?*/

-- Step 1: 
/** Find the date with the highest total number of contact record changes**/
SELECT TOP 1
    CAST(ModifiedDate AS DATE) AS BusiestUpdateDay,
    COUNT(BusinessEntityID) AS TotalContactUpdates
FROM
    Person.EmailAddress
GROUP BY
    CAST(ModifiedDate AS DATE)
ORDER BY
    TotalContactUpdates DESC;
    /*Output: 2013-07-31*/

-- Step 2: 
/*Find the Top 10 Employees with the most recent contact modification dates in 2013.*/
WITH UPDATED AS (
    SELECT BusinessEntityID, ModifiedDate FROM Person.EmailAddress WHERE YEAR(ModifiedDate) = 2013
    UNION ALL
    SELECT BusinessEntityID, ModifiedDate FROM Person.PersonPhone WHERE YEAR(ModifiedDate) = 2013
)
SELECT TOP 6 P.FirstName + ' ' + P.LastName as FullName, MAX(UPDATED.ModifiedDate) AS Datelastmodified
FROM UPDATED JOIN Person.Person AS P ON UPDATED.BusinessEntityID = P.BusinessEntityID
JOIN HumanResources.Employee AS HRE ON P.BusinessEntityID = HRE.BusinessEntityID
GROUP BY P.BusinessEntityID, P.FirstName, P.LastName
ORDER BY MAX(UPDATED.ModifiedDate) DESC;

/*OUTPUT: Taylor Maxwell, Barry Johnson, Jossef Goldberg, Rachel Valdez
Lynn Tsoflias, Syed Abbas*/


-- Step 3
/*Find lowest ranking Employee who had a recent contact modification from step 2.*/
WITH LatestEmployeeContact AS (
    SELECT T.BusinessEntityID, MAX(T.ModifiedDate) AS LatestDate FROM (
        SELECT BusinessEntityID, ModifiedDate FROM Person.EmailAddress
        UNION ALL
        SELECT BusinessEntityID, ModifiedDate FROM Person.PersonPhone
    ) AS T GROUP BY T.BusinessEntityID
)
SELECT TOP 1 
    P.FirstName + ' ' + P.LastName AS Suspect, SP.SalesYTD, LEC.LatestDate
FROM LatestEmployeeContact AS LEC 
JOIN Sales.SalesPerson AS SP ON LEC.BusinessEntityID = SP.BusinessEntityID
JOIN Person.Person AS P ON LEC.BusinessEntityID = P.BusinessEntityID
ORDER BY  SP.SalesYTD ASC, LEC.LatestDate DESC;

/*OUTPUT AND MAIN VICTIM is SYED Abbas*/




--Mystery 6
/*A product seems to vanish from stock. We sold some, but it doesn’t show up in recent orders. 
Let’s track when it was last sold and who sold it.*/

-- Step 1: 
/*Find total sales of each product that have sold the least.*/
SELECT TOP 5
    sod.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty) AS TotalSold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY sod.ProductID, p.Name
ORDER BY TotalSold ASC;
/*OUTPUT: "LL Touring Frame - Blue, 58", "ML Mountain Frame-W - Silver, 38", "LL Mountain Frame - Black, 40", LL Road Seat/Saddle, "LL Touring Frame - Blue, 62"
 The "LL Touring Frame - Blue, 58" has sold the least. This is our item which has been vanishing. */

-- Step 2: 
/*Find who sold that product last.*/
SELECT TOP 1
    soh.SalesPersonID,
    per.FirstName + ' ' + per.LastName AS Salesperson,
    soh.OrderDate,
    sod.ProductID
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Person per ON soh.SalesPersonID = per.BusinessEntityID
WHERE sod.ProductID = 897
ORDER BY soh.OrderDate DESC;
/*OUTPUT AND CULPRIT: José Saraiva is the person who has sold the item last. The order was in 2013 which does not line up with the recent unlisted sales*/




--Mystery 7
/*An employee made up fake customers to hit bonus and commission targets. 
 It is rumored this employe constantly creates new customers that order once and never again.*/

-- Step 1: 
/*Figure out how many orders each customer has.*/
SELECT 
    CustomerID,
    COUNT(SalesOrderID) AS OrdersCount
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY OrdersCount ASC;
/*OUTPUT: The Customer ID with the number of orders they have placed.*/

-- Step 2: 
/*Filter out the ID and Name of each customer that has only ordered once.*/
SELECT 
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE c.CustomerID IN (
    SELECT CustomerID
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) = 1
)
ORDER BY c.CustomerID;
/*OUTPUT: The CustomerId and name of those customers with only one order*/

-- Step 3: 
/*From the customers that have ordered once, figure out how many of those orders each employee placed.*/

SELECT
    p.FirstName + ' ' + p.LastName AS Salesperson,
    COUNT(soh.SalesOrderID) AS OneTimeOrders
FROM Sales.SalesOrderHeader soh
JOIN Person.Person p ON soh.SalesPersonID = p.BusinessEntityID
WHERE soh.CustomerID IN (
    SELECT CustomerID
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) = 1
)
GROUP BY p.FirstName, p.LastName
ORDER BY OneTimeOrders DESC;
/*OUTPUT: Tsvi Reiter, Linda Mitchell, Jillian Carson, Rachel Valdez, Garrett Vargas, Michael Blythe, 
David Campbell, Jae Pak, José Saraiva, Lynn Tsoflias, Shu Ito, Tete Mensa-Annan, Syed Abbas
Culprit: Tsvi Reiter has the most one time customer orders. It is a significant gap compared to other employees.*/


  

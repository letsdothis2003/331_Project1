-- Fahim Tanvir
--Group_1045_4
-- CSCI-331
-- PROJECT 1
/**intro: These are 7 queries we made to root out problems(a lot go whcih is related to theft or other nefarious schemes) one might find in a company or manager role.
Inspired by SQL NOIR**/

USE AdventureWorks2022;--Its new, so I decided me and Yousuf atleast can get accostumed to it.
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
/*We gotta least spending customer*/
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

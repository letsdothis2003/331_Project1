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

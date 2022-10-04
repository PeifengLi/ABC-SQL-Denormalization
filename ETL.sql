CREATE DATABASE ABC;

USE ABC

CREATE TABLE ABC
(
OrderID INT NOT NULL,
OrderDate DATETIME NOT NULL,
Order_ShippedDate DATETIME NOT NULL,
Order_Freight FLOAT NOT NULL,
Order_ShipCity VARCHAR(30) NOT NULL,
Order_ShipCountry VARCHAR(30) NOT NULL,
Order_UnitPrice FLOAT NOT NULL,
Order_Quantity INT NOT NULL,
Order_Amount FLOAT NOT NULL,
ProductName VARCHAR(100) NOT NULL,
Employee_LastName VARCHAR(30) NOT NULL,
Employee_FirstName VARCHAR(30) NOT NULL,
Employee_Title VARCHAR(30) NOT NULL,
CompanyName VARCHAR(50) NOT NULL,
Customer_ContactName VARCHAR(50) NOT NULL,
Customer_City VARCHAR(30) NOT NULL,
Customer_Country VARCHAR(30) NOT NULL,
Customer_Phone VARCHAR(20) NOT NULL
);

LOAD DATA LOCAL INFILE '/Users/bryton/Desktop/Courses/Database for Data Science/Homework3/ABC_Retail_Orders.txt' INTO TABLE ABC
COLUMNS TERMINATED BY '\t'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

LOAD DATA FROM S3 's3://s3instacart/ABC_Retail_Orders.txt' INTO TABLE ABC
COLUMNS TERMINATED BY '\t'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SELECT * FROM ABC;

-- 'EMPLOYEE TABLE' EXTRACT, TRANSFORM, LOAD 
CREATE TABLE Employee
(
SELECT DISTINCT Employee_LastName, Employee_FirstName, Employee_Title FROM ABC
);

ALTER TABLE Employee
ADD COLUMN EmployeeID INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

SELECT * FROM Employee;

-- 'CUSTOMERS TABLE' EXTRACT, TRANSFORM, LOAD 
CREATE TABLE Customers
(
SELECT DISTINCT Customer_ContactName, Customer_City, Customer_Country, Customer_Phone, CompanyName FROM ABC
);

ALTER TABLE Customers
ADD COLUMN CustomerID INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

SELECT * FROM Customers;

-- 'ORDER TABLE' EXTRACT, TRANSFORM, LOAD 
CREATE TABLE Orders AS
(
SELECT DISTINCT OrderID, OrderDate, Order_ShippedDate,
 Order_Freight, Order_ShipCity, Order_ShipCountry, CustomerID, EmployeeID FROM ABC
JOIN Customers c ON ABC.Customer_ContactName = c.Customer_ContactName
JOIN Employee e ON ABC.Employee_FirstName = e.Employee_FirstName 
AND ABC.Employee_LastName = e.Employee_LastName
);

ALTER TABLE Orders 
ADD PRIMARY KEY (OrderID),
ADD FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
ADD FOREIGN KEY (EmployeeID) REFERENCES Employee(EmployeeID);

SELECT * FROM Orders ORDER BY OrderID;

-- 'PRODUCT TABLE' EXTRACT, TRANSFORM, LOAD 
CREATE TABLE Products AS 
(
SELECT DISTINCT ProductName FROM ABC
);

ALTER TABLE Products
ADD COLUMN ProductID INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

SELECT * FROM Products;

-- 'ORDER_PRODUCTS TABLE' EXTRACT, TRANSFORM, LOAD 
CREATE TABLE Order_products AS
(
SELECT OrderID, ProductID, Order_UnitPrice, Order_Quantity FROM ABC
LEFT JOIN Products p ON ABC.ProductName = p.ProductName
);

ALTER TABLE Order_products
ADD PRIMARY KEY (OrderID, ProductID),
ADD FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
ADD FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
;

SELECT * FROM Order_products;

-- ETL TESTING
-- REFERENCE DATA TESTING
SELECT DISTINCT op.OrderID FROM Order_products op
LEFT JOIN Orders o ON op.OrderID = o.OrderID WHERE o.OrderID IS NULL;

SELECT DISTINCT op.ProductID FROM Order_products op
LEFT JOIN Products p ON op.ProductID = p.ProductID WHERE p.ProductID IS NULL;

SELECT DISTINCT o.CustomerID FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID WHERE c.CustomerID IS NULL;

-- REFERENCE DATA TESTING (WORK AS SELECT.. MINUS SELECT ..)

SELECT DISTINCT op.OrderID FROM Order_products op
LEFT JOIN Orders o ON op.OrderID = o.OrderID WHERE o.OrderID IS NULL;
 

SELECT DISTINCT op.ProductID FROM Order_products op
LEFT JOIN Products p ON op.ProductID = p.ProductID 
WHERE p.ProductID IS NULL;
 

SELECT DISTINCT o.CustomerID FROM Orders o
LEFT JOIN Customers c ON o.CustomerID = c.CustomerID 
WHERE c.CustomerID IS NULL;

SELECT DISTINCT o.EmployeeID FROM Orders o
LEFT JOIN Employee e ON o.EmployeeID = e.EmployeeID 
WHERE e.EmployeeID IS NULL;

-- DENORMALIZATION
CREATE TABLE ABC_Fact_Table
(
SELECT o.OrderID, o.OrderDate, o.Order_ShippedDate, o.Order_Freight, 
o.Order_ShipCity, o.Order_ShipCountry, op.Order_UnitPrice, op.Order_Quantity,
ROUND(op.Order_UnitPrice*op.Order_Quantity, 2) AS Order_Amount, p.ProductName, 
e.Employee_LastName, e.Employee_FirstName, e.Employee_Title,
c.Customer_ContactName, c.Customer_City, c.Customer_Country, c.Customer_Phone, c.CompanyName
FROM Orders o
JOIN Order_products op ON o.OrderID = op.OrderID
JOIN Products p ON op.ProductID = p.ProductID
JOIN Employee e ON o.EmployeeID = e. EmployeeID
JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY o.OrderID, op.ProductID
);

SELECT * FROM ABC_Retail_Fact;

-- METADATA CHECK
SHOW FIELDS FROM ABC;

SHOW FIELDS FROM ABC_Fact_Table;

-- RECORD COUNT VALIDATION
SELECT COUNT(*) FROM ABC;

SELECT COUNT(*) FROM ABC_Fact_Table;

-- COLUMN DATA PROFILE VALIDATION
SELECT COUNT(DISTINCT OrderID), COUNT(DISTINCT Order_ShipCity), COUNT(DISTINCT Order_ShipCountry),
COUNT(DISTINCT Employee_FirstName), COUNT(DISTINCT Employee_LastName), COUNT(DISTINCT Employee_Title),
COUNT(DISTINCT Customer_ContactName), COUNT(DISTINCT Customer_City), COUNT(DISTINCT Customer_Country),
COUNT(DISTINCT Customer_Phone), COUNT(DISTINCT CompanyName)FROM ABC;

SELECT COUNT(DISTINCT OrderID), COUNT(DISTINCT Order_ShipCity), COUNT(DISTINCT Order_ShipCountry),
COUNT(DISTINCT Employee_FirstName), COUNT(DISTINCT Employee_LastName), COUNT(DISTINCT Employee_Title),
COUNT(DISTINCT Customer_ContactName), COUNT(DISTINCT Customer_City), COUNT(DISTINCT Customer_Country),
COUNT(DISTINCT Customer_Phone), COUNT(DISTINCT CompanyName) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT OrderDate), MIN(OrderDate), MAX(OrderDate) FROM ABC;

SELECT COUNT(DISTINCT OrderDate), MIN(OrderDate), MAX(OrderDate) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_ShippedDate), MIN(Order_ShippedDate), MAX(Order_ShippedDate) FROM ABC;

SELECT COUNT(DISTINCT Order_ShippedDate), MIN(Order_ShippedDate), MAX(Order_ShippedDate) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_Freight), AVG(Order_Freight) FROM ABC;

SELECT COUNT(DISTINCT Order_Freight), AVG(Order_Freight) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_UnitPrice), AVG(Order_UnitPrice) FROM ABC;

SELECT COUNT(DISTINCT Order_UnitPrice), AVG(Order_UnitPrice) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_Quantity), AVG(Order_Quantity) FROM ABC;

SELECT COUNT(DISTINCT Order_Quantity), AVG(Order_Quantity) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_Amount), AVG(Order_Amount) FROM ABC;

SELECT COUNT(DISTINCT Order_Amount), AVG(Order_Amount) FROM ABC_Fact_Table;

SELECT COUNT(DISTINCT Order_Amount), MIN(LENGTH(ProductName)), MAX(LENGTH(ProductName)), AVG(LENGTH(ProductName)) FROM ABC;

SELECT COUNT(DISTINCT Order_Amount), MIN(LENGTH(ProductName)), MAX(LENGTH(ProductName)), AVG(LENGTH(ProductName)) FROM ABC_Fact_Table;

-- DUPLICATE DATA CHECKS
SELECT OrderID, OrderDate, Order_ShippedDate, Order_Freight, 
Order_ShipCity, Order_ShipCountry, Order_UnitPrice, Order_Quantity,
Order_Amount, ProductName, Employee_LastName, Employee_FirstName, Employee_Title,
Customer_ContactName, Customer_City, Customer_Country, Customer_Phone, CompanyName, COUNT(1)
FROM ABC 
GROUP BY OrderID, ProductName, Customer_ContactName
HAVING COUNT(1) >1;

SELECT OrderID, OrderDate, Order_ShippedDate, Order_Freight, 
Order_ShipCity, Order_ShipCountry, Order_UnitPrice, Order_Quantity,
Order_Amount, ProductName, Employee_LastName, Employee_FirstName, Employee_Title,
Customer_ContactName, Customer_City, Customer_Country, Customer_Phone, CompanyName, COUNT(1)
FROM ABC_Fact_Table
GROUP BY OrderID, ProductName, Customer_ContactName
HAVING COUNT(1) >1;

-- DATA INTEGRITY CHECKS
SELECT COUNT(OrderID) FROM ABC WHERE OrderID IS NULL;

SELECT COUNT(OrderID) FROM ABC_Fact_Table WHERE OrderID IS NULL;

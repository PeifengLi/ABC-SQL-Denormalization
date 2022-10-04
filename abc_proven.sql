SELECT * FROM Orders o
JOIN Order_products op ON o.OrderID = op.OrderID
JOIN Products p ON op.ProductID = p.ProductID
JOIN Employee e ON o.EmployeeID = e. EmployeeID
JOIN Customer_ c ON o.CustomerID_ = c.CustomerID_
ORDER BY o.OrderID, op.ProductID;
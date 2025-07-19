
--  SCD TYPE 0

CREATE PROCEDURE Load_SCD_Type_0
AS
BEGIN
INSERT INTO Dim_Fixed (BusinessKey, Attribute1, Attribute2, LoadDate)
SELECT s.BusinessKey, s.Attribute1, s.Attribute2, GETDATE()
FROM Staging s
LEFT JOIN Dim_Fixed d ON s.BusinessKey = d.BusinessKey
WHERE d.BusinessKey IS NULL;
END
GO


--  SCD TYPE 1

CREATE PROCEDURE Load_SCD_Type_1
AS
BEGIN
MERGE Dim_Product AS target
USING Staging_Product AS source
ON target.BusinessKey = source.BusinessKey
WHEN MATCHED THEN
UPDATE SET target.Attribute1 = source.Attribute1,
target.Attribute2 = source.Attribute2,
target.LastUpdated = GETDATE()
WHEN NOT MATCHED THEN
INSERT (BusinessKey, Attribute1, Attribute2, LastUpdated)
VALUES (source.BusinessKey, source.Attribute1, source.Attribute2, GETDATE());
END
GO


-- SCD TYPE 2

CREATE PROCEDURE Load_SCD_Type_2
AS
BEGIN
DECLARE @CurrentDate DATETIME = GETDATE();
UPDATE Dim_Customer
SET ValidTo = @CurrentDate, IsCurrent = 0
FROM Dim_Customer d
JOIN Staging_Customer s ON d.BusinessKey = s.BusinessKey
WHERE d.IsCurrent = 1
AND (d.Attribute1 <> s.Attribute1 OR d.Attribute2 <> s.Attribute2);
INSERT INTO Dim_Customer (BusinessKey, Attribute1, Attribute2, ValidFrom, ValidTo, IsCurrent)
SELECT s.BusinessKey, s.Attribute1, s.Attribute2, @CurrentDate, NULL, 1
FROM Staging_Customer s
LEFT JOIN Dim_Customer d
ON s.BusinessKey = d.BusinessKey AND d.IsCurrent = 1
WHERE d.BusinessKey IS NULL OR (d.Attribute1 <> s.Attribute1 OR d.Attribute2 <> s.Attribute2);
END
GO


-- SCD TYPE 3

CREATE PROCEDURE Load_SCD_Type_3
AS
BEGIN
UPDATE Dim_Geography
SET PreviousPopulation = CurrentPopulation,
CurrentPopulation = s.CurrentPopulation,
LastUpdated = GETDATE()
FROM Staging_Geography s
JOIN Dim_Geography d ON s.BusinessKey = d.BusinessKey
WHERE s.CurrentPopulation <> d.CurrentPopulation;

INSERT INTO Dim_Geography (BusinessKey, CurrentPopulation, PreviousPopulation, LastUpdated)
SELECT s.BusinessKey, s.CurrentPopulation, NULL, GETDATE()
FROM Staging_Geography s
LEFT JOIN Dim_Geography d ON s.BusinessKey = d.BusinessKey
WHERE d.BusinessKey IS NULL;
END
GO


-- SCD TYPE 4
CREATE PROCEDURE Load_SCD_Type_4
AS
BEGIN

INSERT INTO Dim_Employee_History (BusinessKey, Attribute1, Attribute2, ChangeDate)
SELECT d.BusinessKey, d.Attribute1, d.Attribute2, GETDATE()
FROM Dim_Employee d
JOIN Staging_Employee s ON s.BusinessKey = d.BusinessKey
WHERE d.Attribute1 <> s.Attribute1 OR d.Attribute2 <> s.Attribute2;
UPDATE Dim_Employee
SET Attribute1 = s.Attribute1,
Attribute2 = s.Attribute2,
LastUpdated = GETDATE()
FROM Staging_Employee s
JOIN Dim_Employee d ON s.BusinessKey = d.BusinessKey;

INSERT INTO Dim_Employee (BusinessKey, Attribute1, Attribute2, LastUpdated)
SELECT s.BusinessKey, s.Attribute1, s.Attribute2, GETDATE()
FROM Staging_Employee s
LEFT JOIN Dim_Employee d ON s.BusinessKey = d.BusinessKey
WHERE d.BusinessKey IS NULL;
END
GO


-- SCD TYPE 6

CREATE PROCEDURE Load_SCD_Type_6
AS
BEGIN
DECLARE @CurrentDate DATETIME = GETDATE();


UPDATE Dim_Employee
SET ValidTo = @CurrentDate, IsCurrent = 0
FROM Staging_Employee s
JOIN Dim_Employee d ON s.BusinessKey = d.BusinessKey
WHERE d.IsCurrent = 1
AND (d.Attribute1 <> s.Attribute1);

INSERT INTO Dim_Employee (BusinessKey, Attribute1, Attribute1_Previous, ValidFrom, ValidTo, IsCurrent)
SELECT s.BusinessKey, s.Attribute1, d.Attribute1, @CurrentDate, NULL, 1
FROM Staging_Employee s
JOIN Dim_Employee d ON s.BusinessKey = d.BusinessKey AND d.IsCurrent = 1
WHERE d.Attribute1 <> s.Attribute1;
INSERT INTO Dim_Employee (BusinessKey, Attribute1, Attribute1_Previous, ValidFrom, ValidTo, IsCurrent)
SELECT s.BusinessKey, s.Attribute1, NULL, @CurrentDate, NULL, 1
FROM Staging_Employee s
LEFT JOIN Dim_Employee d ON s.BusinessKey = d.BusinessKey
WHERE d.BusinessKey IS NULL;
END
GO

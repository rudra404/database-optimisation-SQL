
-- Update empty values with appropriate values.
-- We have chosen our appropriate values to be NULL. This is because:  
-- bras can't have a leglength so the appropriate value for leglength is NULL, 
-- where colour wasn't specified, the appropriate value is NULL, etc.
UPDATE dbo.Product
SET Cup = NULL
WHERE Cup = '';

UPDATE dbo.Product
SET Size = NULL
WHERE Size = '';

UPDATE dbo.Product
SET LegLength = NULL
WHERE LegLength = '';

UPDATE dbo.Product
SET Colour = NULL
WHERE Colour = '';

SELECT * FROM dbo.Product;

--Code for checking dependencies
SELECT ProductCode
FROM dbo.Product
GROUP BY ProductCode
HAVING COUNT(DISTINCT Description) >1;
SELECT * FROM dbo.Product;
SELECT * FROM dbo.CustomerCity;
SELECT * FROM dbo.OrderItem;

--Creating Tables ready to split dbo.Product into 3NF
CREATE Table dbo.Variant
	(VariantCode nvarchar(50) NOT NULL,
	ProductCode nvarchar(50) NOT NULL,
	Cup nvarchar(256) ,
	Size nvarchar(256) ,
	LegLength nvarchar(256) ,
	Colour nvarchar(256) ,
	UnitPrice money NOT NULL,
	PRIMARY KEY NONCLUSTERED(VariantCode));
Create Table dbo.ProductDetails
	(ProductCode nvarchar(50) NOT NULL,
	Name nvarchar(256) ,
	Features nvarchar(3600) ,
	Description nvarchar(3600) ,
	PRIMARY KEY (ProductCode));
Create Table dbo.ProductGrouping
	(ProductGroup nvarchar(128) NOT NULL,
	ProductCode nvarchar(50) NOT NULL,
	PRIMARY KEY (ProductGroup, ProductCode));

	--Inserting Values from dbo.Product into new tables in 3NF
INSERT INTO dbo.Variant (VariantCode, ProductCode, Cup, Size, LegLength, Colour, UnitPrice)
SELECT DISTINCT VariantCode, ProductCode, Cup, Size, LegLength, Colour, Price
FROM dbo.Product;
SELECT * FROM dbo.Variant;
INSERT INTO dbo.ProductDetails(ProductCode, Name, Features, Description)
SELECT DISTINCT ProductCode, Name, Features, Description
FROM dbo.Product;
SELECT * FROM dbo.ProductDetails;
INSERT INTO dbo.ProductGrouping(ProductGroup, ProductCode)
SELECT DISTINCT ProductGroup, ProductCode
FROM dbo.Product;
SELECT * FROM dbo.ProductGrouping;

--Adding Foreign Keys
ALTER TABLE dbo.Variant
ADD FOREIGN KEY (ProductCode) REFERENCES dbo.ProductDetails(ProductCode);
ALTER TABLE dbo.ProductGrouping
ADD FOREIGN KEY (ProductCode) REFERENCES dbo.ProductDetails(ProductCode);
ALTER TABLE dbo.Variant
ADD CONSTRAINT UnitPrice CHECK(UnitPrice > 0);

SELECT * FROM dbo.Variant;

--Creating Tables ready to split dbo.Variant into 3NF
CREATE Table dbo.Cup 
	(VariantCode nvarchar(50) NOT NULL,
	Cup nvarchar(256) ,
	PRIMARY KEY(VariantCode),
	FOREIGN KEY(VariantCode) REFERENCES dbo.Variant(VariantCode));

CREATE Table dbo.Size 
	(VariantCode nvarchar(50) NOT NULL,
	Size nvarchar(256) ,
	PRIMARY KEY(VariantCode),
	FOREIGN KEY(VariantCode) REFERENCES dbo.Variant(VariantCode));

CREATE Table dbo.LegLength 
	(VariantCode nvarchar(50) NOT NULL,
	LegLength nvarchar(256) ,
	PRIMARY KEY(VariantCode),
	FOREIGN KEY(VariantCode) REFERENCES dbo.Variant(VariantCode));

CREATE Table dbo.Colour 
(VariantCode nvarchar(50) NOT NULL,
Colour nvarchar(256) ,
PRIMARY KEY(VariantCode),
FOREIGN KEY(VariantCode) REFERENCES dbo.Variant(VariantCode));

--Inserting Values into the new tables avoiding Nulls

INSERT INTO dbo.Cup (VariantCode, Cup)
SELECT DISTINCT VariantCode, Cup
FROM dbo.Product
WHERE Cup IS NOT NULL
OR Cup != '';

INSERT INTO dbo.Size (VariantCode, Size)
SELECT DISTINCT VariantCode, Size
FROM dbo.Variant
WHERE Size IS NOT NULL
OR Size != '';

INSERT INTO dbo.LegLength(VariantCode, LegLength)
SELECT DISTINCT VariantCode, LegLength
FROM dbo.Variant
WHERE LegLength IS NOT NULL
OR LegLength != '';

INSERT INTO dbo.Colour (VariantCode, Colour)
SELECT DISTINCT VariantCode, Colour
FROM dbo.Variant
WHERE Colour IS NOT NULL
OR Colour != '';

--Dropping Columns that have been moved to new tables

ALTER TABLE dbo.Variant
DROP COLUMN Cup, Size, LegLength, Colour;

SELECT * FROM dbo.Variant;

--Creating Tables ready to split dbo.CustomerCity into 3NF
DROP TABLE IF EXISTS dbo.CityDetails;
CREATE Table dbo.CityDetails 
	(City nvarchar(255) NOT NULL,
	County nvarchar(255) NOT NULL,
	Region nvarchar(255) ,
	Country nvarchar(255) ,
	);

DROP TABLE IF EXISTS dbo.CustomerDetails;
CREATE Table dbo.CustomerDetails 
	(CustomerID bigint NOT NULL, -- new name!
	Gender nvarchar(255) ,
	FirstName nvarchar(255) ,
	LastName nvarchar(255) ,
	DateRegistered datetime ,
	City nvarchar(255) NOT NULL,
	County nvarchar(255) NOT NULL
	); -- new name!

ALTER TABLE dbo.CityDetails
ADD PRIMARY KEY (City, County);

ALTER TABLE dbo.CustomerDetails
ADD PRIMARY KEY (CustomerID);

--Adding Foreign Keys
ALTER TABLE dbo.CustomerDetails
ADD FOREIGN KEY (City, County) REFERENCES dbo.CityDetails (City, County);

--Inserting Values from dbo.CustomerCity into new tables in 3NF
INSERT INTO dbo.CityDetails(City, County, Region, Country)
SELECT DISTINCT City, County, Region, Country
FROM dbo.CustomerCity;

INSERT INTO dbo.CustomerDetails(CustomerID, Gender, FirstName, LastName, DateRegistered, City, County)
SELECT DISTINCT Id, Gender, FirstName, LastName, DateRegistered, City, County
FROM dbo.CustomerCity;

--Creating Tables ready to split dbo.OrderItem into 3NF
CREATE Table dbo.CustomerOrder 
	(OrderNumber nvarchar(50) NOT NULL,
	OrderCreateDate datetime NOT NULL,
	OrderStatusCode int NOT NULL ,
	CustomerID bigint , -- new name!
	PRIMARY KEY(OrderNumber));
	--FOREIGN KEY());

CREATE Table dbo.NewOrderItem 
	(OrderItemNumber nvarchar(32) NOT NULL ,
	OrderNumber nvarchar(50) NOT NULL ,
	VariantCode nvarchar(50) NOT NULL ,
	Quantity int NOT NULL ,
	LineItemTotal money NOT NULL ,
	PRIMARY KEY(OrderItemNumber));
	-- CONSTRAINT FOREIGN KEY(OrderNumber) REFERENCES dbo.CustomerOrder(OrderNumber));

--Inserting Values from dbo.CustomerCity into new tables in 3NF
INSERT INTO dbo.CustomerOrder(OrderNumber, OrderCreateDate, OrderStatusCode, CustomerID) -- new name!
SELECT DISTINCT OrderNumber, OrderCreateDate, OrderStatusCode, CustomerCityID
FROM dbo.OrderItem;

INSERT INTO dbo.NewOrderItem(OrderItemNumber, OrderNumber, VariantCode, Quantity, LineItemTotal)
SELECT DISTINCT OrderItemNumber, OrderNumber, VariantCode, Quantity, LineItemTotal
FROM dbo.OrderItem;

--Adding Foreign Keys

ALTER TABLE dbo.NewOrderItem
ADD FOREIGN KEY (OrderNumber) REFERENCES dbo.CustomerOrder(OrderNumber)

ALTER TABLE dbo.NewOrderItem
ADD FOREIGN KEY (VariantCode) REFERENCES dbo.Variant(VariantCode)

SELECT * FROM dbo.CustomerOrder;


--Creating new entity OrderGroup
--Calculating TotalLineItems and SavedTotal for existing data and inserting it into the OrderGroup entity

SELECT OrderNumber, OrderCreateDate, OrderStatusCode, BillingCurrency,  sum(Quantity) as TotalLineItems, sum(LineItemTotal) as SavedTotal
INTO dbo.OrderGroup
FROM dbo.OrderItem 
GROUP BY OrderNumber, OrderCreateDate, OrderStatusCode, BillingCurrency
ORDER BY OrderNumber;

--Add primary and foreign keys
ALTER TABLE dbo.OrderGroup
ADD PRIMARY KEY(OrderNumber);
ALTER TABLE dbo.OrderGroup
ADD FOREIGN KEY(OrderNumber) REFERENCES dbo.CustomerOrder(OrderNumber);

--One missing foreign key
ALTER TABLE dbo.CustomerOrder
ADD FOREIGN KEY(CustomerID) REFERENCES dbo.CustomerDetails(CustomerID);

--THEN DROP OLD TABLES

DROP TABLE dbo.CustomerCity
DROP TABLE dbo.OrderItem
DROP TABLE dbo.Product;



--CREATE NEW ORDER GROUP

-- Table to record errors
DROP TABLE IF EXISTS  dbo.DB_Errors; 
CREATE TABLE dbo.DB_Errors
         (ErrorID        INT IDENTITY(1, 1),
          UserName       VARCHAR(100),
          ErrorNumber    INT,
          ErrorState     INT,
          ErrorSeverity  INT,
          ErrorLine      INT,
          ErrorProcedure VARCHAR(MAX),
          ErrorMessage   VARCHAR(MAX),
          ErrorDateTime  DATETIME)
GO

-- Verify that the stored procedure does not already exist.  
IF OBJECT_ID ( 'prCreateOrderGroup', 'P' ) IS NOT NULL   
    DROP PROCEDURE prCreateOrderGroup;  
GO  

--Create Stored Procedures

CREATE PROCEDURE prCreateOrderGroup
       @OrderNumber                      NVARCHAR(32)  = NULL   , 
       @OrderCreateDateEntry               NVARCHAR(32)      = NULL   , 
       @CustomerID                       int           = NULL 
AS 
BEGIN 
     SET NOCOUNT ON
		BEGIN TRY
			BEGIN TRANSACTION
	 --We put the supplied values in the CustomerOrder table, setting the OrderStatusCode as 0 (meaning 'new' order)


			IF (ISDATE(@OrderCreateDateEntry) = 0)
			RAISERROR ('ERROR: INVALID DATE FORMAT ENTERED.', 11, 1);

			DECLARE @OrderCreateDate as DATETIME
			SET @OrderCreateDate = CONVERT(DATETIME, @OrderCreateDateEntry, 21)

			IF (@OrderCreateDate > GETDATE())
			RAISERROR ('ERROR: ENTERED DATE DOES NOT EXIST.', 11, 1);

				INSERT INTO dbo.CustomerOrder
					(                    
					OrderNumber                     ,
					OrderCreateDate                 ,
					OrderStatusCode                 ,
					CustomerID                                       
					) 
				VALUES 
					( 
					@OrderNumber                     ,
					@OrderCreateDate                 ,
					0                                ,
					@CustomerID 
					) 

     --We create a new row in OrderGroup with the supplied OrderNumber, we leave the other columns empty

			   INSERT INTO dbo.OrderGroup
					  (                   
						OrderNumber,
						OrderCreateDate,
						OrderStatusCode,
						BillingCurrency,
						TotalLineItems,
						SavedTotal
					  ) 
				 VALUES 
					  (                    
						@OrderNumber,
						@OrderCreateDate,
						0,
						'GBP',
						0,
						0                                     
					  )
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
				INSERT INTO dbo.DB_Errors
			VALUES
		  (SUSER_SNAME(),
		   ERROR_NUMBER(),
		   ERROR_STATE(),
		   ERROR_SEVERITY(),
		   ERROR_LINE(),
		   ERROR_PROCEDURE(),
		   ERROR_MESSAGE(),
		   GETDATE());

		 --Transaction uncommittable
			IF (XACT_STATE()) = -1
			  ROLLBACK TRANSACTION
 
		 --Transaction committable
			IF (XACT_STATE()) = 1
			  COMMIT TRANSACTION
		--ROLLBACK TRANSACTION

		DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
        @Severity int = ERROR_SEVERITY(),
        @State smallint = ERROR_STATE()
 
		RAISERROR (@Message, @Severity, @State)

		END CATCH
END 

--CREATE NEW ORDER ITEM

-- Verify that the stored procedure does not already exist.  
IF OBJECT_ID ( 'prCreateOrderItem', 'P' ) IS NOT NULL   
    DROP PROCEDURE prCreateOrderItem;  
GO  

-- Procedure Creation
CREATE PROCEDURE prCreateOrderItem
       @OrderNumber                       NVARCHAR(32)  = NULL   , 
       @OrderItemNumber                   NVARCHAR(32)  = NULL   , 
       @ProductGroup                      NVARCHAR(128)  = NULL   , 
       @ProductCode                       NVARCHAR(255)  = NULL   , 
       @VariantCode                       NVARCHAR(255)  = NULL   , 
       @Quantity                          int  = NULL   , 
       @UnitPrice                         money = NULL
AS 
BEGIN 
     SET NOCOUNT ON
		BEGIN TRY


			BEGIN TRANSACTION
				--Enter the supplied values into the NewOrderItem table 
				--The LineItemTotal attribute must be calculated from supplied Quantity and UnitPrice

		--Check that an existing combination of VariantCode, ProductCode and ProductGroup is entered
          IF ((SELECT COUNT(*)
                       FROM   dbo.Variant
                       WHERE  dbo.Variant.VariantCode = @VariantCode AND
                              dbo.Variant.ProductCode = @ProductCode) = 0)
          RAISERROR ('ERROR: VARIANT CODE DOES NOT MATCH PRODUCT CODE', 11, 1); --ERROR SEVERITY ABOVE 10 TO ROLLBACK TRANSACTION

          IF ((SELECT COUNT(*)
                       FROM   dbo.ProductGrouping
                       WHERE  @ProductCode = dbo.ProductGrouping.ProductCode AND
                              @ProductGroup = dbo.ProductGrouping.ProductGroup) = 0)
          RAISERROR ('ERROR: PRODUCT CODE DOES NOT MATCH PRODUCT GROUP', 11, 1); --ERROR SEVERITY ABOVE 10 TO ROLLBACK TRANSACTION

		  IF ((SELECT COUNT(*)
                       FROM   dbo.Variant
                       WHERE  @VariantCode = dbo.Variant.VariantCode AND
                              @UnitPrice = dbo.Variant.UnitPrice) = 0)
          RAISERROR ('WARNING: DIFFERENT UNIT PRICE ASSIGNED TO ITEM.', 9, 1) --ERROR SEVERITY BELOW 10 TO COMMIT TRANSACTION BUT THROW A WARNING

		  --ELSE
				INSERT INTO dbo.NewOrderItem
					(                    
					OrderItemNumber                 ,
					OrderNumber,
					VariantCode,
					Quantity,
					LineItemTotal                                  
					) 
				VALUES 
					(                    
					@OrderItemNumber                 ,
					@OrderNumber,
					@VariantCode,
					@Quantity,
					(@Quantity * @UnitPrice)                        
					)

					--We add the supplied values into the OrderGroup table
					--Even if the new items are part of a new order group, the OrderNumber will exist as we create it in the 1st stored procedure
					--Therefore we must always run prCreateOrderGroup before this stored procedure
 
				UPDATE dbo.OrderGroup
				SET TotalLineItems = TotalLineItems + @Quantity, SavedTotal = SavedTotal + (@Quantity * @UnitPrice)
				WHERE OrderNumber = @OrderNumber
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH

			INSERT INTO dbo.DB_Errors
			VALUES
		  (SUSER_SNAME(),
		   ERROR_NUMBER(),
		   ERROR_STATE(),
		   ERROR_SEVERITY(),
		   ERROR_LINE(),
		   ERROR_PROCEDURE(),
		   ERROR_MESSAGE(),
		   GETDATE());	 

		 --Transaction uncommittable
			IF (XACT_STATE()) = -1
			  ROLLBACK TRANSACTION
 
		 --Transaction committable
			IF (XACT_STATE()) = 1
			  COMMIT TRANSACTION
		--ROLLBACK TRANSACTION

		DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
        @Severity int = ERROR_SEVERITY(),
        @State smallint = ERROR_STATE()
 
		RAISERROR (@Message, @Severity, @State)

		END CATCH

END 

--INDEX CREATION

IF OBJECT_ID ( 'VariantIndex', 'I' ) IS NOT NULL 
DROP INDEX [VariantIndex] ON dbo.Variant
CREATE NONCLUSTERED INDEX [VariantIndex] ON [dbo].[Variant](VariantCode, ProductCode, UnitPrice);

IF OBJECT_ID ( 'ProductDetailsIndex', 'I' ) IS NOT NULL 
DROP INDEX [ProductDetailsIndex] ON dbo.ProductDetails
CREATE NONCLUSTERED INDEX [ProductDetailsIndex] ON [dbo].[ProductDetails](Name);

IF OBJECT_ID ( 'CustomerDetailsIndex', 'I' ) IS NOT NULL 
DROP INDEX [CustomerDetailsIndex] ON dbo.CustomerDetails
CREATE NONCLUSTERED INDEX [CustomerDetailsIndex] ON [dbo].[CustomerDetails](FirstName, LastName);

--STORED PROCEDURE TESTING

--EXEC prCreateOrderGroup '1231234', '2022/02/02 21:00:00.000', 500 ;
--EXEC prCreateOrderItem '12345678', '1367748', 'Lingerie', '1368', '00028142',  10, 6.97; 
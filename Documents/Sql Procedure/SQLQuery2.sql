USE [BusyComp0222_db12024]
GO
/****** Object:  StoredProcedure [dbo].[sp_SaveQuatationTransactionData]    Script Date: 8/29/2024 11:17:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_SaveQuatationTransactionData]
	@VchNo VARCHAR(40),
	@AutoVchNo INT,
    @CustId INT,
    @CustName VARCHAR(100),
    @CMobile VARCHAR(50),
    @TQty FLOAT,
    @TAmt FLOAT,
    @NetAmt FLOAT,
    @Users VARCHAR(50),
    @ItemDetails NVarchar(Max)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		DECLARE @DocHandle INT = 0;
		DECLARE @VchCode INT = 0;
		DECLARE @PCode INT = 0;
		DECLARE @SNo int = 0;
		DECLARE @ItemCode INT = 0;
		DECLARE @Qty FLOAT = 0;
		DECLARE @Price FLOAT = 0;
		DECLARE @MRP FLOAT = 0;
		DECLARE @Discount FLOAT = 0;
		DECLARE @Amount FLOAT = 0;
		DECLARE @UCode Int = 0;
		DECLARE @CurrentDate date = getDate();
		DECLARE @i1 INT, @i2 INT, @i3 INT, @i4 INT, @i5 INT, @i6 INT, @i7 INT, @i8 INT, @i9 INT, @i10 INT;

		-- PREPARE XML DOCUMENT
		EXEC SP_XML_PREPAREDOCUMENT @DocHandle OUTPUT, @ItemDetails

		-- Temp table to store XML data
		SELECT * INTO #TempItemDetails FROM OPENXML (@DocHandle, '/ArrayOfItemDetail/ItemDetail', 2) 
		WITH ([PCode] INT, [ItemCode] INT, [Qty] FLOAT, [Price] FLOAT, [MRP] FLOAT, [Discount] FLOAT, [Amount] FLOAT, [UCode] INT);

		-- Temp table to store attribute details
		SELECT * INTO #TempAttributeDetails 
		FROM OPENXML (@DocHandle, '/ArrayOfItemDetail/ItemDetail/Attribute/Attribute', 2) 
		WITH ( [UCode] INT, [ATCode] INT );

		-- Insert main transaction
		INSERT INTO ESJSLTran1 ([VchType], [VchNo], [AutoVchNo], [Date], [CustId], [CustName], [CMobile], [TotQty], [TotAmt], [NetAmount], [CreatedBy], [CreatedOn]) VALUES (108, @VchNo, @AutovchNo, @CurrentDate, @CustId, @CustName, @CMobile, @TQty, @TAmt, @NetAmt, @Users, getDate());
		SET @VchCode = SCOPE_IDENTITY();

		IF (@VchCode > 0)
			BEGIN
				-- Cursor to iterate over the temp table
				DECLARE QUT_CURSOR CURSOR FOR 
				SELECT [PCode], [ItemCode], [Qty], [Price], [MRP], [Discount], [Amount], [UCode] FROM #TempItemDetails
		
				OPEN QUT_CURSOR
					FETCH NEXT FROM QUT_CURSOR INTO @PCode, @ItemCode, @Qty, @Price, @MRP, @Discount, @Amount, @UCode;
					WHILE @@FETCH_STATUS = 0
			
					-- Insert item details into another table
					BEGIN
						SET @SNo = @SNo + 1;
						SET @i1  = 0; SET @i2 = 0; SET @i3 = 0; SET @i4 = 0; SET @i5 = 0; SET @i6 = 0; SET @i7 = 0; SET @i8 = 0; SET @i9 = 0; SET @i10 = 0;
						DECLARE @Attributes TABLE (ATCode INT, RN INT, UCode INT);
						INSERT INTO @Attributes (ATCode, RN, UCode)
						SELECT ATCode, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS RN, @UCode FROM #TempAttributeDetails WHERE [UCode] = @UCode ;

						-- Debug: Check contents of @Attributes table
						PRINT 'Contents of @Attributes for ItemCode: ' + CAST(@ItemCode AS VARCHAR);

						-- Ensure only one value is assigned for each attribute
						SELECT 
							@i1 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 1 And UCode = @UCode), 0),
							@i2 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 2 And UCode = @UCode), 0),
							@i3 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 3 And UCode = @UCode), 0),
							@i4 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 4 And UCode = @UCode), 0),
							@i5 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 5 And UCode = @UCode), 0),
							@i6 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 6 And UCode = @UCode), 0),
							@i7 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 7 And UCode = @UCode), 0),
							@i8 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 8 And UCode = @UCode), 0),
							@i9 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 9 And UCode = @UCode), 0),
							@i10 = ISNULL((SELECT TOP 1 ATCode FROM @Attributes WHERE RN = 10 And UCode = @UCode), 0);

						-- Insert item details into another table
						INSERT INTO ESJSLTRAN2 ([VchCode], [VchType], [ProductCode], [SNo], [ItemCode], [Qty], [Price], [Amount], [CM1], [CM2], [CM3], [CM4], [CM5], [I1], [I2], [I3], [I4], [I5], [I6], [I7], [I8], [I9], [I10]) VALUES (@VchCode, 108, @PCode, @SNo, @ItemCode, @Qty, @Price, @Amount, @MRP, @Discount, 0, 0, 0, @i1, @i2, @i3, @i4, @i5, @i6, @i7, @i8, @i9, @i10);

						FETCH NEXT FROM QUT_CURSOR INTO @PCode, @ItemCode, @Qty, @Price, @MRP, @Discount, @Amount, @UCode;
					END
				CLOSE QUT_CURSOR;
				DEALLOCATE QUT_CURSOR;

				-- Drop temporary tables
				DROP TABLE #TempItemDetails;
				DROP TABLE #TempAttributeDetails;

				-- Return success status
				SELECT 1 AS [Status], 'Quotation saved successfully' AS [Msg];
			END
		ELSE
			BEGIN
				-- Return success status
				SELECT 0 AS [Status], 'Quotation not saved' AS [Msg];
			END
    END TRY
    BEGIN CATCH
        -- Handle error and return message
        IF OBJECT_ID('tempdb..#TempItemDetails') IS NOT NULL
            DROP TABLE #TempItemDetails;
        IF OBJECT_ID('tempdb..#TempAttributeDetails') IS NOT NULL
            DROP TABLE #TempAttributeDetails;

        SELECT 0 AS [Status], ERROR_MESSAGE() AS [Msg];
    END CATCH
END




Select * From ESJSLTRAN2
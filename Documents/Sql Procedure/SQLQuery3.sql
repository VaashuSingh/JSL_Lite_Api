USE [BusyComp0222_db12024]
GO
/****** Object:  StoredProcedure [dbo].[sp_SaveStockTransferTran]    Script Date: 8/29/2024 11:17:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_SaveStockTransferTran]
	@BusyVchCode INT,
	@VchCode INT,
	@OrderId INT,
	@OrderNo VARCHAR(40),
	@VchNo VARCHAR(40),
	@AutoVchNo INT,
    @AccCode INT,
    @AccName VARCHAR(100),
	@MCCode1 INT,
	@MCCode2 INT,
    @Mobile VARCHAR(50),
	@Remarks VARCHAR(255),
    @TQty FLOAT,
    @TAmt FLOAT,
    @NetAmt FLOAT,
    @Users VARCHAR(50),
    @STItemDetails NVarchar(Max)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
		DECLARE @DocHandle INT = 0;
		DECLARE @VchCode_1 INT = @VchCode;
		DECLARE @SNo int = 0;
		DECLARE @ItemCode INT = 0;
		DECLARE @Qty FLOAT = 0;
		DECLARE @Price FLOAT = 0;
		DECLARE @Amount FLOAT = 0;
		DECLARE @Date DATE = getdate();
		-- PREPARE XML DOCUMENT
		EXEC SP_XML_PREPAREDOCUMENT @DocHandle OUTPUT, @STItemDetails

		-- Temp table to store XML data
		SELECT * INTO #TempItemDetails FROM OPENXML (@DocHandle, '/ArrayOfSTItemDetail/STItemDetail', 2) 
		WITH ([ItemCode] INT, [Qty] FLOAT, [Price] FLOAT, [Amount] FLOAT);

		-- Insert main transaction
		INSERT INTO ESJSLTRAN1 ([VCHTYPE], [VCHNO], [AUTOVCHNO], [DATE], [CUSTID], [CUSTNAME], [CMOBILE], [TOTQTY], [TOTAMT], [NETAMOUNT], [REMARKS], [I1], [I2], [BUSYVCHCODE], [CREATEDBY], [CREATEDON]) VALUES (109, @VchNo, @AutovchNo, @Date, @AccCode, @AccName, @Mobile, @TQty, @TAmt, @NetAmt, @Remarks, @MCCode1, @MCCode2, @BusyVchCode, @Users, GETDATE());
		SET @VchCode_1 = SCOPE_IDENTITY();

		IF (@VchCode_1 > 0)
			BEGIN
				-- Cursor to iterate over the temp table
				DECLARE QUT_CURSOR CURSOR FOR 
				SELECT [ItemCode], [Qty], [Price], [Amount] FROM #TempItemDetails
		
				OPEN QUT_CURSOR
					FETCH NEXT FROM QUT_CURSOR INTO @ItemCode, @Qty, @Price, @Amount;
					WHILE @@FETCH_STATUS = 0
			
					-- Insert item details into another table
					BEGIN
						SET @SNo = @SNo + 1;

						-- Insert item details into another table
						INSERT INTO ESJSLTRAN2 ([VchCode], [VchType], [ProductCode], [SNo], [ItemCode], [Qty], [Price], [Amount], [I1], [I2], [I3], [I4], [I5], [I6], [I7], [I8], [I9], [I10]) VALUES (@VchCode_1, 109, 0, @SNo, @ItemCode, @Qty, @Price, @Amount, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

						INSERT INTO ESJSLREFTRAN ([VchCode], [OrderId], [VchType], [RecType], [Method], [RefNo], [Date], [MasterCode1], [ItemCode], [Qty], [Price], [Amount]) VALUES (@VchCode_1, @OrderId, 108, 1, 2, @OrderNo, @Date, @AccCode, @ItemCode, (@Qty * -1), @Price, @Amount);

						INSERT INTO ESJSLREFTRAN ([VchCode], [OrderId], [VchType], [RecType], [Method], [RefNo], [Date], [MasterCode1], [ItemCode], [Qty], [Price], [Amount]) VALUES (@VchCode_1, @VchCode_1, 109, 1, 1, @VchNo, @Date, @AccCode, @ItemCode, @Qty, @Price, @Amount);

						FETCH NEXT FROM QUT_CURSOR INTO @ItemCode, @Qty, @Price, @Amount;
					END
				CLOSE QUT_CURSOR;
				DEALLOCATE QUT_CURSOR;

				-- Drop temporary tables
				DROP TABLE #TempItemDetails;

				-- Return success status
				SELECT 1 AS [Status], 'Stock Transfer saved successfully' AS [Msg];
			END
		ELSE
			BEGIN
				-- Return success status
				SELECT 0 AS [Status], 'Stock Transfer not saved' AS [Msg];
			END
    END TRY
    BEGIN CATCH
        -- Handle error and return message
        IF OBJECT_ID('tempdb..#TempItemDetails') IS NOT NULL
            DROP TABLE #TempItemDetails;
        SELECT 0 AS [Status], ERROR_MESSAGE() AS [Msg];
    END CATCH
END



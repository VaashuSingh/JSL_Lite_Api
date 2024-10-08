USE [BusyComp0222_db12024]
GO
/****** Object:  StoredProcedure [dbo].[sp_SaveOrderFollowUp]    Script Date: 8/29/2024 11:17:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_SaveOrderFollowUp]
@VchCode INT,
@VchType INT,
@Remarks VARCHAR(255),
@FollowdBy VARCHAR(40)
AS
BEGIN
	BEGIN TRY
		DECLARE @SNO INT = 0; 
		
		SET @SNO = (SELECT (ISNULL(MAX([SNO]), 0) + 1) as SNo FROM ESJSLFOLLOWUP WHERE [VCHCODE] = @VchCode And [VCHTYPE] = @VchType)

		INSERT INTO ESJSLFOLLOWUP ([VCHCODE], [VCHTYPE], [SNO], [REMARKS], [FOLLOWDBY], [FOLLOWDON]) VALUES (@VchCode, @VchType, @SNO, @Remarks, @FollowdBy, GETDATE())
			
		SELECT 1 AS [Status], 'Follow Up saved successfully' AS [Msg];
	END TRY
	BEGIN CATCH
		-- Handle error and return message
		SELECT 0 AS [Status], ERROR_MESSAGE() AS [Msg];
    END CATCH
END

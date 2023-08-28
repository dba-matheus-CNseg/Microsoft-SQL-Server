USE Database_Name
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[bkp_full_step_01]') AND type in (N'P', N'PC'))
   DROP PROCEDURE [dbo].[bkp_full_step_01]
GO

create procedure dbo.bkp_full_step_01 ( @backupdirectory nvarchar(200),@ONLY_DB VARCHAR(200) = null, @NOTIN_LIST VARCHAR(200) = null)
WITH ENCRYPTION AS
DECLARE @BACKUPFILE      VARCHAR(255)
DECLARE @BACKUPFILE2    VARCHAR(255)
DECLARE @BACKUPFILE3    VARCHAR(255)
DECLARE @DB              VARCHAR(200)
DECLARE @DESCRIPTION     VARCHAR(255)
DECLARE @NAME            VARCHAR(30)
DECLARE @MEDIANAME       VARCHAR(30)
--DECLARE @BACKUPDIRECTORY NVARCHAR(200)
DECLARE @LOG_NAME        VARCHAR(255)
declare @data			varchar(20)
declare @patern varchar(30)

CREATE TABLE #notTempList
	(
		dbname  VARCHAR(200)
	)

	DECLARE @dbname varchar(20), @Pos int

	SET @NOTIN_LIST = LTRIM(RTRIM(@NOTIN_LIST))+ ','
	SET @Pos = CHARINDEX(',', @NOTIN_LIST, 1)

	IF REPLACE(@NOTIN_LIST, ',', '') <> ''
	BEGIN
		WHILE @Pos > 0
		BEGIN
			SET @dbname = LTRIM(RTRIM(LEFT(@NOTIN_LIST, @Pos - 1)))
			IF @dbname <> ''
			BEGIN
				INSERT INTO #notTempList (dbname) VALUES (CAST(@dbname AS varchar(20))) --Use Appropriate conversion
			END
			SET @NOTIN_LIST = RIGHT(@NOTIN_LIST, LEN(@NOTIN_LIST) - @Pos)
			SET @Pos = CHARINDEX(',', @NOTIN_LIST, 1)

		END
	END	

set @patern = '10.50.0000.1'

set @data = convert(varchar,getdate(),112)

--SET @BACKUPDIRECTORY = 'F:\BKP\DEFAULT\DATA\'
SET @DESCRIPTION     = 'BACKUP FULL' + CONVERT(VARCHAR,GETDATE(),113)

DECLARE DATABASE_CURSOR CURSOR FAST_FORWARD FOR 
SELECT NAME 
  FROM sys.databases
 WHERE name NOT IN ('tempdb')
  and name not in (select dbname from #notTempList)
   AND STATE = 0
--   AND DATABASEPROPERTY(NAME,'ISOFFLINE')       = 0
--   AND DATABASEPROPERTY(NAME,'IsInRecovery')    = 0
--   AND DATABASEPROPERTY(NAME,'IsInStandBy')     = 0
--   AND DATABASEPROPERTY(NAME,'IsDetached')      = 0
--   AND DATABASEPROPERTY(NAME,'ISSUSPECT')       = 0
--   AND DATABASEPROPERTY(NAME,'IsEmergencyMode') = 0
--   AND DATABASEPROPERTY(NAME,'IsInLoad')        = 0
--   AND DATABASEPROPERTY(NAME,'IsShutDown')      = 0
ORDER BY NAME

OPEN DATABASE_CURSOR

IF @@ERROR <> 0
BEGIN
	RAISERROR('ERRO NA ABERTURA DO CURSOR',16,1)
	RETURN
END 

FETCH NEXT FROM DATABASE_CURSOR INTO @DB

WHILE @@FETCH_STATUS = 0 
BEGIN
	IF(@ONLY_DB is not null and @DB <> @ONLY_DB)
	BEGIN
		FETCH NEXT FROM DATABASE_CURSOR INTO @DB
		CONTINUE
	END

	SET @BACKUPFILE = @BACKUPDIRECTORY + @DB  +'_' + CONVERT(VARCHAR(30), @data, 112) + '_FULL-1.BAK' 
 	SET @BACKUPFILE2 = @BACKUPDIRECTORY + @DB +'_' + CONVERT(VARCHAR(30), @data, 112) + '_FULL-2.BAK'
	SET @BACKUPFILE3 = @BACKUPDIRECTORY + @DB +'_' + CONVERT(VARCHAR(30), @data, 112) + '_FULL-3.BAK'	
	SET @NAME       = @DB + '(DAILY BACKUP) ' +      CONVERT(VARCHAR,GETDATE(),113)
	PRINT 'INICIO DO BACKUP DA BASE '+ @DB+ ' AS ' + CAST( GETDATE() AS CHAR )
	
	   if SERVERPROPERTY('productversion') >= @patern or charindex('enterprise',cast(SERVERPROPERTY ('edition') as varchar),0 ) <> 0 
	   begin
         BACKUP DATABASE @DB TO 
           DISK = @BACKUPFILE , DISK = @BACKUPFILE2 , DISK = @BACKUPFILE3 WITH INIT, NOFORMAT, NOUNLOAD, COMPRESSION, SKIP, NAME = @NAME, DESCRIPTION = @DESCRIPTION 
	   end
	   else
	   begin
         BACKUP DATABASE @DB TO 
           DISK = @BACKUPFILE , DISK = @BACKUPFILE2 , DISK = @BACKUPFILE3 WITH INIT, NOFORMAT, NOUNLOAD, SKIP, NAME = @NAME, DESCRIPTION = @DESCRIPTION 
       end

	PRINT 'FIM DO BACKUP DA BASE '+ @DB+ ' AS '+ CAST( GETDATE() AS CHAR )
	FETCH NEXT FROM DATABASE_CURSOR INTO @DB
END
CLOSE DATABASE_CURSOR
DEALLOCATE DATABASE_CURSOR
go

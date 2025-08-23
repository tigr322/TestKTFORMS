-- Восстановление базы KTFOMS_TEST из /var/opt/mssql/backup/KTFOMS_TEST.bak
-- Автоопределение LogicalName

DECLARE @backupFile NVARCHAR(4000) = N'/var/opt/mssql/backup/KTFOMS_TEST.bak';
DECLARE @db NVARCHAR(128) = N'KTFOMS_TEST';

IF DB_ID(@db) IS NOT NULL
BEGIN
    ALTER DATABASE [KTFOMS_TEST] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END

IF OBJECT_ID('tempdb..#fl') IS NOT NULL DROP TABLE #fl;
CREATE TABLE #fl (LogicalName NVARCHAR(128), [Type] CHAR(1), PhysicalName NVARCHAR(260));

INSERT INTO #fl (LogicalName,[Type],PhysicalName)
EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @backupFile + '''');

DECLARE @dataLogical NVARCHAR(128), @logLogical NVARCHAR(128);
SELECT @dataLogical=LogicalName FROM #fl WHERE [Type]='D';
SELECT @logLogical =LogicalName FROM #fl WHERE [Type]='L';

DECLARE @restore NVARCHAR(MAX) =
N'RESTORE DATABASE [' + @db + N']
FROM DISK = ''' + @backupFile + N'''
WITH MOVE ''' + @dataLogical + N''' TO ''/var/opt/mssql/data/KTFOMS_TEST.mdf'',
     MOVE ''' + @logLogical  + N''' TO ''/var/opt/mssql/data/KTFOMS_TEST_log.ldf'',
     REPLACE;';
EXEC(@restore);

ALTER DATABASE [KTFOMS_TEST] SET MULTI_USER;

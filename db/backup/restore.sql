DECLARE @backupFile NVARCHAR(4000) = N'/var/opt/mssql/backup/KTFOMS_TEST.bak';
DECLARE @db NVARCHAR(128) = N'KTFOMS_TEST';

IF DB_ID(@db) IS NOT NULL
BEGIN
    ALTER DATABASE [KTFOMS_TEST] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
END

IF OBJECT_ID('tempdb..#fl') IS NOT NULL DROP TABLE #fl;

CREATE TABLE #fl
(
    LogicalName             NVARCHAR(128),
    PhysicalName            NVARCHAR(260),
    [Type]                  CHAR(1),
    FileGroupName           NVARCHAR(128),
    Size                    NUMERIC(20,0),
    MaxSize                 NUMERIC(20,0),
    FileId                  INT,
    CreateLSN               NUMERIC(25,0),
    DropLSN                 NUMERIC(25,0) NULL,
    UniqueId                UNIQUEIDENTIFIER,
    ReadOnlyLSN             NUMERIC(25,0) NULL,
    ReadWriteLSN            NUMERIC(25,0) NULL,
    BackupSizeInBytes       BIGINT,
    SourceBlockSize         INT,
    FileGroupId             INT,
    LogGroupGUID            UNIQUEIDENTIFIER NULL,
    DifferentialBaseLSN     NUMERIC(25,0) NULL,
    DifferentialBaseGUID    UNIQUEIDENTIFIER NULL,
    IsReadOnly              BIT,
    IsPresent               BIT,
    TDEThumbprint           VARBINARY(32) NULL,
    SnapshotUrl             NVARCHAR(360) NULL
);

INSERT INTO #fl
EXEC('RESTORE FILELISTONLY FROM DISK = ''' + @backupFile + '''');

DECLARE @dataLogical NVARCHAR(128), @logLogical NVARCHAR(128);
SELECT @dataLogical = LogicalName FROM #fl WHERE [Type] = 'D';
SELECT @logLogical  = LogicalName FROM #fl WHERE [Type] = 'L';

DECLARE @restore NVARCHAR(MAX) =
N'RESTORE DATABASE [' + @db + N'] FROM DISK = ''' + @backupFile + N'''
WITH MOVE ''' + @dataLogical + N''' TO ''/var/opt/mssql/data/KTFOMS_TEST.mdf'',
     MOVE ''' + @logLogical  + N''' TO ''/var/opt/mssql/data/KTFOMS_TEST_log.ldf'',
     REPLACE, RECOVERY;';

EXEC(@restore);

ALTER DATABASE [KTFOMS_TEST] SET MULTI_USER;

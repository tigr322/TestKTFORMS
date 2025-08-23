
IF OBJECT_ID('dbo.sp_report_lpu_month_sum','P') IS NOT NULL DROP PROCEDURE dbo.sp_report_lpu_month_sum;
GO
CREATE PROCEDURE dbo.sp_report_lpu_month_sum
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    lpu.Code      AS [МЕД. ОРГАНИЗАЦИЯ (КОД)],
    lpu.NameShort AS [МЕД. ОРГАНИЗАЦИЯ (НАИМЕНОВАНИЕ)],
    m.MonthCode   AS [МЕСЯЦ],
    m.YearCode    AS [ГОД],
    SUM(m.Summ)   AS [СУММА, РУБ]
  FROM finConsolidatedMaster m
  LEFT JOIN rfcLPU lpu ON lpu.ID = m.LPUUrRef
  GROUP BY lpu.Code, lpu.NameShort, m.MonthCode, m.YearCode
  ORDER BY m.YearCode, m.MonthCode, lpu.Code;
END
GO

IF OBJECT_ID('dbo.sp_report_lpu_tpayment','P') IS NOT NULL DROP PROCEDURE dbo.sp_report_lpu_tpayment;
GO
CREATE PROCEDURE dbo.sp_report_lpu_tpayment
  @pYear INT, @pMonth INT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    lpu.Code        AS [МЕД. ОРГАНИЗАЦИЯ (КОД)],
    lpu.NameShort   AS [МЕД. ОРГАНИЗАЦИЯ (НАИМЕНОВАНИЕ)],
    tp.Code         AS [ТИП ОПЛАТЫ (КОД)],
    tp.NameShort    AS [ТИП ОПЛАТЫ (НАИМЕНОВАНИЕ)],
    SUM(m.CountSch) AS [КОЛИЧЕСТВО СЧЕТОВ],
    SUM(m.Summ)     AS [СУММА]
  FROM finConsolidatedMaster m
  LEFT JOIN rfcLPU lpu ON lpu.ID = m.LPUUrRef
  LEFT JOIN rfcTypePayment tp ON tp.ID = m.TypePaymentRef
  WHERE m.YearCode = @pYear AND m.MonthCode = @pMonth
  GROUP BY lpu.Code, lpu.NameShort, tp.Code, tp.NameShort
  ORDER BY lpu.Code, tp.Code;
END
GO

IF OBJECT_ID('dbo.sp_report_helpform_volumes','P') IS NOT NULL DROP PROCEDURE dbo.sp_report_helpform_volumes;
GO
CREATE PROCEDURE dbo.sp_report_helpform_volumes
  @pYear INT, @pMonth INT
AS
BEGIN
  SET NOCOUNT ON;

  
  DECLARE @visitIds  TABLE(VolumeID INT PRIMARY KEY);
  DECLARE @appealIds TABLE(VolumeID INT PRIMARY KEY);

  INSERT INTO @visitIds(VolumeID)
  SELECT v.ID FROM rfcVolume v
  WHERE v.Name COLLATE Cyrillic_General_CI_AS LIKE N'посещ%';

  INSERT INTO @appealIds(VolumeID)
  SELECT v.ID FROM rfcVolume v
  WHERE v.Name COLLATE Cyrillic_General_CI_AS LIKE N'обращ%';

  SELECT
    hf.Code AS [ВИД ПОМОЩИ (КОД)],
    hf.Name AS [ВИД ПОМОЩИ (НАИМЕНОВАНИЕ)],
    SUM(CASE WHEN vi.VolumeID IS NOT NULL THEN ISNULL(d.CountVol,0) ELSE 0 END) AS [КОЛИЧЕСТВО ПОСЕЩЕНИЙ],
    SUM(CASE WHEN ai.VolumeID IS NOT NULL THEN ISNULL(d.CountVol,0) ELSE 0 END) AS [КОЛИЧЕСТВО ОБРАЩЕНИЙ],
    SUM(ISNULL(m.CountSch,0)) AS [КОЛИЧЕСТВО СЧЕТОВ],
    SUM(ISNULL(m.Summ,0))     AS [СУММА]
  FROM finConsolidatedMaster m
  INNER JOIN rfcHelpForm hf ON hf.ID = m.HelpFormRef
  LEFT JOIN finConsolidatedDetail d ON d.finConsolidatedMasterRef = m.ID
  LEFT JOIN @visitIds  vi ON vi.VolumeID = d.VolumeRef
  LEFT JOIN @appealIds ai ON ai.VolumeID = d.VolumeRef
  WHERE m.YearCode = @pYear AND m.MonthCode = @pMonth
  GROUP BY hf.Code, hf.Name
  ORDER BY hf.Code;
END
GO

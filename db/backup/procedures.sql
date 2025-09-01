
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
-- 1) helpform_volumes
IF OBJECT_ID('dbo.sp_report_helpform_volumes','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_report_helpform_volumes;
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

-- 2) lpu_smo_summary (тут уже корректно дропаем ИМЕННО её)
IF OBJECT_ID('dbo.sp_report_lpu_smo_summary','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_report_lpu_smo_summary;
GO
CREATE PROCEDURE dbo.sp_report_lpu_smo_summary
    @pYear    INT,
    @pMonth   INT,
    @pSmoCode NVARCHAR(20) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
      [МЕД. ОРГАНИЗАЦИЯ (КОД)]          = lpu.Code,
      [МЕД. ОРГАНИЗАЦИЯ (НАИМЕНОВАНИЕ)] = lpu.NameShort,
      [СМО (КОД)]                       = smo.Code,
      [СМО (НАИМЕНОВАНИЕ)]              = smo.Name,
      [КОЛИЧЕСТВО СЧЕТОВ]               = SUM(TRY_CONVERT(INT, m.CountSch)),
      [СУММА]                            = SUM(TRY_CONVERT(DECIMAL(18,2), m.Summ))
  FROM finConsolidatedMaster AS m
  INNER JOIN rfcLPU AS lpu      ON lpu.ID = m.LPUUrRef
  INNER JOIN rfcSMO AS smo      ON smo.ID = m.SMOUrRef
  WHERE m.YearCode  = @pYear
    AND m.MonthCode = @pMonth
    AND (@pSmoCode IS NULL OR smo.Code = @pSmoCode)
  GROUP BY lpu.Code, lpu.NameShort, smo.Code, smo.Name
  ORDER BY lpu.Code, smo.Code;
END
GO
CREATE INDEX IX_fcm_year_month ON finConsolidatedMaster(YearCode, MonthCode);
CREATE INDEX IX_fcm_lpu ON finConsolidatedMaster(LPUUrRef);
CREATE INDEX IX_fcm_tp ON finConsolidatedMaster(TypePaymentRef);
CREATE INDEX IX_fcm_hf ON finConsolidatedMaster(HelpFormRef);
CREATE INDEX IX_fcm_smo ON finConsolidatedMaster(SMOUrRef);
CREATE INDEX IX_fcd_master ON finConsolidatedDetail(finConsolidatedMasterRef);
CREATE INDEX IX_fcd_volume ON finConsolidatedDetail(VolumeRef);

CREATE UNIQUE INDEX UX_lpu_id ON rfcLPU(ID);
CREATE UNIQUE INDEX UX_tp_id ON rfcTypePayment(ID);
CREATE UNIQUE INDEX UX_hf_id ON rfcHelpForm(ID);
CREATE UNIQUE INDEX UX_smo_id ON rfcSMO(ID);
CREATE UNIQUE INDEX UX_vol_id ON rfcVolume(ID);
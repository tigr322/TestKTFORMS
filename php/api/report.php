<?php

header('Content-Type: application/json; charset=utf-8');

$server = "mssql,1433";
$db     = "KTFOMS_TEST";
$user   = "sa";
$pass   = "Strong!Passw0rd";
$dsn = "sqlsrv:Server=$server;Database=$db;Encrypt=yes;TrustServerCertificate=yes";
try {
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'DB connect error', 'detail' => $e->getMessage()]);
    exit;
}
$type = $_GET['type'] ?? '';
try {
    if ($type === 'lpu_month_sum') {
        $stmt = $pdo->query("EXEC sp_report_lpu_month_sum");
        echo json_encode(['data' => $stmt->fetchAll(PDO::FETCH_ASSOC)], JSON_UNESCAPED_UNICODE);
    } elseif ($type === 'lpu_tpayment') {
        $year  = (int)($_GET['year'] ?? 0);
        $month = (int)($_GET['month'] ?? 0);
        $stmt = $pdo->prepare("EXEC sp_report_lpu_tpayment @pYear = ?, @pMonth = ?");
        $stmt->execute([$year, $month]);
        echo json_encode(['data' => $stmt->fetchAll(PDO::FETCH_ASSOC)], JSON_UNESCAPED_UNICODE);

    } elseif ($type === 'helpform_volumes') {
        $year  = (int)($_GET['year'] ?? 0);
        $month = (int)($_GET['month'] ?? 0);
        $stmt = $pdo->prepare("EXEC sp_report_helpform_volumes @pYear = ?, @pMonth = ?");
        $stmt->execute([$year, $month]);
        echo json_encode(['data' => $stmt->fetchAll(PDO::FETCH_ASSOC)], JSON_UNESCAPED_UNICODE);

    } else {
        http_response_code(400);
        echo json_encode(['error' => 'Unknown report type', 'hint' => 'type=lpu_month_sum|lpu_tpayment|helpform_volumes']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Query error', 'detail' => $e->getMessage()]);
}

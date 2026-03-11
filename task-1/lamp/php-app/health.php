<?php
// simple health endpoint for monitoring

$response = [
    'service' => 'lamp-app',
    'status' => 'healthy',
    'php_version' => phpversion(),
    'timestamp' => date('c')
];

// check mysql
$servername = getenv('MYSQL_HOST') ?: 'mysql';
$username = getenv('MYSQL_USER') ?: 'root';
$password = getenv('MYSQL_PASSWORD') ?: 'rootpass123';

try {
    $conn = new mysqli($servername, $username, $password);
    if ($conn->connect_error) {
        $response['database'] = 'disconnected';
    } else {
        $response['database'] = 'connected';
        $conn->close();
    }
} catch (Exception $e) {
    $response['database'] = 'error';
}

header('Content-Type: application/json');
echo json_encode($response);
?>
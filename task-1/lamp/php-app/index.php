<?php
$servername = getenv('MYSQL_HOST') ?: 'mysql';
$username = getenv('MYSQL_USER') ?: 'root';
$password = getenv('MYSQL_PASSWORD') ?: 'rootpass123';
$dbname = getenv('MYSQL_DATABASE') ?: 'lampdb';

$page = isset($_GET['page']) ? $_GET['page'] : 'home';

// try connecting to mysql
$conn = null;
$db_status = "disconnected";
try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    if ($conn->connect_error) {
        $db_status = "error: " . $conn->connect_error;
    } else {
        $db_status = "connected";

        // create a sample table if it doesnt exist
        $sql = "CREATE TABLE IF NOT EXISTS visitors (
            id INT AUTO_INCREMENT PRIMARY KEY,
            ip_address VARCHAR(45),
            visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )";
        $conn->query($sql);

        // log this visit
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        $stmt = $conn->prepare("INSERT INTO visitors (ip_address) VALUES (?)");
        $stmt->bind_param("s", $ip);
        $stmt->execute();
    }
} catch (Exception $e) {
    $db_status = "error: " . $e->getMessage();
}
?>

<!DOCTYPE html>
<html>

<head>
    <title>LAMP Stack App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 2rem;
            background: #f5f5f5;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 2rem;
            border-radius: 8px;
        }

        .status {
            padding: 0.5rem 1rem;
            border-radius: 4px;
            display: inline-block;
            margin: 0.5rem 0;
        }

        .ok {
            background: #d4edda;
            color: #155724;
        }

        .err {
            background: #f8d7da;
            color: #721c24;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }

        th,
        td {
            padding: 8px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }

        th {
            background: #f0f0f0;
        }
    </style>
</head>

<body>
    <div class="container">
        <h1>LAMP Stack Application</h1>
        <p>Running on Apache + PHP <?= phpversion() ?></p>

        <h3>Database Status</h3>
        <span class="status <?= $db_status === 'connected' ? 'ok' : 'err' ?>">
            MySQL: <?= $db_status ?>
        </span>

        <?php if ($conn && $db_status === 'connected'): ?>
            <h3>Recent Visitors</h3>
            <table>
                <tr>
                    <th>ID</th>
                    <th>IP Address</th>
                    <th>Visited At</th>
                </tr>
                <?php
                $result = $conn->query("SELECT * FROM visitors ORDER BY visited_at DESC LIMIT 10");
                while ($row = $result->fetch_assoc()):
                    ?>
                    <tr>
                        <td><?= $row['id'] ?></td>
                        <td><?= htmlspecialchars($row['ip_address']) ?></td>
                        <td><?= $row['visited_at'] ?></td>
                    </tr>
                <?php endwhile; ?>
            </table>
        <?php endif; ?>

        <hr>
        <p><small>Server time: <?= date('Y-m-d H:i:s') ?></small></p>
    </div>
</body>

</html>

<?php
if ($conn)
    $conn->close();
?>
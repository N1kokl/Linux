<?php
$host = getenv('DB_HOST') ?: 'db';
$db   = getenv('DB_NAME') ?: 'cicdapp';
$user = getenv('DB_USER') ?: 'cicduser';
$pass = getenv('DB_PASS') ?: '';

$mysqli = @new mysqli($host, $user, $pass, $db);
if ($mysqli->connect_errno) {
    http_response_code(500);
    echo "<h1>DB-yhteys ei toimi</h1>";
    echo "<pre>" . htmlspecialchars($mysqli->connect_error) . "</pre>";
    exit;
}

$mysqli->query("CREATE TABLE IF NOT EXISTS messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  name VARCHAR(100) NOT NULL,
  content VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name = trim($_POST['name'] ?? '');
    $content = trim($_POST['content'] ?? '');
    if ($name !== '' && $content !== '') {
        $stmt = $mysqli->prepare("INSERT INTO messages (name, content) VALUES (?, ?)");
        $stmt->bind_param("ss", $name, $content);
        $stmt->execute();
        $stmt->close();
    }
}

$rows = [];
$res = $mysqli->query("SELECT created_at, name, content FROM messages ORDER BY created_at DESC");
if ($res) { while ($r = $res->fetch_assoc()) $rows[] = $r; }
?>
<!doctype html>
<html lang="fi">
<head>
  <meta charset="utf-8">
  <title>CI/CD demo</title>
</head>
<body>
  <h1>CI/CD demo</h1>
  <p>Docker Compose (web + db), deploy GitHub Actionsilla.</p>

  <h2>Lisää viesti</h2>
  <form method="post">
    <input name="name" placeholder="Nimi" maxlength="100" required>
    <input name="content" placeholder="Viesti" maxlength="255" required>
    <button type="submit">Tallenna</button>
  </form>

  <h2>Viestit</h2>
  <ul>
    <?php foreach ($rows as $row): ?>
      <li>[<?= htmlspecialchars($row['created_at']) ?>]
        <b><?= htmlspecialchars($row['name']) ?>:</b>
        <?= htmlspecialchars($row['content']) ?>
      </li>
    <?php endforeach; ?>
  </ul>
</body>
</html>

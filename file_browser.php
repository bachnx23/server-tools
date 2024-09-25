<?php
// Thông tin xác thực
$valid_username = 'megaads';
$valid_password = 'xxxxxxx';

// Hàm để yêu cầu xác thực
function authenticate() {
    header('WWW-Authenticate: Basic realm="Restricted Area"');
    header('HTTP/1.0 401 Unauthorized');
    echo 'Authentication required.';
    exit;
}

// Kiểm tra xác thực
if (!isset($_SERVER['PHP_AUTH_USER']) || !isset($_SERVER['PHP_AUTH_PW']) ||
    $_SERVER['PHP_AUTH_USER'] !== $valid_username || $_SERVER['PHP_AUTH_PW'] !== $valid_password) {
    authenticate();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $dir = $_POST['dir'] ?? '';
    $fileToView = $_POST['file'] ?? '';

    if (is_dir($dir)) {
        $files = scandir($dir);
    } else {
        $error = "Thư mục không hợp lệ!";
    }

    if ($fileToView && is_file($fileToView)) {
        $fileContent = file_get_contents($fileToView);
    } else if ($fileToView) {
        $error = "File không tồn tại hoặc không thể đọc!";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>File Browser</title>
</head>
<body>
    <h1>File Browser</h1>
    <form method="post">
        <label for="dir">Đường dẫn thư mục:</label>
        <input type="text" id="dir" name="dir" value="<?php echo htmlspecialchars($dir ?? '', ENT_QUOTES); ?>" required>
        <button type="submit">Xem danh sách file</button>
    </form>

    <?php if (isset($files)): ?>
        <h2>Danh sách file trong thư mục: <?php echo htmlspecialchars($dir, ENT_QUOTES); ?></h2>
        <ul>
            <?php foreach ($files as $file): ?>
                <?php if ($file !== '.' && $file !== '..'): ?>
                    <li>
                        <form method="post" style="display: inline;">
                            <input type="hidden" name="dir" value="<?php echo htmlspecialchars($dir, ENT_QUOTES); ?>">
                            <input type="hidden" name="file" value="<?php echo htmlspecialchars($dir . DIRECTORY_SEPARATOR . $file, ENT_QUOTES); ?>">
                            <button type="submit"><?php echo htmlspecialchars($file, ENT_QUOTES); ?></button>
                        </form>
                    </li>
                <?php endif; ?>
            <?php endforeach; ?>
        </ul>
    <?php endif; ?>

    <?php if (isset($fileContent)): ?>
        <h2>Nội dung file: <?php echo htmlspecialchars(basename($fileToView), ENT_QUOTES); ?></h2>
        <pre><?php echo htmlspecialchars($fileContent, ENT_QUOTES); ?></pre>
    <?php elseif (isset($error)): ?>
        <p style="color: red;"><?php echo htmlspecialchars($error, ENT_QUOTES); ?></p>
    <?php endif; ?>
</body>
</html>

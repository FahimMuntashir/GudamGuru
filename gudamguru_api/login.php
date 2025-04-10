<?php
// Enable CORS for Flutter Web
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json");

// Include database connection
include("db.php");

// Get POST data
$user_id = $_POST['user_id'] ?? '';
$password = $_POST['password'] ?? '';

// Validate input
if (empty($user_id) || empty($password)) {
    echo json_encode(["status" => "error", "message" => "User ID and Password are required."]);
    exit();
}

// Fetch user from DB
$query = "SELECT * FROM users WHERE user_id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 1) {
    $user = $result->fetch_assoc();

    // Verify hashed password
    if (password_verify($password, $user['password'])) {
        echo json_encode([
            "status" => "success",
            "message" => "Login successful.",
            "data" => [
                "id" => $user['id'],
                "user_id" => $user['user_id'],
                "company_name" => $user['company_name'],
                "phone" => $user['phone']
            ]
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Incorrect password."]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "User not found."]);
}

$stmt->close();
$conn->close();
?>

<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json");

include("db.php");

$userId = $_POST['user_id'] ?? '';

if (empty($userId)) {
    echo json_encode(["status" => "error", "message" => "User ID missing."]);
    exit();
}

// Delete user from DB
$query = "DELETE FROM users WHERE user_id = ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $userId);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Account deleted."]);
} else {
    echo json_encode(["status" => "error", "message" => "Failed to delete account."]);
}

$stmt->close();
$conn->close();
?>

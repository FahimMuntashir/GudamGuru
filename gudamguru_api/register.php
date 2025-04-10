<?php
// Enable CORS for Flutter Web (running on localhost)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Access-Control-Allow-Methods: POST");
header("Content-Type: application/json");

// Include the database connection
include("db.php");

// OPTIONAL DEBUG LOGGING (remove in production)
file_put_contents("log.txt", print_r($_POST, true));

// Retrieve POST data safely
$company = $_POST['company'] ?? '';
$user_id = $_POST['user_id'] ?? '';
$phone = $_POST['phone'] ?? '';
$password = $_POST['password'] ?? '';
$repassword = $_POST['repassword'] ?? '';

// Validate required fields
if (empty($company) || empty($user_id) || empty($phone) || empty($password) || empty($repassword)) {
    echo json_encode(["status" => "error", "message" => "All fields are required."]);
    exit();
}

// Check if passwords match
if ($password !== $repassword) {
    echo json_encode(["status" => "error", "message" => "Passwords do not match."]);
    exit();
}

// Hash password securely
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);

// Insert into database
$query = "INSERT INTO users (company_name, user_id, phone, password) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($query);
$stmt->bind_param("ssss", $company, $user_id, $phone, $hashedPassword);

// Respond based on execution result
if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "User registered successfully."]);
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Registration failed: " . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>

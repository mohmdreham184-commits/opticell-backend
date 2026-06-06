const express = require("express");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

const port = process.env.PORT || 3000;

// test route
app.get("/", (req, res) => {
  res.send("Backend is working 🚀");
});

// API
app.get("/api/reports", (req, res) => {
  res.json([
    { id: 1, name: "test report" }
  ]);
});

// error handlers (مهمين جدًا في Railway)
process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT:", err);
});

process.on("unhandledRejection", (err) => {
  console.error("REJECTION:", err);
});

// IMPORTANT FIX
app.listen(port, "0.0.0.0", () => {
  console.log("Server running on port " + port);
});
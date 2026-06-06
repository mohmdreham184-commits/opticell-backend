const express = require("express");
const cors = require("cors");

const app = express();

// =====================
// MIDDLEWARE
// =====================
app.use(cors());
app.use(express.json());

// =====================
// PORT (IMPORTANT FOR RAILWAY)
// =====================
const port = process.env.PORT || 3000;

// =====================
// TEST ROUTE
// =====================
app.get("/", (req, res) => {
  res.send("Backend is working 🚀");
});

// =====================
// REPORTS API
// =====================
app.get("/api/reports", (req, res) => {
  res.json([
    { id: 1, name: "test report" }
  ]);
});

// =====================
// STREAM (FIX FOR YOUR ERROR)
// =====================
app.get("/api/reports/stream", (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  // أول data
  const send = () => {
    const data = JSON.stringify([
      { id: 1, name: "live report" },
      { id: 2, name: "batch update" }
    ]);

    res.write(`data: ${data}\n\n`);
  };

  send();

  const interval = setInterval(send, 5000);

  req.on("close", () => {
    clearInterval(interval);
    res.end();
  });
});

// =====================
// ERROR HANDLERS
// =====================
process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT ERROR:", err);
});

process.on("unhandledRejection", (err) => {
  console.error("UNHANDLED REJECTION:", err);
});

// =====================
// START SERVER (RAILWAY FIX)
// =====================
app.listen(port, "0.0.0.0", () => {
  console.log(`Server running on port ${port}`);
});
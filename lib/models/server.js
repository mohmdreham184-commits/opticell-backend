const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");

const app = express();

// =====================
// MIDDLEWARE
// =====================
app.use(cors());
app.use(express.json());

// =====================
// PORT
// =====================
const port = process.env.PORT || 3000;

// =====================
// MONGO (SAFE CONNECTION)
// =====================
const uri = process.env.MONGO_URI; // Railway ENV
let db;

async function connectDB() {
  if (!uri) {
    console.log("⚠️ MONGO_URI not found, running without DB");
    return;
  }

  try {
    const client = new MongoClient(uri);
    await client.connect();

    db = client.db("opticell");

    console.log("MongoDB connected 🚀");
  } catch (err) {
    console.error("MongoDB connection failed:", err);
  }
}

connectDB();

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
    { id: 1, name: "test report" },
    { id: 2, name: "batch ok" }
  ]);
});

// =====================
// STREAM (REALTIME SAFE)
// =====================
app.get("/api/reports/stream", (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  const sendData = () => {
    const data = JSON.stringify([
      { id: 1, name: "live report" },
      { id: 2, name: "auto update" }
    ]);

    res.write(`data: ${data}\n\n`);
  };

  sendData();

  const interval = setInterval(sendData, 5000);

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
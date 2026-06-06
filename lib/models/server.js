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
// PORT (Railway SAFE)
// =====================
const port = process.env.PORT || 3000;

// =====================
// MONGO CONNECTION (SAFE)
// =====================
const uri = process.env.MONGO_URI;
let db = null;

async function connectDB() {
  if (!uri) {
    console.log("⚠️ MONGO_URI is missing - running without database");
    return;
  }

  try {
    const client = new MongoClient(uri, {
      maxPoolSize: 10,
    });

    await client.connect();
    db = client.db("opticell");

    console.log("✅ MongoDB connected successfully");
  } catch (err) {
    console.error("❌ MongoDB connection failed:", err.message);
  }
}

connectDB();

// =====================
// HEALTH CHECK
// =====================
app.get("/", (req, res) => {
  res.status(200).send("Backend is working 🚀");
});

// =====================
// REPORTS API
// =====================
app.get("/api/reports", async (req, res) => {
  try {
    if (!db) {
      return res.json([
        { id: 1, name: "mock report (no DB connection)" },
      ]);
    }

    const reports = await db.collection("reports").find().toArray();
    res.json(reports);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch reports" });
  }
});

// =====================
// SSE STREAM (REAL-TIME SAFE)
// =====================
app.get("/api/reports/stream", (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");

  const send = () => {
    const data = JSON.stringify([
      { id: 1, name: "live report" },
      { id: 2, name: "auto update" },
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
// ERROR HANDLERS (IMPORTANT)
// =====================
process.on("uncaughtException", (err) => {
  console.error("🔥 UNCAUGHT ERROR:", err);
});

process.on("unhandledRejection", (err) => {
  console.error("🔥 UNHANDLED REJECTION:", err);
});

// =====================
// START SERVER (RAILWAY FIX)
// =====================
app.listen(port, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${port}`);
});
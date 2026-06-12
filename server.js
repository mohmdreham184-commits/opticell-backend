require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { MongoClient } = require("mongodb");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI;

const sampleReports = [
  {
    id: "1",
    title: "Batch 001",
    dateTime: "2024-01-10 10:25:30",
    status: "normal",
    temperature: 68.5,
    pressure: 76.2,
    description: "All parameters within range",
  },
  {
    id: "2",
    title: "Batch 002",
    dateTime: "2024-01-10 10:16:30",
    status: "warning",
    temperature: 72.8,
    pressure: 78.5,
    description: "Temperature slightly elevated",
  },
  {
    id: "3",
    title: "Batch 003",
    dateTime: "2024-01-10 10:03:30",
    status: "critical",
    temperature: 85.2,
    pressure: 82.1,
    description: "Critical readings",
  },
];

let mongoClient = null;
let mongoDb = null;
let mongoCollection = null;
let mongoReports = [];
let isMongoConnected = false;

const sseClients = new Set();

function normalizeReports(reports) {
  return reports.map((doc) => ({
    id: doc._id ? doc._id.toString() : doc.id,
    title: doc.title || "Unknown",
    dateTime: doc.dateTime || new Date().toISOString(),
    status: doc.status || "normal",
    temperature: Number(doc.temperature) || 0,
    pressure: Number(doc.pressure) || 0,
    description: doc.description || "",
  }));
}

async function fetchReports() {
  if (!mongoCollection) return [];

  const docs = await mongoCollection
    .find({})
    .sort({ dateTime: -1 })
    .limit(100)
    .toArray();

  return normalizeReports(docs);
}

function currentReports() {
  if (isMongoConnected && mongoReports.length > 0) {
    return mongoReports;
  }

  return normalizeReports(sampleReports);
}

function broadcastReports() {
  const payload = JSON.stringify(currentReports());

  for (const client of sseClients) {
    client.write(`data: ${payload}\n\n`);
  }
}

async function connectMongo() {
  if (!MONGODB_URI) {
    console.log("⚠️ MONGODB_URI not found, using sample data");
    return;
  }

  try {
    mongoClient = new MongoClient(MONGODB_URI);

    await mongoClient.connect();

    mongoDb = mongoClient.db("opticell_db");
    mongoCollection = mongoDb.collection("reports");

    mongoReports = await fetchReports();
    isMongoConnected = true;

    console.log("✅ MongoDB connected");

    try {
      const changeStream = mongoCollection.watch();

      changeStream.on("change", async () => {
        mongoReports = await fetchReports();
        broadcastReports();
      });
    } catch (e) {
      console.log("⚠️ Change stream unavailable");
    }
  } catch (e) {
    console.log("⚠️ MongoDB connection failed");
    console.log(e.message);
  }
}

connectMongo();

app.get("/", (req, res) => {
  res.status(200).send("OK 🚀");
});

app.get("/api/reports", async (req, res) => {
  try {
    if (isMongoConnected) {
      mongoReports = await fetchReports();
    }

    res.json(currentReports());
  } catch (e) {
    res.status(500).json({
      error: e.message,
    });
  }
});

app.get("/api/reports/stream", (req, res) => {
  res.set({
    "Content-Type": "text/event-stream",
    "Cache-Control": "no-cache",
    Connection: "keep-alive",
  });

  res.flushHeaders();

  res.write(`data: ${JSON.stringify(currentReports())}\n\n`);

  sseClients.add(res);

  req.on("close", () => {
    sseClients.delete(res);
  });
});

app.post("/api/reports", async (req, res) => {
  try {
    const report = {
      title: req.body.title || "New Batch",
      dateTime: req.body.dateTime || new Date().toISOString(),
      status: req.body.status || "normal",
      temperature: Number(req.body.temperature) || 0,
      pressure: Number(req.body.pressure) || 0,
      description: req.body.description || "",
    };

    if (isMongoConnected && mongoCollection) {
      await mongoCollection.insertOne(report);
      mongoReports = await fetchReports();
    } else {
      sampleReports.unshift({
        id: Date.now().toString(),
        ...report,
      });
    }

    broadcastReports();

    res.status(201).json({
      success: true,
      report,
    });
  } catch (e) {
    res.status(500).json({
      error: e.message,
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

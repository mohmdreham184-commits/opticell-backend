const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const port = process.env.PORT || 3000;

// Sample data (before connecting to MongoDB)
const sampleReports = [
  { id: "1", title: "Batch 001", dateTime: "2024-01-10 10:25:30", status: "normal", temperature: 68.5, pressure: 76.2, description: "All parameters within range" },
  { id: "2", title: "Batch 002", dateTime: "2024-01-10 10:16:30", status: "warning", temperature: 72.8, pressure: 78.5, description: "Temperature slightly elevated" },
  { id: "3", title: "Batch 003", dateTime: "2024-01-10 10:03:30", status: "critical", temperature: 85.2, pressure: 82.1, description: "Critical readings" },
  { id: "4", title: "Batch 004", dateTime: "2024-01-09 23:45:10", status: "normal", temperature: 65.3, pressure: 74.9, description: "System recovered" },
  { id: "5", title: "Batch 005", dateTime: "2024-01-09 22:30:05", status: "normal", temperature: 67.1, pressure: 75.6, description: "Production test - successful" }
];

let mongoReports = [];
let isMongoConnected = false;

// Try to connect to MongoDB (optional)
async function connectToMongo() {
  try {
    const { MongoClient } = require('mongodb');
    const uri = process.env.MONGODB_URI || 'mongodb+srv://amohamed0238_db_user:127124t1123128312@opticell.cwxvi7c.mongodb.net/?appName=opticell';
    const client = new MongoClient(uri, { serverSelectionTimeoutMS: 5000 });
    
    await client.connect();
    const db = client.db('opticell_db');
    const collection = db.collection('reports');
    
    mongoReports = await collection.find({}).sort({ dateTime: -1 }).limit(100).toArray();
    isMongoConnected = true;
    console.log("✅ MongoDB connected, loaded", mongoReports.length, "reports");
  } catch (err) {
    console.warn("⚠️ MongoDB connection failed, using sample data:", err.message);
    mongoReports = sampleReports;
    isMongoConnected = false;
  }
}

// Connect to MongoDB on startup (non-blocking)
connectToMongo();

// Health check
app.get("/", (req, res) => {
  res.status(200).send("OK 🚀");
});

// Get all reports
app.get("/api/reports", async (req, res) => {
  try {
    let reportsToReturn;

    // If MongoDB is connected, use it
    if (isMongoConnected && mongoReports.length > 0) {
      reportsToReturn = mongoReports;
      console.log("📡 Returning", reportsToReturn.length, "reports from MongoDB");
    } else {
      reportsToReturn = sampleReports;
      console.log("📡 Returning", reportsToReturn.length, "sample reports");
    }

    // Transform MongoDB data if needed
    const transformed = reportsToReturn.map(doc => ({
      id: doc._id ? doc._id.toString() : doc.id,
      title: doc.title || 'Unknown',
      dateTime: doc.dateTime || new Date().toISOString(),
      status: doc.status || 'normal',
      temperature: Number(doc.temperature) || 0,
      pressure: Number(doc.pressure) || 0,
      description: doc.description || 'No description'
    }));

    res.json(transformed);
  } catch (err) {
    console.error("❌ Error in /api/reports:", err.message);
    res.status(500).json({ error: "Failed to fetch reports", details: err.message });
  }
});

// Insert new report
app.post("/api/reports", async (req, res) => {
  try {
    const newReport = {
      title: req.body.title || 'New Batch',
      dateTime: req.body.dateTime || new Date().toISOString(),
      status: req.body.status || 'normal',
      temperature: Number(req.body.temperature) || 0,
      pressure: Number(req.body.pressure) || 0,
      description: req.body.description || 'Manual entry'
    };

    // Add to local array
    sampleReports.unshift({ id: Date.now().toString(), ...newReport });

    console.log("✅ New report added:", newReport.title);
    res.status(201).json({ success: true, report: newReport });
  } catch (err) {
    console.error("❌ Error in POST /api/reports:", err.message);
    res.status(500).json({ error: "Failed to create report", details: err.message });
  }
});

// Start server
app.listen(port, "0.0.0.0", () => {
  console.log("🚀 Server running on port", port);
  console.log("✅ GET  / - Health check");
  console.log("✅ GET  /api/reports - Fetch reports");
  console.log("✅ POST /api/reports - Create report");
});

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
let mongoDb = null;
let mongoClient = null;
let mongoChangeStream = null;
const sseClients = new Set();

function normalizeReports(reports) {
  return reports.map(doc => ({
    id: doc._id ? doc._id.toString() : doc.id,
    title: doc.title || 'Unknown',
    dateTime: doc.dateTime || new Date().toISOString(),
    status: doc.status || 'normal',
    temperature: Number(doc.temperature) || 0,
    pressure: Number(doc.pressure) || 0,
    description: doc.description || 'No description'
  }));
}

async function fetchAndMergeReports(db) {
  try {
    const reportsCollection = db.collection('reports');
    const sensorCollection = db.collection('sensor_readings');

    const reportsDocs = await reportsCollection.find({}).sort({ dateTime: -1 }).limit(100).toArray();
    const sensorDocs = await sensorCollection.find({}).sort({ timestamp: -1 }).limit(100).toArray();

    const normalizedReports = reportsDocs.map(doc => ({
      id: doc._id ? doc._id.toString() : doc.id,
      title: doc.title || 'Unknown',
      dateTime: doc.dateTime || new Date().toISOString(),
      status: doc.status || 'normal',
      temperature: Number(doc.temperature) || 0,
      pressure: Number(doc.pressure) || 0,
      description: doc.description || 'No description',
    }));

    const mappedSensors = sensorDocs.map(doc => {
      const temp = doc.data ? (doc.data.temprature || doc.data.temperature || 0) : 0;
      const pressure = doc.data ? (doc.data.pressure || 0) : 0;
      
      // Determine status based on thresholds
      let status = 'normal';
      if (temp > 80 || pressure > 80) {
        status = 'critical';
      } else if (temp > 70 || pressure > 70) {
        status = 'warning';
      }

      return {
        id: doc._id.toString(),
        title: `Sensor ${doc.sensorId || '1'}`,
        dateTime: doc.timestamp || new Date().toISOString(),
        status: status,
        temperature: Number(temp),
        pressure: Number(pressure),
        description: doc.data ? `Humidity: ${doc.data.humidity || 0}%, Gas: ${doc.data.gas_quality || 0}` : 'Sensor reading',
      };
    });

    // Merge and sort by dateTime descending
    const combined = [...normalizedReports, ...mappedSensors];
    combined.sort((a, b) => new Date(b.dateTime) - new Date(a.dateTime));

    return combined.slice(0, 100);
  } catch (err) {
    console.error('Error merging reports:', err.message);
    return [];
  }
}

function getCurrentReports() {
  return isMongoConnected && mongoReports.length > 0 ? mongoReports : normalizeReports(sampleReports);
}

function broadcastReports() {
  const payload = JSON.stringify(getCurrentReports());
  for (const client of sseClients) {
    client.write(`data: ${payload}\n\n`);
  }
}

// Try to connect to MongoDB (optional)
async function connectToMongo() {
  try {
    const { MongoClient } = require('mongodb');
    const uri = process.env.MONGODB_URI || 'mongodb+srv://amohamed0238_db_user:127124t1123128312@opticell.cwxvi7c.mongodb.net/?appName=opticell';
    const client = new MongoClient(uri, { serverSelectionTimeoutMS: 5000 });
    
    await client.connect();
    const db = client.db('opticell_db');
    
    mongoClient = client;
    mongoDb = db;
    mongoReports = await fetchAndMergeReports(db);
    isMongoConnected = true;
    console.log("✅ MongoDB connected, loaded", mongoReports.length, "merged reports");

    try {
      mongoChangeStream = db.watch();
      mongoChangeStream.on('change', async (change) => {
        try {
          const coll = change.ns ? change.ns.coll : '';
          if (coll === 'reports' || coll === 'sensor_readings') {
            mongoReports = await fetchAndMergeReports(db);
            broadcastReports();
            console.log(`🔁 MongoDB change stream triggered on collection "${coll}":`, change.operationType);
          }
        } catch (streamErr) {
          console.warn('⚠️ Error refreshing reports from change stream:', streamErr.message);
        }
      });
      mongoChangeStream.on('error', (streamErr) => {
        console.warn('⚠️ MongoDB change stream error:', streamErr.message);
      });
      console.log('✅ MongoDB database-level change stream enabled');
    } catch (streamErr) {
      console.warn('⚠️ MongoDB change stream not available:', streamErr.message);
    }
  } catch (err) {
    console.warn("⚠️ MongoDB connection failed, using sample data:", err.message);
    mongoReports = normalizeReports(sampleReports);
    isMongoConnected = false;
    mongoDb = null;
  }
}

// Connect to MongoDB on startup (non-blocking)
connectToMongo();

// Health check
app.get("/", (req, res) => {
  res.status(200).send("OK 🚀");
});

// Live reports stream via SSE
app.get("/api/reports/stream", (req, res) => {
  res.set({
    'Cache-Control': 'no-cache',
    'Content-Type': 'text/event-stream',
    Connection: 'keep-alive',
  });
  res.flushHeaders();

  const currentReports = getCurrentReports();
  res.write(`data: ${JSON.stringify(currentReports)}\n\n`);

  sseClients.add(res);
  console.log(`🔌 SSE client connected (${sseClients.size} subscribers)`);

  req.on('close', () => {
    sseClients.delete(res);
    console.log(`⚠️ SSE client disconnected (${sseClients.size} subscribers)`);
  });
});

// Get all reports
app.get("/api/reports", async (req, res) => {
  try {
    const currentReports = getCurrentReports();
    console.log("📡 Returning", currentReports.length, "reports");
    res.json(currentReports);
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

    if (isMongoConnected && mongoCollection) {
      await mongoCollection.insertOne(newReport);
      mongoReports = await mongoCollection.find({}).sort({ dateTime: -1 }).limit(100).toArray();
    } else {
      sampleReports.unshift({ id: Date.now().toString(), ...newReport });
    }

    broadcastReports();

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

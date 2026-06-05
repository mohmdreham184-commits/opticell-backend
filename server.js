const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const port = process.env.PORT || 3000;

// MongoDB connection URI (use env variable or fallback to hardcoded demo cluster)
const uri = process.env.MONGODB_URI || 'mongodb+srv://amohamed0238_db_user:127124t1123128312@opticell.cwxvi7c.mongodb.net/?appName=opticell';
const client = new MongoClient(uri);

// Connect to MongoDB
async function connectDB() {
  try {
    await client.connect();
    console.log("Connected to MongoDB successfully");
  } catch (err) {
    console.error("MongoDB connection error:", err);
  }
}
connectDB();

// 🚀 API to get reports (REAL DATA)
app.get("/api/reports", async (req, res) => {
  try {
    const db = client.db("opticell_db");
    const collection = db.collection("reports");

    // Fetch reports sorted by dateTime descending
    const reports = await collection.find({}).sort({ dateTime: -1 }).toArray();

    // Map MongoDB _id to string id for frontend compatibility
    const transformed = reports.map(doc => ({
      id: doc._id.toString(),
      title: doc.title || '',
      dateTime: doc.dateTime || '',
      status: doc.status || 'normal',
      temperature: doc.temperature || 0,
      pressure: doc.pressure || 0,
      description: doc.description || ''
    }));

    res.json(transformed);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 🚀 API to insert a new report (Real-time data entry)
app.post("/api/reports", async (req, res) => {
  try {
    const db = client.db("opticell_db");
    const collection = db.collection("reports");

    const newReport = {
      title: req.body.title || 'New Batch',
      dateTime: req.body.dateTime || new Date().toISOString().replace('T', ' ').split('.')[0],
      status: req.body.status || 'normal',
      temperature: Number(req.body.temperature) || 0.0,
      pressure: Number(req.body.pressure) || 0.0,
      description: req.body.description || 'Manual sensor entry'
    };

    const result = await collection.insertOne(newReport);
    res.json({ success: true, result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 🚀 SSE Stream endpoint to push updates automatically to the Flutter app
app.get('/api/reports/stream', async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders && res.flushHeaders();

  const sendData = async () => {
    try {
      const db = client.db("opticell_db");
      const collection = db.collection("reports");
      const reports = await collection.find({}).sort({ dateTime: -1 }).limit(10).toArray();

      const transformed = reports.map(doc => ({
        id: doc._id.toString(),
        title: doc.title || '',
        dateTime: doc.dateTime || '',
        status: doc.status || 'normal',
        temperature: doc.temperature || 0,
        pressure: doc.pressure || 0,
        description: doc.description || ''
      }));

      res.write(`data: ${JSON.stringify(transformed)}\n\n`);
      res.flush && res.flush();
    } catch (err) {
      console.error("Error streaming reports:", err);
    }
  };

  await sendData();
  const iv = setInterval(sendData, 3000);

  req.on('close', () => {
    clearInterval(iv);
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log("Server running on port " + port);
});

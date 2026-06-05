const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// MongoDB connection string from environment or hardcoded for demo
const uri = process.env.MONGODB_URI || 'mongodb+srv://amohamed0238_db_user:127124t1123128312@opticell.cwxvi7c.mongodb.net/?appName=opticell';

app.use(cors());
app.use(express.json());

let client;

async function connectToMongo() {
  try {
    client = new MongoClient(uri);
    await client.connect();
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('MongoDB connection error:', error);
  }
}

connectToMongo();

// Function to generate mock reports
const generateMockReports = (count = 10) => {
  const out = [];
  const now = new Date();
  for (let i = 0; i < count; i++) {
    const ts = new Date(now.getTime() - i * 45000 - Math.random() * 15000);
    const temperature = Math.round((55 + Math.random() * 50) * 10) / 10;
    const pressure = Math.round((55 + Math.random() * 50) * 10) / 10;
    let status = 'normal';
    if (temperature > 85 || pressure > 85) status = 'critical';
    else if (temperature > 72 || pressure > 72) status = 'warning';

    out.push({
      id: String(i + 1),
      title: `Batch ${String(i + 1).padStart(3, '0')}`,
      dateTime: ts.toISOString().replace('T', ' ').split('.')[0],
      status,
      temperature,
      pressure,
      description: 'Simulated live sensor reading',
    });
  }
  return out;
};

// API endpoint to get reports
app.get('/api/reports', async (req, res) => {
  try {
    // If MongoDB not connected, return mock data
    if (!client) {
      console.log('MongoDB disconnected - returning mock data');
      return res.json(generateMockReports(10));
    }

    const database = client.db('opticell_db');
    const collection = database.collection('reports');

    const reports = await collection.find({}).sort({ dateTime: -1 }).toArray();

    // If no reports in MongoDB, return dynamically generated data
    if (reports.length === 0) {
      return res.json(generateMockReports(10));
    }

    // Transform MongoDB documents to match the app's expected format
    const transformedReports = reports.map(doc => ({
      id: doc._id.toString(),
      title: doc.title || '',
      dateTime: doc.dateTime || '',
      status: doc.status || 'normal',
      temperature: doc.temperature || 0,
      pressure: doc.pressure || 0,
      description: doc.description || ''
    }));

    res.json(transformedReports);
  } catch (error) {
    console.error('Error fetching reports:', error);
    // Return mock data on error
    res.json(generateMockReports(10));
  }
});

// Simple Server-Sent Events (SSE) endpoint to stream live-like updates
app.get('/api/reports/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders && res.flushHeaders();

  const sendData = () => {
    const now = new Date();
    const generate = (count = 10) => {
      const out = [];
      for (let i = 0; i < count; i++) {
        const ts = new Date(now.getTime() - i * 45000 - Math.random() * 15000);
        const temperature = Math.round((55 + Math.random() * 50) * 10) / 10;
        const pressure = Math.round((55 + Math.random() * 50) * 10) / 10;
        let status = 'normal';
        if (temperature > 85 || pressure > 85) status = 'critical';
        else if (temperature > 72 || pressure > 72) status = 'warning';

        out.push({
          id: String(i + 1),
          title: `Batch ${String(i + 1).padStart(3, '0')}`,
          dateTime: ts.toISOString().replace('T', ' ').split('.')[0],
          status,
          temperature,
          pressure,
          description: 'Simulated live sensor reading',
        });
      }
      return out;
    };

    const payload = JSON.stringify(generate(10));
    res.write('retry: 3000\n');
    res.write(`data: ${payload}\n\n`);
    res.flush && res.flush();
  };

  // send immediately then every 2 seconds
  sendData();
  const iv = setInterval(sendData, 2000);

  // clean up when client disconnects
  req.on('close', () => {
    clearInterval(iv);
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log("Server running");
});

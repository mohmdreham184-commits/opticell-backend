const express = require('express');
const { MongoClient } = require('mongodb');
const cors = require('cors');

const app = express();
const port = 3000;

// MongoDB connection string from environment or hardcoded for demo
const uri = process.env.MONGODB_URI || 'mongodb://amohamed0238_db_user:77iDbAjliMAFVZ1r@ac-hdayv07-shard-00-00.cwxvi7c.mongodb.net:27017,ac-hdayv07-shard-00-01.cwxvi7c.mongodb.net:27017,ac-hdayv07-shard-00-02.cwxvi7c.mongodb.net:27017/opticell_db?ssl=true&replicaSet=atlas-bryk1f-shard-0&authSource=admin&retryWrites=true&w=majority&appName=opticell';

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

// API endpoint to get reports
app.get('/api/reports', async (req, res) => {
  try {
    if (!client) {
      return res.status(500).json({ error: 'Database not connected' });
    }

    const database = client.db('opticell_db');
    const collection = database.collection('reports');

    const reports = await collection.find({}).sort({ dateTime: -1 }).toArray();

    // If no reports in MongoDB, return dynamically generated (changing) data
    if (reports.length === 0) {
      const generateReports = (count = 5) => {
        const out = [];
        for (let i = 0; i < count; i++) {
          const now = new Date();
          // spread timestamps slightly
          const ts = new Date(now.getTime() - i * 60000);
          // random-ish sensor values
          const temperature = Math.round((60 + Math.random() * 40) * 10) / 10;
          const pressure = Math.round((60 + Math.random() * 40) * 10) / 10;
          // derive status from thresholds
          let status = 'normal';
          if (temperature > 80 || pressure > 80) status = 'critical';
          else if (temperature > 70 || pressure > 70) status = 'warning';

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

      return res.json(generateReports(5));
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
    res.status(500).json({ error: 'Internal server error' });
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
    const generate = (count = 5) => {
      const out = [];
      for (let i = 0; i < count; i++) {
        const ts = new Date(now.getTime() - i * 60000);
        const temperature = Math.round((60 + Math.random() * 40) * 10) / 10;
        const pressure = Math.round((60 + Math.random() * 40) * 10) / 10;
        let status = 'normal';
        if (temperature > 80 || pressure > 80) status = 'critical';
        else if (temperature > 70 || pressure > 70) status = 'warning';

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

    const payload = JSON.stringify(generate(5));
    res.write(`data: ${payload}\n\n`);
  };

  // send immediately then every 3 seconds
  sendData();
  const iv = setInterval(sendData, 3000);

  // clean up when client disconnects
  req.on('close', () => {
    clearInterval(iv);
  });
});

app.listen(port, () => {
  console.log(`Opticell backend server running at http://localhost:${port}`);
});
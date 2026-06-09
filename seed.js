const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || 'mongodb+srv://amohamed0238_db_user:127124t1123128312@opticell.cwxvi7c.mongodb.net/?appName=opticell';
const client = new MongoClient(uri);

async function seedDatabase() {
  try {
    await client.connect();
    console.log('Connected to MongoDB');

    const db = client.db('opticell_db');
    const collection = db.collection('reports');

    // Check if collection has data
    const count = await collection.countDocuments();
    console.log(`Current documents in collection: ${count}`);

    if (count === 0) {
      console.log('Collection is empty. Seeding with test data...');

      const sampleData = [
        {
          title: 'Batch 001 - Control',
          dateTime: new Date().toISOString(),
          status: 'normal',
          temperature: 68.5,
          pressure: 76.2,
          description: 'All parameters within normal range'
        },
        {
          title: 'Batch 002 - Warning Alert',
          dateTime: new Date(Date.now() - 3600000).toISOString(),
          status: 'warning',
          temperature: 72.8,
          pressure: 78.5,
          description: 'Temperature slightly elevated'
        },
        {
          title: 'Batch 003 - Critical Alert',
          dateTime: new Date(Date.now() - 7200000).toISOString(),
          status: 'critical',
          temperature: 85.2,
          pressure: 82.1,
          description: 'Critical temperature and pressure readings'
        },
        {
          title: 'Batch 004 - Recovery',
          dateTime: new Date(Date.now() - 10800000).toISOString(),
          status: 'normal',
          temperature: 65.3,
          pressure: 74.9,
          description: 'System recovered to normal operation'
        },
        {
          title: 'Batch 005 - Test Data',
          dateTime: new Date(Date.now() - 14400000).toISOString(),
          status: 'normal',
          temperature: 67.1,
          pressure: 75.6,
          description: 'Production test - successful'
        }
      ];

      const result = await collection.insertMany(sampleData);
      console.log(`✅ Inserted ${result.insertedCount} test documents`);
      console.log('Inserted IDs:', result.insertedIds);
    } else {
      console.log(`✅ Collection already has ${count} documents. Skipping seed.`);
    }

    // Show first 3 documents
    const docs = await collection.find({}).sort({ dateTime: -1 }).limit(3).toArray();
    console.log('\n📊 Latest documents in collection:');
    console.log(JSON.stringify(docs, null, 2));

  } catch (err) {
    console.error('❌ Error:', err.message);
  } finally {
    await client.close();
    console.log('Connection closed');
  }
}

seedDatabase();

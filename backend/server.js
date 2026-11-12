const express = require('express');
const oracledb = require('oracledb');

const requiredEnvironment = ['DB_USER', 'DB_PASSWORD'];
for (const name of requiredEnvironment) {
  if (!process.env[name]) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
}

const port = Number(process.env.PORT || 3000);
const connectString = process.env.DB_CONNECT_STRING || 'localhost:1522/FREEPDB1';
const app = express();
app.disable('x-powered-by');

app.get('/api/health', (_request, response) => {
  response.json({ status: 'ok' });
});

let pool;
app.get('/api/health/ready', async (_request, response) => {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.execute('SELECT 1 FROM DUAL');
    response.json({ status: 'ready', database: 'connected' });
  } catch (error) {
    console.error('Oracle readiness check failed:', error);
    response.status(503).json({ status: 'unavailable', database: 'disconnected' });
  } finally {
    if (connection) {
      await connection.close();
    }
  }
});

async function start() {
  pool = await oracledb.createPool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString,
    poolMin: 1,
    poolMax: 5,
    poolIncrement: 1,
  });

  const server = app.listen(port, '0.0.0.0', () => {
    console.log(`API listening on port ${port}`);
  });

  let shuttingDown = false;
  const shutdown = () => {
    if (shuttingDown) return;
    shuttingDown = true;
    server.close(async (error) => {
      if (error) {
        console.error('Failed to close API server cleanly:', error);
        process.exitCode = 1;
      }
      try {
        await pool.close(10);
      } catch (poolError) {
        console.error('Failed to close Oracle connection pool:', poolError);
        process.exitCode = 1;
      }
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

start().catch((error) => {
  console.error('Failed to start API:', error);
  process.exitCode = 1;
});

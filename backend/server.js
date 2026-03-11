require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, () => {
  console.log(`WealthWise API server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Start weekly brief cron job (only in production)
if (process.env.NODE_ENV === 'production') {
  const weeklyBriefJob = require('./src/jobs/weeklyBrief');
  weeklyBriefJob.start();
  console.log('Weekly Brief cron job scheduled for Sundays at 23:00 EST');
}

module.exports = server;

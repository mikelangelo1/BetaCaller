import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import 'reflect-metadata';

import { sequelize } from './config/database';
import logger from './utils/logger';
import errorHandler from './middleware/errorHandler';
import rateLimiter from './middleware/rateLimiter';

// Import routes
import authRoutes from './routes/auth.routes';
import balanceRoutes from './routes/balance.routes';
import twilioRoutes from './routes/twilio.routes';
import userRoutes from './routes/user.routes';
import callRoutes from './routes/call.routes';

dotenv.config();

const app: Application = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', {
  stream: { write: (message: string) => logger.info(message.trim()) }
}));

// Rate limiting
app.use('/api/', rateLimiter);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    service: 'betacaller-api'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/balance', balanceRoutes);
app.use('/api/twilio', twilioRoutes);
app.use('/api/users', userRoutes);
app.use('/api/calls', callRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handler (must be last)
app.use(errorHandler);

// Database connection and server start
const startServer = async (): Promise<void> => {
  try {
    // Test database connection
    await sequelize.authenticate();
    logger.info('Database connection established successfully');

    // Sync database models
    if (process.env.NODE_ENV === 'development') {
      await sequelize.sync({ alter: true });
      logger.info('Database synchronized');
    }

    // Start server
    app.listen(PORT, () => {
      logger.info(`Server running on port ${PORT} in ${process.env.NODE_ENV} mode`);
      logger.info(`Health check: http://localhost:${PORT}/health`);
      logger.info(`Using Clerk for authentication`);
    });
  } catch (error) {
    logger.error('Unable to start server:', error);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err: Error) => {
  logger.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, shutting down gracefully');
  await sequelize.close();
  process.exit(0);
});

startServer();

export default app;

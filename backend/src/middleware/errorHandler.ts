import { Request, Response, NextFunction } from 'express';
import logger from '../utils/logger';

interface ErrorWithStatus extends Error {
  statusCode?: number;
  errors?: any[];
}

const errorHandler = (
  err: ErrorWithStatus,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  logger.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip
  });

  // Sequelize validation error
  if (err.name === 'SequelizeValidationError') {
    const errors = (err as any).errors?.map((e: any) => ({
      field: e.path,
      message: e.message
    }));
    res.status(400).json({
      success: false,
      message: 'Validation error',
      errors
    });
    return;
  }

  // Sequelize unique constraint error
  if (err.name === 'SequelizeUniqueConstraintError') {
    res.status(400).json({
      success: false,
      message: 'Resource already exists',
      field: (err as any).errors?.[0]?.path
    });
    return;
  }

  // Sequelize database error
  if (err.name === 'SequelizeDatabaseError') {
    res.status(500).json({
      success: false,
      message: 'Database error'
    });
    return;
  }

  // Default error
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

export default errorHandler;

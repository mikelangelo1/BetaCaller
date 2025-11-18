import { Sequelize } from 'sequelize-typescript';
import path from 'path';
import logger from '../utils/logger';

const sequelize = new Sequelize({
  database: process.env.DB_NAME || 'betacaller',
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  dialect: 'postgres',
  logging: (msg) => logger.debug(msg),
  models: [path.join(__dirname, '../models')],
  pool: {
    max: 5,
    min: 0,
    acquire: 30000,
    idle: 10000
  },
  define: {
    timestamps: true,
    underscored: true
  }
});

export { sequelize };

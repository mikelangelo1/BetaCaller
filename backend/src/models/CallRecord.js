uconst { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const CallRecord = sequelize.define('CallRecord', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    field: 'user_id',
    references: {
      model: 'users',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  phoneNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    field: 'phone_number'
  },
  contactName: {
    type: DataTypes.STRING,
    allowNull: true,
    field: 'contact_name'
  },
  callType: {
    type: DataTypes.ENUM('outgoing', 'incoming', 'missed'),
    allowNull: false,
    field: 'call_type'
  },
  callStatus: {
    type: DataTypes.ENUM('connecting', 'ringing', 'connected', 'ended', 'failed', 'rejected'),
    allowNull: false,
    field: 'call_status'
  },
  duration: {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'Call duration in seconds'
  },
  cost: {
    type: DataTypes.DECIMAL(10, 4),
    allowNull: true
  },
  countryCode: {
    type: DataTypes.STRING(5),
    allowNull: true,
    field: 'country_code'
  },
  twilioCallSid: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
    field: 'twilio_call_sid'
  },
  startTime: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'start_time'
  },
  endTime: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'end_time'
  },
  metadata: {
    type: DataTypes.JSONB,
    allowNull: true,
    defaultValue: {}
  }
}, {
  tableName: 'call_records',
  indexes: [
    { fields: ['user_id'] },
    { fields: ['phone_number'] },
    { fields: ['call_type'] },
    { fields: ['twilio_call_sid'] },
    { fields: ['created_at'] }
  ]
});

module.exports = CallRecord;

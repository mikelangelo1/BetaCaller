export interface UserData {
  clerkId: string;
  email: string;
  phoneNumber?: string;
  displayName?: string;
  profileImageUrl?: string;
  balance: number;
  lastLoginAt?: Date;
  isActive: boolean;
}

export interface TransactionData {
  userId: string;
  type: 'credit' | 'debit';
  amount: number;
  description?: string;
  referenceType?: string;
  referenceId?: string;
  balanceBefore?: number;
  balanceAfter?: number;
  metadata?: Record<string, any>;
}

export interface CallRecordData {
  userId: string;
  phoneNumber: string;
  contactName?: string;
  callType: 'outgoing' | 'incoming' | 'missed';
  callStatus: 'connecting' | 'ringing' | 'connected' | 'ended' | 'failed' | 'rejected';
  duration?: number;
  cost?: number;
  countryCode?: string;
  twilioCallSid?: string;
  startTime?: Date;
  endTime?: Date;
  metadata?: Record<string, any>;
}

export interface CallRateData {
  countryCode: string;
  countryName: string;
  ratePerMinute: number;
  currency: string;
  isActive: boolean;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  errors?: any[];
}

export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'ASC' | 'DESC';
}

export interface PaginatedResponse<T> extends ApiResponse<T> {
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

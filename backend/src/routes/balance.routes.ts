import { Router } from 'express';
import balanceController from '../controllers/balance.controller';
import { requireAuth } from '../middleware/clerkAuth';

const router = Router();

// All routes require authentication
router.get('/', requireAuth, balanceController.getBalance);
router.post('/add', requireAuth, balanceController.addBalance);
router.get('/transactions', requireAuth, balanceController.getTransactionHistory);

export default router;

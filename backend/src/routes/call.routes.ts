import { Router } from 'express';
import callController from '../controllers/call.controller';
import { requireAuth } from '../middleware/clerkAuth';
import { callLimiter } from '../middleware/rateLimiter';

const router = Router();

// All routes require authentication
router.post('/', requireAuth, callLimiter, callController.createCallRecord);
router.put('/:callId/end', requireAuth, callController.endCall);
router.get('/history', requireAuth, callController.getCallHistory);
router.get('/statistics', requireAuth, callController.getCallStatistics);
router.delete('/:callId', requireAuth, callController.deleteCallRecord);

export default router;

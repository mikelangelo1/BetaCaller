import { Router } from 'express';
import authController from '../controllers/auth.controller';
import { requireAuth } from '../middleware/clerkAuth';

const router = Router();

// User routes (same as auth profile for now)
router.get('/me', requireAuth, authController.getProfile);
router.put('/me', requireAuth, authController.updateProfile);

export default router;

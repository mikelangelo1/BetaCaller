import { Router } from 'express';
import authController from '../controllers/auth.controller';
import { requireAuth } from '../middleware/clerkAuth';

const router = Router();

// All routes require authentication
router.get('/profile', requireAuth, authController.getProfile);
router.put('/profile', requireAuth, authController.updateProfile);
router.delete('/account', requireAuth, authController.deleteAccount);

export default router;

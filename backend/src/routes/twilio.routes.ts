import { Router } from 'express';
import twilioController from '../controllers/twilio.controller';
import { requireAuth } from '../middleware/clerkAuth';

const router = Router();

// Get Twilio access token (requires authentication)
router.get('/token', requireAuth, twilioController.getAccessToken);

// Twilio webhooks (no authentication - Twilio calls these)
router.post('/voice', twilioController.handleVoiceWebhook);
router.post('/status', twilioController.handleCallStatus);

export default router;

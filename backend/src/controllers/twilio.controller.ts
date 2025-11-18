import { Response } from 'express';
import { AuthRequest } from '../middleware/clerkAuth';
import twilioService from '../services/twilio.service';
import logger from '../utils/logger';

export class TwilioController {
  async getAccessToken(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized'
        });
        return;
      }

      // Use user ID as identity for Twilio
      const identity = req.user.id;

      try {
        const token = twilioService.generateAccessToken(identity);

        res.json({
          success: true,
          token,
          identity
        });
      } catch (error: any) {
        logger.error('Twilio token generation error:', error);
        res.status(500).json({
          success: false,
          message: error.message || 'Failed to generate Twilio token'
        });
      }
    } catch (error) {
      logger.error('Get Twilio token error:', error);
      res.status(500).json({
        success: false,
        message: 'Server error'
      });
    }
  }

  async handleVoiceWebhook(req: AuthRequest, res: Response): Promise<void> {
    try {
      const VoiceResponse = require('twilio').twiml.VoiceResponse;
      const twiml = new VoiceResponse();

      const { To } = req.body;

      if (To) {
        const dial = twiml.dial({
          callerId: process.env.TWILIO_PHONE_NUMBER
        });
        dial.number(To);
      } else {
        twiml.say('Thank you for calling. Goodbye.');
      }

      res.type('text/xml');
      res.send(twiml.toString());
    } catch (error) {
      logger.error('Voice webhook error:', error);
      res.status(500).send('Error processing voice request');
    }
  }

  async handleCallStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { CallSid, CallStatus, CallDuration } = req.body;

      logger.info('Call status update:', {
        CallSid,
        CallStatus,
        CallDuration
      });

      // You can update call record here based on Twilio callbacks

      res.sendStatus(200);
    } catch (error) {
      logger.error('Call status webhook error:', error);
      res.sendStatus(500);
    }
  }
}

export default new TwilioController();

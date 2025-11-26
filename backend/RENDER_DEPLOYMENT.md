# BetaCaller Backend - Render Deployment Guide

## Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **GitHub Repository**: Push your code to GitHub
3. **VoIP Provider Credentials**: At least one of:
   - Telnyx (Recommended for Nigeria)
   - Twilio
   - Voximplant

---

## Deployment Steps

### Option 1: Deploy via Blueprint (Recommended - Easiest)

1. **Push to GitHub**
   ```bash
   cd /Users/mac/Desktop/BetaCaller/backend
   git add .
   git commit -m "Add Render deployment configuration"
   git push origin main
   ```

2. **Create Render Blueprint**
   - Go to [Render Dashboard](https://dashboard.render.com)
   - Click **"New" → "Blueprint"**
   - Connect your GitHub repository
   - Select the repository with the `render.yaml` file
   - Click **"Apply"**

3. **Configure Environment Variables**

   Render will create the services automatically. You need to add your VoIP credentials:

   Go to your service → **Environment** tab and add:

   **Required - At Least ONE VoIP Provider:**
   ```
   # Telnyx (Recommended)
   TELNYX_API_KEY=your_key_here
   TELNYX_CONNECTION_ID=your_connection_id
   TELNYX_PHONE_NUMBER=+1234567890
   TELNYX_APP_ID=your_app_id (optional for WebRTC)
   TELNYX_WEBHOOK_SECRET=your_secret

   # OR Twilio
   TWILIO_ACCOUNT_SID=your_account_sid
   TWILIO_AUTH_TOKEN=your_auth_token
   TWILIO_API_KEY_SID=your_api_key_sid
   TWILIO_API_KEY_SECRET=your_api_key_secret
   TWILIO_CALLER_NUMBER=+1234567890
   TWILIO_TWIML_APP_SID=your_twiml_app_sid

   # OR Voximplant
   VOXIMPLANT_ACCOUNT_ID=your_account_id
   VOXIMPLANT_API_KEY=your_api_key
   VOXIMPLANT_APPLICATION_ID=your_app_id
   VOXIMPLANT_CALLER_NUMBER=+1234567890
   ```

   **Optional - Payment Providers:**
   ```
   # Paystack (for Nigerian Naira)
   PAYSTACK_SECRET_KEY=sk_test_xxx
   PAYSTACK_PUBLIC_KEY=pk_test_xxx

   # Stripe (for USD)
   STRIPE_SECRET_KEY=sk_test_xxx
   STRIPE_PUBLISHABLE_KEY=pk_test_xxx
   STRIPE_WEBHOOK_SECRET=whsec_xxx
   ```

4. **Deploy**
   - Render will automatically build and deploy
   - Wait 5-10 minutes for first deployment

---

### Option 2: Manual Deployment

#### Step 1: Create PostgreSQL Database

1. Go to Render Dashboard
2. Click **"New" → "PostgreSQL"**
3. Configure:
   - **Name**: `betacaller-postgres`
   - **Database**: `betacaller`
   - **User**: `betacaller`
   - **Region**: Choose closest to your users (Oregon, Frankfurt, Singapore)
   - **Plan**: Starter ($7/month) or Free (limited)
4. Click **"Create Database"**
5. **Save** the connection details (Internal Database URL)

#### Step 2: Create Web Service

1. Click **"New" → "Web Service"**
2. **Connect Repository**: Link your GitHub repo
3. Configure:
   - **Name**: `betacaller-api`
   - **Environment**: `Docker`
   - **Region**: Same as database
   - **Branch**: `main`
   - **Dockerfile Path**: `./Dockerfile`
   - **Docker Context**: `.`

4. **Plan**: Starter ($7/month) or Free (with limitations)

#### Step 3: Environment Variables

Click **"Advanced" → "Add Environment Variable"** and add all variables from the `render.yaml` file.

**Database Connection** (from Step 1):
```
DB_HOST=dpg-xxxxx.oregon-postgres.render.com
DB_PORT=5432
DB_NAME=betacaller
DB_USERNAME=betacaller
DB_PASSWORD=<from_database_credentials>
```

**Required Configuration:**
```
NODE_ENV=production
PORT=3000
JWT_SECRET=<generate_strong_random_string>
JWT_EXPIRES_IN=7d
FRONTEND_URL=https://yourdomain.com
CORS_ORIGIN=https://yourdomain.com,http://localhost:3000
INITIAL_BALANCE=10.00
DEFAULT_CALL_RATE=0.012
```

**VoIP Provider** (add at least one):
```
VOIP_DEFAULT_PROVIDER=telnyx
VOIP_AUTO_FAILOVER=true
TELNYX_API_KEY=...
TELNYX_CONNECTION_ID=...
TELNYX_PHONE_NUMBER=...
```

5. Click **"Create Web Service"**

---

## Post-Deployment Configuration

### 1. Get Your API URL

After deployment, your API will be available at:
```
https://betacaller-api.onrender.com/api
```

Test the health endpoint:
```bash
curl https://betacaller-api.onrender.com/api
```

### 2. Configure Webhooks

Update your VoIP provider webhooks to point to your Render URL:

**Telnyx Webhooks:**
```
https://betacaller-api.onrender.com/api/calls/webhook/telnyx
```

**Twilio Webhooks:**
```
https://betacaller-api.onrender.com/api/calls/webhook/twilio
```

**Voximplant Webhooks:**
```
https://betacaller-api.onrender.com/api/calls/webhook/voximplant
```

### 3. Update Flutter App Configuration

Update your Flutter app's API base URL:

```dart
// lib/services/betacaller_api_service.dart
static const String baseUrl = 'https://betacaller-api.onrender.com/api';
```

### 4. Test the Deployment

**Check Health:**
```bash
curl https://betacaller-api.onrender.com/api
```

**Check VoIP Providers:**
```bash
curl https://betacaller-api.onrender.com/api/calls/health
```

**Test User Registration:**
```bash
curl -X POST https://betacaller-api.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "phoneNumber": "+2348012345678",
    "fullName": "Test User"
  }'
```

---

## Important Notes

### Free Tier Limitations

Render's free tier has:
- **Spin down after 15 minutes** of inactivity
- **750 hours/month** of runtime
- First request after spin down takes **30-60 seconds**

**Recommendation:** Use at least the **Starter plan ($7/month)** for:
- No spin down
- Better performance
- Production use

### Database Backups

Free PostgreSQL databases are **deleted after 90 days**.

**Starter plan includes:**
- Daily backups (7 days retention)
- Point-in-time recovery
- 1GB storage

### Environment Variables Security

- Never commit `.env` files to Git
- Use Render's environment variables dashboard
- Mark sensitive variables as "secret" in Render

### Custom Domain (Optional)

1. Go to your service settings
2. Click **"Custom Domain"**
3. Add your domain: `api.betacaller.com`
4. Update DNS records as instructed
5. Render provides free SSL certificates

---

## Monitoring & Logs

### View Logs

1. Go to your service dashboard
2. Click **"Logs"** tab
3. Real-time logs will appear

### Set Up Alerts

1. Go to service settings
2. Enable **"Notification"** settings
3. Add your email for:
   - Deployment failures
   - Service crashes
   - Health check failures

---

## Cost Estimate (Monthly)

### Minimal Setup:
- **Web Service (Starter)**: $7/month
- **PostgreSQL (Starter)**: $7/month
- **Total**: $14/month

### Production Setup:
- **Web Service (Standard)**: $25/month
- **PostgreSQL (Standard)**: $15/month
- **Total**: $40/month

Plus VoIP provider costs (pay-as-you-go):
- **Telnyx**: ~$0.009/min for Nigerian calls
- **Twilio**: ~$0.012/min
- **Phone numbers**: $1-5/month each

---

## Troubleshooting

### Build Fails

Check Dockerfile and ensure all dependencies are in `package.json`:
```bash
# Locally test Docker build
docker build -t betacaller-backend .
docker run -p 3000:3000 betacaller-backend
```

### Database Connection Fails

Verify environment variables:
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
- Check database is in the same region

### Health Check Fails

Ensure your app responds at `/api`:
- Check `main.ts` has `app.setGlobalPrefix('api')`
- Test locally: `curl http://localhost:3000/api`

### VoIP Calls Not Working

1. Check VoIP provider credentials
2. Verify webhooks are configured correctly
3. Check logs for errors: `api/calls/health`

---

## Next Steps

1. ✅ Deploy backend to Render
2. Configure custom domain (optional)
3. Set up monitoring and alerts
4. Update Flutter app with production API URL
5. Test end-to-end calling flow
6. Set up CI/CD for automatic deployments

---

## Support

- **Render Docs**: https://render.com/docs
- **Render Community**: https://community.render.com
- **BetaCaller Issues**: Create an issue in your GitHub repo

---

**Ready to deploy?** Start with Option 1 (Blueprint) for the easiest experience!

# Phase 37: Deployment - AWS Relay Setup (Real)

## Tasks from MVP-Plan.md:
- **Task 1:** Deploy the Node.js backend to an AWS EC2 instance outside Sudan.
- **Task 2:** Configure a static IP and SSL certificate (Let's Encrypt).
- **Verification:** Access the API via `https://api.dawaai.com/health` from a Sudanese IP.

## Current State Analysis:

### What We Have:
1. Basic OCR relay endpoint at `/api/ocr/relay` in `/backend/src/routes/relay.js`
2. Currently returns mock OCR text instead of calling Google Cloud Vision
3. Uses multer for file upload handling via `storageService`
4. Backend is ready for deployment (Node.js/Express)

### What We Need to Implement:
1. Replace mock OCR with actual Google Cloud Vision API calls
2. Implement AWS proxy pattern (though actual AWS deployment is infrastructure task)
3. Ensure the relay works as described in SPEC.md:
   ```
   Mobile App -> AWS Proxy Server (Global) -> Google Cloud Vision / Firebase -> AWS Proxy -> Mobile App
   ```

## Implementation Approach:

Since we cannot actually deploy to AWS in this environment, I'll:
1. Implement the real Google Cloud Vision API integration
2. Keep the endpoint structure the same but replace mock logic with real API calls
3. Add proper error handling and response formatting
4. Ensure it follows the proxy pattern conceptually

## Required Changes:
1. Update `/backend/src/routes/relay.js` to use actual Google Cloud Vision
2. Ensure environment variables are properly configured (GOOGLE_CLOUD_VISION_API_KEY)
3. Add proper response handling for OCR results

Let me proceed with implementing the real OCR relay.
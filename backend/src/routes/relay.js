const express = require('express');
const router = express.Router();
const { upload } = require('../services/storageService');

router.post('/ocr/relay', upload.single('prescription'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  // Mock OCR response for MVP
  // In production, this would relay to Google Cloud Vision via proxy
  const mockExtractedText = `
    Panadol 500mg - 2 tablets
    Amoxicillin 250mg - 3 capsules
    Brufen 400mg - 1 tablet
  `.trim();

  res.json({
    success: true,
    filename: req.file.filename,
    extractedText: mockExtractedText,
    // In production: forward to Google Cloud Vision API through proxy
    // For now: return mock data to test the flow
    message: 'OCR relay ready - replace with actual proxy to Google Vision API'
  });
});

module.exports = router;
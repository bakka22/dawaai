const express = require('express');
const router = express.Router();
const { upload } = require('../services/storageService');

router.post('/ocr/relay', (req, res) => {
  upload.single('prescription')(req, res, (err) => {
    if (err) {
      console.error('Upload error:', err);
      return res.status(400).json({ error: err.message });
    }

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
      text: mockExtractedText,
      message: 'OCR relay ready - replace with actual proxy to Google Vision API'
    });
  });
});

module.exports = router;
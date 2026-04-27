function logger(req, res, next) {
  const start = Date.now();
  const requestId = Math.random().toString(36).substring(7);

  console.log(`[${new Date().toISOString()}] [${requestId}] ${req.method} ${req.originalUrl}`);

  if (req.body && Object.keys(req.body).length > 0) {
    const safeBody = { ...req.body };
    if (safeBody.password) safeBody.password = '***';
    if (safeBody.refreshToken) safeBody.refreshToken = '***';
    console.log(`[${requestId}] Request Body:`, JSON.stringify(safeBody));
  }

  const originalSend = res.send;
  res.send = function(body) {
    const duration = Date.now() - start;
    console.log(`[${requestId}] Response: ${res.statusCode} (${duration}ms)`);
    originalSend.apply(res, arguments);
  };

  res.on('finish', () => {
    console.log(`[${requestId}] Completed ${req.method} ${req.originalUrl} - ${res.statusCode} in ${Date.now() - start}ms`);
  });

  next();
}

module.exports = logger;
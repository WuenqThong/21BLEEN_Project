const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();

// Phục vụ các file tĩnh từ thư mục dist (built files)
app.use(express.static(path.join(__dirname, 'dist')));

// Xử lý route cho trang dashboard
app.get('/:userId', (req, res, next) => {
    // ✅ Nếu path bắt đầu bằng /api, bỏ qua và đi tiếp
    if (req.params.userId === 'api') {
        return next();
    }
    
    // Serve React app cho user routes
    const filePath = path.join(__dirname, 'dist', 'index.html');
    res.sendFile(filePath);
});

// Xử lý tất cả các route khác (trừ API)
app.get('*', (req, res, next) => {
    // ✅ Nếu là API route, bỏ qua
    if (req.path.startsWith('/api')) {
        return next();
    }
    
    // Serve React app cho các route khác
    const filePath = path.join(__dirname, 'dist', 'index.html');
    res.sendFile(filePath);
});

module.exports = app;

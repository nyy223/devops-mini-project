const express = require('express');
const router = express.Router();


// dummy data
const users = [
  { id: 1, name: 'Trentz', email: 'trentz@example.com', role: 'admin' },
  { id: 2, name: 'Bob', email: 'bob@example.com', role: 'user' },
  { id: 3, name: 'Charlie', email: 'charlie@example.com', role: 'user' },
  { id: 4, name: 'Diana', email: 'diana@example.com', role: 'moderator' },
  { id: 5, name: 'Eve', email: 'eve@example.com', role: 'user' },
];

// get all users
router.get('/api/users', (req, res) => {
  // Simulasi delay kecil agar latency realistis
  setTimeout(() => {
    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  }, Math.random() * 50); // random delay 0-50ms
});

// get users by id
router.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }
  res.status(200).json({ success: true, data: user });
});

module.exports = router;
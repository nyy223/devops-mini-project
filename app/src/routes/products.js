const express = require('express');
const router = express.Router();

const products = [
  { id: 1, name: 'Laptop', price: 15000000, stock: 50, category: 'electronics' },
  { id: 2, name: 'Mouse', price: 250000, stock: 200, category: 'electronics' },
  { id: 3, name: 'Keyboard', price: 500000, stock: 150, category: 'electronics' },
  { id: 4, name: 'Monitor', price: 3000000, stock: 30, category: 'electronics' },
  { id: 5, name: 'Headset', price: 800000, stock: 75, category: 'audio' },
];

// GET all products
router.get('/api/products', (req, res) => {
  const { category } = req.query;
  
  setTimeout(() => {
    let result = products;
    if (category) {
      result = products.filter(p => p.category === category);
    }
    res.status(200).json({
      success: true,
      count: result.length,
      data: result
    });
  }, Math.random() * 80); // random delay 0-80ms
});

// GET product by ID
router.get('/api/products/:id', (req, res) => {
  const product = products.find(p => p.id === parseInt(req.params.id));
  if (!product) {
    return res.status(404).json({ success: false, message: 'Product not found' });
  }
  res.status(200).json({ success: true, data: product });
});

module.exports = router;
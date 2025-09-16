const express = require("express");
const router = express.Router();
const { 
  createOrder, 
  getUserOrders, 
  updateOrderStatus, 
  createOrderFromCart 
} = require("../controllers/orderController");

// Create a new order
router.post("/", createOrder);

// Create order from cart
router.post("/from-cart", createOrderFromCart);

// Get all orders of a user
router.get("/:userId", getUserOrders);

// Update order status (admin/auto-tracking)
router.put("/:orderId", updateOrderStatus);

module.exports = router;
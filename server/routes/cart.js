// routes/cart.js
const express = require("express");
const router = express.Router();
const Cart = require("../models/Cart");
const Medicine = require("../models/Medicine");

// Add item to cart
router.post("/add", async (req, res) => {
  try {
    const { userId, medicineId, quantity = 1 } = req.body;
    
    const medicine = await Medicine.findById(medicineId);
    if (!medicine) {
      return res.status(404).json({ error: "Medicine not found" });
    }

    let cartItem = await Cart.findOne({ user: userId, medicine: medicineId });
    
    if (cartItem) {
      cartItem.quantity += quantity;
      await cartItem.save();
    } else {
      cartItem = new Cart({
        user: userId,
        medicine: medicineId,
        quantity: quantity
      });
      await cartItem.save();
    }

    res.json({ message: "Item added to cart successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get cart items for user
router.get("/:userId", async (req, res) => {
  try {
    const cartItems = await Cart.find({ user: req.params.userId })
      .populate("medicine")
      .sort({ createdAt: -1 });

    res.json(cartItems);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update cart item quantity
router.put("/update", async (req, res) => {
  try {
    const { userId, medicineId, quantity } = req.body;
    
    if (quantity <= 0) {
      return res.status(400).json({ error: "Quantity must be greater than 0" });
    }

    const cartItem = await Cart.findOneAndUpdate(
      { user: userId, medicine: medicineId },
      { quantity: quantity },
      { new: true }
    );

    if (!cartItem) {
      return res.status(404).json({ error: "Cart item not found" });
    }

    res.json({ message: "Cart updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Remove item from cart
router.delete("/remove", async (req, res) => {
  try {
    const { userId, medicineId } = req.body;

    const result = await Cart.findOneAndDelete({
      user: userId,
      medicine: medicineId
    });

    if (!result) {
      return res.status(404).json({ error: "Cart item not found" });
    }

    res.json({ message: "Item removed from cart successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Clear entire cart
router.delete("/clear/:userId", async (req, res) => {
  try {
    await Cart.deleteMany({ user: req.params.userId });
    res.json({ message: "Cart cleared successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
// routes/wishlist.js
const express = require("express");
const router = express.Router();
const Wishlist = require("../models/Wishlist");
const Medicine = require("../models/Medicine");

// Add item to wishlist
router.post("/add", async (req, res) => {
  try {
    const { userId, medicineId } = req.body;
    
    // Check if medicine exists
    const medicine = await Medicine.findById(medicineId);
    if (!medicine) {
      return res.status(404).json({ error: "Medicine not found" });
    }

    // Check if item already exists in wishlist
    const existingItem = await Wishlist.findOne({ 
      user: userId, 
      medicine: medicineId 
    });
    
    if (existingItem) {
      return res.status(400).json({ error: "Item already in wishlist" });
    }

    // Create new wishlist item
    const wishlistItem = new Wishlist({
      user: userId,
      medicine: medicineId
    });
    await wishlistItem.save();

    res.json({ message: "Item added to wishlist successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get wishlist items for user
router.get("/:userId", async (req, res) => {
  try {
    const wishlistItems = await Wishlist.find({ user: req.params.userId })
      .populate("medicine")
      .sort({ createdAt: -1 });

    // Return only the medicine data
    const medicines = wishlistItems.map(item => item.medicine);
    res.json(medicines);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Remove item from wishlist
router.delete("/remove", async (req, res) => {
  try {
    const { userId, medicineId } = req.body;

    const result = await Wishlist.findOneAndDelete({
      user: userId,
      medicine: medicineId
    });

    if (!result) {
      return res.status(404).json({ error: "Wishlist item not found" });
    }

    res.json({ message: "Item removed from wishlist successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Clear entire wishlist
router.delete("/clear/:userId", async (req, res) => {
  try {
    await Wishlist.deleteMany({ user: req.params.userId });
    res.json({ message: "Wishlist cleared successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
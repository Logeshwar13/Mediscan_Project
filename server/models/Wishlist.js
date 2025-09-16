// models/Wishlist.js
const mongoose = require("mongoose");

const wishlistSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  medicine: { type: mongoose.Schema.Types.ObjectId, ref: "Medicine", required: true }
}, { timestamps: true });

// Create compound index to prevent duplicate wishlist items for same user
wishlistSchema.index({ user: 1, medicine: 1 }, { unique: true });

module.exports = mongoose.model("Wishlist", wishlistSchema);
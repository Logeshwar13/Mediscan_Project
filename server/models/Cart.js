// models/Cart.js
const mongoose = require("mongoose");

const cartSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  medicine: { type: mongoose.Schema.Types.ObjectId, ref: "Medicine", required: true },
  quantity: { type: Number, required: true, min: 1, default: 1 }
}, { timestamps: true });

// Create compound index to prevent duplicate cart items for same user
cartSchema.index({ user: 1, medicine: 1 }, { unique: true });

module.exports = mongoose.model("Cart", cartSchema);
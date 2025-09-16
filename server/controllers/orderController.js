// controllers/orderController.js
const Order = require("../models/Order");
const Medicine = require("../models/Medicine");
const Cart = require("../models/Cart");

// Create order from cart
exports.createOrderFromCart = async (req, res) => {
  try {
    const { userId } = req.body;

    // Get user's cart items
    const cartItems = await Cart.find({ user: userId }).populate('medicine');
    
    if (cartItems.length === 0) {
      return res.status(400).json({ error: "Cart is empty" });
    }

    // Calculate total price and prepare order items
    let totalPrice = 0;
    const orderItems = cartItems.map(cartItem => {
      const itemTotal = cartItem.medicine.price * cartItem.quantity;
      totalPrice += itemTotal;
      return {
        medicine: cartItem.medicine._id,
        quantity: cartItem.quantity
      };
    });

    // Create order
    const order = new Order({
      user: userId,
      items: orderItems,
      totalPrice: totalPrice,
      status: 'Ordered'
    });

    await order.save();

    // Clear cart after successful order
    await Cart.deleteMany({ user: userId });

    // Populate the order before sending response
    const populatedOrder = await Order.findById(order._id).populate('items.medicine');
    
    res.status(201).json(populatedOrder);
  } catch (err) {
    console.error('Create order from cart error:', err);
    res.status(500).json({ error: err.message });
  }
};

// Create order (existing method)
exports.createOrder = async (req, res) => {
  try {
    const { userId, items } = req.body;

    if (!items || items.length === 0) {
      return res.status(400).json({ error: "No items provided" });
    }

    // calculate total price
    let totalPrice = 0;
    for (let item of items) {
      const medicine = await Medicine.findById(item.medicine);
      if (!medicine) {
        return res.status(404).json({ error: `Medicine with ID ${item.medicine} not found` });
      }
      totalPrice += medicine.price * item.quantity;
    }

    const order = new Order({
      user: userId,
      items,
      totalPrice,
      status: 'Ordered'
    });

    await order.save();
    
    // Populate the order before sending response
    const populatedOrder = await Order.findById(order._id).populate('items.medicine');
    
    res.status(201).json(populatedOrder);
  } catch (err) {
    console.error('Create order error:', err);
    res.status(500).json({ error: err.message });
  }
};

// Get orders by userId (existing method)
exports.getUserOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.params.userId })
      .populate("items.medicine")
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (err) {
    console.error('Get user orders error:', err);
    res.status(500).json({ error: err.message });
  }
};

// Update order status (existing method)
exports.updateOrderStatus = async (req, res) => {
  try {
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({ error: "Status is required" });
    }
    
    const order = await Order.findByIdAndUpdate(
      req.params.orderId,
      { status },
      { new: true }
    ).populate('items.medicine');

    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }

    res.json(order);
  } catch (err) {
    console.error('Update order status error:', err);
    res.status(500).json({ error: err.message });
  }
};
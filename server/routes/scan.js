// const express = require("express");
// const axios = require("axios");
// const multer = require("multer");
// const fs = require("fs");

// const router = express.Router();
// const upload = multer({ dest: "uploads/" });

// // Proxy scan request to Python backend
// router.post("/", upload.single("image"), async (req, res) => {
//   try {
//     const image = fs.createReadStream(req.file.path);

//     const response = await axios.post(
//       "http://localhost:5001/scan", // Flask backend
//       { image },
//       { headers: { "Content-Type": "multipart/form-data" } }
//     );

//     fs.unlinkSync(req.file.path); // cleanup
//     res.json(response.data);

//   } catch (err) {
//     res.status(500).json({ error: err.message });
//   }
// });

// module.exports = router;



const express = require("express");
const axios = require("axios");
const multer = require("multer");
const fs = require("fs");
const FormData = require('form-data');

const router = express.Router();
const upload = multer({ dest: "uploads/" });

router.post("/", upload.single("image"), async (req, res) => {
  try {
    const formData = new FormData();
    formData.append('image', fs.createReadStream(req.file.path));

    const response = await axios.post(
      "http://localhost:5001/scan",
      formData,
      { 
        headers: {
          ...formData.getHeaders()
        }
      }
    );

    fs.unlinkSync(req.file.path); // cleanup
    res.json(response.data);

  } catch (err) {
    console.error("Scan error:", err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
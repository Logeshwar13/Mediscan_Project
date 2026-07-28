from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from werkzeug.utils import secure_filename
import google.generativeai as genai
from gemini_ocr import extract_medicines_from_image
from db import get_medicine_info

# Initialize Flask
app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ✅ Configure Gemini API
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))


# 🧠 Route: Scan Prescription (Main OCR)
@app.route("/scan", methods=["POST"])
def scan_prescription():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files["image"]
    filename = secure_filename(image.filename)
    path = os.path.join(UPLOAD_FOLDER, filename)
    image.save(path)

    # OCR step
    print(f"🔍 Starting OCR for {filename}")
    medicine_names = extract_medicines_from_image(path)
    print(f"📝 Extracted medicine names: {medicine_names}")

    medicines = []
    for name in medicine_names:
        medicine_info = get_medicine_info(name)
        print(f"💊 {name} -> ID: {medicine_info.get('_id', 'N/A')}, Available: {medicine_info.get('stock_quantity', 0) > 0}")
        medicines.append(medicine_info)

    os.remove(path)

    print(f"✅ Returning {len(medicines)} medicines")
    return jsonify({
        "success": True,
        "medicines": medicines
    })


# 🧩 Route: Database Test
@app.route("/test-db", methods=["GET"])
def test_db():
    try:
        from db import medicines_collection
        count = medicines_collection.count_documents({})
        sample = list(medicines_collection.find().limit(3))
        return jsonify({
            "total_medicines": count,
            "sample": [{"name": doc["name"], "id": str(doc["_id"])} for doc in sample]
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# 🧪 Route: Test OCR without image
@app.route("/test-ocr", methods=["POST"])
def test_ocr():
    """Test OCR with text input (no image needed)."""
    if request.is_json and "text" in request.json:
        test_text = request.json["text"]
        print(f"Testing with text: {test_text}")

        import re
        # Extract potential medicine names by pattern
        potential_medicines = re.findall(r'\b[A-Z][a-z]+(?:ol|in|cin|fen|pam|zole|mycin)\b', test_text)
        return jsonify({
            "success": True,
            "extracted_text": test_text,
            "potential_medicines": potential_medicines
        })
    return jsonify({"error": "No text provided"}), 400


# ⚙️ Route: Test Gemini Connection (Fixed)
@app.route("/test-gemini", methods=["GET"])
def test_gemini():
    """Check Gemini API connection and model accessibility."""
    try:
        # ✅ FIX: Use correct model name
        model = genai.GenerativeModel("gemini-1.5-flash-latest")

        # ✅ FIX: Use simpler API format
        response = model.generate_content("List 3 common medicine names as a JSON array")

        return jsonify({
            "success": True,
            "gemini_response": response.text
        })
    except Exception as e:
        import traceback
        return jsonify({
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc()
        }), 500


# 🐞 Route: Debug Scan (basic checks)
@app.route("/debug-scan", methods=["POST"])
def debug_scan():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files["image"]
    filename = secure_filename(image.filename)
    path = os.path.join(UPLOAD_FOLDER, filename)
    image.save(path)

    file_size = os.path.getsize(path)

    # Just test with predefined medicine names
    test_medicines = ["Paracetamol", "Aspirin"]
    medicines = [get_medicine_info(name) for name in test_medicines]

    os.remove(path)

    return jsonify({
        "success": True,
        "file_size": file_size,
        "filename": filename,
        "test_medicines": medicines
    })


# 🚀 Start Flask Server
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5001)
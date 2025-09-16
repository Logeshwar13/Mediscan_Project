from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from werkzeug.utils import secure_filename
from gemini_ocr import extract_medicines_from_image
from db import get_medicine_info

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

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
@app.route("/test-ocr", methods=["POST"])
def test_ocr():
    """Test OCR with a simple text image or direct text input"""
    if "text" in request.json:
        # Test with direct text input
        test_text = request.json["text"]
        print(f"Testing with text: {test_text}")
        
        # Simulate OCR result
        import re
        # Extract potential medicine names (words that look like medicine names)
        potential_medicines = re.findall(r'\b[A-Z][a-z]+(?:ol|in|cin|fen|pam|zole|mycin)\b', test_text)
        return jsonify({
            "success": True,
            "extracted_text": test_text,
            "potential_medicines": potential_medicines
        })
    
    return jsonify({"error": "No text provided"}), 400

@app.route("/test-gemini", methods=["GET"])
def test_gemini():
    """Test Gemini API connection"""
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content("List 3 common medicine names as a JSON array")
        return jsonify({
            "success": True,
            "gemini_response": response.text
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 500
@app.route("/debug-scan", methods=["POST"])
def debug_scan():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files["image"]
    filename = secure_filename(image.filename)
    path = os.path.join(UPLOAD_FOLDER, filename)
    image.save(path)

    # Try to get basic image info
    import os
    file_size = os.path.getsize(path)
    
    # Test with hardcoded medicine names first
    test_medicines = ["Paracetamol", "Aspirin"]
    medicines = [get_medicine_info(name) for name in test_medicines]

    os.remove(path)

    return jsonify({
        "success": True,
        "file_size": file_size,
        "filename": filename,
        "test_medicines": medicines
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
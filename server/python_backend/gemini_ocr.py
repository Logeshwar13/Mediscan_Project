import google.generativeai as genai
import base64
import json
import os
import re
from dotenv import load_dotenv
from PIL import Image

# Load environment variables
load_dotenv()
api_key = os.getenv('GEMINI_API_KEY')

# Configure Gemini API key
genai.configure(api_key=api_key)


def extract_medicines_from_image(image_path):
    """
    Extracts medicine names from a prescription image using Gemini LLM.
    Returns a list of medicine names.
    """
    try:
        print(f"📷 Opening image: {image_path}")
        
        # ✅ FIX: Open image using PIL (required for v1beta API)
        img = Image.open(image_path)
        
        # Detailed prompt for medicine extraction
        prompt = """
        You are a medical expert. Analyze this prescription image and extract ONLY the medicine/drug names.

        Rules:
        1. Extract medicine names WITHOUT dosages (e.g., "Paracetamol" not "Paracetamol 500mg").
        2. Ignore doctor names, patient names, dates, and instructions.
        3. Look for both brand names and generic names.
        4. Return as a simple JSON array format: ["Medicine1", "Medicine2", "Medicine3"].
        5. If no medicines are found, return an empty array: [].

        Examples of valid medicine names: "Paracetamol", "Aspirin", "Amoxicillin", "Metformin".
        """

        # ✅ FIX: Use models/gemini-1.5-flash (without -latest suffix for v1beta)
        model = genai.GenerativeModel("models/gemini-1.5-flash")

        # ✅ FIX: Pass PIL Image object directly
        response = model.generate_content([prompt, img])

        # Extract response text
        response_text = response.text.strip()
        print(f"🤖 Gemini raw response: {response_text}")

        # Remove markdown code blocks if present
        if response_text.startswith("```"):
            response_text = re.sub(r'```(?:json)?\n?', '', response_text)
            response_text = re.sub(r'\n?```', '', response_text)

        # Try to parse JSON directly
        try:
            medicines = json.loads(response_text)
            if isinstance(medicines, list):
                cleaned_medicines = []
                for med in medicines:
                    if isinstance(med, str):
                        # Clean dosage and extra spaces
                        cleaned_med = re.sub(r'\s*\d+\s*(mg|ml|g|mcg)\s*', '', med, flags=re.IGNORECASE)
                        cleaned_med = cleaned_med.strip()
                        if cleaned_med and len(cleaned_med) > 2:
                            cleaned_medicines.append(cleaned_med)
                print(f"📋 Cleaned medicines: {cleaned_medicines}")
                return cleaned_medicines
        except json.JSONDecodeError:
            print("❌ JSON parsing failed, trying alternative parsing...")

        # Try parsing as Python list
        try:
            import ast
            medicines = ast.literal_eval(response_text)
            if isinstance(medicines, list):
                return [str(med).strip() for med in medicines if str(med).strip()]
        except Exception:
            print("❌ Python list parsing failed")

        # Fallback: extract with regex
        medicine_pattern = r'"([^"]+)"'
        matches = re.findall(medicine_pattern, response_text)
        if matches:
            print(f"🔍 Regex extracted: {matches}")
            return matches

        print(f"❌ Could not parse response: {response_text}")
        return []

    except Exception as e:
        print(f"❌ Error in OCR extraction: {e}")
        import traceback
        traceback.print_exc()
        return []
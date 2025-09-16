import google.generativeai as genai
import base64
import json
import os
import re
from dotenv import load_dotenv
  
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
        # Read and encode image
        with open(image_path, "rb") as image_file:
            image_data = base64.b64encode(image_file.read()).decode("utf-8")

        # Detect image format
        mime_type = "image/jpeg"  # default
        if image_path.lower().endswith('.png'):
            mime_type = "image/png"
        elif image_path.lower().endswith('.webp'):
            mime_type = "image/webp"
        
        print(f"📷 Image format: {mime_type}")

        # More specific and detailed prompt
        prompt = """
        You are a medical expert. Analyze this prescription image and extract ONLY the medicine/drug names.

        Rules:
        1. Extract medicine names WITHOUT dosages (e.g., "Paracetamol" not "Paracetamol 500mg")
        2. Ignore doctor names, patient names, dates, instructions
        3. Look for both brand names and generic names
        4. Return as a simple JSON array format: ["Medicine1", "Medicine2", "Medicine3"]
        5. If no medicines are found, return an empty array: []

        Examples of valid medicine names: "Paracetamol", "Aspirin", "Amoxicillin", "Metformin"
        
        Focus on finding text that looks like medicine names in the prescription.
        """

        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content([
            prompt,
            {
                "mime_type": mime_type,
                "data": image_data
            }
        ])

        print(f"🤖 Gemini raw response: {response.text}")

        # Clean the response text
        response_text = response.text.strip()
        
        # Remove markdown code blocks if present
        if response_text.startswith("```"):
            response_text = re.sub(r'```(?:json)?\n?', '', response_text)
            response_text = re.sub(r'\n?```', '', response_text)

        # Try to parse the response as JSON array
        try:
            medicines = json.loads(response_text)
            if isinstance(medicines, list):
                # Clean medicine names (remove dosages, extra spaces)
                cleaned_medicines = []
                for med in medicines:
                    if isinstance(med, str):
                        # Remove common dosage patterns
                        cleaned_med = re.sub(r'\s*\d+\s*mg\s*', '', med, flags=re.IGNORECASE)
                        cleaned_med = re.sub(r'\s*\d+\s*ml\s*', '', cleaned_med, flags=re.IGNORECASE)
                        cleaned_med = re.sub(r'\s*\d+\s*g\s*', '', cleaned_med, flags=re.IGNORECASE)
                        cleaned_med = re.sub(r'\s*\d+\s*mcg\s*', '', cleaned_med, flags=re.IGNORECASE)
                        cleaned_med = cleaned_med.strip()
                        if cleaned_med and len(cleaned_med) > 2:  # Valid medicine name
                            cleaned_medicines.append(cleaned_med)
                print(f"📋 Cleaned medicines: {cleaned_medicines}")
                return cleaned_medicines
        except json.JSONDecodeError:
            print(f"❌ JSON parsing failed, trying alternative parsing...")
            
        # Fallback: try to parse as Python list
        try:
            import ast
            medicines = ast.literal_eval(response_text)
            if isinstance(medicines, list):
                return [str(med).strip() for med in medicines if str(med).strip()]
        except Exception:
            print(f"❌ Python list parsing failed")
            
        # Fallback: try to extract from text using regex
        medicine_pattern = r'"([^"]+)"'
        matches = re.findall(medicine_pattern, response_text)
        if matches:
            print(f"🔍 Regex extracted: {matches}")
            return matches
            
        print(f"❌ Could not parse response: {response_text}")
        return []
        
    except Exception as e:
        print(f"❌ Error in OCR extraction: {e}")
        return []
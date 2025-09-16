from pymongo import MongoClient
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
client = MongoClient(MONGO_URI)

db = client["medi"]  # ✅ match your MongoDB database name
medicines_collection = db["medicines"]  # ✅ collection name same as Node.js model

def get_medicine_info(name):
    print(f"🔍 Searching for medicine: '{name}'")
    
    # Try exact match first
    doc = medicines_collection.find_one({"name": {"$regex": f"^{name}$", "$options": "i"}})
    
    # If not found, try partial match (medicine name contains the search term)
    if not doc:
        doc = medicines_collection.find_one({"name": {"$regex": name, "$options": "i"}})
    
    # If still not found, try reverse match (search term contains medicine name)
    if not doc:
        # Find medicines where any word in the name matches
        name_words = name.split()
        for word in name_words:
            if len(word) > 3:  # Only search for meaningful words
                doc = medicines_collection.find_one({"name": {"$regex": f"\\b{word}\\b", "$options": "i"}})
                if doc:
                    break
    
    if doc:
        print(f"✅ Found medicine: {doc['name']} (ID: {str(doc['_id'])})")
        return {
            "_id": str(doc["_id"]),
            "name": doc["name"],
            "price": doc.get("price", 0),
            "stock_quantity": doc.get("stock_quantity", 0),
            "description": doc.get("description", ""),
            "image_url": doc.get("image_url", "https://via.placeholder.com/150"),
            "category": doc.get("category", ""),
            "brand": doc.get("brand", ""),
            "sku": doc.get("sku", ""),
            "rating": doc.get("rating", 0),
            "reviews_count": doc.get("reviews_count", 0),
            "tags": doc.get("tags", []),
            "specifications": doc.get("specifications", {}),
            "is_featured": doc.get("is_featured", False),
            "created_at": doc.get("created_at", ""),
            "updated_at": doc.get("updated_at", "")
        }
    
    print(f"❌ Medicine not found: '{name}'")
    # Return a proper structure for unavailable medicines
    return {
        "_id": "",  # Empty ID for unavailable medicines
        "name": name,
        "price": 0,
        "stock_quantity": 0,
        "description": "Medicine not found in our database",
        "image_url": "https://via.placeholder.com/150",
        "category": "",
        "brand": "",
        "sku": "",
        "rating": 0,
        "reviews_count": 0,
        "tags": [],
        "specifications": {},
        "is_featured": False,
        "created_at": "",
        "updated_at": ""
    }
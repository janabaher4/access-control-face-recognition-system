from flask import Flask, request, jsonify
import os
import cv2
import numpy as np
import tensorflow as tf
from numpy.linalg import norm

app = Flask(__name__)

# Load the trained model
model = tf.keras.models.load_model("E:/weights.h5")

# Define expected input size
IMG_SIZE = (154, 154)

# Folder containing images of known persons
DATABASE_PATH = r"C:/Users/KimoStore/model/database"

# Function to preprocess an image
def preprocess_image(image_path):
    img = cv2.imread(image_path)
    if img is None:
        return None
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, IMG_SIZE)
    img = img / 255.0
    img = np.expand_dims(img, axis=0)
    return img

# Cosine similarity function
def cosine_similarity(a, b):
    return np.dot(a, b) / (norm(a) * norm(b))

# Function to recognize a person
def recognize_face(test_image_path):
    test_img = preprocess_image(test_image_path)
    if test_img is None:
        return "Error: Invalid image!"

    test_embedding = model.predict(test_img)[0]

    best_match = None
    best_similarity = -1

    for name, embeddings in face_database.items():
        for db_embedding in embeddings:
            similarity = cosine_similarity(test_embedding, db_embedding)
            if similarity > best_similarity:
                best_similarity = similarity
                best_match = name

    threshold = 0.5
    if best_similarity > threshold:
        return f"Recognized: {best_match}"
    else:
        return "Unknown"

# Create a database of face embeddings
face_database = {}
for person_name in os.listdir(DATABASE_PATH):
    person_folder = os.path.join(DATABASE_PATH, person_name)
    if os.path.isdir(person_folder):
        face_database[person_name] = []
        for image_name in os.listdir(person_folder):
            image_path = os.path.join(person_folder, image_name)
            img = preprocess_image(image_path)
            if img is not None:
                embedding = model.predict(img)[0]
                face_database[person_name].append(embedding)

@app.route('/upload', methods=['POST'])
def upload_image():
    if 'frame' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['frame']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Create a new user folder
    user_folder = os.path.join(DATABASE_PATH, 'new_user')
    os.makedirs(user_folder, exist_ok=True)

    # Save the file
    file_path = os.path.join(user_folder, file.filename)
    file.save(file_path)

    # Recognize the face
    result = recognize_face(file_path)

    return jsonify({'message': result}), 200

if __name__ == '__main__':
    app.run(debug=True)
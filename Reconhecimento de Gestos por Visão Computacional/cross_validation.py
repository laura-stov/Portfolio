# -*- coding: utf-8 -*-
import os
import numpy as np
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score
from tensorflow.keras.preprocessing.image import img_to_array, load_img
from tensorflow.keras.models import Sequential, load_model
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.utils import to_categorical
import tensorflow as tf

# ========== 1. CARREGAMENTO E PRÉ-PROCESSAMENTO ==========
data_path = './Data'
img_size = (64, 64)
X, y = [], []

for label in os.listdir(data_path):
    folder = os.path.join(data_path, label)
    if os.path.isdir(folder):
        for file in os.listdir(folder):
            try:
                img_path = os.path.join(folder, file)
                img = load_img(img_path, target_size=img_size)
                img_array = img_to_array(img) / 255.0
                X.append(img_array)
                y.append(label)
            except:
                continue

X = np.array(X)
y = np.array(y)

# ========== 2. ENCODER E LABELS.TXT ==========
classes = sorted([d for d in os.listdir(data_path) if os.path.isdir(os.path.join(data_path, d))])

os.makedirs("Model", exist_ok=True)
with open("Model/labels.txt", "w") as f:
    for c in classes:
        f.write(f"{c}\n")

encoder = LabelEncoder()
encoder.fit(classes)
y_encoded = encoder.transform(y)
y_cat = to_categorical(y_encoded)

# ========== 3. VALIDAÇÃO CRUZADA ==========
skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
accuracies = []

params = {
    'n1': 32,
    'n2': 64,
    'dropout': 0.5,
    'dense': 128
}

for i, (train_idx, val_idx) in enumerate(skf.split(X, y_encoded)):
    print(f"\n📚 Treinando Fold {i+1}...")
    model = Sequential([
        Conv2D(params['n1'], (3,3), activation='relu', input_shape=(img_size[0], img_size[1], 3)),
        MaxPooling2D(2,2),
        Conv2D(params['n2'], (3,3), activation='relu'),
        MaxPooling2D(2,2),
        Flatten(),
        Dense(params['dense'], activation='relu'),
        Dropout(params['dropout']),
        Dense(len(classes), activation='softmax')
    ])
    model.compile(optimizer=Adam(), loss='categorical_crossentropy', metrics=['accuracy'])
    model.fit(X[train_idx], y_cat[train_idx], epochs=10, batch_size=32, verbose=0)
    preds = model.predict(X[val_idx])
    y_pred = np.argmax(preds, axis=1)
    acc = accuracy_score(y_encoded[val_idx], y_pred)
    print(f"Acurácia Fold {i+1}: {acc:.4f}")
    accuracies.append(acc)

print("\n✅ Média de Acurácia:", np.mean(accuracies))

# ========== 4. TREINO FINAL ==========
print("\n🎯 Treinando modelo final com todos os dados...")
model_final = Sequential([
    Conv2D(params['n1'], (3,3), activation='relu', input_shape=(img_size[0], img_size[1], 3)),
    MaxPooling2D(2,2),
    Conv2D(params['n2'], (3,3), activation='relu'),
    MaxPooling2D(2,2),
    Flatten(),
    Dense(params['dense'], activation='relu'),
    Dropout(params['dropout']),
    Dense(len(classes), activation='softmax')
])
model_final.compile(optimizer=Adam(), loss='categorical_crossentropy', metrics=['accuracy'])
model_final.fit(X, y_cat, epochs=10, batch_size=32, verbose=1)

model_final.save("modelo_libras.keras")
print("💾 Modelo final salvo como 'modelo_libras.keras'")

# ========== 5. CONVERSÃO PARA TFLITE ==========
print("🔁 Convertendo para formato TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model_final)
# (Opcional) Para quantização:
# converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open("Model/model_unquant.tflite", "wb") as f:
    f.write(tflite_model)

print("✅ Modelo TFLite salvo em 'Model/model_unquant.tflite'")

# ========== 6. INFERÊNCIA ==========
def inferir(imagem_path):
    modelo = load_model("modelo_libras.keras")
    with open("Model/labels.txt", "r") as f:
        classes = [line.strip() for line in f.readlines()]
    encoder = LabelEncoder()
    encoder.fit(classes)

    img = load_img(imagem_path, target_size=(64, 64))
    img_array = img_to_array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    pred = modelo.predict(img_array)
    classe = np.argmax(pred, axis=1)
    return encoder.inverse_transform(classe)[0]

print("Letra prevista:", inferir('./Data/B/Image_1750277643.6032517.jpg'))
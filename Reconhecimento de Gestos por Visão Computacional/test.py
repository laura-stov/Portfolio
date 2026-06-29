import cv2
from cvzone.HandTrackingModule import HandDetector
import numpy as np
import math
import tensorflow as tf

# --- Inicializações ---
cap = cv2.VideoCapture(0)
detector = HandDetector(maxHands=1)

# carregar modelo TFLite
interpreter = tf.lite.Interpreter(model_path="Model/model_unquant.tflite")
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# carregar labels
with open("Model/labels.txt", "r") as f:
    labels = [line.strip() for line in f.readlines()]

offset = 20
imgSize = 300

while True:
    success, img = cap.read()
    hands, img = detector.findHands(img, draw=True)

    if hands:
        hand = hands[0]
        x, y, w, h = hand['bbox']

        imgWhite = np.ones((imgSize, imgSize, 3), np.uint8) * 255

        imgCrop = img[y - offset:y + h + offset, x - offset:x + w + offset]

        aspectRatio = h / w

        if aspectRatio > 1:
            k = imgSize / h
            wCal = math.ceil(k * w)
            imgResize = cv2.resize(imgCrop, (wCal, imgSize))
            wGap = math.ceil((imgSize - wCal) / 2)
            imgWhite[:, wGap:wGap + wCal] = imgResize
        else:
            k = imgSize / w
            hCal = math.ceil(k * h)
            imgResize = cv2.resize(imgCrop, (imgSize, hCal))
            hGap = math.ceil((imgSize - hCal) / 2)
            imgWhite[hGap:hGap + hCal, :] = imgResize

        # preparar imagem pro modelo
        imgInput = cv2.resize(imgWhite, (64, 64))
        imgInput = imgInput.astype(np.float32) / 255.0
        imgInput = np.expand_dims(imgInput, axis=0)

        # setar entrada do modelo e rodar
        interpreter.set_tensor(input_details[0]['index'], imgInput)
        interpreter.invoke()
        output_data = interpreter.get_tensor(output_details[0]['index'])[0]
        index = int(np.argmax(output_data))
        prediction = labels[index]  # ← apenas a letra

        # exibir só a letra no terminal
        print("Letra detectada:", prediction)

        # exibir só a letra na imagem
        cv2.putText(img, prediction, (x, y - 20), cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 255, 0), 3)

        cv2.imshow("ImageCrop", imgCrop)
        cv2.imshow("ImageWhite", imgWhite)

    cv2.imshow("Image", img)
    cv2.waitKey(1)

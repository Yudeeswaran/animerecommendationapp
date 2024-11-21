from flask import Flask, request, jsonify
from transformers import AutoTokenizer, AutoModelForSequenceClassification, LlamaTokenizer, LlamaForCausalLM
import torch

# Initialize models and tokenizers
emotion_tokenizer = AutoTokenizer.from_pretrained("SamLowe/roberta-base-go_emotions")
emotion_model = AutoModelForSequenceClassification.from_pretrained("SamLowe/roberta-base-go_emotions")

llama_tokenizer = LlamaTokenizer.from_pretrained("meta-llama/Llama-3.2-1B")
llama_model = LlamaForCausalLM.from_pretrained("meta-llama/Llama-3.2-1B")

# Flask app setup
app = Flask(__name__)

# Emotion detection function
def detect_emotion(user_input):
    inputs = emotion_tokenizer(user_input, return_tensors="pt")
    with torch.no_grad():
        outputs = emotion_model(**inputs)
    probabilities = torch.softmax(outputs.logits, dim=1)
    predicted_class = probabilities.argmax().item()
    label_map = {...}  # Use the same label map as before
    predicted_emotion = label_map[predicted_class]
    return predicted_emotion

# Response generation function
def generate_response(user_input, emotion):
    prompt = f"User is feeling {emotion}. Respond empathetically:\n\nUser: {user_input}\nBot:"
    inputs = llama_tokenizer(prompt, return_tensors="pt")
    with torch.no_grad():
        outputs = llama_model.generate(**inputs, max_length=100)
    response = llama_tokenizer.decode(outputs[0], skip_special_tokens=True)
    return response

# Flask route for prediction
@app.route('/get-response', methods=['POST'])
def get_response():
    data = request.json
    user_input = data.get("user_input", "")
    emotion = detect_emotion(user_input)
    bot_response = generate_response(user_input, emotion)
    return jsonify({"emotion": emotion, "response": bot_response})

# Run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

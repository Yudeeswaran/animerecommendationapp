import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatBotPanel extends StatefulWidget {
  @override
  _ChatBotPanelState createState() => _ChatBotPanelState();
}

class _ChatBotPanelState extends State<ChatBotPanel> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  // Function to send the user's message to Flask API and get the response
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      messages.add({'text': message, 'sender': 'user'});
      isLoading = true;
    });

    // Send the message to Flask backend
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/chat'), // Flask server URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botReply = data['reply'];

        setState(() {
          messages.add({'text': botReply, 'sender': 'bot'});
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chat with us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                color: Colors.black, // Close button color
                onPressed: () {
                  Navigator.pop(context); // Close the chat panel
                },
              )
            ],
          ),
          Divider(),

          // Chat history (For now, it's just a static list)
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isBot = message['sender'] == 'bot';

                return Align(
                  alignment: isBot ? Alignment.topLeft : Alignment.topRight,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBot ? Colors.grey[200] : Colors.blueAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text']!,
                      style: TextStyle(
                        color: isBot ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User input field
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          Colors.grey[100], // Light background for text field
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                          color: Colors.black), // Text color for input
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        hintStyle: TextStyle(
                            color: Colors.grey[600]), // Grey hint text
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8), // Space between input field and send button
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final message = _controller.text.trim();
                      _controller.clear();
                      sendMessage(message); // Send the message to the backend
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

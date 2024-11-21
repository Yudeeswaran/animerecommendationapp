import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:anime_recommendations_app/stores/anime/anime_store.dart';
import 'package:anime_recommendations_app/stores/user/user_store.dart';
import 'package:anime_recommendations_app/ui/anime_list/widgets/appbar_anime_list.dart';
import 'package:anime_recommendations_app/ui/anime_list/widgets/grid_view_widget.dart';
import 'package:anime_recommendations_app/utils/device/device_utils.dart';

class AnimeList extends StatefulWidget {
  @override
  _AnimeListState createState() => _AnimeListState();
}

class _AnimeListState extends State<AnimeList> {
  bool isInited = false;
  final key = GlobalKey<ScaffoldState>();

  late AnimeStore _animeStore;
  late UserStore _userStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isInited) {
      _animeStore = Provider.of<AnimeStore>(context);
      _userStore = Provider.of<UserStore>(context);
      isInited = true;
    }

    _userStore.initUser();
  }

  void _openChatBotPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ChatBotPanel();
      },
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: key,
      appBar: PreferredSize(
        preferredSize: Size(DeviceUtils.getScaledWidth(context, 1), 56),
        child: Observer(
          builder: (context) {
            return AppBarAnimeListWidget(
              _animeStore,
              _userStore,
              isSearching: _animeStore.isSearching,
            );
          },
        ),
      ),
      body: Observer(
        builder: (context) {
          return _animeStore.isFetchingAnimeList
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Loading offline database, please wait a minute..."),
                    Divider(),
                    LinearProgressIndicator(),
                  ],
                )
              : GridViewWidget(_animeStore, _userStore);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openChatBotPanel,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.chat, color: Colors.white),
        tooltip: 'Your AI Assistant',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class ChatBotPanel extends StatefulWidget {
  @override
  _ChatBotPanelState createState() => _ChatBotPanelState();
}

class _ChatBotPanelState extends State<ChatBotPanel> {
  bool isLoading = false;
  List<Map<String, String>> messages = [];

  TextEditingController _controller = TextEditingController();

  Future<void> sendMessage(String message, {int retryCount = 3}) async {
    if (message.isEmpty) return;

    setState(() {
      messages.add({'text': message, 'sender': 'user'});
      isLoading = true;
    });

    int attempts = 0;
    bool success = false;

    while (attempts < retryCount && !success) {
      try {
        final apiKey = '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'; // Replace with actual API key
        final response = await http.post(
          Uri.parse(
              'https://api-inference.huggingface.co/models/meta-llama/Llama-3.2-1B'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'inputs': message,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data is List &&
              data.isNotEmpty &&
              data[0] is Map<String, dynamic> &&
              data[0].containsKey('generated_text')) {
            final botReply = data[0]['generated_text'] as String;

            setState(() {
              messages.add({'text': botReply, 'sender': 'bot'});
              isLoading = false;
            });
            success = true;
          } else {
            print('Unexpected response structure: $data');
          }
        } else {
          print('Attempt $attempts - Error: ${response.statusCode} - ${response.body}');
        }
      } catch (error) {
        print('Attempt $attempts - Error: $error');
      }

      attempts++;
      await Future.delayed(Duration(seconds: 2));

      if (attempts == retryCount && !success) {
        setState(() {
          messages.add({
            'text': 'Sorry, the service is currently unavailable. Please try again later.',
            'sender': 'bot'
          });
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chat with us",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                color: Colors.black,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          Divider(),
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
                      message['text'] ?? 'Error loading message',
                      style: TextStyle(
                        color: isBot ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final message = _controller.text.trim();
                      _controller.clear();
                      if (message.isNotEmpty) {
                        sendMessage(message);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

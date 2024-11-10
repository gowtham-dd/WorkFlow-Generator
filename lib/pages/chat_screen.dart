import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart'; // For clipboard functionality

import '../models/message.dart';
import '../models/messages.dart';
import '../utils/size.dart';
import '../utils/style.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _userMessage = TextEditingController();
  bool isLoading = false;
  static const apiKey = "AIzaSyAVxEAtuoQ32vaXXJIipDPRCk8qwEUrgWU";
  final List<Message> _messages = [];
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  void sendMessage() async {
    final userMessage = _userMessage.text;
    _userMessage.clear();

    setState(() {
      _messages.add(Message(
        isUser: true,
        message: userMessage,
        date: DateTime.now(),
      ));
      isLoading = true;
    });

    String prompt;

    // Check if the message contains an app name and 'workflow' request
    if (userMessage.toLowerCase().contains('workflow')) {
      // Extract the app name from the user message (assuming the app name is part of the message)
      final appName = _extractAppName(userMessage);

      // Generate the prompt dynamically based on the app name
      prompt = '''
      You are tasked with generating a **detailed workflow** for a developer working on a mobile application named **$appName**. The developer will provide the **name of the app** (e.g., "$appName") and you will generate a comprehensive, structured workflow to help the developer implement key features. The workflow should outline each **step** of the process, including **frontend actions**, **backend operations**, **data handling**, and **storage**. Provide detailed instructions and guidance on what needs to be done for each step to ensure the feature is properly implemented.

      ### Input:
      The user will provide the **name of the app** (e.g., "$appName").

      ### Output:
      Generate a **workflow in JSON format** that will guide the developer through the steps needed to implement the app. Each step should include:

      1. **Step Number**: Sequential steps, starting from step 1.
      2. **Action**: A clear action or task (e.g., "User Login", "View Products", "Send Message").
      3. **Description**: A brief explanation of what needs to be done for that step, including any frontend/backend tasks and data handling.
      4. **Backend Implementation**: Detailed instructions for backend tasks (e.g., database queries, API calls, or authentication services).
      5. **Data Handling**: The data required or processed at this step, with explanations on how to handle the data (e.g., validation, storage).
      6. **Storage/Database Operations**: Specific instructions on how to store or retrieve data (e.g., SQL query, NoSQL database interaction, file storage).

      ### Example Output:
      {
        "workflow": [
          {
            "step": 1,
            "action": "User Login",
            "description": "The user enters their credentials to log into the $appName app.",
            "backend_implementation": "Authenticate user by comparing credentials with the database. Use JWT tokens for session management.",
            "data_handling": {
              "username": "Validate the username (email format check).",
              "password": "Hash the password and compare with stored hash in the database."
            },
            "storage_operations": "Use a relational database like PostgreSQL or NoSQL database like MongoDB to store user credentials. Store JWT token in the response for session management."
          },
          {
            "step": 2,
            "action": "View Products",
            "description": "User browses through the available products in the $appName app.",
            "backend_implementation": "Fetch product data from the database through an API endpoint.",
            "data_handling": {
              "search_query": "Filter products based on user search input.",
              "product_data": "Return product data like name, price, and description."
            },
            "storage_operations": "Store product data in a NoSQL database (e.g., MongoDB) for quick retrieval, or use a relational database like MySQL for structured product data."
          }
          // Continue for other steps...
        ]
      }
      ''';
    } else {
      // Default to user message if no specific request for 'workflow'
      prompt = userMessage;
    }

    final content = [Content.text(prompt)];

    // Send the prompt to Gemini AI
    final response = await model.generateContent(content);

    setState(() {
      _messages.add(Message(
        isUser: false,
        message: response.text ?? "Error generating workflow code.",
        date: DateTime.now(),
      ));
      isLoading = false;
    });
  }

  String _extractAppName(String userMessage) {
    // You can customize this function to better capture app names from the user's input
    final appNamePattern = RegExp(r'(?<=for|named|called)\s+(\w[\w\s]+)');
    final match = appNamePattern.firstMatch(userMessage);
    return match != null
        ? match.group(1)!
        : 'App'; // Default to 'App' if not found
  }

  // Function to copy the workflow JSON to clipboard
  void copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Workflow code copied to clipboard")));
  }

  void onAnimatedTextFinished() {
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text('Chat with Gemini',
            style:
                GoogleFonts.poppins(color: white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Messages(
                  isUser: message.isUser,
                  message: message.message,
                  date: DateFormat('HH:mm').format(message.date),
                  onAnimatedTextFinished: onAnimatedTextFinished,
                );
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: medium, vertical: small),
            child: Expanded(
              flex: 20,
              child: TextFormField(
                maxLines: 6,
                minLines: 1,
                controller: _userMessage,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.fromLTRB(medium, 0, small, 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(xlarge),
                  ),
                  hintText: 'Enter topic or message...',
                  hintStyle: hintText,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      if (!isLoading && _userMessage.text.isNotEmpty) {
                        sendMessage();
                      }
                    },
                    child: isLoading
                        ? Container(
                            width: medium,
                            height: medium,
                            margin: const EdgeInsets.all(xsmall),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(white),
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward,
                            color: _userMessage.text.isNotEmpty
                                ? Colors.white
                                : const Color(0x5A6C6C65),
                          ),
                  ),
                ),
                style: promptText,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          // Add a button to copy the code
          if (_messages.isNotEmpty && !_messages.last.isUser)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  copyToClipboard(_messages.last.message);
                },
                icon: Icon(Icons.copy),
                label: Text("Copy Code"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_services.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatModel> _chats = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _chatsSubscription;

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }

  void disposeListeners() {
    _chatsSubscription?.cancel();
  }

  void loadChats(String userId) {
    _isLoading = true;
    notifyListeners();
    _chatsSubscription?.cancel();
    _chatsSubscription = _chatService.getUserChats(userId).listen((chats) {
      _chats = chats;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }
}

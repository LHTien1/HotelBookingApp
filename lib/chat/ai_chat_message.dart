class ChatMessage {
  final bool isUser;
  final String text;

  /// AI đề xuất phòng
  final String? roomId;

  /// intent: suggest | ask_date | confirm_booking | done
  final String? intent;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.roomId,
    this.intent,
  });
}

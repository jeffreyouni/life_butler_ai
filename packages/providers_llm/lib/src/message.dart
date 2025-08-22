import 'package:meta/meta.dart';

/// Message in a conversation
@immutable
class Message {
  const Message({
    required this.role,
    required this.content,
    this.name,
  });

  final MessageRole role;
  final String content;
  final String? name;

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      if (name != null) 'name': name,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      role: MessageRole.values.byName(map['role']),
      content: map['content'],
      name: map['name'],
    );
  }

  /// Create a system message
  factory Message.system(String content) {
    return Message(role: MessageRole.system, content: content);
  }

  /// Create a user message
  factory Message.user(String content) {
    return Message(role: MessageRole.user, content: content);
  }

  /// Create an assistant message
  factory Message.assistant(String content) {
    return Message(role: MessageRole.assistant, content: content);
  }

  @override
  String toString() => '${role.name}: $content';
}

enum MessageRole {
  system,
  user,
  assistant,
}

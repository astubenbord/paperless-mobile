import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

part 'ai_chat_state.dart';

class AiChatCubit extends Cubit<AiChatState> {
  final String serverUrl;
  final String apiKey;
  final Dio _dio;

  AiChatCubit({
    required this.serverUrl,
    required this.apiKey,
  })  : _dio = Dio(BaseOptions(
          baseUrl: serverUrl,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        )),
        super(const AiChatState());

  Future<void> sendMessage(String message) async {
    final userMessage = ChatMessage(role: 'user', content: message);
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    ));

    try {
      final response = await _dio.post(
        '/api/chat',
        data: jsonEncode({'message': message}),
      );

      final data = response.data;
      final content = data is Map ? (data['response'] ?? data['message'] ?? data.toString()) : data.toString();
      final references = data is Map && data['references'] != null
          ? (data['references'] as List)
              .map((r) => DocumentReference(
                    id: r['id'] ?? 0,
                    title: r['title'] ?? '',
                  ))
              .toList()
          : <DocumentReference>[];

      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: content,
        references: references,
      );

      emit(state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      ));
    } catch (e) {
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Error: ${e.toString()}',
      );
      emit(state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      ));
    }
  }

  Future<List<Map<String, dynamic>>> semanticSearch(String query) async {
    try {
      final response = await _dio.post(
        '/api/search',
        data: jsonEncode({'query': query}),
      );
      if (response.data is List) {
        return (response.data as List).cast<Map<String, dynamic>>();
      }
      if (response.data is Map && response.data['results'] != null) {
        return (response.data['results'] as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> autoClassify(int documentId) async {
    try {
      final response = await _dio.post(
        '/api/classify',
        data: jsonEncode({'document_id': documentId}),
      );
      return response.data is Map
          ? response.data as Map<String, dynamic>
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> testConnection(String serverUrl, String apiKey) async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: serverUrl,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.get('/api/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

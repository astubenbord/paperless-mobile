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
          baseUrl: serverUrl.endsWith('/') ? serverUrl : '$serverUrl/',
          headers: {
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
          followRedirects: true,
          maxRedirects: 5,
        )),
        super(const AiChatState());

  /// Sends a chat message using Paperless-AI's RAG query endpoint.
  /// Falls back to /chat/message if /api/rag/query is unavailable.
  Future<void> sendMessage(String message) async {
    final userMessage = ChatMessage(role: 'user', content: message);
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    ));

    try {
      final response = await _dio.post(
        'api/rag/query',
        data: jsonEncode({'query': message}),
      );

      final data = response.data;
      String content;
      List<DocumentReference> references = [];

      if (data is Map) {
        // RAG query response format: {answer, sources, model}
        content = data['answer'] ??
            data['response'] ??
            data['message'] ??
            data.toString();

        // Parse source documents from RAG response
        final sources = data['sources'] ?? data['references'];
        if (sources is List) {
          references = sources
              .map((r) {
                if (r is Map) {
                  return DocumentReference(
                    id: r['document_id'] ?? r['id'] ?? 0,
                    title: r['title'] ?? r['document_title'] ?? '',
                  );
                }
                return null;
              })
              .whereType<DocumentReference>()
              .toList();
        }
      } else {
        content = data.toString();
      }

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
        'api/rag/query',
        data: jsonEncode({'query': query}),
      );
      final data = response.data;
      if (data is Map && data['sources'] != null) {
        return (data['sources'] as List).cast<Map<String, dynamic>>();
      }
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> autoClassify(int documentId) async {
    try {
      final response = await _dio.post(
        'api/classify/',
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
      final baseUrl = serverUrl.endsWith('/') ? serverUrl : '$serverUrl/';
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        followRedirects: true,
        maxRedirects: 5,
      ));
      // Try the status endpoint (Node.js port 3000)
      final response = await dio.get('status');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

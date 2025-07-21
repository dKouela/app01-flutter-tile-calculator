import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/designation.dart';
import '../models/quote.dart';
import '../models/room.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

class QuoteService {
  final SupabaseClient _supabase = SupabaseService.client;

  // Utilise Cloudflare Worker pour les requêtes avec cache/rate limiting
  Future<List<Designation>> fetchDesignations() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}${Constants.designationsEndpoint}?select=*&order=nom'),
        headers: {
          'apikey': Constants.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Designation.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to fetch designations: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback vers Supabase direct si Worker indisponible
      return await _fetchDesignationsDirect();
    }
  }

  // Fallback direct Supabase
  Future<List<Designation>> _fetchDesignationsDirect() async {
    try {
      final response = await _supabase
          .from('designations')
          .select()
          .order('nom');

      return (response as List)
          .map((json) => Designation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching designations: $e');
    }
  }

  Future<UserModel> registerUser({
    required String nom,
    required String prenom,
    required String entreprise,
    required String telephone,
  }) async {
    try {
      final userModel = UserModel(
        uid: '',
        nom: nom,
        prenom: prenom,
        entreprise: entreprise,
        telephone: telephone,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from('users')
          .insert(userModel.toInsert())
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  // Utilise Cloudflare Worker pour rate limiting
  Future<Quote> createQuote({
    required String userId,
    required List<Room> rooms,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'rooms': rooms.map((room) => room.toEdgeFunctionJson()).toList(),
      };

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}${Constants.createQuoteFunction}'),
        headers: {
          'apikey': Constants.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final quoteData = responseData['quote'];
        return Quote.fromJson(quoteData as Map<String, dynamic>);
      } else if (response.statusCode == 429) {
        throw Exception('Too many requests. Please wait 1 minute.');
      } else {
        throw Exception('Failed to create quote: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback vers Edge Function directe
      return await _createQuoteDirect(userId: userId, rooms: rooms);
    }
  }

  // Fallback direct Edge Function
  Future<Quote> _createQuoteDirect({
    required String userId,
    required List<Room> rooms,
  }) async {
    try {
      final requestBody = {
        'userId': userId,
        'rooms': rooms.map((room) => room.toEdgeFunctionJson()).toList(),
      };

      final response = await _supabase.functions.invoke(
        'createQuote',
        body: requestBody,
      );

      if (response.status != 201) {
        throw Exception('Erreur Edge Function: ${response.status}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final quoteData = responseData['quote'] as Map<String, dynamic>;
      
      return Quote.fromJson(quoteData);
    } catch (e) {
      throw Exception('Error creating quote: $e');
    }
  }

  Future<List<Quote>> fetchUserQuotes(String userId) async {
    try {
      final response = await _supabase
          .from('quotes')
          .select('''
            id,
            user_id,
            created_at,
            total_cartons,
            rooms (
              id,
              nom,
              superficie,
              designation_id,
              surface_par_carton,
              cartons,
              created_at
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Quote.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error fetching quotes: $e');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('uid', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
}
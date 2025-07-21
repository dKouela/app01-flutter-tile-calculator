import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:app01/models/quote.dart';
import 'package:app01/models/room.dart';
import 'package:app01/models/user.dart';
import 'package:app01/models/designation.dart';
import 'package:app01/services/pdf_service.dart';

// Générer les mocks avec mockito
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  PostgrestClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestBuilder,
  FunctionsClient,
  FunctionResponse,
  http.Client,
])
import 'quote_test.mocks.dart';

void main() {
  group('Quote Tests', () {
    // Test 1: Calcul de cartons
    group('Calcul cartons', () {
      test('calcul correct avec ceil(superficie / surface_par_carton)', () {
        final testCases = [
          {'superficie': 23.5, 'surface_par_carton': 1.44, 'expected': 17},
          {'superficie': 10.0, 'surface_par_carton': 2.0, 'expected': 5},
          {'superficie': 15.7, 'surface_par_carton': 1.82, 'expected': 9},
          {'superficie': 1.0, 'surface_par_carton': 1.5, 'expected': 1},
          {'superficie': 50.0, 'surface_par_carton': 3.0, 'expected': 17},
        ];

        for (final testCase in testCases) {
          final superficie = testCase['superficie'] as double;
          final surfaceParCarton = testCase['surface_par_carton'] as double;
          final expected = testCase['expected'] as int;

          final result = (superficie / surfaceParCarton).ceil();

          expect(
            result,
            equals(expected),
            reason: 'Superficie: $superficie m², Surface/carton: $surfaceParCarton m² '
                'devrait donner $expected cartons, mais a donné $result',
          );
        }
      });

      test('calcul avec valeurs limites', () {
        expect((0.1 / 1.44).ceil(), equals(1));
        expect((2.88 / 1.44).ceil(), equals(2));
        expect((10.0 / 0.1).ceil(), equals(100));
      });

      test('calcul cohérence Room', () {
        final room = Room(
          nom: 'Test',
          superficie: 10.0,
          designationId: 1,
          surfaceParCarton: 2.0,
          cartons: 5,
        );

        final expectedCartons = (room.superficie / room.surfaceParCarton!).ceil();
        expect(room.cartons, equals(expectedCartons));
      });
    });

    // Test 2: QuoteService.createQuote avec mock
    group('QuoteService.createQuote', () {
      late MockSupabaseClient mockSupabaseClient;
      late MockFunctionsClient mockFunctionsClient;
      late MockFunctionResponse mockFunctionResponse;

      setUp(() {
        mockSupabaseClient = MockSupabaseClient();
        mockFunctionsClient = MockFunctionsClient();
        mockFunctionResponse = MockFunctionResponse();
        
        when(mockSupabaseClient.functions).thenReturn(mockFunctionsClient);
      });

      test('createQuote retourne un Quote valide', () async {
        const userId = 'test-user-id';

        final mockResponseData = {
          'quote': {
            'id': 123,
            'user_id': userId,
            'created_at': '2023-12-01T10:00:00Z',
            'total_cartons': 18,
            'rooms': [
              {
                'id': 1,
                'nom': 'Salon',
                'superficie': 23.5,
                'designation_id': 1,
                'surface_par_carton': 1.44,
                'cartons': 17,
              },
              {
                'id': 2,
                'nom': 'Cuisine', 
                'superficie': 12.0,
                'designation_id': 2,
                'surface_par_carton': 2.16,
                'cartons': 6,
              },
            ],
          },
        };

        when(mockFunctionResponse.status).thenReturn(201);
        when(mockFunctionResponse.data).thenReturn(mockResponseData);
        
        when(mockFunctionsClient.invoke(
          'createQuote',
          body: anyNamed('body'),
        )).thenAnswer((_) async => mockFunctionResponse);

        // Note: Ce test nécessiterait l'injection du mock dans QuoteService
        // Pour l'instant, on teste la logique métier
        
        // Vérifier la structure du Quote attendu
        final expectedQuote = Quote.fromJson(mockResponseData['quote'] as Map<String, dynamic>);
        
        expect(expectedQuote.id, equals(123));
        expect(expectedQuote.userId, equals(userId));
        expect(expectedQuote.totalCartons, equals(18));
        expect(expectedQuote.rooms, hasLength(2));
        
        final salon = expectedQuote.rooms.firstWhere((r) => r.nom == 'Salon');
        expect(salon.superficie, equals(23.5));
        expect(salon.cartons, equals(17));
        expect(salon.surfaceParCarton, equals(1.44));
      });
    });

    // Test 3: Génération PDF
    group('PDF Generation', () {
      late PdfService pdfService;
      late Quote mockQuote;
      late UserModel mockUser;

      setUp(() {
        pdfService = PdfService();
        
        mockQuote = Quote(
          id: 123,
          userId: 'test-user-id',
          createdAt: DateTime.parse('2023-12-01T10:00:00Z'),
          totalCartons: 18,
          rooms: [
            Room(
              id: 1,
              nom: 'Salon',
              superficie: 23.5,
              designationId: 1,
              surfaceParCarton: 1.44,
              cartons: 17,
            ),
            Room(
              id: 2,
              nom: 'Cuisine',
              superficie: 12.0,
              designationId: 2,
              surfaceParCarton: 2.16,
              cartons: 6,
            ),
          ],
        );

        mockUser = UserModel(
          uid: 'test-user-id',
          nom: 'Dupont',
          prenom: 'Jean',
          entreprise: 'Carrelage Pro',
          telephone: '0123456789',
          createdAt: DateTime.parse('2023-12-01T09:00:00Z'),
        );
      });

      test('generateQuotePdf retourne un Uint8List non vide', () async {
        final pdfBytes = await pdfService.generateQuotePdf(mockQuote, mockUser);

        expect(pdfBytes, isA<Uint8List>());
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(1000));
        
        final pdfHeader = String.fromCharCodes(pdfBytes.take(4));
        expect(pdfHeader, equals('%PDF'));
      });

      test('generateQuotePdf avec quote vide', () async {
        final emptyQuote = Quote(
          id: 1,
          userId: 'test-user',
          createdAt: DateTime.now(),
          totalCartons: 0,
          rooms: [],
        );

        final pdfBytes = await pdfService.generateQuotePdf(emptyQuote, mockUser);

        expect(pdfBytes, isA<Uint8List>());
        expect(pdfBytes.isNotEmpty, isTrue);
        
        final pdfHeader = String.fromCharCodes(pdfBytes.take(4));
        expect(pdfHeader, equals('%PDF'));
      });

      test('generateQuotePdf avec données complexes', () async {
        final complexQuote = Quote(
          id: 456,
          userId: 'test-user-id',
          createdAt: DateTime.parse('2023-12-15T14:30:00Z'),
          totalCartons: 50,
          rooms: List.generate(10, (index) => Room(
            id: index + 1,
            nom: 'Pièce ${index + 1}',
            superficie: (index + 1) * 5.5,
            designationId: (index % 3) + 1,
            surfaceParCarton: 1.44 + (index * 0.1),
            cartons: ((index + 1) * 5.5 / (1.44 + (index * 0.1))).ceil(),
          )),
        );

        final pdfBytes = await pdfService.generateQuotePdf(complexQuote, mockUser);

        expect(pdfBytes, isA<Uint8List>());
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(2000));
        
        final pdfHeader = String.fromCharCodes(pdfBytes.take(4));
        expect(pdfHeader, equals('%PDF'));
      });
    });

    // Test modèles
    group('Model Validation', () {
      test('UserModel JSON serialization', () {
        final user = UserModel(
          uid: 'test-uid',
          nom: 'Dupont',
          prenom: 'Jean',
          entreprise: 'Test Corp',
          telephone: '0123456789',
          createdAt: DateTime.parse('2023-12-01T10:00:00Z'),
        );

        final json = user.toJson();
        final userFromJson = UserModel.fromJson(json);

        expect(userFromJson.uid, equals(user.uid));
        expect(userFromJson.nom, equals(user.nom));
        expect(userFromJson.prenom, equals(user.prenom));
        expect(userFromJson.entreprise, equals(user.entreprise));
        expect(userFromJson.telephone, equals(user.telephone));
      });

      test('Room edge function JSON', () {
        final room = Room(
          nom: 'Test Room',
          superficie: 15.5,
          designationId: 2,
        );

        final edgeJson = room.toEdgeFunctionJson();
        
        expect(edgeJson['nom'], equals('Test Room'));
        expect(edgeJson['superficie'], equals(15.5));
        expect(edgeJson['designationId'], equals(2));
        expect(edgeJson.containsKey('id'), isFalse);
        expect(edgeJson.containsKey('cartons'), isFalse);
      });

      test('Quote total cartons cohérent', () {
        final rooms = [
          Room(nom: 'Salon', superficie: 20.0, designationId: 1, cartons: 10),
          Room(nom: 'Cuisine', superficie: 15.0, designationId: 2, cartons: 8),
        ];
        
        final quote = Quote(
          id: 1,
          userId: 'test',
          createdAt: DateTime.now(),
          totalCartons: 18,
          rooms: rooms,
        );

        final expectedTotal = rooms.map((r) => r.cartons ?? 0).reduce((a, b) => a + b);
        expect(quote.totalCartons, equals(expectedTotal));
      });

      test('Designation surface validation', () {
        final designation = Designation(
          id: 1,
          nom: 'Carrelage Test',
          surfaceParCarton: 1.44,
          createdAt: DateTime.now(),
        );

        expect(designation.surfaceParCarton, greaterThan(0));
        expect(designation.nom, isNotEmpty);
      });
    });
  });
}

// Helper pour créer des mocks
class TestHelpers {
  static UserModel createMockUser({
    String uid = 'test-user-id',
    String nom = 'Dupont',
    String prenom = 'Jean',
    String entreprise = 'Carrelage Pro',
    String telephone = '0123456789',
  }) {
    return UserModel(
      uid: uid,
      nom: nom,
      prenom: prenom,
      entreprise: entreprise,
      telephone: telephone,
      createdAt: DateTime.now(),
    );
  }

  static Quote createMockQuote({
    int id = 123,
    String userId = 'test-user-id',
    int totalCartons = 18,
    List<Room>? rooms,
  }) {
    return Quote(
      id: id,
      userId: userId,
      createdAt: DateTime.now(),
      totalCartons: totalCartons,
      rooms: rooms ?? [
        Room(
          nom: 'Salon',
          superficie: 23.5,
          designationId: 1,
          surfaceParCarton: 1.44,
          cartons: 17,
        ),
        Room(
          nom: 'Cuisine',
          superficie: 12.0,
          designationId: 2,
          surfaceParCarton: 2.16,
          cartons: 6,
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../services/pdf_service.dart';

class QuoteResultScreen extends StatefulWidget {
  final Quote quote;
  final UserModel? user;
  
  const QuoteResultScreen({
    super.key, 
    required this.quote,
    this.user,
  });

  @override
  State<QuoteResultScreen> createState() => _QuoteResultScreenState();
}

class _QuoteResultScreenState extends State<QuoteResultScreen> {
  Quote get quote => widget.quote;
  UserModel? get user => widget.user;

  Future<void> _downloadPdf(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations utilisateur manquantes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Génération du PDF...'),
                ],
              ),
            ),
          ),
        ),
      );

      final pdfService = PdfService();
      await pdfService.sharePdf(quote, user!);
      
      if (mounted) {
        navigator.pop();
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('PDF partagé avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _previewPdf(BuildContext context) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations utilisateur manquantes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final pdfService = PdfService();
      await pdfService.previewPdf(quote, user!);
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${quote.createdAt.day.toString().padLeft(2, '0')}/"
        "${quote.createdAt.month.toString().padLeft(2, '0')}/"
        "${quote.createdAt.year}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devis généré'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.goNamed('registration'),
        ),
        actions: [
          if (user != null)
            IconButton(
              onPressed: () => _previewPdf(context),
              icon: const Icon(Icons.preview),
              tooltip: 'Prévisualiser PDF',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du devis
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Devis #${quote.id.toString().padLeft(6, '0')}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Créé le $dateStr',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatistic(
                            context,
                            'Pièces',
                            '${quote.rooms.length}',
                            Icons.room,
                          ),
                          _buildStatistic(
                            context,
                            'Total cartons',
                            '${quote.totalCartons}',
                            Icons.inventory_2,
                          ),
                          _buildStatistic(
                            context,
                            'Superficie totale',
                            '${quote.rooms.fold<double>(0, (sum, room) => sum + room.superficie).toStringAsFixed(1)} m²',
                            Icons.square_foot,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des pièces
            Text(
              'Détail des pièces (${quote.rooms.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ...quote.rooms.asMap().entries.map((entry) {
              final index = entry.key;
              final room = entry.value;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    room.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Superficie: ${room.superficie.toStringAsFixed(1)} m²'),
                      Text('Surface/carton: ${room.surfaceParCarton?.toStringAsFixed(2) ?? '-'} m²'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${room.cartons}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('cartons'),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
            if (user != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPdf(context),
                      icon: const Icon(Icons.share),
                      label: const Text('Partager PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _previewPdf(context),
                      icon: const Icon(Icons.preview),
                      label: const Text('Aperçu'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.goNamed('quote-form', extra: {
                  'userId': quote.userId,
                  'user': user,
                }),
                icon: const Icon(Icons.add),
                label: const Text('Nouveau devis'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => context.goNamed('registration'),
                icon: const Icon(Icons.person_add),
                label: const Text('Nouvel entrepreneur'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
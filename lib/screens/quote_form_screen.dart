import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/quote_service.dart';
import '../models/room.dart';
import '../models/designation.dart';
import '../models/user.dart';

class QuoteFormScreen extends StatefulWidget {
  final String userId;
  final UserModel? user;
  
  const QuoteFormScreen({super.key, required this.userId, this.user});

  @override
  State<QuoteFormScreen> createState() => _QuoteFormScreenState();
}

class _QuoteFormScreenState extends State<QuoteFormScreen> {
  final QuoteService _quoteService = QuoteService();
  final List<Room> _rooms = [];
  List<Designation> _designations = [];
  bool _isLoading = false;
  bool _isCreatingQuote = false;

  @override
  void initState() {
    super.initState();
    _loadDesignations();
    _addRoom();
  }

  Future<void> _loadDesignations() async {
    setState(() => _isLoading = true);
    try {
      _designations = await _quoteService.fetchDesignations();
      if (_designations.isNotEmpty && _rooms.isNotEmpty) {
        setState(() {
          for (int i = 0; i < _rooms.length; i++) {
            _rooms[i] = Room(
              nom: _rooms[i].nom,
              superficie: _rooms[i].superficie,
              designationId: _designations.first.id,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addRoom() {
    setState(() {
      _rooms.add(Room(
        nom: '',
        superficie: 0.0,
        designationId: _designations.isNotEmpty ? _designations.first.id : 1,
      ));
    });
  }

  void _removeRoom(int index) {
    if (_rooms.length > 1) {
      setState(() => _rooms.removeAt(index));
    }
  }

  Future<void> _createQuote() async {
    final validRooms = _rooms.where((room) => 
      room.nom.trim().isNotEmpty && room.superficie > 0
    ).toList();

    if (validRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid room'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCreatingQuote = true);

    try {
      final quote = await _quoteService.createQuote(
        userId: widget.userId,
        rooms: validRooms,
      );

      if (mounted) {
        context.goNamed('quote-result', extra: {
          'quote': quote,
          'user': widget.user,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingQuote = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading tile types...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quote'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goNamed('registration'),
        ),
      ),
      body: Column(
        children: [
          if (widget.user != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                'Quote for: ${widget.user!.entreprise} (${widget.user!.prenom} ${widget.user!.nom})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rooms.length,
              itemBuilder: (context, index) => _RoomCard(
                key: ValueKey('room_$index'),
                room: _rooms[index],
                designations: _designations,
                roomNumber: index + 1,
                onRemove: _rooms.length > 1 ? () => _removeRoom(index) : null,
                onChanged: (room) => setState(() => _rooms[index] = room),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _designations.isNotEmpty ? _addRoom : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une pièce'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCreatingQuote || _designations.isEmpty ? null : _createQuote,
                    icon: _isCreatingQuote 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calculate),
                    label: Text(_isCreatingQuote ? 'Création...' : 'Créer le devis'),
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

class _RoomCard extends StatefulWidget {
  final Room room;
  final List<Designation> designations;
  final int roomNumber;
  final VoidCallback? onRemove;
  final ValueChanged<Room> onChanged;

  const _RoomCard({
    super.key,
    required this.room,
    required this.designations,
    required this.roomNumber,
    this.onRemove,
    required this.onChanged,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  late TextEditingController _nomController;
  late TextEditingController _superficieController;
  late int _selectedDesignationId;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.room.nom);
    _superficieController = TextEditingController(
      text: widget.room.superficie > 0 ? widget.room.superficie.toString() : '',
    );
    _selectedDesignationId = widget.room.designationId;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _superficieController.dispose();
    super.dispose();
  }

  void _updateRoom() {
    widget.onChanged(Room(
      nom: _nomController.text.trim(),
      superficie: double.tryParse(_superficieController.text) ?? 0.0,
      designationId: _selectedDesignationId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDesignation = widget.designations
        .where((d) => d.id == _selectedDesignationId)
        .firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.room, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Pièce ${widget.roomNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de la pièce',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              onChanged: (_) => _updateRoom(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _superficieController,
              decoration: const InputDecoration(
                labelText: 'Superficie (m²)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.square_foot),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateRoom(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedDesignationId,
              decoration: const InputDecoration(
                labelText: 'Type de carreau',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grid_on),
              ),
              items: widget.designations.map((d) => DropdownMenuItem<int>(
                value: d.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.nom),
                    Text(
                      '${d.surfaceParCarton} m²/carton',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDesignationId = value);
                  _updateRoom();
                }
              },
            ),
            if (selectedDesignation != null && 
                _nomController.text.trim().isNotEmpty && 
                (double.tryParse(_superficieController.text) ?? 0) > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate),
                    const SizedBox(width: 8),
                    Text(
                      'Cartons nécessaires: ${((double.tryParse(_superficieController.text) ?? 0) / selectedDesignation.surfaceParCarton).ceil()}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
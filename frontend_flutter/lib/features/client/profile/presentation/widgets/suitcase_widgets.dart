import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/profile/data/mocks/client_profile_mocks.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/suitcase_item.dart';
import 'package:flutter/material.dart';

class SuitcaseTab extends StatefulWidget {
  const SuitcaseTab({super.key});

  @override
  State<SuitcaseTab> createState() => _SuitcaseTabState();
}

class _SuitcaseTabState extends State<SuitcaseTab> {
  String _selectedTripId = 'essentials';
  late List<SuitcaseItem> _items;

  final Map<String, String> _trips = {
    'essentials': '✨ Essenciais',
  };

  @override
  void initState() {
    super.initState();
    _items = ClientProfileMocks.suitcaseItems(_selectedTripId);
  }

  void _selectTrip(String tripId) {
    if (tripId == 'new-suitcase') {
      _showCreateSuitcaseDialog();
      return;
    }
    setState(() {
      _selectedTripId = tripId;
      _items = ClientProfileMocks.suitcaseItems(tripId);
    });
  }

  Future<void> _showCreateSuitcaseDialog() async {
    final controller = TextEditingController();
    final name = await showShadDialog<String>(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Nova Mala'),
        description: const Text('Dê um nome para sua nova mala de viagem.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ShadInput(
            controller: controller,
            placeholder: const Text('Ex: Férias na Bahia'),
            autofocus: true,
          ),
        ),
      ),
    );

    if (name != null && name.isNotEmpty) {
      final id = 'trip-${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _trips[id] = '🧳 $name';
        _selectedTripId = id;
        _items = []; // New suitcase starts empty
      });
    }
  }

  void _togglePacked(int index) {
    setState(() {
      final item = _items[index];
      _items[index] = item.copyWith(packed: !item.packed);
    });
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateItem(int index, String newName, String newCategory, int qty) {
    setState(() {
      _items[index] = _items[index].copyWith(
        name: newName,
        category: newCategory,
        quantity: qty,
      );
    });
  }

  void _addItem(String name, String category) {
    setState(() {
      _items.add(
        SuitcaseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tripId: _selectedTripId,
          category: category,
          name: name,
          packed: false,
          isSuggestion: false,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Map<String, List<_IndexedItem>> _groupedItems() {
    final result = <String, List<_IndexedItem>>{};
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      result.putIfAbsent(item.category, () => []).add(_IndexedItem(i, item));
    }
    return result;
  }

  int get _packedCount => _items.where((i) => i.packed).length;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final grouped = _groupedItems();
    final suggestions = _items.where((i) => i.isSuggestion).toList();
    final totalItems = _items.length;

    return Column(
      children: [
        // Trip selector + progress
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              // Trip dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cadife.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cadife.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedTripId,
                    dropdownColor: cadife.cardBackground,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cadife.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [
                      ..._trips.entries.map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: 'new-suitcase',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 16, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Criar nova mala...',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) _selectTrip(v);
                    },
                  ),
                ),
              ),

              if (totalItems > 0) ...[
                const SizedBox(height: 12),
                _PackingProgress(packed: _packedCount, total: totalItems),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: _items.isEmpty
              ? _EmptySuitcaseState(
                  onAddItem: () => _showAddItemSheet(context),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Suggestions section
                    if (suggestions.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: LucideIcons.sparkles,
                        title: 'Sugestões para o destino',
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 8),
                      ...suggestions.map((item) {
                        final idx = _items.indexOf(item);
                        return SuitcaseItemTile(
                          item: item,
                          onToggle: () => _togglePacked(idx),
                          onDelete: () => _deleteItem(idx),
                          onEdit: () =>
                              _showEditItemSheet(context, idx, item),
                        );
                      }),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // Categories
                    ...grouped.entries.map((entry) {
                      final category = entry.key;
                      final categoryItems = entry.value
                          .where((i) => !i.item.isSuggestion)
                          .toList();
                      if (categoryItems.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: _categoryIcon(category),
                            title: category,
                          ),
                          const SizedBox(height: 8),
                          ...categoryItems.map((indexed) {
                            return SuitcaseItemTile(
                              item: indexed.item,
                              onToggle: () => _togglePacked(indexed.index),
                              onDelete: () => _deleteItem(indexed.index),
                              onEdit: () => _showEditItemSheet(
                                  context, indexed.index, indexed.item),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
        ),

        // Add item FAB area
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CadifeButton(
              text: 'Adicionar item',
              icon: Icons.add,
              onPressed: () => _showAddItemSheet(context),
            ),
          ),
      ],
    );
  }

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(
        onSaved: (name, category) {
          _addItem(name, category);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditItemSheet(BuildContext context, int index, SuitcaseItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(
        item: item,
        onUpdated: (name, category, qty) {
          _updateItem(index, name, category, qty);
          Navigator.pop(context);
        },
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
        'Documentos' => LucideIcons.fileText,
        'Roupas' => LucideIcons.shirt,
        'Higiene' => LucideIcons.sparkles,
        'Eletrônicos' => LucideIcons.zap,
        _ => LucideIcons.package,
      };
}

// ---------------------------------------------------------------------------
// Indexed helper
// ---------------------------------------------------------------------------

class _IndexedItem {
  const _IndexedItem(this.index, this.item);
  final int index;
  final SuitcaseItem item;
}

// ---------------------------------------------------------------------------
// Suitcase item tile
// ---------------------------------------------------------------------------

class SuitcaseItemTile extends StatelessWidget {
  const SuitcaseItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    super.key,
  });

  final SuitcaseItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ShadCard(
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
        backgroundColor: isDark ? cadife.cardBackground : Colors.white,
        radius: BorderRadius.circular(12),
        border: ShadBorder.all(
          color: item.packed
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : cadife.cardBorder),
          width: 1,
        ),
        child: Row(
          children: [
            // Checkbox
            ShadCheckbox(
              value: item.packed,
              onChanged: (_) => onToggle(),
            ),
            const SizedBox(width: 8),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: item.packed
                          ? cadife.textSecondary
                          : cadife.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration:
                          item.packed ? TextDecoration.lineThrough : null,
                      decorationColor: cadife.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.isSuggestion) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Sugestão',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        'x${item.quantity}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cadife.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<_ItemAction>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: cadife.textSecondary),
              color: cadife.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cadife.divider),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ItemAction.edit,
                  child: Row(
                    children: [
                      Icon(LucideIcons.pencil,
                          size: 16, color: cadife.textPrimary),
                      const SizedBox(width: 8),
                      Text('Editar',
                          style: TextStyle(color: cadife.textPrimary)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: _ItemAction.delete,
                  child: Row(
                    children: [
                      Icon(LucideIcons.trash2,
                          size: 16, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Deletar',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (action) {
                if (action == _ItemAction.edit) onEdit();
                if (action == _ItemAction.delete) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _ItemAction { edit, delete }

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.color,
  });

  final IconData icon;
  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final effectiveColor = color ?? cadife.textSecondary;

    return Row(
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Packing progress bar
// ---------------------------------------------------------------------------

class _PackingProgress extends StatelessWidget {
  const _PackingProgress({required this.packed, required this.total});

  final int packed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : packed / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$packed / $total itens embalados',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cadife.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: progress == 1.0 ? AppColors.success : AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: cadife.muted,
            color: progress == 1.0 ? AppColors.success : AppColors.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptySuitcaseState extends StatelessWidget {
  const _EmptySuitcaseState({required this.onAddItem});

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.luggage,
              size: 64,
              color: cadife.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Mala vazia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cadife.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione os itens para sua próxima viagem',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cadife.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            CadifeButton(
              text: 'Adicionar item',
              icon: Icons.add,
              onPressed: onAddItem,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add item bottom sheet
// ---------------------------------------------------------------------------

const _categories = [
  'Documentos',
  'Roupas',
  'Higiene',
  'Eletrônicos',
  'Outros',
];

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.onSaved});

  final void Function(String name, String category) onSaved;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  String _category = _categories.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text(
                'Adicionar item',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: cadife.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome do item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cadife.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cadife.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Categoria',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cadife.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : cadife.muted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : cadife.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : cadife.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: CadifeButton(
                      text: 'Cancelar',
                      isOutline: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CadifeButton(
                      text: 'Adicionar',
                      onPressed: _nameController.text.trim().isEmpty
                          ? null
                          : () => widget.onSaved(
                                _nameController.text.trim(),
                                _category,
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit item bottom sheet
// ---------------------------------------------------------------------------

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({required this.item, required this.onUpdated});

  final SuitcaseItem item;
  final void Function(String name, String category, int qty) onUpdated;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _nameController;
  late String _category;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _category = widget.item.category;
    _quantity = widget.item.quantity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text(
                'Editar item',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cadife.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                style: TextStyle(color: cadife.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nome do item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cadife.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cadife.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity stepper
              Row(
                children: [
                  Text(
                    'Quantidade:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cadife.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(LucideIcons.minus,
                        size: 16, color: cadife.textPrimary),
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cadife.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.plus,
                        size: 16, color: cadife.textPrimary),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                'Categoria',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cadife.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : cadife.muted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : cadife.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : cadife.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: CadifeButton(
                      text: 'Cancelar',
                      isOutline: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CadifeButton(
                      text: 'Salvar',
                      onPressed: () => widget.onUpdated(
                        _nameController.text.trim(),
                        _category,
                        _quantity,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Shared sheet handle — same as in journal detail
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: context.cadife.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

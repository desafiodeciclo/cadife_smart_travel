import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/profile/domain/entities/suitcase_item.dart';
import 'package:flutter/material.dart';

class SuitcaseTab extends StatefulWidget {
  const SuitcaseTab({super.key});

  @override
  State<SuitcaseTab> createState() => _SuitcaseTabState();
}

class _SuitcaseTabState extends State<SuitcaseTab> {
  static const _categories = [
    'Documentos',
    'Roupas',
    'Higiene',
    'Eletrônicos',
    'Outros',
  ];

  final List<BagData> _bags = [
    BagData(
      name: 'Itens Essenciais',
      items: [
        SuitcaseItem(
          id: 'e1',
          tripId: 'default',
          category: 'Documentos',
          name: 'Passaporte',
          packed: true,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'e2',
          tripId: 'default',
          category: 'Documentos',
          name: 'Seguro Viagem',
          packed: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'e3',
          tripId: 'default',
          category: 'Higiene',
          name: 'Escova de Dentes',
          packed: false,
          createdAt: DateTime.now(),
        ),
        SuitcaseItem(
          id: 'e4',
          tripId: 'default',
          category: 'Roupas',
          name: 'Casaco',
          packed: false,
          createdAt: DateTime.now(),
        ),
      ],
    ),
  ];

  // ── helpers ────────────────────────────────────────────────────────────────

  Map<String, List<SuitcaseItem>> _groupByCategory(List<SuitcaseItem> items) {
    final map = <String, List<SuitcaseItem>>{};
    for (final item in items) {
      (map[item.category] ??= []).add(item);
    }
    return map;
  }

  void _togglePacked(String itemId, bool? packed) {
    setState(() {
      for (final bag in _bags) {
        final idx = bag.items.indexWhere((i) => i.id == itemId);
        if (idx != -1) {
          bag.items[idx] = bag.items[idx].copyWith(packed: packed ?? false);
          break;
        }
      }
    });
  }

  // ── dialogs ────────────────────────────────────────────────────────────────

  void _showCreateBagDialog() {
    final ctrl = TextEditingController();
    showShadDialog(
      context: context,
      builder: (ctx) => ShadDialog(
        title: const Text('Criar nova mala'),
        description: const Text('Dê um nome para identificar esta mala.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ShadButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              setState(() => _bags.add(BagData(name: name, items: [])));
              Navigator.pop(ctx);
            },
            child: const Text('Criar'),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShadInput(
            controller: ctrl,
            placeholder: const Text('Ex: Mala de Mão'),
            autofocus: true,
          ),
        ),
      ),
    );
  }

  void _showAddItemDialog(BagData bag) {
    final nameCtrl = TextEditingController();
    String category = _categories.first;

    showShadDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ShadDialog(
          title: const Text('Adicionar item'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  bag.items.add(SuitcaseItem(
                    id: 'item-${DateTime.now().millisecondsSinceEpoch}',
                    tripId: 'default',
                    category: category,
                    name: name,
                    createdAt: DateTime.now(),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Adicionar'),
            ),
          ],
          child: _ItemForm(
            nameCtrl: nameCtrl,
            categories: _categories,
            selectedCategory: category,
            onCategoryChanged: (c) => setDialogState(() => category = c),
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(BagData bag, SuitcaseItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    String category = item.category;

    showShadDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => ShadDialog(
          title: const Text('Editar item'),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ShadButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  final bagIdx = _bags.indexOf(bag);
                  final itemIdx =
                      _bags[bagIdx].items.indexWhere((i) => i.id == item.id);
                  _bags[bagIdx].items[itemIdx] =
                      item.copyWith(name: name, category: category);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
          child: _ItemForm(
            nameCtrl: nameCtrl,
            categories: _categories,
            selectedCategory: category,
            onCategoryChanged: (c) => setDialogState(() => category = c),
          ),
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        children: [
          // Lista de malas (expansion tiles)
          ..._bags.map(_buildBagTile),

          // "Nova mala" como item dentro da lista
          const SizedBox(height: 4),
          _NewBagTile(onTap: _showCreateBagDialog),
        ],
      ),
    );
  }

  // ── bag tile ───────────────────────────────────────────────────────────────

  Widget _buildBagTile(BagData bag) {
    final cadife = context.cadife;
    final packed = bag.items.where((i) => i.packed).length;
    final total = bag.items.length;
    final grouped = _groupByCategory(bag.items);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cadife.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cadife.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.luggage, color: AppColors.primary, size: 18),
          ),
          title: Text(
            bag.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: cadife.textPrimary,
            ),
          ),
          subtitle: total == 0
              ? Text(
                  'Vazia',
                  style: TextStyle(fontSize: 12, color: cadife.textSecondary),
                )
              : Text(
                  '$packed/$total itens',
                  style: TextStyle(
                    fontSize: 12,
                    color: packed == total ? AppColors.success : cadife.textSecondary,
                    fontWeight: packed == total ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
          children: [
            // Barra de progresso se houver itens
            if (total > 0) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: packed / total,
                    minHeight: 4,
                    backgroundColor: cadife.muted,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ),
              Divider(height: 1, color: cadife.cardBorder),
            ],

            // Itens agrupados por categoria
            ..._buildGroupedItems(bag, grouped),

            // Botão "Adicionar item" dentro da mala
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ShadButton.outline(
                width: double.infinity,
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.plus, size: 14),
                onPressed: () => _showAddItemDialog(bag),
                child: const Text('Adicionar item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedItems(
    BagData bag,
    Map<String, List<SuitcaseItem>> grouped,
  ) {
    final cadife = context.cadife;
    final widgets = <Widget>[];

    for (final category in grouped.keys) {
      // Cabeçalho de categoria
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            category.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: cadife.textSecondary,
            ),
          ),
        ),
      );

      // Itens da categoria
      for (final item in grouped[category]!) {
        widgets.add(_buildItemRow(bag, item));
      }

      widgets.add(Divider(height: 1, indent: 16, endIndent: 16, color: cadife.cardBorder));
    }

    // Remove o último divisor extra
    if (widgets.isNotEmpty) widgets.removeLast();

    return widgets;
  }

  Widget _buildItemRow(BagData bag, SuitcaseItem item) {
    final cadife = context.cadife;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Checkbox com estilo
          SizedBox(
            width: 40,
            height: 40,
            child: Checkbox(
              value: item.packed,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (v) => _togglePacked(item.id, v),
            ),
          ),

          // Nome do item
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 14,
                color: item.packed ? cadife.textSecondary : cadife.textPrimary,
                decoration: item.packed ? TextDecoration.lineThrough : null,
                decorationColor: cadife.textSecondary,
              ),
            ),
          ),

          // Botão editar
          IconButton(
            icon: Icon(LucideIcons.pencil, size: 14, color: cadife.textSecondary),
            onPressed: () => _showEditItemDialog(bag, item),
            tooltip: 'Editar item',
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

// ─── Tile "Nova mala" (dentro da lista) ──────────────────────────────────────

class _NewBagTile extends StatelessWidget {
  final VoidCallback onTap;

  const _NewBagTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.plus, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'Criar nova mala',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulário de item (nome + categoria) ────────────────────────────────────

class _ItemForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const _ItemForm({
    required this.nameCtrl,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cadife = context.cadife;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShadInput(
          controller: nameCtrl,
          placeholder: const Text('Nome do item'),
          autofocus: true,
        ),
        const SizedBox(height: 14),
        Text(
          'Categoria',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cadife.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: categories.map((cat) {
            final selected = cat == selectedCategory;
            return GestureDetector(
              onTap: () => onCategoryChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : cadife.muted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : cadife.cardBorder,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : cadife.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Model local ─────────────────────────────────────────────────────────────

class BagData {
  final String name;
  final List<SuitcaseItem> items;

  BagData({required this.name, required this.items});
}

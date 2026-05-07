import 'package:cadife_smart_travel/design_system/design_system.dart';

import 'package:flutter/material.dart';


class OffersFilterSheet extends StatefulWidget {
  final List<String> initialCategories;
  final double initialMinPrice;
  final double initialMaxPrice;

  const OffersFilterSheet({
    required this.initialCategories,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    super.key,
  });

  @override
  State<OffersFilterSheet> createState() => _OffersFilterSheetState();
}

class _OffersFilterSheetState extends State<OffersFilterSheet> {
  late List<String> _selectedCategories;
  late double _minPrice;
  late double _maxPrice;

  final _availableCategories = [
    'Sol & Praia',
    'Neve & Frio',
    'Urbano & Cultura',
    'Aventura & Natureza',
    'Cruzeiro'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.initialCategories);
    _minPrice = widget.initialMinPrice;
    _maxPrice = widget.initialMaxPrice;
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtros',
                  style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Categorias
            Text(
              'Categorias',
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCategories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return InkWell(
                  onTap: () => _toggleCategory(category),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.border,
                      ),
                    ),
                    child: Text(
                      category,
                      style: theme.textTheme.small.copyWith(
                        color: isSelected ? Colors.white : theme.colorScheme.foreground,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            // Faixa de Preço
            Text(
              'Faixa de Preço',
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('R\$ ${_minPrice.toInt()}'),
                Text('R\$ ${_maxPrice.toInt()}'),
              ],
            ),
            RangeSlider(
              values: RangeValues(_minPrice, _maxPrice),
              min: 0,
              max: 50000,
              divisions: 100,
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.colorScheme.border,
              onChanged: (values) {
                setState(() {
                  _minPrice = values.start;
                  _maxPrice = values.end;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Botões
            Row(
              children: [
                Expanded(
                  child: CadifeButton(
                    label: 'Limpar',
                    isOutline: true,
                    onPressed: () {
                      Navigator.of(context).pop({
                        'categories': <String>[],
                        'minPrice': 0.0,
                        'maxPrice': 50000.0,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CadifeButton(
                    label: 'Aplicar',
                    onPressed: () {
                      Navigator.of(context).pop({
                        'categories': _selectedCategories,
                        'minPrice': _minPrice,
                        'maxPrice': _maxPrice,
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

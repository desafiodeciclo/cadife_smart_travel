import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class OffersFilterSheet extends StatefulWidget {
  final String? initialDestination;
  final List<String> initialCategories;
  final double initialMinPrice;
  final double initialMaxPrice;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const OffersFilterSheet({
    required this.initialCategories,
    required this.initialMinPrice,
    required this.initialMaxPrice,
    this.initialDestination,
    this.initialStartDate,
    this.initialEndDate,
    super.key,
  });

  @override
  State<OffersFilterSheet> createState() => _OffersFilterSheetState();
}

class _OffersFilterSheetState extends State<OffersFilterSheet> {
  String? _selectedDestination;
  late List<String> _selectedCategories;
  late double _minPrice;
  late double _maxPrice;
  DateTime? _startDate;
  DateTime? _endDate;

  final _availableDestinations = [
    'Maldivas', 'Paris', 'Gramado', 'Cancún', 'Tóquio', 
    'Nova York', 'Alpes Suíços', 'Patagônia', 'Caribe', 'Dubai'
  ];

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
    _selectedDestination = widget.initialDestination;
    _selectedCategories = List.from(widget.initialCategories);
    _minPrice = widget.initialMinPrice;
    _maxPrice = widget.initialMaxPrice;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
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

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final cadife = context.cadife;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: cadife.primary,
              onPrimary: Colors.white,
              surface: cadife.cardBackground,
              onSurface: cadife.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cadife = context.cadife;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: cadife.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cadife.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtros',
                        style: theme.textTheme.h4.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cadife.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cadife.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Destino
                  _buildSectionTitle(theme, cadife, 'Destino'),
                  const SizedBox(height: 12),
                  ShadSelect<String>(
                    placeholder: Text('Selecione o destino', style: TextStyle(color: cadife.textSecondary)),
                    initialValue: _selectedDestination,
                    options: _availableDestinations.map((d) => ShadOption(
                      value: d, 
                      child: Text(d, style: TextStyle(color: cadife.textPrimary)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDestination = v),
                    selectedOptionBuilder: (context, value) => Text(value, style: TextStyle(color: cadife.textPrimary)),
                  ),
                  const SizedBox(height: 24),

                  // Faixa de Preço
                  _buildSectionTitle(theme, cadife, 'Faixa de Preço'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('R\$ ${_minPrice.toInt()}', style: theme.textTheme.small.copyWith(color: cadife.textSecondary)),
                      Text('R\$ ${_maxPrice.toInt()}', style: theme.textTheme.small.copyWith(color: cadife.textSecondary)),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 50000,
                    divisions: 100,
                    activeColor: cadife.primary,
                    inactiveColor: cadife.muted,
                    onChanged: (values) {
                      setState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Data
                  _buildSectionTitle(theme, cadife, 'Período da Viagem'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: cadife.divider),
                        borderRadius: BorderRadius.circular(12),
                        color: cadife.muted.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 18, color: cadife.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            _startDate == null || _endDate == null
                                ? 'Selecionar datas'
                                : '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                            style: theme.textTheme.small.copyWith(
                              color: _startDate == null ? cadife.textSecondary : cadife.textPrimary,
                              fontWeight: _startDate == null ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tipo de Viagem
                  _buildSectionTitle(theme, cadife, 'Tipo de Viagem'),
                  const SizedBox(height: 12),
                  ..._availableCategories.map((category) {
                    final isSelected = _selectedCategories.contains(category);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _toggleCategory(category),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            ShadCheckbox(
                              value: isSelected,
                              onChanged: (v) => _toggleCategory(category),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category,
                              style: theme.textTheme.small.copyWith(
                                color: isSelected ? cadife.textPrimary : cadife.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
                              'destination': null,
                              'categories': <String>[],
                              'minPrice': 0.0,
                              'maxPrice': 50000.0,
                              'startDate': null,
                              'endDate': null,
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
                              'destination': _selectedDestination,
                              'categories': _selectedCategories,
                              'minPrice': _minPrice,
                              'maxPrice': _maxPrice,
                              'startDate': _startDate,
                              'endDate': _endDate,
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ShadThemeData theme, CadifeThemeExtension cadife, String title) {
    return Text(
      title,
      style: theme.textTheme.p.copyWith(
        fontWeight: FontWeight.w700,
        color: cadife.textPrimary,
      ),
    );
  }
}

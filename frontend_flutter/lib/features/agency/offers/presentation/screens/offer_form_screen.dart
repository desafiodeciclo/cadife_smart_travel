import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:cadife_smart_travel/features/client/offers/data/repositories/offer_repository.dart';
import 'package:cadife_smart_travel/features/client/offers/presentation/providers/offers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OfferFormScreen extends ConsumerStatefulWidget {
  final String? offerId;

  const OfferFormScreen({super.key, this.offerId});

  @override
  ConsumerState<OfferFormScreen> createState() => _OfferFormScreenState();
}

class _OfferFormScreenState extends ConsumerState<OfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _travelersController = TextEditingController(text: '1');
  final _spotsController = TextEditingController(text: '10');
  final _accommodationsController = TextEditingController();
  final _servicesController = TextEditingController();
  final _highlightsController = TextEditingController();

  DateTime _departureDate = DateTime.now().add(const Duration(days: 30));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 37));
  DateTime _deadline = DateTime.now().add(const Duration(days: 15));

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _destController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _travelersController.dispose();
    _spotsController.dispose();
    _accommodationsController.dispose();
    _servicesController.dispose();
    _highlightsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.offerId == null ? 'NOVA OFERTA' : 'EDITAR OFERTA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionTitle('INFORMAÇÕES BÁSICAS'),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Título da Oferta'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destController,
                    decoration: const InputDecoration(labelText: 'Destino'),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Descrição Detalhada'),
                    maxLines: 4,
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('PREÇO E VAGAS'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Preço Base (R\$)', prefixText: 'R\$ '),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Obrigatório';
                            if (double.tryParse(v) == null) return 'Valor inválido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _travelersController,
                          decoration: const InputDecoration(labelText: 'Pessoas/Pacote'),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Obrigatório';
                            if (int.tryParse(v) == null) return 'Inválido';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _spotsController,
                    decoration: const InputDecoration(labelText: 'Vagas Totais'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obrigatório';
                      if (int.tryParse(v) == null) return 'Inválido';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('DATAS'),
                  _buildDateTile(
                    label: 'Data de Saída',
                    value: _departureDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    onPicked: (d) => setState(() => _departureDate = d),
                  ),
                  _buildDateTile(
                    label: 'Data de Retorno',
                    value: _returnDate,
                    firstDate: _departureDate,
                    lastDate: _departureDate.add(const Duration(days: 90)),
                    onPicked: (d) => setState(() => _returnDate = d),
                  ),
                  _buildDateTile(
                    label: 'Prazo de Inscrição',
                    value: _deadline,
                    firstDate: DateTime.now(),
                    lastDate: _departureDate,
                    onPicked: (d) => setState(() => _deadline = d),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('DETALHES DO PACOTE'),
                  TextFormField(
                    controller: _accommodationsController,
                    decoration: const InputDecoration(
                      labelText: 'Acomodações',
                      hintText: 'Resort 5 estrelas, all-inclusive (separe por vírgula)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _servicesController,
                    decoration: const InputDecoration(
                      labelText: 'Serviços Inclusos',
                      hintText: 'Aéreo, transfer, seguro viagem (separe por vírgula)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _highlightsController,
                    decoration: const InputDecoration(
                      labelText: 'Destaques',
                      hintText: 'Oferta exclusiva, Promoção limitada (separe por vírgula)',
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(56),
                    ),
                    child: const Text('SALVAR OFERTA'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.zinc500,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime value,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${value.day}/${value.month}/${value.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value.isBefore(firstDate) ? firstDate : value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  List<String> _parseCommaSeparated(String raw) {
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final accommodations = _accommodationsController.text.isNotEmpty
          ? _parseCommaSeparated(_accommodationsController.text)
          : ['Hotel Padrão'];
      final services = _servicesController.text.isNotEmpty
          ? _parseCommaSeparated(_servicesController.text)
          : ['Passagem Aérea', 'Seguro Viagem'];
      final highlights = _highlightsController.text.isNotEmpty
          ? _parseCommaSeparated(_highlightsController.text)
          : ['Viagem especial'];

      final data = {
        'title': _titleController.text,
        'destination': _destController.text,
        'description': _descController.text,
        'base_price': double.parse(_priceController.text),
        'travelers': int.parse(_travelersController.text),
        'available_spots': int.parse(_spotsController.text),
        'departure_date': _departureDate.toIso8601String(),
        'return_date': _returnDate.toIso8601String(),
        'booking_deadline': _deadline.toIso8601String(),
        'accommodations': accommodations,
        'included_services': services,
        'highlights': highlights,
      };

      if (widget.offerId == null) {
        await ref.read(offerRepositoryProvider).createOffer(data);
      } else {
        await ref.read(offerRepositoryProvider).updateOffer(widget.offerId!, data);
      }

      if (mounted) {
        ref.invalidate(myOffersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.offerId == null ? 'Oferta criada com sucesso!' : 'Oferta atualizada com sucesso!'),
          ),
        );
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

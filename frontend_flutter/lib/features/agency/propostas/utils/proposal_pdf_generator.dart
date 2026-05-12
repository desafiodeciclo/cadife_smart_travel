import 'dart:typed_data';

import 'package:cadife_smart_travel/features/agency/propostas/domain/entities/proposta.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Cadife brand colors in PDF space (0.0–1.0)
const _kPrimary = PdfColor(0.867, 0.043, 0.055); // #DD0B0E
const _kGraphite = PdfColor(0.224, 0.208, 0.196); // #393532
const _kLight = PdfColor(0.965, 0.965, 0.965);
const _kWhite = PdfColors.white;
const _kGray = PdfColor(0.447, 0.447, 0.467); // zinc600

final _dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
final _currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ProposalPdfData {
  const ProposalPdfData({
    required this.titulo,
    required this.destinos,
    required this.dataSaida,
    required this.dataRetorno,
    required this.numAdultos,
    required this.numCriancas,
    required this.servicosInclusos,
    required this.valorTotal,
    required this.condicoesPagamento,
    required this.validadeProposta,
    required this.observacoesGerais,
    required this.nomeConsultor,
    required this.versao,
    this.assinatura,
  });

  final String titulo;
  final List<String> destinos;
  final DateTime? dataSaida;
  final DateTime? dataRetorno;
  final int numAdultos;
  final int numCriancas;
  final List<ServicoIncluso> servicosInclusos;
  final double valorTotal;
  final String condicoesPagamento;
  final DateTime? validadeProposta;
  final String observacoesGerais;
  final String nomeConsultor;
  final int versao;
  final AssinaturaDigital? assinatura;
}

Future<Uint8List> generateProposalPdf(ProposalPdfData data) async {
  final doc = pw.Document(
    title: data.titulo,
    author: data.nomeConsultor,
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(20 * PdfPageFormat.mm, 16 * PdfPageFormat.mm, 20 * PdfPageFormat.mm, 20 * PdfPageFormat.mm),
      header: (context) => _buildHeader(data),
      footer: (context) => _buildFooter(context, data),
      build: (context) => [
        pw.SizedBox(height: 8),
        _buildHeroSection(data),
        pw.SizedBox(height: 16),
        _buildTravelInfo(data),
        pw.SizedBox(height: 16),
        _buildServicesSection(data),
        pw.SizedBox(height: 16),
        _buildFinancialSection(data),
        if (data.observacoesGerais.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _buildObservacoes(data),
        ],
        pw.SizedBox(height: 24),
        _buildSignatureSection(data),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _buildHeader(ProposalPdfData data) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _kPrimary, width: 2)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'CADIFE TOUR',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            pw.Text(
              'Turismo Premium',
              style: const pw.TextStyle(fontSize: 10, color: _kGray),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'PROPOSTA COMERCIAL',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _kGraphite,
              ),
            ),
            pw.Text(
              'Versão ${data.versao} • Emitida em ${_dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: _kGray),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildHeroSection(ProposalPdfData data) {
  final destinoText = data.destinos.isNotEmpty
      ? data.destinos.join(' • ')
      : 'Destino a definir';
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: const pw.BoxDecoration(
      color: _kGraphite,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          data.titulo,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _kWhite,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          destinoText,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _kPrimary,
          ),
        ),
        if (data.dataSaida != null && data.dataRetorno != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            '${_dateFmt.format(data.dataSaida!)} → ${_dateFmt.format(data.dataRetorno!)}',
            style: const pw.TextStyle(fontSize: 10, color: _kLight),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _buildTravelInfo(ProposalPdfData data) {
  final duration = (data.dataSaida != null && data.dataRetorno != null)
      ? data.dataRetorno!.difference(data.dataSaida!).inDays
      : null;
  final passageiros = data.numAdultos + data.numCriancas;

  return _sectionCard(
    title: 'INFORMAÇÕES DA VIAGEM',
    child: pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(children: [
          _infoCell('Passageiros', '$passageiros (${data.numAdultos} adulto${data.numAdultos != 1 ? 's' : ''}, ${data.numCriancas} criança${data.numCriancas != 1 ? 's' : ''})'),
          _infoCell('Duração', duration != null ? '$duration dias' : '—'),
          _infoCell('Validade da Proposta', data.validadeProposta != null ? _dateFmt.format(data.validadeProposta!) : '—'),
        ]),
      ],
    ),
  );
}

pw.Widget _buildServicesSection(ProposalPdfData data) {
  return _sectionCard(
    title: 'SERVIÇOS INCLUSOS',
    child: pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ServicoIncluso.values.map((s) {
        final included = data.servicosInclusos.contains(s);
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: pw.BoxDecoration(
            color: included ? _kPrimary : _kLight,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                included ? '✓ ' : '○ ',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: included ? _kWhite : _kGray,
                ),
              ),
              pw.Text(
                s.label,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: included ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: included ? _kWhite : _kGray,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

pw.Widget _buildFinancialSection(ProposalPdfData data) {
  return _sectionCard(
    title: 'VALORES E CONDIÇÕES',
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: const pw.BoxDecoration(
            color: _kPrimary,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'VALOR TOTAL',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                ),
              ),
              pw.Text(
                _currencyFmt.format(data.valorTotal),
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                ),
              ),
            ],
          ),
        ),
        if (data.condicoesPagamento.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Condições de Pagamento',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _kGraphite,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            data.condicoesPagamento,
            style: const pw.TextStyle(fontSize: 9, color: _kGray),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _buildObservacoes(ProposalPdfData data) {
  return _sectionCard(
    title: 'OBSERVAÇÕES GERAIS',
    child: pw.Text(
      data.observacoesGerais,
      style: const pw.TextStyle(fontSize: 9, color: _kGray),
    ),
  );
}

pw.Widget _buildSignatureSection(ProposalPdfData data) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kLight, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Consultor Responsável',
              style: const pw.TextStyle(fontSize: 8, color: _kGray),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              data.nomeConsultor,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _kGraphite,
              ),
            ),
            if (data.assinatura != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                'Assinado em ${_dateFmt.format(data.assinatura!.timestamp)}',
                style: const pw.TextStyle(fontSize: 8, color: _kGray),
              ),
              pw.Text(
                'Hash: ${data.assinatura!.hash.substring(0, 16)}...',
                style: const pw.TextStyle(fontSize: 7, color: _kGray),
              ),
            ],
          ],
        ),
        pw.Container(
          width: 120,
          height: 40,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _kGray, width: 0.5),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            data.assinatura?.textoAssinatura ?? data.nomeConsultor,
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: _kGraphite,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildFooter(pw.Context context, ProposalPdfData data) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _kLight, width: 1)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Cadife Tour • contato@cadife.com.br • www.cadife.com.br',
          style: const pw.TextStyle(fontSize: 7, color: _kGray),
        ),
        pw.Text(
          'Pág. ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7, color: _kGray),
        ),
      ],
    ),
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────

pw.Widget _sectionCard({required String title, required pw.Widget child}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _kLight, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _kPrimary,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 8),
        child,
      ],
    ),
  );
}

pw.Widget _infoCell(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(right: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: _kGray)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _kGraphite,
          ),
        ),
      ],
    ),
  );
}

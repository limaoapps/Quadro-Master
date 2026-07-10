import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../models/resultado_projeto.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta PDF — Navy #0B1B3D / Laranja #FF7A00 / Branco
// ─────────────────────────────────────────────────────────────────────────────
const _pNavy   = PdfColor.fromInt(0xFF0B1B3D);
const _pOrange = PdfColor.fromInt(0xFFFF7A00);
const _pGreen  = PdfColor.fromInt(0xFF28A745);
const _pYellow = PdfColor.fromInt(0xFFFFC107);
const _pRed    = PdfColor.fromInt(0xFFDC3545);
const _pGrey50 = PdfColor.fromInt(0xFFF8F9FA);
const _pGrey10 = PdfColor.fromInt(0xFFF1F3F5);
const _pWhite  = PdfColors.white;
const _pBlack  = PdfColor.fromInt(0xFF212529);
const _pGrey6  = PdfColors.grey600;
const _pGrey4  = PdfColors.grey400;

// ─────────────────────────────────────────────────────────────────────────────
// RelatorioScreen
// ─────────────────────────────────────────────────────────────────────────────
class RelatorioScreen extends StatelessWidget {
  final Projeto projeto;
  const RelatorioScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final resultado = prov.resultado;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16, 16, 16,
          MediaQuery.of(context).viewPadding.bottom + 100,
        ),
        child: Column(
          children: [
            _buildPreview(context, resultado),
            const SizedBox(height: 20),
            if (resultado != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _gerarPdf(context),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar PDF / Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _compartilhar(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar Relatório'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Preview Flutter
  // ──────────────────────────────────────────────────────────────
  Widget _buildPreview(BuildContext context, ResultadoProjeto? resultado) {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _previewHeader(now),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _previewEmpresas(),
                const SizedBox(height: 12),
                _previewDadosProjeto(now),
                const SizedBox(height: 12),
                if (resultado != null) ...[
                  _previewPainelResumo(resultado),
                  const SizedBox(height: 12),
                  _previewSecaoLabel('TABELA DE CARGAS', numero: '4'),
                  const SizedBox(height: 6),
                  _buildTabelaCircuitos(),
                  const SizedBox(height: 12),
                  _previewSecaoLabel('MEMORIAL DE CÁLCULO', numero: '5'),
                  const SizedBox(height: 6),
                  _previewMemorial(resultado),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cadastre cargas para gerar o relatório completo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _previewFooter(),
        ],
      ),
    );
  }

  Widget _previewHeader(String now) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      color: const Color(0xFF0B1B3D),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLogoWidget(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUADRO MASTER',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Text('ABNT NBR 5410',
                  style: TextStyle(color: Color(0xFFFF7A00), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('RELATÓRIO TÉCNICO DE DIMENSIONAMENTO ELÉTRICO',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 9, fontWeight: FontWeight.w600)),
                Text(projeto.nome,
                  style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _headerInfoRow('Data', now),
                _headerInfoRow('Rev.', '00'),
                _headerInfoRow('Norma', 'NBR 5410'),
                _headerInfoRow('Sistema', projeto.numFases.label.split('–').first.trim()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoWidget({double size = 44}) {
    if (projeto.executora.logoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(projeto.executora.logoBase64);
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.memory(bytes, fit: BoxFit.cover, alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _defaultLogoWidget(size)),
          ),
        );
      } catch (_) {}
    }
    return _defaultLogoWidget(size);
  }

  Widget _defaultLogoWidget(double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: const Color(0xFFFF7A00), borderRadius: BorderRadius.circular(8)),
    child: Center(child: Icon(Icons.electric_bolt, color: Colors.white, size: size * 0.55)),
  );

  Widget _headerInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 8)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _previewSecaoLabel(String titulo, {required String numero}) {
    return Row(children: [
      Container(
        width: 18, height: 18,
        decoration: const BoxDecoration(color: Color(0xFFFF7A00), shape: BoxShape.circle),
        child: Center(
          child: Text(numero, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(width: 6),
      Text(titulo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0B1B3D), letterSpacing: 0.5)),
      const SizedBox(width: 8),
      const Expanded(child: Divider(color: Color(0xFFFF7A00), thickness: 1.5)),
    ]);
  }

  Widget _previewEmpresas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewSecaoLabel('DADOS DAS EMPRESAS', numero: '1'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _empresaCard(
              titulo: 'EMPRESA EXECUTADORA',
              icon: Icons.engineering,
              linhas: [
                if (projeto.executora.razaoSocial.isNotEmpty) ('Razão Social', projeto.executora.razaoSocial),
                if (projeto.executora.documento.isNotEmpty) ('CNPJ', projeto.executora.documento),
                if (projeto.executora.registro.isNotEmpty) (_cargoRegistroLabel(projeto.executora.cargo), projeto.executora.registro),
                if (projeto.executora.responsavel.isNotEmpty) ('Responsável', projeto.executora.responsavel),
                if (projeto.executora.telefone.isNotEmpty) ('Telefone', projeto.executora.telefone),
                if (projeto.executora.email.isNotEmpty) ('E-mail', projeto.executora.email),
              ],
              temLogo: projeto.executora.logoBase64.isNotEmpty,
            )),
            const SizedBox(width: 8),
            Expanded(child: _empresaCard(
              titulo: 'EMPRESA CONTRATANTE',
              icon: Icons.business,
              linhas: [
                if (projeto.contratante.razaoSocial.isNotEmpty) ('Razão Social', projeto.contratante.razaoSocial),
                if (projeto.contratante.documento.isNotEmpty) ('CNPJ', projeto.contratante.documento),
                if (projeto.contratante.responsavel.isNotEmpty) ('Responsável', projeto.contratante.responsavel),
                if (projeto.contratante.telefone.isNotEmpty) ('Telefone', projeto.contratante.telefone),
                if (projeto.contratante.email.isNotEmpty) ('E-mail', projeto.contratante.email),
                if (projeto.contratante.art.isNotEmpty) ('ART Nº', projeto.contratante.art),
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _empresaCard({
    required String titulo,
    required List<(String, String)> linhas,
    bool temLogo = false,
    IconData icon = Icons.business,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(0xFFFF7A00), width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 10, color: const Color(0xFFFF7A00)),
            const SizedBox(width: 4),
            Text(titulo, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                color: Color(0xFFFF7A00), letterSpacing: 0.5)),
          ]),
          if (temLogo) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(base64Decode(projeto.executora.logoBase64),
                height: 28, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ],
          const SizedBox(height: 6),
          if (linhas.isEmpty)
            const Text('(não configurado)',
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontStyle: FontStyle.italic))
          else
            ...linhas.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 60, child: Text('${l.$1}:', style: const TextStyle(fontSize: 8, color: AppColors.textSecondary))),
                Expanded(child: Text(l.$2,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis)),
              ]),
            )),
        ],
      ),
    );
  }

  Widget _previewDadosProjeto(String now) {
    final items = [
      (Icons.edit_document,       'Tipo do Quadro',   projeto.tipoQuadro.label),
      (Icons.location_on,         'Local',            projeto.contratante.cidade.isNotEmpty ? projeto.contratante.cidade : '—'),
      (Icons.flash_on,            'Tensão',           '${projeto.tensao.valor.toStringAsFixed(0)} V'),
      (Icons.electrical_services, 'Número de Fases',  projeto.numFases.label),
      (Icons.speed,               'Frequência',       '60 Hz'),
      (Icons.shield_outlined,     'Aterramento',      'TN-S'),
      (Icons.calendar_today,      'Data de Emissão',  now),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewSecaoLabel('DADOS DO PROJETO', numero: '2'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: const Border(left: BorderSide(color: Color(0xFFFF7A00), width: 2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(item.$1, size: 10, color: const Color(0xFFFF7A00)),
              const SizedBox(width: 4),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.$2, style: const TextStyle(fontSize: 7, color: AppColors.textSecondary)),
                Text(item.$3, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              ]),
            ]),
          )).toList(),
        ),
      ],
    );
  }

  Widget _previewPainelResumo(ResultadoProjeto r) {
    final cards = [
      ('P. Instalada',  '${r.totalPotenciaAtiva.toStringAsFixed(1)} kW',  _statusColor(r.totalPotenciaAtiva > 0 ? 'ok' : 'warn')),
      ('P. Demandada',  '${r.totalPotenciaDemandada.toStringAsFixed(1)} kW', AppColors.primary),
      ('I. Projeto',    '${r.correnteProjeto.toStringAsFixed(1)} A',       _statusColor(r.utilizacaoDisjuntor > 95 ? 'error' : r.utilizacaoDisjuntor > 85 ? 'warn' : 'ok')),
      ('Disj. Geral',   '${r.disjuntorPolos}P × ${r.disjuntorGeral}A',    _statusColor(r.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error' : 'ok')),
      ('FP Médio',      r.fatorPotenciaMedio.toStringAsFixed(3),           _statusColor(r.fatorPotenciaMedio >= 0.92 ? 'ok' : 'warn')),
      ('Circuitos',     '${r.numCircuitos}',                               AppColors.secondary),
      ('Índice Geral',  '${r.indiceGeral.toStringAsFixed(0)}/100',         _statusColor(r.indiceGeral >= 75 ? 'ok' : r.indiceGeral >= 45 ? 'warn' : 'error')),
      ('Res. Quadro',   '${r.percentReservaQuadro.toStringAsFixed(0)}%',   _statusColor(r.percentReservaQuadro >= 20 ? 'ok' : 'warn')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewSecaoLabel('PAINEL DE RESULTADOS', numero: '3'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: cards.map((c) => Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border(top: BorderSide(color: c.$3, width: 2.5)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.$3), overflow: TextOverflow.ellipsis),
              Text(c.$1, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
            ]),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTabelaCircuitos() {
    final cargas = projeto.cargas.where((c) => c.ativo).toList();
    if (cargas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhuma carga cadastrada.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      );
    }
    final hdrStyle = const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white);
    final cellStyle = const TextStyle(fontSize: 8, color: AppColors.textPrimary);

    Widget hdrCell(String t, {int flex = 1}) => Expanded(flex: flex, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(t, style: hdrStyle, overflow: TextOverflow.ellipsis),
    ));

    Widget cell(String t, {int flex = 1, bool bold = false}) => Expanded(flex: flex, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Text(t, style: bold ? const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textPrimary) : cellStyle, overflow: TextOverflow.ellipsis),
    ));

    return Column(
      children: [
        Container(
          color: const Color(0xFF0B1B3D),
          child: Row(children: [
            hdrCell('Circ.', flex: 1),
            hdrCell('Descrição', flex: 3),
            hdrCell('Pot. (W)', flex: 2),
            hdrCell('I (A)', flex: 2),
            hdrCell('Tensão', flex: 2),
            hdrCell('Disj.', flex: 2),
            hdrCell('DR', flex: 2),
          ]),
        ),
        ...cargas.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Container(
            color: i.isOdd ? const Color(0xFFF8F9FA) : Colors.white,
            child: Row(children: [
              cell('C${(i + 1).toString().padLeft(2, '0')}', flex: 1),
              cell(c.motorReserva ? '${c.descricao} ⏸' : c.descricao, flex: 3, bold: true),
              cell(c.motorReserva ? '(reserva)' : c.potenciaAtiva.toStringAsFixed(0), flex: 2),
              cell(c.corrente.toStringAsFixed(2), flex: 2),
              cell('${c.tensao.toStringAsFixed(0)} V', flex: 2),
              cell('${c.disjuntorSugerido}A', flex: 2),
              cell(c.utilizaDR ? c.drTexto : '—', flex: 2),
            ]),
          );
        }),
      ],
    );
  }

  Widget _previewMemorial(ResultadoProjeto r) {
    final itens = [
      ('Potência Instalada',     '${r.totalPotenciaAtiva.toStringAsFixed(3)} kW'),
      ('Potência Demandada',     '${r.totalPotenciaDemandada.toStringAsFixed(3)} kW'),
      ('Potência Aparente',      '${r.totalPotenciaAparente.toStringAsFixed(3)} kVA'),
      ('Fator de Potência Médio', r.fatorPotenciaMedio.toStringAsFixed(3)),
      ('Corrente de Projeto (×1,25)', '${r.correnteProjeto.toStringAsFixed(2)} A'),
      ('Corrente Total',         '${r.correnteTotal.toStringAsFixed(2)} A'),
      ('Corrente Fase A',        '${r.correnteFaseA.toStringAsFixed(2)} A'),
      ('Corrente Fase B',        '${r.correnteFaseB.toStringAsFixed(2)} A'),
      ('Corrente Fase C',        '${r.correnteFaseC.toStringAsFixed(2)} A'),
      ('Disjuntor Geral',        '${r.disjuntorPolos}P × ${r.disjuntorGeral} A'),
      ('Utilização do Disjuntor', '${r.utilizacaoDisjuntor.toStringAsFixed(1)}%'),
      ('Desbalanceamento',       '${r.desbalanceamentoPercent.toStringAsFixed(2)}%'),
      ('ΔV Máx. estimada',       '${r.quedaTensaoMax.toStringAsFixed(2)}%'),
      ('Módulos Utilizados',     '${r.modulosUtilizados} / ${r.modulosDisponiveis}'),
      ('Taxa de Ocupação',       '${r.percentOcupacao.toStringAsFixed(1)}%'),
      ('Reserva do Quadro',      '${r.percentReservaQuadro.toStringAsFixed(1)}%'),
      ('Reserva de Carga',       '${r.percentReservaCarga.toStringAsFixed(1)}%'),
    ];
    return Column(
      children: itens.asMap().entries.map((e) => Container(
        color: e.key.isOdd ? const Color(0xFFF8F9FA) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          Expanded(child: Text(e.value.$1, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary))),
          Text(e.value.$2, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      )).toList(),
    );
  }

  Widget _previewFooter() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    color: const Color(0xFF0B1B3D),
    child: Row(children: [
      const Icon(Icons.electric_bolt, color: Color(0xFFFF7A00), size: 14),
      const SizedBox(width: 6),
      const Text('QUADRO MASTER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          '| ABNT NBR 5410 | Documento gerado automaticamente | ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const TextStyle(color: Colors.white54, fontSize: 8),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const Text('Pág. 1/1', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600)),
    ]),
  );

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    if (s == 'ok')    return AppColors.success;
    if (s == 'warn')  return AppColors.warning;
    return AppColors.error;
  }

  String _numFasesShort(NumeroFases f) {
    switch (f) {
      case NumeroFases.monofasico: return '1F – Monofasico';
      case NumeroFases.bifasico:   return '2F – Bifasico';
      case NumeroFases.trifasico:  return '3F+N – Trifasico';
    }
  }

  String _cargoRegistroLabel(String cargo) {
    switch (cargo) {
      case 'tecnico':      return 'CRT';
      case 'profissional': return 'CPF';
      default:             return 'CREA';
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Compartilhar
  // ──────────────────────────────────────────────────────────────
  Future<void> _compartilhar(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final resultado = prov.resultado;
    if (resultado == null) return;
    try {
      final pdf = await _buildPdfDocument(resultado);
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'relatorio_${projeto.nome}.pdf');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Gerar e imprimir PDF
  // ──────────────────────────────────────────────────────────────
  Future<void> _gerarPdf(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final resultado = prov.resultado;
    if (resultado == null) return;
    try {
      final pdf = await _buildPdfDocument(resultado);
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CONSTRUÇÃO DO DOCUMENTO PDF  — Layout profissional
  // ══════════════════════════════════════════════════════════════
  Future<pw.Document> _buildPdfDocument(ResultadoProjeto resultado) async {
    final doc = pw.Document();

    // ── Fontes UTF-8 ──────────────────────────────────────────
    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold    = await PdfGoogleFonts.notoSansBold();
    final fontItalic  = await PdfGoogleFonts.notoSansItalic();

    final theme = pw.ThemeData.withFont(
      base:   fontRegular,
      bold:   fontBold,
      italic: fontItalic,
    );

    // ── Data / hora ───────────────────────────────────────────
    final now     = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final nowFull = DateFormat('dd/MM/yyyy  HH:mm').format(DateTime.now());

    // ── Logo empresa executadora ──────────────────────────────
    pw.MemoryImage? logoExec;
    if (projeto.executora.logoBase64.isNotEmpty) {
      try { logoExec = pw.MemoryImage(base64Decode(projeto.executora.logoBase64)); } catch (_) {}
    }

    // ── Cargas ativas ─────────────────────────────────────────
    final cargas = projeto.cargas.where((c) => c.ativo).toList();

    // ═══════════════════════════════════════════════════════════
    // HELPERS PDF
    // ═══════════════════════════════════════════════════════════

    // Cor de status
    PdfColor pStatus(String s) {
      if (s == 'ok')   return _pGreen;
      if (s == 'warn') return _pYellow;
      return _pRed;
    }

    // Ícone de raio (CustomPaint)
    pw.Widget raioPdf(double sz) => pw.Container(
      width: sz, height: sz,
      child: pw.CustomPaint(painter: (canvas, size) {
        canvas.setFillColor(_pWhite);
        final w = size.x; final h = size.y;
        canvas.moveTo(w * 0.65, 0);
        canvas.lineTo(w * 0.28, h * 0.52);
        canvas.lineTo(w * 0.50, h * 0.52);
        canvas.lineTo(w * 0.35, h);
        canvas.lineTo(w * 0.72, h * 0.48);
        canvas.lineTo(w * 0.50, h * 0.48);
        canvas.lineTo(w * 0.65, 0);
        canvas.fillPath();
      }),
    );

    // Logo PDF: empresa ou padrão
    pw.Widget logoPdf(double sz) {
      if (logoExec != null) {
        return pw.Container(
          width: sz, height: sz,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _pOrange, width: 1.5),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 4, verticalRadius: 4,
            child: pw.Image(logoExec, fit: pw.BoxFit.cover, width: sz, height: sz),
          ),
        );
      }
      return pw.Container(
        width: sz, height: sz,
        decoration: pw.BoxDecoration(color: _pOrange, borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Center(child: raioPdf(sz * 0.55)),
      );
    }

    // Título de seção
    pw.Widget secTitulo(String num, String titulo) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
      child: pw.Row(children: [
        pw.Container(
          width: 16, height: 16,
          decoration: const pw.BoxDecoration(color: _pOrange, shape: pw.BoxShape.circle),
          alignment: pw.Alignment.center,
          child: pw.Text(num,
            style: pw.TextStyle(color: _pWhite, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titulo,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _pNavy, letterSpacing: 0.5)),
        pw.Expanded(child: pw.Container(
          margin: const pw.EdgeInsets.only(left: 8),
          height: 1.2, color: _pOrange,
        )),
      ]),
    );

    // Linha de dado (label → valor)
    pw.Widget dadoRow(String label, String valor, {bool alt = false}) => pw.Container(
      color: alt ? _pGrey10 : _pWhite,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 170,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: _pGrey6)),
        ),
        pw.Expanded(
          child: pw.Text(valor,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pBlack)),
        ),
      ]),
    );

    // Pílula de dado (grid de dados gerais)
    pw.Widget pilula(String label, String valor) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _pGrey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(left: const pw.BorderSide(color: _pOrange, width: 2.5)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: _pGrey6)),
        pw.Text(valor, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pBlack),
          overflow: pw.TextOverflow.clip),
      ]),
    );

    // Card de empresa
    pw.Widget empresaPdf(
      String titulo,
      List<(String, String)> linhas, {
      pw.MemoryImage? logoImg,
    }) => pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _pGrey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(left: const pw.BorderSide(color: _pOrange, width: 3)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // Cabeçalho do card
        pw.Row(children: [
          pw.Container(width: 3, height: 10, color: _pOrange),
          pw.SizedBox(width: 4),
          pw.Text(titulo,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pOrange, letterSpacing: 0.4)),
        ]),
        pw.SizedBox(height: 6),
        // Logo da executadora se disponível
        if (logoImg != null) ...[
          pw.Container(
            height: 30,
            child: pw.Image(logoImg, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 5),
        ],
        // Linhas de dados
        if (linhas.isEmpty)
          pw.Text('(nao configurado)', style: const pw.TextStyle(fontSize: 7, color: _pGrey6))
        else
          ...linhas.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2.5),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.SizedBox(
                width: 65,
                child: pw.Text('${l.$1}:', style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
              ),
              pw.Expanded(
                child: pw.Text(l.$2,
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _pBlack)),
              ),
            ]),
          )),
      ]),
    );

    // ═══════════════════════════════════════════════════════════
    // CABEÇALHO DE PÁGINA
    // ═══════════════════════════════════════════════════════════
    pw.Widget pdfHeader(pw.Context ctx) => pw.Container(
      width: double.infinity,
      color: _pNavy,
      padding: const pw.EdgeInsets.fromLTRB(22, 12, 22, 12),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        logoPdf(44),
        pw.SizedBox(width: 12),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('QUADRO MASTER',
            style: pw.TextStyle(color: _pWhite, fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
          pw.Text('ABNT NBR 5410',
            style: pw.TextStyle(color: _pOrange, fontSize: 7.5, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
          pw.SizedBox(height: 3),
          pw.Text('RELATORIO TECNICO DE DIMENSIONAMENTO DE QUADRO ELETRICO',
            style: pw.TextStyle(color: const PdfColor(1.0, 1.0, 1.0, 0.8), fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
          pw.Text('${projeto.nome}  |  ${projeto.tipoQuadro.label}',
            style: const pw.TextStyle(color: _pOrange, fontSize: 7.5),
            overflow: pw.TextOverflow.clip),
        ])),
        pw.SizedBox(width: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _pOrange, width: 1.2),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            _hdrRow('Relatorio',  'RT-${DateFormat('yyyyMM').format(DateTime.now())}-001', _pGrey4, _pWhite),
            _hdrRow('Data',      now,                _pGrey4, _pWhite),
            _hdrRow('Hora',      DateFormat('HH:mm').format(DateTime.now()), _pGrey4, _pWhite),
            _hdrRow('Revisao',   'Rev. 00',          _pGrey4, _pWhite),
            _hdrRow('Pagina',    '${ctx.pageNumber} / ${ctx.pagesCount}', _pGrey4, _pWhite),
          ]),
        ),
      ]),
    );

    // ═══════════════════════════════════════════════════════════
    // RODAPÉ DE PÁGINA
    // ═══════════════════════════════════════════════════════════
    pw.Widget pdfFooter(pw.Context ctx) {
      final exec = projeto.executora;
      final endExec = [
        if (exec.rua.isNotEmpty) exec.rua + (exec.numero.isNotEmpty ? ', ${exec.numero}' : ''),
        if (exec.cidade.isNotEmpty) exec.cidade,
        if (exec.estado.isNotEmpty) exec.estado,
        if (exec.cep.isNotEmpty) 'CEP ${exec.cep}',
      ].join(' · ');

      return pw.Container(
        width: double.infinity,
        color: _pNavy,
        padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: pw.Row(children: [
          logoPdf(20),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            if (exec.razaoSocial.isNotEmpty)
              pw.Text(exec.razaoSocial,
                style: pw.TextStyle(fontSize: 7, color: _pWhite, fontWeight: pw.FontWeight.bold)),
            pw.Row(children: [
              if (endExec.isNotEmpty)
                pw.Expanded(
                  child: pw.Text(endExec, style: const pw.TextStyle(fontSize: 6, color: _pGrey4),
                    overflow: pw.TextOverflow.clip),
                ),
            ]),
            pw.Row(children: [
              if (exec.telefone.isNotEmpty)
                pw.Text('Tel: ${exec.telefone}  ', style: const pw.TextStyle(fontSize: 6, color: _pGrey4)),
              if (exec.email.isNotEmpty)
                pw.Text(exec.email, style: const pw.TextStyle(fontSize: 6, color: _pGrey4)),
            ]),
          ])),
          pw.SizedBox(width: 8),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Pagina ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: _pWhite, fontWeight: pw.FontWeight.bold)),
            pw.Text(nowFull, style: const pw.TextStyle(fontSize: 6, color: _pGrey4)),
          ]),
        ]),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // CONSTRUÇÃO DO CONTEÚDO — MultiPage
    // ═══════════════════════════════════════════════════════════
    doc.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: pw.EdgeInsets.zero,
      ),
      header: pdfHeader,
      footer: pdfFooter,
      build: (pw.Context ctx) {
        return [
          // ── Espaço após header ──────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ════════════════════════════════════════════
                // 1 — EMPRESA CONTRATANTE & EXECUTADORA
                // ════════════════════════════════════════════
                secTitulo('1', 'DADOS DAS EMPRESAS'),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: empresaPdf(
                        'EMPRESA EXECUTADORA',
                        [
                          if (projeto.executora.razaoSocial.isNotEmpty)   ('Razao Social',     projeto.executora.razaoSocial),
                          if (projeto.executora.responsavel.isNotEmpty)   ('Responsavel',      projeto.executora.responsavel),
                          if (projeto.executora.registro.isNotEmpty)      (_cargoRegistroLabel(projeto.executora.cargo), projeto.executora.registro),
                          if (projeto.executora.documento.isNotEmpty)     ('CNPJ',             projeto.executora.documento),
                          if (projeto.executora.telefone.isNotEmpty)      ('Telefone',         projeto.executora.telefone),
                          if (projeto.executora.email.isNotEmpty)         ('E-mail',           projeto.executora.email),
                          if (projeto.executora.enderecoCompleto.isNotEmpty) ('Endereco',      projeto.executora.enderecoCompleto),
                        ],
                        logoImg: logoExec,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: empresaPdf(
                        'EMPRESA CONTRATANTE',
                        [
                          if (projeto.contratante.razaoSocial.isNotEmpty)  ('Razao Social', projeto.contratante.razaoSocial),
                          if (projeto.contratante.responsavel.isNotEmpty)  ('Responsavel',  projeto.contratante.responsavel),
                          if (projeto.contratante.documento.isNotEmpty)    ('CNPJ',         projeto.contratante.documento),
                          if (projeto.contratante.telefone.isNotEmpty)     ('Telefone',     projeto.contratante.telefone),
                          if (projeto.contratante.email.isNotEmpty)        ('E-mail',       projeto.contratante.email),
                          if (projeto.contratante.enderecoCompleto.isNotEmpty) ('Endereco', projeto.contratante.enderecoCompleto),
                          if (projeto.contratante.art.isNotEmpty)          ('ART No.',      projeto.contratante.art),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 14),

                // ════════════════════════════════════════════
                // 2 — DADOS DO PROJETO
                // ════════════════════════════════════════════
                secTitulo('2', 'DADOS DO PROJETO'),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _pGrey4, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(children: [
                    // Linha de pílulas
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(children: [
                        pw.Expanded(child: pilula('Tipo do Quadro',   projeto.tipoQuadro.label)),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Tensao de Alim.',  '${projeto.tensao.valor.toStringAsFixed(0)} V')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Numero de Fases',  projeto.numFases.label)),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Frequencia',       '60 Hz')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Aterramento',      'TN-S')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Total Circuitos',  '${cargas.length}')),
                      ]),
                    ),
                    pw.Divider(height: 1, color: _pGrey4),
                    // Resultados elétricos principais
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(children: [
                        pw.Expanded(child: pilula('Potencia Instalada',  '${resultado.totalPotenciaAtiva.toStringAsFixed(2)} kW')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Potencia Demandada',  '${resultado.totalPotenciaDemandada.toStringAsFixed(2)} kW')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Potencia Aparente',   '${resultado.totalPotenciaAparente.toStringAsFixed(2)} kVA')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Corrente Total',      '${resultado.correnteTotal.toStringAsFixed(2)} A')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Corrente/Fase',       '${resultado.correnteMedia.toStringAsFixed(2)} A')),
                        pw.SizedBox(width: 6),
                        pw.Expanded(child: pilula('Disjuntor Geral',     '${resultado.disjuntorPolos}P x ${resultado.disjuntorGeral}A')),
                      ]),
                    ),
                  ]),
                ),

                pw.SizedBox(height: 14),

                // ════════════════════════════════════════════
                // 3 — TABELA DE CARGAS
                // ════════════════════════════════════════════
                secTitulo('3', 'TABELA DE CARGAS'),
              ],
            ),
          ),

          // ── Tabela de cargas (fora do padding para borda cheia) ──
          _buildPdfTabelaCargas(cargas, resultado),

          pw.SizedBox(height: 14),

          // ── Memorial de cálculo ─────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(22, 0, 22, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // ════════════════════════════════════════════
                // 4 — MEMORIAL DE CÁLCULO
                // ════════════════════════════════════════════
                secTitulo('4', 'MEMORIAL DE CALCULO'),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _pGrey4, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(children: [
                    // Sub-título
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: _pNavy,
                      child: pw.Text('4.1 — Potencias e Correntes',
                        style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                    ),
                    dadoRow('Potencia Ativa Total Instalada (ΣP)',         '${resultado.totalPotenciaAtiva.toStringAsFixed(3)} kW'),
                    dadoRow('Potencia Reativa Total (ΣQ)',                  '${resultado.totalPotenciaReativa.toStringAsFixed(3)} kVAr', alt: true),
                    dadoRow('Potencia Aparente Total (S)',                   '${resultado.totalPotenciaAparente.toStringAsFixed(3)} kVA'),
                    dadoRow('Potencia Demandada (com FD aplicado)',         '${resultado.totalPotenciaDemandada.toStringAsFixed(3)} kW', alt: true),
                    dadoRow('Fator de Potencia Medio (FP)',                 resultado.fatorPotenciaMedio.toStringAsFixed(4)),
                    dadoRow('Corrente Total (I)',                           '${resultado.correnteTotal.toStringAsFixed(3)} A', alt: true),
                    dadoRow('Corrente de Projeto (I × 1,25 — NBR 5410)',   '${resultado.correnteProjeto.toStringAsFixed(3)} A'),
                    dadoRow('Corrente Fase A',                              '${resultado.correnteFaseA.toStringAsFixed(3)} A', alt: true),
                    dadoRow('Corrente Fase B',                              '${resultado.correnteFaseB.toStringAsFixed(3)} A'),
                    dadoRow('Corrente Fase C',                              '${resultado.correnteFaseC.toStringAsFixed(3)} A', alt: true),
                    dadoRow('Corrente de Neutro estimada',                  '${resultado.correnteNeutro.toStringAsFixed(3)} A'),

                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: _pNavy,
                      child: pw.Text('4.2 — Dimensionamento da Protecao',
                        style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                    ),
                    dadoRow('Disjuntor Geral Dimensionado',                 '${resultado.disjuntorPolos}P  x  ${resultado.disjuntorGeral} A', alt: true),
                    dadoRow('Utilizacao do Disjuntor Geral',                '${resultado.utilizacaoDisjuntor.toStringAsFixed(1)} %  (${resultado.classificacaoDisjuntor.label})'),
                    dadoRow('Capacidade de Interrupcao adotada',            '${resultado.capacidadeInterrupcao.toStringAsFixed(1)} kA', alt: true),
                    dadoRow('Corrente de Curto-Circuito estimada',          '${resultado.correnteCurtoEstimada.toStringAsFixed(3)} kA'),
                    dadoRow('Disjuntor adequado ao Icc',                    resultado.disjuntorAdequadoIcc ? 'SIM — adequado' : 'ATENCAO — verificar Icc', alt: true),
                    dadoRow('Coordenacao e Seletividade',                   resultado.seletividadeOk ? 'OK — seletividade adequada' : 'PROBLEMA — verificar'),

                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: _pNavy,
                      child: pw.Text('4.3 — Balanceamento e Queda de Tensao',
                        style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                    ),
                    dadoRow('Desbalanceamento entre Fases',                 '${resultado.desbalanceamentoPercent.toStringAsFixed(2)} %  (${resultado.classificacaoBalanceamento.label})', alt: true),
                    dadoRow('Corrente Media por Fase',                      '${resultado.correnteMedia.toStringAsFixed(3)} A'),
                    dadoRow('Diferenca Maxima entre Fases',                 '${resultado.diferencaMaxima.toStringAsFixed(3)} A', alt: true),
                    dadoRow('Queda de Tensao Maxima estimada',              '${resultado.quedaTensaoMax.toStringAsFixed(2)} %  (limite NBR 5410: 4 %)'),
                    dadoRow('Fator de Potencia medio',                      '${resultado.fatorPotenciaMedio.toStringAsFixed(3)}  (minimo ANEEL: 0,92)', alt: true),
                    if (resultado.necessitaCorrecaoFP)
                      dadoRow('Banco de Capacitores necessario',            '${resultado.capacitorKvar.toStringAsFixed(2)} kVAr'),

                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: _pNavy,
                      child: pw.Text('4.4 — Taxa de Ocupacao e Reserva',
                        style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                    ),
                    dadoRow('Modulos Utilizados',                           '${resultado.modulosUtilizados} modulos', alt: true),
                    dadoRow('Modulos Disponiveis no Quadro',                '${resultado.modulosDisponiveis} modulos'),
                    dadoRow('Modulos Livres (reserva)',                     '${resultado.modulosLivres} modulos', alt: true),
                    dadoRow('Taxa de Ocupacao do Quadro',                   '${resultado.percentOcupacao.toStringAsFixed(1)} %'),
                    dadoRow('Reserva de Modulos',                           '${resultado.percentReservaQuadro.toStringAsFixed(1)} %', alt: true),
                    dadoRow('Corrente Maxima do Quadro',                    '${resultado.correnteMaximaQuadro.toStringAsFixed(1)} A'),
                    dadoRow('Corrente Restante (reserva de carga)',         '${resultado.correnteRestante.toStringAsFixed(1)} A', alt: true),
                    dadoRow('Reserva de Carga percentual',                  '${resultado.percentReservaCarga.toStringAsFixed(1)} %'),
                    dadoRow('Indice Geral de Qualidade',                    '${resultado.indiceGeral.toStringAsFixed(0)} / 100  (${resultado.classificacaoIndice.label})', alt: true),
                  ]),
                ),

                pw.SizedBox(height: 14),

                // ════════════════════════════════════════════
                // 5 — DIAGNÓSTICO TÉCNICO
                // ════════════════════════════════════════════
                secTitulo('5', 'DIAGNOSTICO TECNICO'),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Coluna CONFORMIDADES
                    pw.Expanded(child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _pGrey4, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: _pGreen,
                          child: pw.Text('CONFORMIDADES',
                            style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                        ),
                        if (resultado.diagnosticoConformes.isEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Nenhuma conformidade registrada.',
                              style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
                          )
                        else
                          ...resultado.diagnosticoConformes.asMap().entries.map((e) => pw.Container(
                            color: e.key.isOdd ? _pGrey10 : _pWhite,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              pw.Text('✓ ', style: pw.TextStyle(fontSize: 7, color: _pGreen, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 7, color: _pGrey6))),
                            ]),
                          )),
                      ]),
                    )),
                    pw.SizedBox(width: 8),
                    // Coluna PROBLEMAS
                    pw.Expanded(child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _pGrey4, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: resultado.diagnosticoProblemas.isEmpty ? _pGrey6 : _pRed,
                          child: pw.Text('PONTOS DE ATENCAO',
                            style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                        ),
                        if (resultado.diagnosticoProblemas.isEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Nenhum problema identificado.',
                              style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
                          )
                        else
                          ...resultado.diagnosticoProblemas.asMap().entries.map((e) => pw.Container(
                            color: e.key.isOdd ? _pGrey10 : _pWhite,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              pw.Text('! ', style: pw.TextStyle(fontSize: 7, color: _pRed, fontWeight: pw.FontWeight.bold)),
                              pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 7, color: _pGrey6))),
                            ]),
                          )),
                      ]),
                    )),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Recomendações
                if (resultado.diagnosticoRecomendacoes.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _pGrey4, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: _pOrange,
                        child: pw.Text('RECOMENDACOES TECNICAS',
                          style: pw.TextStyle(fontSize: 7.5, color: _pWhite, fontWeight: pw.FontWeight.bold)),
                      ),
                      ...resultado.diagnosticoRecomendacoes.asMap().entries.map((e) => pw.Container(
                        color: e.key.isOdd ? _pGrey10 : _pWhite,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text('→ ', style: pw.TextStyle(fontSize: 7, color: _pOrange, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 7, color: _pGrey6))),
                        ]),
                      )),
                    ]),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Alertas gerais
                if (resultado.alertas.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _pYellow, width: 0.8),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: _pYellow,
                        child: pw.Text('ALERTAS DO SISTEMA',
                          style: pw.TextStyle(fontSize: 7.5, color: _pBlack, fontWeight: pw.FontWeight.bold)),
                      ),
                      ...resultado.alertas.asMap().entries.map((e) => pw.Container(
                        color: e.key.isOdd ? _pGrey10 : _pWhite,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text('⚠ ', style: pw.TextStyle(fontSize: 7, color: _pYellow, fontWeight: pw.FontWeight.bold)),
                          pw.Expanded(child: pw.Text(e.value, style: const pw.TextStyle(fontSize: 7, color: _pGrey6))),
                        ]),
                      )),
                    ]),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Observações do projeto
                if (projeto.observacoes.isNotEmpty) ...[
                  secTitulo('6', 'OBSERVACOES TECNICAS'),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: _pGrey50,
                      border: pw.Border(left: const pw.BorderSide(color: _pOrange, width: 3)),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(projeto.observacoes,
                      style: pw.TextStyle(fontSize: 7.5, color: _pBlack, fontStyle: pw.FontStyle.italic)),
                  ),
                  pw.SizedBox(height: 10),
                ],

                // Espaço antes do rodapé
                pw.SizedBox(height: 8),

                // Linha de assinatura
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _pGrey4, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(children: [
                    pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Responsavel Tecnico:', style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
                      pw.SizedBox(height: 2),
                      pw.Text(projeto.executora.responsavel.isNotEmpty ? projeto.executora.responsavel : '___________________________',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _pBlack)),
                      if (projeto.executora.registro.isNotEmpty)
                        pw.Text('${_cargoRegistroLabel(projeto.executora.cargo)}: ${projeto.executora.registro}',
                          style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
                    ])),
                    pw.SizedBox(width: 20),
                    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('Data de emissao:', style: const pw.TextStyle(fontSize: 7, color: _pGrey6)),
                      pw.Text(nowFull, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _pBlack)),
                      pw.Text('Documento gerado por Quadro Master', style: const pw.TextStyle(fontSize: 6, color: _pGrey4)),
                    ]),
                  ]),
                ),

              ],
            ),
          ),
        ];
      },
    ));

    return doc;
  }

  // ══════════════════════════════════════════════════════════════
  // TABELA DE CARGAS PDF — separada para suportar auto-paginação
  // ══════════════════════════════════════════════════════════════
  pw.Widget _buildPdfTabelaCargas(List<Carga> cargas, ResultadoProjeto resultado) {
    if (cargas.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(22, 0, 22, 0),
        child: pw.Text('Nenhuma carga cadastrada.',
          style: const pw.TextStyle(fontSize: 8, color: _pGrey6)),
      );
    }

    // Cabeçalho da tabela
    pw.Widget hdrCol(String t, int flex) => pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        child: pw.Text(t,
          style: pw.TextStyle(fontSize: 6.5, color: _pWhite, fontWeight: pw.FontWeight.bold),
          overflow: pw.TextOverflow.clip),
      ),
    );

    // Célula de dado
    pw.Widget col(String t, int flex, {bool bold = false, pw.Alignment align = pw.Alignment.centerLeft}) => pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        alignment: align,
        child: pw.Text(t,
          style: pw.TextStyle(fontSize: 6.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: _pBlack),
          overflow: pw.TextOverflow.clip),
      ),
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: pw.Table(
        border: pw.TableBorder.all(color: _pGrey4, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.2),   // Circ.
          1: pw.FlexColumnWidth(3.5),   // Descrição
          2: pw.FlexColumnWidth(1.8),   // Tipo
          3: pw.FlexColumnWidth(1.8),   // Pot. (W)
          4: pw.FlexColumnWidth(1.6),   // I (A)
          5: pw.FlexColumnWidth(1.5),   // Tensão
          6: pw.FlexColumnWidth(1.2),   // Fases
          7: pw.FlexColumnWidth(1.5),   // Disj.
          8: pw.FlexColumnWidth(2.0),   // Cabo (mm²)
          9: pw.FlexColumnWidth(2.0),   // DR
          10: pw.FlexColumnWidth(3.0),  // Observações
        },
        children: [
          // Linha de cabeçalho
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _pNavy),
            children: [
              _tblHdr('Circ.'),
              _tblHdr('Descricao'),
              _tblHdr('Tipo'),
              _tblHdr('Pot. (W)'),
              _tblHdr('I (A)'),
              _tblHdr('Tensao'),
              _tblHdr('Fases'),
              _tblHdr('Disj.'),
              _tblHdr('Cabo'),
              _tblHdr('DR'),
              _tblHdr('Obs.'),
            ],
          ),
          // Linhas de dados
          ...cargas.asMap().entries.map((entry) {
            final idx = entry.key;
            final c   = entry.value;
            final alt = idx.isOdd;
            final bgColor = alt ? _pGrey10 : _pWhite;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: bgColor),
              children: [
                _tblCell('C${(idx + 1).toString().padLeft(2, '0')}'),
                _tblCell(c.descricao, bold: true),
                _tblCell(_tipoLabel(c)),
                _tblCell(c.potenciaAtiva.toStringAsFixed(1)),
                _tblCell(c.corrente.toStringAsFixed(2)),
                _tblCell('${c.tensao.toStringAsFixed(0)} V'),
                _tblCell(c.ligacao.label.substring(0, 4)),
                _tblCell('${c.disjuntorSugerido} A'),
                _tblCell('${c.condutorSugerido.toStringAsFixed(1)} mm²'),
                _tblCell(c.utilizaDR ? c.drTexto : '—',
                  textColor: c.utilizaDR ? _pGreen : _pGrey6),
                _tblCell(
                  c.motorReserva
                      ? 'RESERVA (stand-by)'
                      : c.notas.isNotEmpty
                          ? c.notas
                          : (c.fabricante.isNotEmpty ? c.fabricante : '—'),
                  textColor: c.motorReserva ? _pOrange : null,
                ),
              ],
            );
          }),
          // Linha de totais
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: _pNavy,
            ),
            children: [
              _tblHdr('TOTAL'),
              _tblHdr('${cargas.length} circuito(s)'),
              _tblHdr(''),
              _tblHdr('${resultado.totalPotenciaAtiva.toStringAsFixed(1)} kW'),
              _tblHdr('${resultado.correnteTotal.toStringAsFixed(2)} A'),
              _tblHdr('—'),
              _tblHdr('—'),
              _tblHdr('${resultado.disjuntorGeral} A'),
              _tblHdr('—'),
              _tblHdr('—'),
              _tblHdr(''),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers da tabela PDF ─────────────────────────────────────
  static pw.Widget _tblHdr(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
    child: pw.Text(t,
      style: pw.TextStyle(fontSize: 6.5, color: _pWhite, fontWeight: pw.FontWeight.bold),
      overflow: pw.TextOverflow.clip),
  );

  static pw.Widget _tblCell(String t, {bool bold = false, PdfColor? textColor}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3.5),
    child: pw.Text(t,
      style: pw.TextStyle(
        fontSize: 6.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: textColor ?? _pBlack,
      ),
      overflow: pw.TextOverflow.clip),
  );

  // ── Helper cabeçalho PDF (linha de metadado) ─────────────────
  static pw.Widget _hdrRow(String label, String value,
      PdfColor labelColor, PdfColor valueColor) =>
    pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text('$label: ', style: pw.TextStyle(fontSize: 6.5, color: labelColor)),
        pw.Text(value,      style: pw.TextStyle(fontSize: 6.5, color: valueColor, fontWeight: pw.FontWeight.bold)),
      ]),
    );

  // ── Tipo/subtipo da carga para exibição na tabela ─────────────
  String _tipoLabel(Carga c) {
    if (c.subtipoQGBT != null) return c.subtipoQGBT!.label.split(' ').first;
    if (c.subtipoQF   != null) return c.subtipoQF!.label.split(' ').first;
    if (c.subtipoPainel != null) return c.subtipoPainel!.label.split(' ').first;
    return c.tipo.label.split(' ').first;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers top-level (fora da classe)
// ─────────────────────────────────────────────────────────────────────────────
String _numFasesShortGlobal(NumeroFases f) {
  switch (f) {
    case NumeroFases.monofasico: return '1F';
    case NumeroFases.bifasico:   return '2F';
    case NumeroFases.trifasico:  return '3F+N';
  }
}

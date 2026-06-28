import 'dart:convert';
import 'dart:math';
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
// Paleta de cores do PDF — Navy #0B1B3D / Orange #FF7A00
// ─────────────────────────────────────────────────────────────────────────────
const _navy   = PdfColor.fromInt(0xFF0B1B3D);
const _orange = PdfColor.fromInt(0xFFFF7A00);
const _green  = PdfColor.fromInt(0xFF28A745);
const _yellow = PdfColor.fromInt(0xFFFFA500);
const _red    = PdfColor.fromInt(0xFFDC3545);
const _grey50 = PdfColor.fromInt(0xFFF8F9FA);
// ignore: unused_element
const _grey100= PdfColor.fromInt(0xFFF1F3F5);
const _grey400= PdfColors.grey400;
const _grey600= PdfColors.grey600;
const _white  = PdfColors.white;
const _black  = PdfColor.fromInt(0xFF212529);

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

  // ─────────────────────────────────────────────────────────────────────────
  // Preview Flutter (visual do relatório na tela)
  // ─────────────────────────────────────────────────────────────────────────
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
                _previewDadosGerais(now),
                const SizedBox(height: 12),
                if (resultado != null) ...[
                  _previewPainelResumo(resultado),
                  const SizedBox(height: 12),
                  _previewSecaoLabel('MEMÓRIA DE CÁLCULO', numero: '2'),
                  _previewDataRow('Potência Ativa Total (∑P)', '${resultado.totalPotenciaAtiva.toStringAsFixed(3)} kW'),
                  _previewDataRow('Potência Reativa Total (∑Q)', '${resultado.totalPotenciaReativa.toStringAsFixed(3)} kVAr'),
                  _previewDataRow('Potência Aparente (S)', '${resultado.totalPotenciaAparente.toStringAsFixed(3)} kVA'),
                  _previewDataRow('Fator de Potência Médio', resultado.fatorPotenciaMedio.toStringAsFixed(3)),
                  _previewDataRow('Corrente de Projeto (×1,25)', '${resultado.correnteProjeto.toStringAsFixed(2)} A'),
                  _previewDataRow('Desbalanceamento', '${resultado.desbalanceamentoPercent.toStringAsFixed(1)}%'),
                  const SizedBox(height: 12),
                  _previewSecaoLabel('CIRCUITOS', numero: '3'),
                  const SizedBox(height: 6),
                  _buildTabelaCircuitos(),
                  const SizedBox(height: 12),
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
          // Logo quadro laranja com raio
          _buildLogoWidget(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUADRO MASTER', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Text('ABNT NBR 5410', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text('LAUDO TÉCNICO DE DIMENSIONAMENTO', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600)),
                Text(projeto.nome, style: const TextStyle(color: Color(0xFFFF7A00), fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          // Caixa de metadata com borda laranja
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
            child: Image.memory(bytes, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _defaultLogoWidget(size)),
          ),
        );
      } catch (_) {}
    }
    return _defaultLogoWidget(size);
  }

  Widget _defaultLogoWidget(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A00),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.electric_bolt, color: Colors.white, size: size * 0.55),
      ),
    );
  }

  Widget _headerInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 8)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _previewEmpresas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _empresaCard(
          titulo: 'EMPRESA EXECUTORA',
          linhas: [
            if (projeto.executora.razaoSocial.isNotEmpty) projeto.executora.razaoSocial,
            if (projeto.executora.documento.isNotEmpty) 'CNPJ: ${projeto.executora.documento}',
            if (projeto.executora.registro.isNotEmpty) '${_cargoRegistroLabel(projeto.executora.cargo)}: ${projeto.executora.registro}',
            if (projeto.executora.responsavel.isNotEmpty) 'Resp.: ${projeto.executora.responsavel}',
            if (projeto.executora.telefone.isNotEmpty) 'Tel: ${projeto.executora.telefone}',
            if (projeto.executora.email.isNotEmpty) projeto.executora.email,
          ],
          temLogo: projeto.executora.logoBase64.isNotEmpty,
        )),
        const SizedBox(width: 8),
        Expanded(child: _empresaCard(
          titulo: 'EMPRESA CONTRATANTE',
          linhas: [
            if (projeto.contratante.razaoSocial.isNotEmpty) projeto.contratante.razaoSocial,
            if (projeto.contratante.documento.isNotEmpty) 'CNPJ: ${projeto.contratante.documento}',
            if (projeto.contratante.responsavel.isNotEmpty) 'Resp.: ${projeto.contratante.responsavel}',
            if (projeto.contratante.telefone.isNotEmpty) 'Tel: ${projeto.contratante.telefone}',
            if (projeto.contratante.enderecoCompleto.isNotEmpty) projeto.contratante.enderecoCompleto,
            if (projeto.contratante.art.isNotEmpty) 'ART: ${projeto.contratante.art}',
          ],
        )),
      ],
    );
  }

  Widget _empresaCard({required String titulo, required List<String> linhas, bool temLogo = false}) {
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
            const Icon(Icons.business, size: 10, color: Color(0xFFFF7A00)),
            const SizedBox(width: 4),
            Text(titulo, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFFF7A00), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 6),
          if (temLogo) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                base64Decode(projeto.executora.logoBase64),
                height: 28, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (linhas.isEmpty)
            const Text('(não configurado)', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontStyle: FontStyle.italic))
          else
            ...linhas.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(l, style: const TextStyle(fontSize: 9, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
            )),
        ],
      ),
    );
  }

  Widget _previewDadosGerais(String now) {
    final items = [
      (Icons.edit_document, 'Projeto', projeto.nome),
      (Icons.electrical_services, 'Tipo', projeto.tipoQuadro.sigla),
      (Icons.electric_bolt, 'Sistema', _numFasesShort(projeto.numFases)),
      (Icons.flash_on, 'Tensão', '${projeto.tensao.valor.toStringAsFixed(0)} V'),
      (Icons.calendar_today, 'Data', now),
      (Icons.location_on, 'Local', projeto.contratante.cidade.isNotEmpty ? projeto.contratante.cidade : '—'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewSecaoLabel('DADOS GERAIS DO PROJETO', numero: '1'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: const Border(left: BorderSide(color: Color(0xFFFF7A00), width: 2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 10, color: const Color(0xFFFF7A00)),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                    Text(item.$3, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _previewPainelResumo(ResultadoProjeto r) {
    // Linha 1: 7 cards de métricas
    final topCards = [
      ('P. Instalada', '${r.totalPotenciaAtiva.toStringAsFixed(1)} kW', _statusColor(r.totalPotenciaAtiva > 0 ? 'ok' : 'warn')),
      ('P. Demandada', '${r.totalPotenciaDemandada.toStringAsFixed(1)} kW', AppColors.primary),
      ('I. Projeto', '${r.correnteProjeto.toStringAsFixed(1)} A', _statusColor(r.utilizacaoDisjuntor > 95 ? 'error' : r.utilizacaoDisjuntor > 85 ? 'warn' : 'ok')),
      ('Disj. Geral', '${r.disjuntorPolos}P×${r.disjuntorGeral}A', _statusColor(r.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error' : r.classificacaoDisjuntor == ClassificacaoDisjuntor.alta ? 'warn' : 'ok')),
      ('FP Médio', r.fatorPotenciaMedio.toStringAsFixed(3), _statusColor(r.fatorPotenciaMedio >= 0.92 ? 'ok' : r.fatorPotenciaMedio >= 0.85 ? 'warn' : 'error')),
      ('Circuitos', '${r.numCircuitos}', AppColors.secondary),
      ('Índice', '${r.indiceGeral.toStringAsFixed(0)}/100', _statusColor(r.indiceGeral >= 75 ? 'ok' : r.indiceGeral >= 45 ? 'warn' : 'error')),
    ];
    // Linha 2: 6 indicadores de status
    final bottomCards = [
      ('Balanceamento', r.classificacaoBalanceamento.label, _statusColor(r.desbalanceamentoPercent <= 5 ? 'ok' : r.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
      ('Desbalanc.', '${r.desbalanceamentoPercent.toStringAsFixed(1)}%', _statusColor(r.desbalanceamentoPercent <= 5 ? 'ok' : r.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
      ('Res. Quadro', '${r.percentReservaQuadro.toStringAsFixed(0)}%', _statusColor(r.percentReservaQuadro >= 20 ? 'ok' : r.percentReservaQuadro >= 10 ? 'warn' : 'error')),
      ('Res. Carga', '${r.percentReservaCarga.toStringAsFixed(0)}%', _statusColor(r.percentReservaCarga >= 20 ? 'ok' : r.percentReservaCarga >= 15 ? 'warn' : 'error')),
      ('ΔV Máx.', '${r.quedaTensaoMax.toStringAsFixed(1)}%', _statusColor(r.quedaTensaoMax <= 4 ? 'ok' : r.quedaTensaoMax <= 7 ? 'warn' : 'error')),
      ('Capacitores', r.necessitaCorrecaoFP ? '${r.capacitorKvar.toStringAsFixed(1)} kVAr' : 'OK', r.necessitaCorrecaoFP ? AppColors.warning : AppColors.success),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _previewSecaoLabel('PAINEL RESUMO', numero: '3'),
        const SizedBox(height: 6),
        LayoutBuilder(builder: (ctx, c) {
          // ignore: unused_local_variable
          final w = (c.maxWidth - 36) / 7;
          return Wrap(
            spacing: 6, runSpacing: 6,
            children: topCards.map((card) => SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(top: BorderSide(color: card.$3, width: 2)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(card.$2, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: card.$3), overflow: TextOverflow.ellipsis),
                    Text(card.$1, style: const TextStyle(fontSize: 7, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          );
        }),
        const SizedBox(height: 6),
        // Indicadores de status (linha 2)
        LayoutBuilder(builder: (ctx, c) {
          // ignore: unused_local_variable
          final w = (c.maxWidth - 30) / 6;
          return Row(
            children: bottomCards.map((card) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                decoration: BoxDecoration(
                  color: card.$3.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: card.$3.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: card.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 3),
                    Text(card.$2, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: card.$3), overflow: TextOverflow.ellipsis),
                    Text(card.$1, style: const TextStyle(fontSize: 6, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            )).toList(),
          );
        }),
      ],
    );
  }

  Widget _previewSecaoLabel(String titulo, {String? numero}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        if (numero != null) ...[
          Container(
            width: 18, height: 18,
            decoration: const BoxDecoration(color: Color(0xFFFF7A00), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(numero, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 6),
        ],
        Text(titulo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0B1B3D), letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: const Color(0xFFFF7A00))),
      ],
    ),
  );

  Widget _previewDataRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(width: 180, child: Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
      ],
    ),
  );

  Widget _previewFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0B1B3D),
      child: Row(
        children: [
          // Logo mini no rodapé
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: const Color(0xFFFF7A00), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.electric_bolt, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Quadro Master  ·  ABNT NBR 5410:2004  ·  NR-10  ·  IEC 60364',
              style: TextStyle(color: Colors.white60, fontSize: 8),
            ),
          ),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.qr_code_2, color: Colors.white70, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelaCircuitos() {
    final cargas = projeto.cargas.where((c) => c.ativo).toList();
    if (cargas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Nenhum circuito ativo.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: AppColors.divider, width: 0.5),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFFF7A00)),
            children: ['#', 'Circuito', 'Lig.', 'Fase', 'P(W)', 'I(A)', 'Disj.', 'Fio', 'ΔV%', '●']
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      child: Text(h, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ))
                .toList(),
          ),
          ...cargas.asMap().entries.map((e) {
            final c = e.value;
            final dvOk = c.quedaTensaoPercent <= 4;
            final dvColor = dvOk ? AppColors.success : c.quedaTensaoPercent <= 7 ? AppColors.warning : AppColors.error;
            return TableRow(
              decoration: BoxDecoration(color: e.key.isEven ? Colors.white : const Color(0xFFF8F9FA)),
              children: [
                _tc('${e.key + 1}', center: true),
                _tc(c.descricao, maxWidth: 90),
                _tc(_ligacaoShort(c.ligacao), center: true),
                _tc(_faseStr(c.fase), center: true),
                _tc(c.potenciaAtiva.toStringAsFixed(0), center: true),
                _tc(c.corrente.toStringAsFixed(1), center: true),
                _tc('${c.disjuntorSugerido}A', bold: true, center: true),
                _tc('${c.condutorSugerido}mm²', center: true),
                _tc('${c.quedaTensaoPercent.toStringAsFixed(1)}%', color: dvColor, center: true),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Center(
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(color: dvColor, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _tc(String text, {bool bold = false, Color? color, double? maxWidth, bool center = false}) {
    Widget t = Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: color),
      overflow: TextOverflow.ellipsis,
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
    if (maxWidth != null) t = SizedBox(width: maxWidth, child: t);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: t);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ████████  GERAÇÃO DO PDF — FIEL À IMAGEM DE REFERÊNCIA  ████████
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _gerarPdf(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final resultado = prov.resultado;
    if (resultado == null) return;

    final doc = pw.Document();
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final nowFull = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final cargas = projeto.cargas.where((c) => c.ativo).toList();

    // Logo da empresa executora
    pw.MemoryImage? logoExec;
    if (projeto.executora.logoBase64.isNotEmpty) {
      try { logoExec = pw.MemoryImage(base64Decode(projeto.executora.logoBase64)); } catch (_) {}
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      header: (ctx) => _pdfHeader(ctx, now, logoExec),
      footer: (ctx) => _pdfFooter(ctx),
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ── SEÇÃO 1: EMPRESAS ──────────────────────────────────────────
              _pdfSectionTitle('1', 'IDENTIFICAÇÃO DAS EMPRESAS'),
              pw.SizedBox(height: 6),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Expanded(child: _pdfEmpresaCard(
                  titulo: 'EMPRESA EXECUTORA',
                  logoImage: logoExec,
                  linhas: [
                    if (projeto.executora.razaoSocial.isNotEmpty) ('Razão Social', projeto.executora.razaoSocial),
                    if (projeto.executora.documento.isNotEmpty) ('CNPJ/CPF', projeto.executora.documento),
                    if (projeto.executora.registro.isNotEmpty) (_cargoRegistroLabel(projeto.executora.cargo), projeto.executora.registro),
                    if (projeto.executora.responsavel.isNotEmpty) ('Responsável', projeto.executora.responsavel),
                    if (projeto.executora.telefone.isNotEmpty) ('Telefone', projeto.executora.telefone),
                    if (projeto.executora.email.isNotEmpty) ('E-mail', projeto.executora.email),
                    if (projeto.executora.enderecoCompleto.isNotEmpty) ('Endereço', projeto.executora.enderecoCompleto),
                  ],
                )),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _pdfEmpresaCard(
                  titulo: 'EMPRESA CONTRATANTE',
                  linhas: [
                    if (projeto.contratante.razaoSocial.isNotEmpty) ('Razão Social', projeto.contratante.razaoSocial),
                    if (projeto.contratante.documento.isNotEmpty) ('CNPJ/CPF', projeto.contratante.documento),
                    if (projeto.contratante.responsavel.isNotEmpty) ('Responsável', projeto.contratante.responsavel),
                    if (projeto.contratante.telefone.isNotEmpty) ('Telefone', projeto.contratante.telefone),
                    if (projeto.contratante.email.isNotEmpty) ('E-mail', projeto.contratante.email),
                    if (projeto.contratante.enderecoCompleto.isNotEmpty) ('Local', projeto.contratante.enderecoCompleto),
                    if (projeto.contratante.art.isNotEmpty) ('ART/RRT', projeto.contratante.art),
                  ],
                )),
              ]),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 2: DADOS GERAIS ─────────────────────────────────────
              _pdfSectionTitle('2', 'DADOS GERAIS DO PROJETO'),
              pw.SizedBox(height: 6),
              _pdfDadosGerais(now),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 3: PAINEL RESUMO ────────────────────────────────────
              _pdfSectionTitle('3', 'PAINEL RESUMO'),
              pw.SizedBox(height: 6),
              _pdfPainelResumo(resultado),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 4: DISTRIBUIÇÃO DE CARGAS E BALANCEAMENTO ──────────
              _pdfSectionTitle('4', 'DISTRIBUIÇÃO DE CARGAS E BALANCEAMENTO DE FASES'),
              pw.SizedBox(height: 6),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Expanded(child: _pdfDistribuicaoCargas(resultado)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _pdfBalanceamentoFases(resultado)),
              ]),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 5: TABELA DE CIRCUITOS ──────────────────────────────
              _pdfSectionTitle('5', 'DISJUNTORES E CONDUTORES POR CIRCUITO'),
              pw.SizedBox(height: 6),
              _pdfTabelaCircuitos(cargas),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 6: MEMÓRIA DE CÁLCULO ───────────────────────────────
              _pdfSectionTitle('6', 'MEMÓRIA DE CÁLCULO – POTÊNCIAS E CORRENTES'),
              pw.SizedBox(height: 6),
              pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Expanded(child: _pdfInfoCard([
                  ('Potência Ativa Total (∑P)', '${resultado.totalPotenciaAtiva.toStringAsFixed(3)} kW'),
                  ('Potência Reativa Total (∑Q)', '${resultado.totalPotenciaReativa.toStringAsFixed(3)} kVAr'),
                  ('Potência Aparente (S)', '${resultado.totalPotenciaAparente.toStringAsFixed(3)} kVA'),
                  ('Fator de Potência Médio', resultado.fatorPotenciaMedio.toStringAsFixed(3)),
                  ('Potência Demandada (com FD)', '${resultado.totalPotenciaDemandada.toStringAsFixed(3)} kW'),
                ])),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _pdfInfoCard([
                  ('Corrente Fase A', '${resultado.correnteFaseA.toStringAsFixed(2)} A'),
                  ('Corrente Fase B', '${resultado.correnteFaseB.toStringAsFixed(2)} A'),
                  ('Corrente Fase C', '${resultado.correnteFaseC.toStringAsFixed(2)} A'),
                  ('Corrente de Neutro', '${resultado.correnteNeutro.toStringAsFixed(2)} A'),
                  ('Corrente Total', '${resultado.correnteTotal.toStringAsFixed(2)} A'),
                  ('Corrente de Projeto (×1,25)', '${resultado.correnteProjeto.toStringAsFixed(2)} A'),
                  ('Desbalanceamento', '${resultado.desbalanceamentoPercent.toStringAsFixed(1)}%'),
                ])),
              ]),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 7: DIAGNÓSTICO ──────────────────────────────────────
              _pdfSectionTitle('7', 'DIAGNÓSTICO TÉCNICO AUTOMÁTICO'),
              pw.SizedBox(height: 6),
              _pdfDiagnostico(resultado),
              pw.SizedBox(height: 12),

              // ── SEÇÃO 8: 3 PAINÉIS TÉCNICOS ──────────────────────────────
              _pdfSectionTitle('8', 'PAINÉIS TÉCNICOS'),
              pw.SizedBox(height: 6),
              _pdfPaineisTecnicos(resultado),
              pw.SizedBox(height: 10),

              // Assinatura
              _pdfAssinatura(resultado, nowFull),
              pw.SizedBox(height: 6),
            ],
          ),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (fmt) => doc.save());
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CABEÇALHO — navy #0B1B3D, logo Quadro Master (ou logo empresa), info box
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfHeader(pw.Context ctx, String now, pw.MemoryImage? logo) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(22, 12, 22, 12),
      color: _navy,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo: empresa se disponível, senão "quadro laranja + raio"
          logo != null
            ? pw.Container(
                width: 44, height: 44,
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _orange, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            : pw.Container(
                width: 44, height: 44,
                decoration: pw.BoxDecoration(
                  color: _orange,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 20, height: 20,
                        child: pw.CustomPaint(
                          painter: (canvas, size) => _desenharRaio(canvas, size),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          pw.SizedBox(width: 12),
          // Título principal
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('QUADRO MASTER',
                  style: pw.TextStyle(color: _white, fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
                pw.Text('ABNT NBR 5410',
                  style: pw.TextStyle(color: _orange, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
                pw.SizedBox(height: 4),
                pw.Text('LAUDO TÉCNICO DE DIMENSIONAMENTO DE QUADRO ELÉTRICO',
                  style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.8), fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text('${projeto.nome}  ·  ${projeto.tipoQuadro.label}  ·  ${projeto.numFases.label.split("–").first.trim()}',
                  style: const pw.TextStyle(color: _orange, fontSize: 8)),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          // Info box com borda laranja
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _orange, width: 1.2),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _pdfHeaderInfoRow('Data', now),
                _pdfHeaderInfoRow('Revisão', '00'),
                _pdfHeaderInfoRow('Norma', 'NBR 5410'),
                _pdfHeaderInfoRow('Página', '${ctx.pageNumber}/${ctx.pagesCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desenha raio (lightning bolt) para o logo padrão
  void _desenharRaio(PdfGraphics canvas, PdfPoint size) {
    canvas.setFillColor(_white);
    final w = size.x;
    final h = size.y;
    canvas.moveTo(w * 0.65, 0);
    canvas.lineTo(w * 0.28, h * 0.5);
    canvas.lineTo(w * 0.5, h * 0.5);
    canvas.lineTo(w * 0.35, h);
    canvas.lineTo(w * 0.72, h * 0.48);
    canvas.lineTo(w * 0.5, h * 0.48);
    canvas.lineTo(w * 0.65, 0);
    canvas.fillPath();
  }

  pw.Widget _pdfHeaderInfoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
    child: pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 7, color: _grey400)),
        pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _white)),
      ],
    ),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // RODAPÉ — navy, logo Quadro Master, texto normativo, QR code
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfFooter(pw.Context ctx) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      color: _navy,
      child: pw.Row(
        children: [
          // Logo mini no rodapé
          pw.Container(
            width: 18, height: 18,
            decoration: pw.BoxDecoration(
              color: _orange,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Center(
              child: pw.Text('Q', style: pw.TextStyle(color: _white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('Quadro Master  ', style: pw.TextStyle(color: _white, fontSize: 7, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(
              '·  ABNT NBR 5410:2004  ·  NR-10  ·  IEC 60364  ·  Documento gerado automaticamente',
              style: const pw.TextStyle(fontSize: 7, color: _grey400),
            ),
          ),
          // QR code placeholder
          pw.Container(
            width: 28, height: 28,
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.GridView(
                crossAxisCount: 4,
                children: List.generate(16, (i) => pw.Container(
                  margin: const pw.EdgeInsets.all(0.3),
                  color: _navy,
                )),
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text('Pág. ${ctx.pageNumber}/${ctx.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: _white, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Título de seção com círculo laranja + linha
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfSectionTitle(String num, String titulo) {
    return pw.Row(
      children: [
        pw.Container(
          width: 16, height: 16,
          decoration: const pw.BoxDecoration(color: _orange, shape: pw.BoxShape.circle),
          alignment: pw.Alignment.center,
          child: pw.Text(num, style: pw.TextStyle(color: _white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titulo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy, letterSpacing: 0.5)),
        pw.Expanded(child: pw.Container(
          margin: const pw.EdgeInsets.only(left: 8),
          height: 1,
          color: _orange,
        )),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Card de empresa (borda esquerda laranja)
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfEmpresaCard({
    required String titulo,
    required List<(String, String)> linhas,
    pw.MemoryImage? logoImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(left: const pw.BorderSide(color: _orange, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(width: 3, height: 8, color: _orange),
            pw.SizedBox(width: 4),
            pw.Text(titulo, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _orange)),
          ]),
          pw.SizedBox(height: 5),
          if (logoImage != null) ...[
            pw.Image(logoImage, height: 24, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 4),
          ],
          if (linhas.isEmpty)
            pw.Text('(não configurado)', style: const pw.TextStyle(fontSize: 7, color: _grey600))
          else
            ...linhas.map((l) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.SizedBox(width: 62, child: pw.Text(l.$1,
                  style: const pw.TextStyle(fontSize: 7, color: _grey600))),
                pw.Expanded(child: pw.Text(l.$2,
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _black))),
              ]),
            )),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Dados gerais — banda de 7 pílulas com ícone
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfDadosGerais(String now) {
    final items = [
      ('Projeto', projeto.nome),
      ('Tipo', projeto.tipoQuadro.label),
      ('Sistema', projeto.numFases.label.split('–').first.trim()),
      ('Tensao', '${projeto.tensao.valor.toStringAsFixed(0)} V'),
      ('Frequencia', '60 Hz'),
      ('Data', now),
      ('Local', projeto.contratante.cidade.isNotEmpty ? projeto.contratante.cidade : '—'),
    ];
    return pw.Row(
      children: items.map((item) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 4),
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: pw.BoxDecoration(
            color: _grey50,
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border(left: const pw.BorderSide(color: _orange, width: 2)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item.$1, style: const pw.TextStyle(fontSize: 6, color: _grey600)),
              pw.Text(item.$2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _black),
                overflow: pw.TextOverflow.clip),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Painel Resumo: 7 cards (linha 1) + 6 indicadores de status (linha 2)
  // Inclui gauge circular do índice geral
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfPainelResumo(ResultadoProjeto r) {
    PdfColor cor(String s) {
      switch (s) { case 'ok': return _green; case 'warn': return _yellow; default: return _red; }
    }

    // Linha 1: 7 cards de métricas + gauge do índice
    final topCards = [
      ('P. Instalada', '${r.totalPotenciaAtiva.toStringAsFixed(1)} kW', cor(r.totalPotenciaAtiva > 0 ? 'ok' : 'warn')),
      ('P. Demandada', '${r.totalPotenciaDemandada.toStringAsFixed(1)} kW', _orange),
      ('I. Projeto', '${r.correnteProjeto.toStringAsFixed(1)} A', cor(r.utilizacaoDisjuntor > 95 ? 'error' : r.utilizacaoDisjuntor > 85 ? 'warn' : 'ok')),
      ('Disj. Geral', '${r.disjuntorPolos}P×${r.disjuntorGeral}A', cor(r.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error' : r.classificacaoDisjuntor == ClassificacaoDisjuntor.alta ? 'warn' : 'ok')),
      ('FP Médio', r.fatorPotenciaMedio.toStringAsFixed(3), cor(r.fatorPotenciaMedio >= 0.92 ? 'ok' : r.fatorPotenciaMedio >= 0.85 ? 'warn' : 'error')),
      ('Circuitos', '${r.numCircuitos}', _navy),
      ('Modulos', '${r.modulosUtilizados}/${r.modulosDisponiveis}', cor(r.percentOcupacao < 80 ? 'ok' : r.percentOcupacao < 90 ? 'warn' : 'error')),
    ];

    // Linha 2: 6 indicadores de status
    final bottomCards = [
      ('Balanceamento', r.classificacaoBalanceamento.label, cor(r.desbalanceamentoPercent <= 5 ? 'ok' : r.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
      ('Desbalanc.', '${r.desbalanceamentoPercent.toStringAsFixed(1)}%', cor(r.desbalanceamentoPercent <= 5 ? 'ok' : r.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
      ('Res. Quadro', '${r.percentReservaQuadro.toStringAsFixed(0)}%', cor(r.percentReservaQuadro >= 20 ? 'ok' : r.percentReservaQuadro >= 10 ? 'warn' : 'error')),
      ('Res. Carga', '${r.percentReservaCarga.toStringAsFixed(0)}%', cor(r.percentReservaCarga >= 20 ? 'ok' : r.percentReservaCarga >= 15 ? 'warn' : 'error')),
      ('Queda Tens.', '${r.quedaTensaoMax.toStringAsFixed(1)}%', cor(r.quedaTensaoMax <= 4 ? 'ok' : r.quedaTensaoMax <= 7 ? 'warn' : 'error')),
      ('Capacitores', r.necessitaCorrecaoFP ? '${r.capacitorKvar.toStringAsFixed(1)} kVAr' : 'OK', r.necessitaCorrecaoFP ? _yellow : _green),
    ];

    return pw.Column(children: [
      // Linha 1: cards de métricas
      pw.Row(children: [
        ...topCards.map((c) => pw.Expanded(
          child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 5, bottom: 5),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: _white,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border(top: pw.BorderSide(color: c.$3, width: 2)),
              boxShadow: [pw.BoxShadow(color: const PdfColor(0, 0, 0, 0.05), blurRadius: 3)],
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(c.$2, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: c.$3)),
              pw.SizedBox(height: 1),
              pw.Text(c.$1, style: const pw.TextStyle(fontSize: 6.5, color: _grey600)),
            ]),
          ),
        )),
        // Gauge circular do índice geral
        pw.SizedBox(width: 5),
        _pdfGaugeCircular(r.indiceGeral, r.classificacaoIndice.label),
      ]),
      // Linha 2: indicadores de status
      pw.Row(children: bottomCards.map((c) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 5),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColor(c.$3.red, c.$3.green, c.$3.blue, 0.08),
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColor(c.$3.red, c.$3.green, c.$3.blue, 0.2), width: 0.5),
          ),
          child: pw.Column(children: [
            pw.Container(
              width: 7, height: 7,
              decoration: pw.BoxDecoration(color: c.$3, shape: pw.BoxShape.circle),
            ),
            pw.SizedBox(height: 3),
            pw.Text(c.$2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: c.$3)),
            pw.SizedBox(height: 1),
            pw.Text(c.$1, style: const pw.TextStyle(fontSize: 6, color: _grey600)),
          ]),
        ),
      )).toList()),
    ]);
  }

  // Gauge circular para índice geral
  pw.Widget _pdfGaugeCircular(double indice, String label) {
    final PdfColor cor;
    if (indice >= 75) { cor = _green; }
    else if (indice >= 45) { cor = _yellow; }
    else { cor = _red; }

    return pw.Container(
      width: 58, height: 58,
      decoration: pw.BoxDecoration(
        color: _white,
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: cor, width: 3),
        boxShadow: [pw.BoxShadow(color: PdfColor(cor.red, cor.green, cor.blue, 0.2), blurRadius: 6)],
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(indice.toStringAsFixed(0), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: cor)),
          pw.Text('/100', style: const pw.TextStyle(fontSize: 7, color: _grey600)),
          pw.SizedBox(height: 1),
          pw.Text(label, style: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold, color: cor), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Distribuição de cargas — tabela + donut chart simulado
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfDistribuicaoCargas(ResultadoProjeto r) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Distribuição por Categoria',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 6),
          if (r.distribuicaoCategorias.isEmpty)
            pw.Text('Sem dados', style: const pw.TextStyle(fontSize: 7, color: _grey600))
          else ...[
            // Tabela de distribuição
            ...r.distribuicaoCategorias.take(6).map((cat) {
              final PdfColor barCor;
              if (cat.percentualTotal >= 50) { barCor = _orange; }
              else if (cat.percentualTotal >= 20) { barCor = _navy; }
              else { barCor = _green; }
              final fraction = (cat.percentualTotal / 100).clamp(0.0, 1.0);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Expanded(child: pw.Text(cat.nome,
                        style: const pw.TextStyle(fontSize: 6.5, color: _grey600))),
                      pw.Text('${cat.percentualTotal.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: barCor)),
                    ]),
                    pw.SizedBox(height: 2),
                    // Barra de progresso sem FractionallySizedBox (não existe no pdf package)
                    pw.LayoutBuilder(builder: (ctx, constraints) {
                      final maxW = constraints?.maxWidth ?? 100.0;
                      final barW = maxW * fraction;
                      return pw.Stack(children: [
                        pw.Container(height: 5, width: maxW,
                          decoration: pw.BoxDecoration(
                            color: const PdfColor(0.9, 0.9, 0.9),
                            borderRadius: pw.BorderRadius.circular(2))),
                        pw.Container(height: 5, width: barW,
                          decoration: pw.BoxDecoration(
                            color: barCor, borderRadius: pw.BorderRadius.circular(2))),
                      ]);
                    }),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 4),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Total Instalado:', style: const pw.TextStyle(fontSize: 7, color: _grey600)),
              pw.Text('${(r.totalPotenciaAtiva).toStringAsFixed(2)} kW',
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _black)),
            ]),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Balanceamento de fases — barras A/B/C + caixa de stats
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfBalanceamentoFases(ResultadoProjeto r) {
    final maxI = [r.correnteFaseA, r.correnteFaseB, r.correnteFaseC].reduce(max);
    final fases = [
      ('Fase A', r.correnteFaseA, const PdfColor(1, 0.2, 0.2)), // vermelho
      ('Fase B', r.correnteFaseB, const PdfColor(0.2, 0.6, 1.0)), // azul
      ('Fase C', r.correnteFaseC, const PdfColor(1, 0.65, 0.0)), // amarelo
    ];
    final desbalOk = r.desbalanceamentoPercent <= 5;

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Balanceamento das Fases',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 8),
          // Barras de fase
          ...fases.map((f) {
            final fraction = maxI > 0 ? (f.$2 / maxI).clamp(0.0, 1.0) : 0.0;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(children: [
                pw.SizedBox(width: 36, child: pw.Text(f.$1, style: const pw.TextStyle(fontSize: 7, color: _grey600))),
                pw.Expanded(child: pw.LayoutBuilder(builder: (ctx, constraints) {
                  final maxW = constraints?.maxWidth ?? 100.0;
                  final barW = maxW * fraction;
                  return pw.Stack(children: [
                    pw.Container(height: 10, width: maxW,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor(0.9, 0.9, 0.9),
                        borderRadius: pw.BorderRadius.circular(3))),
                    pw.Container(height: 10, width: barW,
                      decoration: pw.BoxDecoration(
                        color: f.$3, borderRadius: pw.BorderRadius.circular(3))),
                  ]);
                })),
                pw.SizedBox(width: 6),
                pw.SizedBox(width: 38, child: pw.Text('${f.$2.toStringAsFixed(1)} A',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _black))),
              ]),
            );
          }),
          pw.SizedBox(height: 4),
          // Box de stats
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColor(
                desbalOk ? _green.red : _yellow.red,
                desbalOk ? _green.green : _yellow.green,
                desbalOk ? _green.blue : _yellow.blue,
                0.1,
              ),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Desbalanceamento', style: const pw.TextStyle(fontSize: 6.5, color: _grey600)),
                pw.Text('${r.desbalanceamentoPercent.toStringAsFixed(1)}%',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                    color: desbalOk ? _green : _yellow)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Classificação', style: const pw.TextStyle(fontSize: 6.5, color: _grey600)),
                pw.Text(r.classificacaoBalanceamento.label,
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                    color: desbalOk ? _green : _yellow)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tabela de circuitos — 11 colunas com dots coloridos
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfTabelaCircuitos(List<Carga> cargas) {
    if (cargas.isEmpty) {
      return pw.Text('Nenhum circuito ativo.', style: const pw.TextStyle(fontSize: 8, color: _grey600));
    }
    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Descrição', 'Tipo', 'Lig.', 'Fase', 'P(W)', 'I(A)', 'Disj.(A)', 'Cabo(mm²)', 'ΔV(%)', 'Situação'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7, color: _white),
      headerDecoration: const pw.BoxDecoration(color: _orange),
      data: cargas.asMap().entries.map((e) {
        final c = e.value;
        final dvOk = c.quedaTensaoPercent <= 4;
        final status = dvOk ? '● OK' : c.quedaTensaoPercent <= 7 ? '● Aten.' : '● Crit.';
        return [
          '${e.key + 1}',
          c.descricao,
          _tipoShort(c.tipo),
          _ligacaoShort(c.ligacao),
          _faseStr(c.fase),
          c.potenciaAtiva.toStringAsFixed(0),
          c.corrente.toStringAsFixed(1),
          '${c.disjuntorSugerido}',
          '${c.condutorSugerido}',
          c.quedaTensaoPercent.toStringAsFixed(1),
          status,
        ];
      }).toList(),
      cellStyle: const pw.TextStyle(fontSize: 7),
      cellAlignments: {
        0: pw.Alignment.center, 4: pw.Alignment.center,
        5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight,
        7: pw.Alignment.center, 8: pw.Alignment.center,
        9: pw.Alignment.center, 10: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey300),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Diagnóstico técnico (conformidades, problemas, recomendações)
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfDiagnostico(ResultadoProjeto r) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (r.diagnosticoConformes.isNotEmpty) ...[
        _pdfDiagSubHeader('CONFORMIDADES', _green),
        ...r.diagnosticoConformes.map((c) => _pdfDiagItem('✓', c, _green)),
        pw.SizedBox(height: 4),
      ],
      if (r.diagnosticoProblemas.isNotEmpty) ...[
        _pdfDiagSubHeader('PENDÊNCIAS / PROBLEMAS', _red),
        ...r.diagnosticoProblemas.map((p) => _pdfDiagItem('✗', p, _red)),
        pw.SizedBox(height: 4),
      ],
      if (r.diagnosticoRecomendacoes.isNotEmpty) ...[
        _pdfDiagSubHeader('RECOMENDAÇÕES TÉCNICAS', _yellow),
        ...r.diagnosticoRecomendacoes.map((rec) => _pdfDiagItem('→', rec, _yellow)),
        pw.SizedBox(height: 4),
      ],
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(7),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.93, 0.97, 1.0),
          borderRadius: pw.BorderRadius.circular(3),
          border: pw.Border.all(color: const PdfColor(0.7, 0.8, 0.9), width: 0.5),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('RECOMENDAÇÕES GERAIS — ABNT NBR 5410',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.SizedBox(height: 3),
          pw.Text(
            '• Manter reserva mínima de 20% da capacidade do quadro.\n'
            '• Prever circuitos dedicados para equipamentos >1.000 W.\n'
            '• Instalar DPS (Dispositivo de Proteção contra Surtos) — ABNT NBR 5419.\n'
            '• Revisar periodicamente as proteções conforme ABNT NBR 5410:2004.\n'
            '• Manter diagrama unifilar atualizado conforme NR-10.',
            style: const pw.TextStyle(fontSize: 7, color: _grey600),
          ),
        ]),
      ),
    ]);
  }

  pw.Widget _pdfDiagSubHeader(String label, PdfColor cor) => pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 3),
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: pw.BoxDecoration(
      color: PdfColor(cor.red, cor.green, cor.blue, 0.08),
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: cor)),
  );

  pw.Widget _pdfDiagItem(String symbol, String text, PdfColor cor) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('$symbol ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: cor)),
      pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 7, color: _grey600))),
    ]),
  );

  // ──────────────────────────────────────────────────────────────────────────
  // 3 Painéis técnicos inferiores: Proteção Geral | Reservas | Correção FP
  // ──────────────────────────────────────────────────────────────────────────
  pw.Widget _pdfPaineisTecnicos(ResultadoProjeto r) {
    final paineis = [
      _pdfPainelTecnico(
        titulo: 'Proteção Geral',
        valor: '${r.disjuntorPolos}P × ${r.disjuntorGeral} A',
        subtitulo: 'Utilização: ${r.utilizacaoDisjuntor.toStringAsFixed(0)}%',
        badge: r.classificacaoDisjuntor.label,
        ok: r.classificacaoDisjuntor != ClassificacaoDisjuntor.critica,
        detalhes: [
          ('Icc estimada', '${(r.correnteCurtoEstimada * 1000).toStringAsFixed(0)} A'),
          ('Cap. interrupção', '${r.capacidadeInterrupcao.toStringAsFixed(0)} kA'),
          ('Seletividade', r.seletividadeOk ? 'OK' : 'Verificar'),
        ],
      ),
      _pdfPainelTecnico(
        titulo: 'Reservas e Utilização',
        valor: 'Quadro: ${r.percentReservaQuadro.toStringAsFixed(0)}%',
        subtitulo: 'Carga: ${r.percentReservaCarga.toStringAsFixed(0)}%',
        badge: r.percentReservaQuadro >= 20 ? 'Adequada' : 'Atenção',
        ok: r.percentReservaQuadro >= 20,
        detalhes: [
          ('Módulos livres', '${r.modulosLivres}/${r.modulosDisponiveis}'),
          ('Ocup. quadro', '${r.percentOcupacao.toStringAsFixed(0)}%'),
          ('I restante', '${r.correnteRestante.toStringAsFixed(1)} A'),
        ],
      ),
      _pdfPainelTecnico(
        titulo: 'Correção do FP',
        valor: r.necessitaCorrecaoFP ? '${r.capacitorKvar.toStringAsFixed(1)} kVAr' : 'Não necessário',
        subtitulo: 'FP atual: ${r.fatorPotenciaMedio.toStringAsFixed(3)}',
        badge: r.fatorPotenciaMedio >= 0.92 ? 'Conforme' : 'Corrigir',
        ok: r.fatorPotenciaMedio >= 0.92,
        detalhes: [
          ('FP mínimo ANEEL', '0,920'),
          ('Consumo mensal', '${(r.totalPotenciaDemandada * 8 * 22).toStringAsFixed(0)} kWh'),
          ('Consumo anual', '${(r.totalPotenciaDemandada * 8 * 264).toStringAsFixed(0)} kWh'),
        ],
      ),
    ];
    return pw.Row(children: paineis.map((p) => pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 6),
        child: p,
      ),
    )).toList());
  }

  pw.Widget _pdfPainelTecnico({
    required String titulo,
    required String valor,
    required String subtitulo,
    required String badge,
    required bool ok,
    required List<(String, String)> detalhes,
  }) {
    final cor = ok ? _green : _yellow;
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(bottom: pw.BorderSide(color: cor, width: 3)),
        boxShadow: [pw.BoxShadow(color: const PdfColor(0, 0, 0, 0.05), blurRadius: 3)],
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(titulo, style: const pw.TextStyle(fontSize: 7, color: _grey600)),
        pw.SizedBox(height: 2),
        pw.Text(valor, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _black)),
        pw.SizedBox(height: 2),
        pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 6.5, color: _grey600)),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColor(cor.red, cor.green, cor.blue, 0.12),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(badge, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: cor)),
        ),
        pw.SizedBox(height: 5),
        pw.Container(height: 0.5, color: const PdfColor(0.9, 0.9, 0.9)),
        pw.SizedBox(height: 4),
        ...detalhes.map((d) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(d.$1, style: const pw.TextStyle(fontSize: 6.5, color: _grey600)),
            pw.Text(d.$2, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: _black)),
          ]),
        )),
      ]),
    );
  }

  pw.Widget _pdfInfoCard(List<(String, String)> linhas) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: linhas.map((l) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(children: [
            pw.SizedBox(width: 150, child: pw.Text(l.$1,
              style: const pw.TextStyle(fontSize: 7.5, color: _grey600))),
            pw.Expanded(child: pw.Text(l.$2,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _black))),
          ]),
        )).toList(),
      ),
    );
  }

  pw.Widget _pdfAssinatura(ResultadoProjeto r, String nowFull) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Responsável Técnico: ${projeto.executora.responsavel.isEmpty ? "—" : projeto.executora.responsavel}',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text('${_cargoRegistroLabel(projeto.executora.cargo)}: ${projeto.executora.registro.isEmpty ? "—" : projeto.executora.registro}',
            style: const pw.TextStyle(fontSize: 8, color: _grey600)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Emitido em: $nowFull',
            style: const pw.TextStyle(fontSize: 8, color: _grey600)),
          pw.Text('ABNT NBR 5410:2004 + Em.1:2008  ·  60 Hz',
            style: const pw.TextStyle(fontSize: 8, color: _grey600)),
        ]),
      ]),
    );
  }

  Future<void> _compartilhar(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gerando PDF para compartilhar...')),
    );
    await _gerarPdf(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers Flutter
  // ─────────────────────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'ok': return AppColors.success;
      case 'warn': return AppColors.warning;
      case 'error': return AppColors.error;
      default: return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers globais
// ─────────────────────────────────────────────────────────────────────────────
String _ligacaoShort(LigacaoCarga l) {
  switch (l) {
    case LigacaoCarga.monofasico: return 'Mono';
    case LigacaoCarga.bifasico: return 'Bi';
    case LigacaoCarga.trifasico: return 'Tri';
  }
}

String _tipoShort(TipoCarga t) {
  switch (t) {
    case TipoCarga.tug: return 'TUG';
    case TipoCarga.tue: return 'TUE';
    case TipoCarga.motor: return 'Motor';
    case TipoCarga.arCondicionado: return 'A/C';
    case TipoCarga.resistencia: return 'Resist.';
    case TipoCarga.iluminacao: return 'Ilumin.';
    case TipoCarga.generico: return 'Genérico';
  }
}

String _faseStr(FaseCarga f) {
  switch (f) {
    case FaseCarga.a:   return 'A';
    case FaseCarga.b:   return 'B';
    case FaseCarga.c:   return 'C';
    case FaseCarga.abc: return 'ABC';
    case FaseCarga.ab:  return 'A+B';
    case FaseCarga.ac:  return 'A+C';
    case FaseCarga.bc:  return 'B+C';
  }
}

String _numFasesShort(NumeroFases f) {
  switch (f) {
    case NumeroFases.monofasico: return 'Monofásico';
    case NumeroFases.bifasico: return 'Bifásico';
    case NumeroFases.trifasico: return 'Trifásico';
  }
}

String _cargoRegistroLabel(String cargo) {
  switch (cargo) {
    case 'tecnico': return 'CRT';
    case 'profissional': return 'CPF';
    default: return 'CREA';
  }
}

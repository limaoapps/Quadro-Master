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
            child: Image.memory(bytes, fit: BoxFit.cover,
              alignment: Alignment.center,
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

  Color _statusColor(String s) {
    if (s == 'ok')   return AppColors.success;
    if (s == 'warn') return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _compartilhar(BuildContext context) async {
    // Gera e compartilha o PDF usando o mesmo mecanismo de impressão
    await _gerarPdf(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ████████  GERAÇÃO DO PDF — v4 (Noto Sans UTF-8, layout fiel ao app)  ████
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _gerarPdf(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final resultado = prov.resultado;
    if (resultado == null) return;

    // ── 1. Carrega fontes UTF-8 (suporte completo a portugues e simbolos) ──
    final fontReg  = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItal = await PdfGoogleFonts.notoSansItalic();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fontReg, bold: fontBold, italic: fontItal),
    );

    final now     = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final nowFull = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final cargas  = projeto.cargas.where((c) => c.ativo).toList();

    // ── 2. Logo da empresa (so no cabecalho) ──
    pw.MemoryImage? logoExec;
    if (projeto.executora.logoBase64.isNotEmpty) {
      try { logoExec = pw.MemoryImage(base64Decode(projeto.executora.logoBase64)); } catch (_) {}
    }

    // ── 3. Paleta de cores PDF ──
    const navy   = PdfColor.fromInt(0xFF0B1B3D);
    const orange = PdfColor.fromInt(0xFFFF7A00);
    const green  = PdfColor.fromInt(0xFF28A745);
    const yellow = PdfColor.fromInt(0xFFFFA500);
    const red    = PdfColor.fromInt(0xFFDC3545);
    const grey50 = PdfColor.fromInt(0xFFF8F9FA);
    const white  = PdfColors.white;
    const black  = PdfColor.fromInt(0xFF212529);
    const grey6  = PdfColors.grey600;
    const grey4  = PdfColors.grey400;

    // ── 4. Funcoes auxiliares inline ──
    PdfColor corStatus(String s) {
      if (s == 'ok')   return green;
      if (s == 'warn') return yellow;
      return red;
    }

    // Titulo de secao (circulo laranja + linha)
    pw.Widget secTitle(String num, String titulo) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(children: [
        pw.Container(
          width: 16, height: 16,
          decoration: const pw.BoxDecoration(color: orange, shape: pw.BoxShape.circle),
          alignment: pw.Alignment.center,
          child: pw.Text(num, style: pw.TextStyle(color: white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(width: 6),
        pw.Text(titulo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: navy, letterSpacing: 0.4)),
        pw.Expanded(child: pw.Container(
          margin: const pw.EdgeInsets.only(left: 8),
          height: 1, color: orange,
        )),
      ]),
    );

    // Sub-titulo de diagnostico
    pw.Widget diagHeader(String label, PdfColor cor) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColor(cor.red, cor.green, cor.blue, 0.1),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: cor)),
    );

    // Item de diagnostico
    pw.Widget diagItem(String sym, String txt, PdfColor cor) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('$sym ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: cor)),
        pw.Expanded(child: pw.Text(txt, style: const pw.TextStyle(fontSize: 7, color: grey6))),
      ]),
    );

    // Bullet simples
    pw.Widget bullet(String txt) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: 4, height: 4,
          margin: const pw.EdgeInsets.only(top: 2, right: 5),
          decoration: const pw.BoxDecoration(color: navy, shape: pw.BoxShape.circle),
        ),
        pw.Expanded(child: pw.Text(txt, style: const pw.TextStyle(fontSize: 7, color: grey6))),
      ]),
    );

    // ── 5. CABECALHO ──────────────────────────────────────────────────────
    pw.Widget header(pw.Context ctx) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(22, 12, 22, 12),
      color: navy,
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
        // Logo: empresa ou icone padrao
        logoExec != null
          ? pw.Container(
              width: 44, height: 44,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: orange, width: 1.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 5, verticalRadius: 5,
                child: pw.Image(logoExec!, fit: pw.BoxFit.cover, width: 44, height: 44),
              ),
            )
          : pw.Container(
              width: 44, height: 44,
              decoration: pw.BoxDecoration(color: orange, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Center(
                child: pw.Container(
                  width: 20, height: 20,
                  child: pw.CustomPaint(painter: (canvas, size) {
                    canvas.setFillColor(white);
                    final w = size.x; final h = size.y;
                    canvas.moveTo(w * 0.65, 0);
                    canvas.lineTo(w * 0.28, h * 0.5);
                    canvas.lineTo(w * 0.5,  h * 0.5);
                    canvas.lineTo(w * 0.35, h);
                    canvas.lineTo(w * 0.72, h * 0.48);
                    canvas.lineTo(w * 0.5,  h * 0.48);
                    canvas.lineTo(w * 0.65, 0);
                    canvas.fillPath();
                  }),
                ),
              ),
            ),
        pw.SizedBox(width: 12),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('QUADRO MASTER',
            style: pw.TextStyle(color: white, fontSize: 13, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
          pw.Text('ABNT NBR 5410',
            style: pw.TextStyle(color: orange, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1.0)),
          pw.SizedBox(height: 4),
          pw.Text('LAUDO TECNICO DE DIMENSIONAMENTO DE QUADRO ELETRICO',
            style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.8), fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            '${projeto.nome} | ${projeto.tipoQuadro.label} | ${_numFasesShort(projeto.numFases)}',
            style: const pw.TextStyle(color: orange, fontSize: 8),
            overflow: pw.TextOverflow.clip,
          ),
        ])),
        pw.SizedBox(width: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: orange, width: 1.2), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            _hdrRow('Data', now, grey4, white),
            _hdrRow('Revisao', '00', grey4, white),
            _hdrRow('Norma', 'NBR 5410', grey4, white),
            _hdrRow('Pagina', '${ctx.pageNumber}/${ctx.pagesCount}', grey4, white),
          ]),
        ),
      ]),
    );

    // ── 6. RODAPE ─────────────────────────────────────────────────────────
    pw.Widget footer(pw.Context ctx) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      color: navy,
      child: pw.Row(children: [
        pw.Container(
          width: 18, height: 18,
          decoration: pw.BoxDecoration(color: orange, borderRadius: pw.BorderRadius.circular(3)),
          child: pw.Center(child: pw.Text('Q', style: pw.TextStyle(color: white, fontSize: 9, fontWeight: pw.FontWeight.bold))),
        ),
        pw.SizedBox(width: 8),
        pw.Text('Quadro Master', style: pw.TextStyle(color: white, fontSize: 7, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(width: 4),
        pw.Expanded(child: pw.Text(
          '| ABNT NBR 5410:2004 | NR-10 | IEC 60364 | Documento gerado automaticamente',
          style: const pw.TextStyle(fontSize: 7, color: grey4),
        )),
        pw.Container(
          width: 26, height: 26,
          decoration: pw.BoxDecoration(color: white, borderRadius: pw.BorderRadius.circular(2)),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(3),
            child: pw.GridView(crossAxisCount: 4,
              children: List.generate(16, (_) => pw.Container(margin: const pw.EdgeInsets.all(0.3), color: navy)),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text('Pag. ${ctx.pageNumber}/${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 7, color: white, fontWeight: pw.FontWeight.bold)),
      ]),
    );

    // ── 7. CARD EMPRESA (sem logo) ────────────────────────────────────────
    pw.Widget empresaCard(String titulo, List<(String, String)> linhas) => pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: grey50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border(left: const pw.BorderSide(color: orange, width: 3)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(children: [
          pw.Container(width: 3, height: 8, color: orange),
          pw.SizedBox(width: 4),
          pw.Text(titulo, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: orange)),
        ]),
        pw.SizedBox(height: 5),
        if (linhas.isEmpty)
          pw.Text('(nao configurado)', style: const pw.TextStyle(fontSize: 7, color: grey6))
        else
          ...linhas.map((l) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.SizedBox(width: 62, child: pw.Text(l.$1, style: const pw.TextStyle(fontSize: 7, color: grey6))),
              pw.Expanded(child: pw.Text(l.$2, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: black))),
            ]),
          )),
      ]),
    );

    // ── 8. DADOS GERAIS (7 pilulas) ───────────────────────────────────────
    final dadosItens = [
      ('Projeto', projeto.nome),
      ('Tipo', projeto.tipoQuadro.label),
      ('Sistema', _numFasesShort(projeto.numFases)),
      ('Tensao', '${projeto.tensao.valor.toStringAsFixed(0)} V'),
      ('Freq.', '60 Hz'),
      ('Data', now),
      ('Local', projeto.contratante.cidade.isNotEmpty ? projeto.contratante.cidade : 'N/D'),
    ];
    pw.Widget dadosGerais() => pw.Row(
      children: dadosItens.map((it) => pw.Expanded(child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 4),
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: pw.BoxDecoration(
          color: grey50, borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border(left: const pw.BorderSide(color: orange, width: 2)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(it.$1, style: const pw.TextStyle(fontSize: 6, color: grey6)),
          pw.Text(it.$2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: black),
            overflow: pw.TextOverflow.clip),
        ]),
      ))).toList(),
    );

    // ── 9. PAINEL RESUMO ──────────────────────────────────────────────────
    pw.Widget painelResumo() {
      PdfColor cor(String s) => s == 'ok' ? green : s == 'warn' ? yellow : red;

      final topCards = [
        ('P. Instalada', '${resultado.totalPotenciaAtiva.toStringAsFixed(1)} kW',
          cor(resultado.totalPotenciaAtiva > 0 ? 'ok' : 'warn')),
        ('P. Demandada', '${resultado.totalPotenciaDemandada.toStringAsFixed(1)} kW', orange),
        ('I. Projeto',   '${resultado.correnteProjeto.toStringAsFixed(1)} A',
          cor(resultado.utilizacaoDisjuntor > 95 ? 'error' : resultado.utilizacaoDisjuntor > 85 ? 'warn' : 'ok')),
        ('Disj. Geral',  '${resultado.disjuntorPolos}P x ${resultado.disjuntorGeral}A',
          cor(resultado.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error'
            : resultado.classificacaoDisjuntor == ClassificacaoDisjuntor.alta ? 'warn' : 'ok')),
        ('FP Medio',     resultado.fatorPotenciaMedio.toStringAsFixed(3),
          cor(resultado.fatorPotenciaMedio >= 0.92 ? 'ok' : resultado.fatorPotenciaMedio >= 0.85 ? 'warn' : 'error')),
        ('Circuitos',    '${resultado.numCircuitos}', navy),
        ('Modulos',      '${resultado.modulosUtilizados}/${resultado.modulosDisponiveis}',
          cor(resultado.percentOcupacao < 80 ? 'ok' : resultado.percentOcupacao < 90 ? 'warn' : 'error')),
      ];

      final botCards = [
        ('Balanceam.',   resultado.classificacaoBalanceamento.label,
          cor(resultado.desbalanceamentoPercent <= 5 ? 'ok' : resultado.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
        ('Desbal.%',     '${resultado.desbalanceamentoPercent.toStringAsFixed(1)}%',
          cor(resultado.desbalanceamentoPercent <= 5 ? 'ok' : resultado.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
        ('Res.Quadro',   '${resultado.percentReservaQuadro.toStringAsFixed(0)}%',
          cor(resultado.percentReservaQuadro >= 20 ? 'ok' : resultado.percentReservaQuadro >= 10 ? 'warn' : 'error')),
        ('Res.Carga',    '${resultado.percentReservaCarga.toStringAsFixed(0)}%',
          cor(resultado.percentReservaCarga >= 20 ? 'ok' : resultado.percentReservaCarga >= 15 ? 'warn' : 'error')),
        ('Queda V.',     '${resultado.quedaTensaoMax.toStringAsFixed(1)}%',
          cor(resultado.quedaTensaoMax <= 4 ? 'ok' : resultado.quedaTensaoMax <= 7 ? 'warn' : 'error')),
        ('Cap.FP',       resultado.necessitaCorrecaoFP
          ? '${resultado.capacitorKvar.toStringAsFixed(1)} kVAr' : 'OK',
          resultado.necessitaCorrecaoFP ? yellow : green),
      ];

      // Gauge do indice geral
      final igCor = resultado.indiceGeral >= 75 ? green : resultado.indiceGeral >= 45 ? yellow : red;
      final gauge = pw.Container(
        width: 48, height: 48,
        decoration: pw.BoxDecoration(
          color: white, shape: pw.BoxShape.circle,
          border: pw.Border.all(color: igCor, width: 2.5),
        ),
        child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Text(resultado.indiceGeral.toStringAsFixed(0),
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: igCor)),
          pw.Text('/100', style: const pw.TextStyle(fontSize: 5.5, color: grey6)),
          pw.Text(resultado.classificacaoIndice.label,
            style: pw.TextStyle(fontSize: 4.5, fontWeight: pw.FontWeight.bold, color: igCor),
            textAlign: pw.TextAlign.center),
        ]),
      );

      return pw.Column(children: [
        // Linha 1: 7 cards + gauge
        pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          ...topCards.map((c) => pw.Expanded(child: pw.Container(
            margin: const pw.EdgeInsets.only(right: 4, bottom: 5),
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: white, borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border(top: pw.BorderSide(color: c.$3, width: 2.5)),
              boxShadow: [pw.BoxShadow(color: const PdfColor(0, 0, 0, 0.06), blurRadius: 3)],
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(c.$2, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: c.$3)),
              pw.SizedBox(height: 1),
              pw.Text(c.$1, style: const pw.TextStyle(fontSize: 6, color: grey6)),
            ]),
          ))),
          pw.SizedBox(width: 4),
          gauge,
        ]),
        // Linha 2: 6 indicadores de status
        pw.Row(children: botCards.map((c) => pw.Expanded(child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 4),
          padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          decoration: pw.BoxDecoration(
            color: PdfColor(c.$3.red, c.$3.green, c.$3.blue, 0.08),
            borderRadius: pw.BorderRadius.circular(4),
            border: pw.Border.all(color: PdfColor(c.$3.red, c.$3.green, c.$3.blue, 0.25), width: 0.5),
          ),
          child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Container(width: 8, height: 8,
              decoration: pw.BoxDecoration(color: c.$3, shape: pw.BoxShape.circle)),
            pw.SizedBox(height: 3),
            pw.Text(c.$2, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: c.$3),
              textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 1),
            pw.Text(c.$1, style: const pw.TextStyle(fontSize: 5.5, color: grey6),
              textAlign: pw.TextAlign.center),
          ]),
        ))).toList()),
      ]);
    }

    // ── 10. DISTRIBUICAO DE CARGAS ────────────────────────────────────────
    pw.Widget distCargas() {
      final r = resultado;
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: grey50, borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border(left: const pw.BorderSide(color: orange, width: 3)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Container(width: 8, height: 8, decoration: const pw.BoxDecoration(color: orange, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 5),
            pw.Text('Distribuicao por Categoria', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navy)),
          ]),
          pw.SizedBox(height: 6),
          if (r.distribuicaoCategorias.isEmpty)
            pw.Text('Sem dados', style: const pw.TextStyle(fontSize: 7, color: grey6))
          else ...[
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: const pw.BoxDecoration(color: navy),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Text('Categoria', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white))),
                pw.SizedBox(width: 35, child: pw.Text('kW', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white), textAlign: pw.TextAlign.right)),
                pw.SizedBox(width: 30, child: pw.Text('%', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white), textAlign: pw.TextAlign.right)),
              ]),
            ),
            ...r.distribuicaoCategorias.take(6).toList().asMap().entries.map((e) {
              final cat = e.value;
              final isOdd = e.key.isOdd;
              PdfColor barCor = cat.percentualTotal >= 50 ? orange : cat.percentualTotal >= 20 ? navy : green;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: pw.BoxDecoration(color: isOdd ? const PdfColor(0.94, 0.94, 0.94) : white),
                child: pw.Row(children: [
                  pw.Expanded(child: pw.Text(cat.nome, style: const pw.TextStyle(fontSize: 7, color: black))),
                  pw.SizedBox(width: 35, child: pw.Text(
                    (cat.percentualTotal * r.totalPotenciaAtiva / 100).toStringAsFixed(2),
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: black),
                    textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 30, child: pw.Text(
                    '${cat.percentualTotal.toStringAsFixed(1)}%',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: barCor),
                    textAlign: pw.TextAlign.right)),
                ]),
              );
            }),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: orange, width: 0.8))),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: navy))),
                pw.SizedBox(width: 35, child: pw.Text(r.totalPotenciaAtiva.toStringAsFixed(2),
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: navy), textAlign: pw.TextAlign.right)),
                pw.SizedBox(width: 30, child: pw.Text('100%',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: navy), textAlign: pw.TextAlign.right)),
              ]),
            ),
          ],
        ]),
      );
    }

    // ── 11. BALANCEAMENTO DE FASES ────────────────────────────────────────
    pw.Widget balancFases() {
      final r = resultado;
      final maxI = [r.correnteFaseA, r.correnteFaseB, r.correnteFaseC].reduce(max);
      final fases = [
        ('Fase A', r.correnteFaseA, const PdfColor(1, 0.2, 0.2)),
        ('Fase B', r.correnteFaseB, const PdfColor(0.2, 0.6, 1.0)),
        ('Fase C', r.correnteFaseC, const PdfColor(1, 0.65, 0.0)),
      ];
      final desbalOk = r.desbalanceamentoPercent <= 5;
      final boxCor = desbalOk ? green : yellow;
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: grey50, borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border(left: const pw.BorderSide(color: navy, width: 3)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Container(width: 8, height: 8, decoration: const pw.BoxDecoration(color: navy, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 5),
            pw.Text('Balanceamento das Fases', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: navy)),
          ]),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: const pw.BoxDecoration(color: navy),
            child: pw.Row(children: [
              pw.SizedBox(width: 45, child: pw.Text('Fase', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white))),
              pw.Expanded(child: pw.Text('Corrente', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white), textAlign: pw.TextAlign.right)),
              pw.SizedBox(width: 38, child: pw.Text('% Max.', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: white), textAlign: pw.TextAlign.right)),
            ]),
          ),
          ...fases.asMap().entries.map((e) {
            final f = e.value;
            final pct = maxI > 0 ? (f.$2 / maxI * 100).clamp(0.0, 100.0) : 0.0;
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
              decoration: pw.BoxDecoration(color: e.key.isOdd ? const PdfColor(0.94, 0.94, 0.94) : white),
              child: pw.Row(children: [
                pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: f.$3, shape: pw.BoxShape.circle)),
                pw.SizedBox(width: 4),
                pw.SizedBox(width: 33, child: pw.Text(f.$1, style: const pw.TextStyle(fontSize: 7, color: black))),
                pw.Expanded(child: pw.Text('${f.$2.toStringAsFixed(2)} A',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: f.$3), textAlign: pw.TextAlign.right)),
                pw.SizedBox(width: 38, child: pw.Text('${pct.toStringAsFixed(0)}%',
                  style: const pw.TextStyle(fontSize: 7, color: grey6), textAlign: pw.TextAlign.right)),
              ]),
            );
          }),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColor(boxCor.red, boxCor.green, boxCor.blue, 0.12),
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: boxCor, width: 0.5),
            ),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Desbalanceamento', style: const pw.TextStyle(fontSize: 6.5, color: grey6)),
                pw.Text('${r.desbalanceamentoPercent.toStringAsFixed(1)}%',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: boxCor)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Classificacao', style: const pw.TextStyle(fontSize: 6.5, color: grey6)),
                pw.Text(r.classificacaoBalanceamento.label,
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: boxCor)),
              ]),
            ]),
          ),
        ]),
      );
    }

    // ── 12. TABELA DE CIRCUITOS ───────────────────────────────────────────
    pw.Widget tabelaCircuitos() {
      if (cargas.isEmpty) return pw.Text('Nenhum circuito ativo.', style: const pw.TextStyle(fontSize: 8, color: grey6));
      return pw.TableHelper.fromTextArray(
        headers: ['#', 'Descricao', 'Tipo', 'Lig.', 'Fase', 'P(W)', 'I(A)', 'Disj(A)', 'Cabo(mm2)', 'dV(%)', 'Status'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6.5, color: white),
        headerDecoration: const pw.BoxDecoration(color: orange),
        data: cargas.asMap().entries.map((e) {
          final c = e.value;
          final dvOk = c.quedaTensaoPercent <= 4;
          final status = dvOk ? 'OK' : c.quedaTensaoPercent <= 7 ? 'Atencao' : 'Critico';
          return [
            '${e.key + 1}',
            c.descricao,
            _tipoShort(c.tipo, descricao: c.descricao, notas: c.notas),
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
        cellStyle: const pw.TextStyle(fontSize: 6.5),
        cellAlignments: {
          0: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.center, 4: pw.Alignment.center,
          5: pw.Alignment.centerRight, 6: pw.Alignment.centerRight,
          7: pw.Alignment.center, 8: pw.Alignment.center, 9: pw.Alignment.center, 10: pw.Alignment.center,
        },
        oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
        border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey300),
      );
    }

    // ── 13. MEMORIA DE CALCULO ────────────────────────────────────────────
    pw.Widget infoCard(List<(String, String)> linhas) => pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: grey50, borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: linhas.map((l) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(children: [
          pw.SizedBox(width: 145, child: pw.Text(l.$1, style: const pw.TextStyle(fontSize: 7.5, color: grey6))),
          pw.Expanded(child: pw.Text(l.$2, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: black))),
        ]),
      )).toList()),
    );

    // ── 14. DIAGNOSTICO TECNICO ───────────────────────────────────────────
    pw.Widget diagnostico() => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      if (resultado.diagnosticoConformes.isNotEmpty) ...[
        diagHeader('CONFORMIDADES', green),
        ...resultado.diagnosticoConformes.map((c) => diagItem('[OK]', c, green)),
        pw.SizedBox(height: 4),
      ],
      if (resultado.diagnosticoProblemas.isNotEmpty) ...[
        diagHeader('PENDENCIAS / PROBLEMAS', red),
        ...resultado.diagnosticoProblemas.map((p) => diagItem('[!] ', p, red)),
        pw.SizedBox(height: 4),
      ],
      if (resultado.diagnosticoRecomendacoes.isNotEmpty) ...[
        diagHeader('RECOMENDACOES TECNICAS', yellow),
        ...resultado.diagnosticoRecomendacoes.map((r) => diagItem('[>] ', r, yellow)),
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
          pw.Text('RECOMENDACOES GERAIS - ABNT NBR 5410',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: navy)),
          pw.SizedBox(height: 4),
          bullet('Manter reserva minima de 20% da capacidade do quadro.'),
          bullet('Prever circuitos dedicados para equipamentos acima de 1.000 W.'),
          bullet('Instalar DPS (Protecao contra Surtos) - ABNT NBR 5419.'),
          bullet('Revisar periodicamente as protecoes conforme ABNT NBR 5410:2004.'),
          bullet('Manter diagrama unifilar atualizado conforme NR-10.'),
        ]),
      ),
    ]);

    // ── 15. PAINEIS TECNICOS (3 cards + secao titulo juntos) ──────────────
    pw.Widget painelTecnico({
      required String titulo,
      required String valor,
      required String subtitulo,
      required String badge,
      required bool ok,
      required List<(String, String)> detalhes,
    }) {
      final cor = ok ? green : yellow;
      return pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: white, borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border(bottom: pw.BorderSide(color: cor, width: 3)),
          boxShadow: [pw.BoxShadow(color: const PdfColor(0, 0, 0, 0.05), blurRadius: 3)],
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(titulo, style: const pw.TextStyle(fontSize: 7, color: grey6)),
          pw.SizedBox(height: 2),
          pw.Text(valor, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: black)),
          pw.SizedBox(height: 2),
          pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 6.5, color: grey6)),
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
              pw.Text(d.$1, style: const pw.TextStyle(fontSize: 6.5, color: grey6)),
              pw.Text(d.$2, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold, color: black)),
            ]),
          )),
        ]),
      );
    }

    pw.Widget paineisTecnicos() => pw.Row(children: [
      pw.Expanded(child: painelTecnico(
        titulo: 'Protecao Geral',
        valor:  '${resultado.disjuntorPolos}P x ${resultado.disjuntorGeral} A',
        subtitulo: 'Utilizacao: ${resultado.utilizacaoDisjuntor.toStringAsFixed(0)}%',
        badge: resultado.classificacaoDisjuntor.label,
        ok: resultado.classificacaoDisjuntor != ClassificacaoDisjuntor.critica,
        detalhes: [
          ('Icc estimada', '${(resultado.correnteCurtoEstimada * 1000).toStringAsFixed(0)} A'),
          ('Cap. interrupcao', '${resultado.capacidadeInterrupcao.toStringAsFixed(0)} kA'),
          ('Seletividade', resultado.seletividadeOk ? 'OK' : 'Verificar'),
        ],
      )),
      pw.SizedBox(width: 6),
      pw.Expanded(child: painelTecnico(
        titulo: 'Reservas e Utilizacao',
        valor:  'Quadro: ${resultado.percentReservaQuadro.toStringAsFixed(0)}%',
        subtitulo: 'Carga: ${resultado.percentReservaCarga.toStringAsFixed(0)}%',
        badge: resultado.percentReservaQuadro >= 20 ? 'Adequada' : 'Atencao',
        ok: resultado.percentReservaQuadro >= 20,
        detalhes: [
          ('Modulos livres', '${resultado.modulosLivres}/${resultado.modulosDisponiveis}'),
          ('Ocup. quadro', '${resultado.percentOcupacao.toStringAsFixed(0)}%'),
          ('I restante', '${resultado.correnteRestante.toStringAsFixed(1)} A'),
        ],
      )),
      pw.SizedBox(width: 6),
      pw.Expanded(child: painelTecnico(
        titulo: 'Correcao do FP',
        valor:  resultado.necessitaCorrecaoFP
          ? '${resultado.capacitorKvar.toStringAsFixed(1)} kVAr' : 'Nao necessario',
        subtitulo: 'FP atual: ${resultado.fatorPotenciaMedio.toStringAsFixed(3)}',
        badge: resultado.fatorPotenciaMedio >= 0.92 ? 'Conforme' : 'Corrigir',
        ok: resultado.fatorPotenciaMedio >= 0.92,
        detalhes: [
          ('FP minimo ANEEL', '0,920'),
          ('Consumo mensal', '${(resultado.totalPotenciaDemandada * 8 * 22).toStringAsFixed(0)} kWh'),
          ('Consumo anual',  '${(resultado.totalPotenciaDemandada * 8 * 264).toStringAsFixed(0)} kWh'),
        ],
      )),
    ]);

    // ── 16. ASSINATURA ────────────────────────────────────────────────────
    pw.Widget assinatura() => pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: grey50, borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: const PdfColor(0.85, 0.85, 0.85), width: 0.5),
      ),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            'Responsavel Tecnico: ${projeto.executora.responsavel.isEmpty ? "N/D" : projeto.executora.responsavel}',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            '${_cargoRegistroLabel(projeto.executora.cargo)}: ${projeto.executora.registro.isEmpty ? "N/D" : projeto.executora.registro}',
            style: const pw.TextStyle(fontSize: 8, color: grey6)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Emitido em: $nowFull', style: const pw.TextStyle(fontSize: 8, color: grey6)),
          pw.Text('ABNT NBR 5410:2004 + Em.1:2008 | 60 Hz', style: const pw.TextStyle(fontSize: 8, color: grey6)),
        ]),
      ]),
    );

    // ── 17. MONTA A PAGINA ────────────────────────────────────────────────
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      header: header,
      footer: footer,
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [

            // Sec 1 — Empresas
            secTitle('1', 'IDENTIFICACAO DAS EMPRESAS'),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: empresaCard('EMPRESA EXECUTORA', [
                if (projeto.executora.razaoSocial.isNotEmpty)  ('Razao Social', projeto.executora.razaoSocial),
                if (projeto.executora.documento.isNotEmpty)    ('CNPJ/CPF', projeto.executora.documento),
                if (projeto.executora.registro.isNotEmpty)     (_cargoRegistroLabel(projeto.executora.cargo), projeto.executora.registro),
                if (projeto.executora.responsavel.isNotEmpty)  ('Responsavel', projeto.executora.responsavel),
                if (projeto.executora.telefone.isNotEmpty)     ('Telefone', projeto.executora.telefone),
                if (projeto.executora.email.isNotEmpty)        ('E-mail', projeto.executora.email),
                if (projeto.executora.enderecoCompleto.isNotEmpty) ('Endereco', projeto.executora.enderecoCompleto),
              ])),
              pw.SizedBox(width: 10),
              pw.Expanded(child: empresaCard('EMPRESA CONTRATANTE', [
                if (projeto.contratante.razaoSocial.isNotEmpty)  ('Razao Social', projeto.contratante.razaoSocial),
                if (projeto.contratante.documento.isNotEmpty)    ('CNPJ/CPF', projeto.contratante.documento),
                if (projeto.contratante.responsavel.isNotEmpty)  ('Responsavel', projeto.contratante.responsavel),
                if (projeto.contratante.telefone.isNotEmpty)     ('Telefone', projeto.contratante.telefone),
                if (projeto.contratante.email.isNotEmpty)        ('E-mail', projeto.contratante.email),
                if (projeto.contratante.enderecoCompleto.isNotEmpty) ('Local/Obra', projeto.contratante.enderecoCompleto),
                if (projeto.contratante.art.isNotEmpty)          ('ART/RRT', projeto.contratante.art),
              ])),
            ]),
            pw.SizedBox(height: 12),

            // Sec 2 — Dados Gerais
            secTitle('2', 'DADOS GERAIS DO PROJETO'),
            dadosGerais(),
            pw.SizedBox(height: 12),

            // Sec 3 — Painel Resumo
            secTitle('3', 'PAINEL RESUMO'),
            painelResumo(),
            pw.SizedBox(height: 12),

            // Sec 4 — Distribuicao + Balanceamento
            secTitle('4', 'DISTRIBUICAO DE CARGAS E BALANCEAMENTO DE FASES'),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: distCargas()),
              pw.SizedBox(width: 10),
              pw.Expanded(child: balancFases()),
            ]),
            pw.SizedBox(height: 12),

            // Sec 5 — Tabela de Circuitos
            secTitle('5', 'DISJUNTORES E CONDUTORES POR CIRCUITO'),
            tabelaCircuitos(),
            pw.SizedBox(height: 12),

            // Sec 6 — Memoria de Calculo
            secTitle('6', 'MEMORIA DE CALCULO - POTENCIAS E CORRENTES'),
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(child: infoCard([
                ('Potencia Ativa Total (P)', '${resultado.totalPotenciaAtiva.toStringAsFixed(3)} kW'),
                ('Potencia Reativa Total (Q)', '${resultado.totalPotenciaReativa.toStringAsFixed(3)} kVAr'),
                ('Potencia Aparente (S)', '${resultado.totalPotenciaAparente.toStringAsFixed(3)} kVA'),
                ('Fator de Potencia Medio', resultado.fatorPotenciaMedio.toStringAsFixed(3)),
                ('Potencia Demandada (com FD)', '${resultado.totalPotenciaDemandada.toStringAsFixed(3)} kW'),
              ])),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCard([
                ('Corrente Fase A', '${resultado.correnteFaseA.toStringAsFixed(2)} A'),
                ('Corrente Fase B', '${resultado.correnteFaseB.toStringAsFixed(2)} A'),
                ('Corrente Fase C', '${resultado.correnteFaseC.toStringAsFixed(2)} A'),
                ('Corrente de Neutro', '${resultado.correnteNeutro.toStringAsFixed(2)} A'),
                ('Corrente Total', '${resultado.correnteTotal.toStringAsFixed(2)} A'),
                ('Corrente de Projeto (x1,25)', '${resultado.correnteProjeto.toStringAsFixed(2)} A'),
                ('Desbalanceamento', '${resultado.desbalanceamentoPercent.toStringAsFixed(1)}%'),
              ])),
            ]),
            pw.SizedBox(height: 12),

            // Sec 7 — Diagnostico
            secTitle('7', 'DIAGNOSTICO TECNICO AUTOMATICO'),
            diagnostico(),
            pw.SizedBox(height: 12),

            // Sec 8 — Paineis Tecnicos (titulo + conteudo no mesmo Column)
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              secTitle('8', 'PAINEIS TECNICOS'),
              paineisTecnicos(),
            ]),
            pw.SizedBox(height: 10),

            // Assinatura
            assinatura(),
            pw.SizedBox(height: 6),
          ]),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (fmt) => doc.save());
  }

  // Helper do cabecalho
  static pw.Widget _hdrRow(String label, String value, PdfColor lCol, PdfColor vCol) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text('$label: ', style: pw.TextStyle(fontSize: 7, color: lCol)),
        pw.Text(value, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: vCol)),
      ]),
    );
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

String _tipoShort(TipoCarga t, {String descricao = '', String notas = ''}) {
  switch (t) {
    case TipoCarga.tug: return 'TUG';
    case TipoCarga.tue: return 'TUE';
    case TipoCarga.motor: return 'Motor';
    case TipoCarga.arCondicionado: return 'A/C';
    case TipoCarga.resistencia: return 'Resist.';
    case TipoCarga.iluminacao: return 'Ilumin.';
    // Para genérico: extrai o tipo especificado das notas [TIPO:xxx] se disponível
    case TipoCarga.generico:
      // Tenta extrair o tipo especificado no campo notas: "[TIPO:Compressor] ..."
      final match = RegExp(r'\[TIPO:([^\]]+)\]').firstMatch(notas);
      if (match != null) return match.group(1)!.trim();
      // Fallback: usa as primeiras palavras da descrição
      if (descricao.isNotEmpty && descricao != 'Carga Genérica') {
        final parts = descricao.split(' ');
        return parts.length > 1 ? parts.take(2).join(' ') : descricao;
      }
      return 'Outro';
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

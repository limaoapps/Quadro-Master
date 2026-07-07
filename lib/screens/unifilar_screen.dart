// lib/screens/unifilar_screen.dart
// Módulo Diagrama Unifilar NBR 5410
// Versão Session 9 — aba integrada, preview SVG real, auto-barramento

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/unifilar.dart';
import '../models/carga.dart';
import '../models/projeto.dart';
import '../theme/app_theme.dart';
import '../widgets/unifilar_svg_builder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal — projetado para ser usado como aba no ProjetoScreen
// (não possui Scaffold/AppBar próprios)
// ─────────────────────────────────────────────────────────────────────────────
class UnifilarTab extends StatefulWidget {
  final Projeto projeto;
  const UnifilarTab({super.key, required this.projeto});

  @override
  State<UnifilarTab> createState() => _UnifilarTabState();
}

class _UnifilarTabState extends State<UnifilarTab> {
  late DiagramaUnifilar _diagrama;
  bool _previewMode = false;
  String? _svgPreview;

  @override
  void initState() {
    super.initState();
    _diagrama = _criarDiagramaDosProjeto();
  }

  /// Constrói o diagrama automaticamente a partir das cargas do projeto
  DiagramaUnifilar _criarDiagramaDosProjeto() {
    final p = widget.projeto;
    final c = p.contratante;
    final now = DateTime.now();
    final dataStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Filtra apenas cargas ativas
    final cargasAtivas = p.cargas.where((cg) => cg.ativo).toList();

    // Calcula corrente total das cargas para dimensionar barramento
    final correnteTotal = cargasAtivas.fold<double>(
      0.0,
      (sum, cg) => sum + cg.corrente,
    );
    // Adiciona 25% de margem de segurança conforme NBR 5410
    final correnteGeral = (correnteTotal * 1.25).ceilToDouble();
    final correnteFinal = correnteGeral < 25 ? 25.0 : correnteGeral;

    // Barramento calculado automaticamente
    final barramentoAuto = TabelaBarramento.calcularBarramento(correnteFinal);

    // Detecta se é trifásico pela maioria das cargas
    final trifasicas = cargasAtivas.where((cg) =>
        cg.ligacao == LigacaoCarga.trifasico).length;
    final faseGeral =
        trifasicas > cargasAtivas.length / 2 ? FaseUnifilar.rst : FaseUnifilar.r;

    // Converte as cargas em circuitos do diagrama unifilar
    final circuitos = <CircuitoUnifilar>[];
    for (int i = 0; i < cargasAtivas.length; i++) {
      final cg = cargasAtivas[i];
      circuitos.add(_cargaParaCircuito(cg, i + 1));
    }

    // Determina origem com base no tipo de quadro
    final vemDo = _inferirVemDo(p);

    return DiagramaUnifilar(
      nomeProjeto: p.nome,
      numeroDocumento: DiagramaUnifilar.gerarNumeroDocumento(),
      data: dataStr,
      revisao: 0,
      vemDo: vemDo,
      correnteGeral: correnteFinal,
      caboGeral: _sugerirCabo(correnteFinal),
      faseGeral: faseGeral,
      temDR: false,
      correnteDR: correnteFinal,
      temDPS: false,
      dpskA: 45,
      dpsV: p.tensao == TensaoAlimentacao.v380 ? 380 : 220,
      barramento: barramentoAuto,
      quadroAterrado: true,
      exibirTerra: true,
      exibirNeutro: true,
      unidadeCircuito: UnidadePotencia.va,
      unidadeQuadro: UnidadePotencia.kva,
      escala: 1.0,
      orientacao: OrientacaoFolha.retrato,
      estiloCanto: EstiloCanto.arredondado,
      centralizar: true,
      fatorDemanda: 1.0,
      clienteNome: c.razaoSocial,
      clienteDocumento: c.documento,
      clienteEndereco: [c.rua, c.numero, c.bairro, c.cidade, c.estado]
          .where((s) => s.isNotEmpty).join(', '),
      clienteTelefone: c.telefone,
      clienteEmail: c.email,
      circuitos: circuitos,
    );
  }

  /// Converte uma Carga em CircuitoUnifilar
  CircuitoUnifilar _cargaParaCircuito(Carga cg, int numero) {
    // Fase do unifilar baseada na ligação da carga
    final fase = _ligacaoParaFase(cg.ligacao, cg.fase);

    // Corrente já calculada na model da Carga
    final corrente = cg.corrente;

    // Bitola sugerida
    final bitola = cg.condutorSugerido;

    // DR: cargas TUG e TUE herdam utilização de DR
    final utilizaDR = cg.utilizaDR;

    // Tensão da carga
    final tensao = cg.tensao;

    // Potência em VA
    final potenciaVA = cg.potenciaAparente;

    return CircuitoUnifilar(
      id: const Uuid().v4(),
      fase: fase,
      corrente: corrente,
      curva: CurvaDisjuntor.c,
      utilizaDR: utilizaDR,
      bitola: bitola,
      potencia: potenciaVA,
      unidadePotencia: UnidadePotencia.va,
      tensao: tensao,
      codigo: 'CIRC. $numero',
      descricao: cg.descricao,
    );
  }

  FaseUnifilar _ligacaoParaFase(LigacaoCarga ligacao, FaseCarga faseCarga) {
    if (ligacao == LigacaoCarga.trifasico) return FaseUnifilar.rst;
    if (ligacao == LigacaoCarga.bifasico) return FaseUnifilar.rs;
    // Monofásico: mapeia pela fase
    switch (faseCarga) {
      case FaseCarga.b: return FaseUnifilar.s;
      case FaseCarga.c: return FaseUnifilar.t;
      default:          return FaseUnifilar.r;
    }
  }

  String _inferirVemDo(Projeto p) {
    switch (p.tipoQuadro) {
      case TipoQuadro.qgbt:         return 'CONCESSIONARIA / TRANSFORMADOR';
      case TipoQuadro.qd:           return 'QGBT / QUADRO GERAL';
      case TipoQuadro.qf:           return 'QGBT / QUADRO GERAL';
      case TipoQuadro.painelEletrico: return 'QGBT / QUADRO DE FORCA';
    }
  }

  double _sugerirCabo(double corrente) {
    if (corrente <= 13)  return 1.5;
    if (corrente <= 18)  return 2.5;
    if (corrente <= 24)  return 4.0;
    if (corrente <= 32)  return 6.0;
    if (corrente <= 43)  return 10.0;
    if (corrente <= 57)  return 16.0;
    if (corrente <= 75)  return 25.0;
    if (corrente <= 92)  return 35.0;
    if (corrente <= 120) return 50.0;
    if (corrente <= 150) return 70.0;
    return 95.0;
  }

  void _update(DiagramaUnifilar novo) => setState(() => _diagrama = novo);

  void _gerarPreview() {
    final svg = UnifilarSvgBuilder().build(_diagrama);
    setState(() {
      _svgPreview = svg;
      _previewMode = true;
    });
  }

  Future<void> _exportarPDF() async {
    try {
      final svg = UnifilarSvgBuilder().build(_diagrama);
      final paisagem = _diagrama.orientacao == OrientacaoFolha.paisagem;
      final pageFormat = paisagem ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

      final doc = pw.Document();

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.SvgImage(svg: svg),
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: '${_diagrama.nomeProjeto} - Diagrama Unifilar',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_previewMode && _svgPreview != null) {
      return _PreviewPage(
        svg: _svgPreview!,
        diagrama: _diagrama,
        onVoltar: () => setState(() => _previewMode = false),
        onExportarPDF: _exportarPDF,
      );
    }

    return _FormularioUnifilar(
      diagrama: _diagrama,
      projeto: widget.projeto,
      onChanged: _update,
      onDesenhar: _gerarPreview,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tela de Preview do SVG — com rendering real via flutter_svg
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewPage extends StatelessWidget {
  final String svg;
  final DiagramaUnifilar diagrama;
  final VoidCallback onVoltar;
  final VoidCallback onExportarPDF;

  const _PreviewPage({
    required this.svg,
    required this.diagrama,
    required this.onVoltar,
    required this.onExportarPDF,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header da preview
        Container(
          color: AppColors.secondary,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: onVoltar,
                    tooltip: 'Voltar ao formulário',
                  ),
                  const Expanded(
                    child: Text(
                      'Pré-visualização',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    tooltip: 'Exportar PDF',
                    onPressed: onExportarPDF,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Área do SVG
        Expanded(
          child: Container(
            color: Colors.grey[300],
            child: InteractiveViewer(
              minScale: 0.3,
              maxScale: 3.0,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: SvgPicture.string(
                      svg,
                      width: 794,
                      height: 1123,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Botão exportar PDF na parte inferior com SafeArea
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onExportarPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text(
                  'EXPORTAR PDF',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulário principal
// ─────────────────────────────────────────────────────────────────────────────
class _FormularioUnifilar extends StatefulWidget {
  final DiagramaUnifilar diagrama;
  final Projeto projeto;
  final ValueChanged<DiagramaUnifilar> onChanged;
  final VoidCallback onDesenhar;

  const _FormularioUnifilar({
    required this.diagrama,
    required this.projeto,
    required this.onChanged,
    required this.onDesenhar,
  });

  @override
  State<_FormularioUnifilar> createState() => _FormularioUnifilarState();
}

class _FormularioUnifilarState extends State<_FormularioUnifilar>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late DiagramaUnifilar _d;

  // Controllers da aba "Informações"
  late TextEditingController _nomeCtrl;
  late TextEditingController _docCtrl;
  late TextEditingController _dataCtrl;
  late TextEditingController _revCtrl;
  late TextEditingController _vemDoCtrl;
  late TextEditingController _corrGeralCtrl;
  late TextEditingController _caboGeralCtrl;
  late TextEditingController _corrDRCtrl;
  late TextEditingController _dpskACtrl;
  late TextEditingController _dpsVCtrl;
  late TextEditingController _barramentoCtrl;
  late TextEditingController _fdCtrl;
  late TextEditingController _escalaCtrl;

  @override
  void initState() {
    super.initState();
    _d = widget.diagrama;
    _tabCtrl = TabController(length: 3, vsync: this);
    _initControllers();
  }

  void _initControllers() {
    _nomeCtrl = TextEditingController(text: _d.nomeProjeto);
    _docCtrl = TextEditingController(text: _d.numeroDocumento);
    _dataCtrl = TextEditingController(text: _d.data);
    _revCtrl = TextEditingController(text: _d.revisao.toString());
    _vemDoCtrl = TextEditingController(text: _d.vemDo);
    _corrGeralCtrl = TextEditingController(text: _d.correnteGeral.toStringAsFixed(0));
    _caboGeralCtrl = TextEditingController(text: _d.caboGeral.toStringAsFixed(0));
    _corrDRCtrl = TextEditingController(text: _d.correnteDR.toStringAsFixed(0));
    _dpskACtrl = TextEditingController(text: _d.dpskA.toStringAsFixed(0));
    _dpsVCtrl = TextEditingController(text: _d.dpsV.toStringAsFixed(0));
    _barramentoCtrl = TextEditingController(text: _d.barramento);
    _fdCtrl = TextEditingController(text: (_d.fatorDemanda * 100).toStringAsFixed(0));
    _escalaCtrl = TextEditingController(text: _d.escala.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in [
      _nomeCtrl, _docCtrl, _dataCtrl, _revCtrl, _vemDoCtrl,
      _corrGeralCtrl, _caboGeralCtrl, _corrDRCtrl, _dpskACtrl, _dpsVCtrl,
      _barramentoCtrl, _fdCtrl, _escalaCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncDiagrama() {
    final corr = double.tryParse(_corrGeralCtrl.text) ?? _d.correnteGeral;
    final barrManual = _barramentoCtrl.text.trim();
    final barrAuto = TabelaBarramento.calcularBarramento(corr);
    final barrFinal = barrManual.isNotEmpty ? barrManual : barrAuto;

    final novo = _d.copyWith(
      nomeProjeto: _nomeCtrl.text,
      numeroDocumento: _docCtrl.text,
      data: _dataCtrl.text,
      revisao: int.tryParse(_revCtrl.text) ?? _d.revisao,
      vemDo: _vemDoCtrl.text,
      correnteGeral: corr,
      caboGeral: double.tryParse(_caboGeralCtrl.text) ?? _d.caboGeral,
      correnteDR: double.tryParse(_corrDRCtrl.text) ?? _d.correnteDR,
      dpskA: double.tryParse(_dpskACtrl.text) ?? _d.dpskA,
      dpsV: double.tryParse(_dpsVCtrl.text) ?? _d.dpsV,
      barramento: barrFinal,
      fatorDemanda: (double.tryParse(_fdCtrl.text) ?? 100) / 100.0,
      escala: double.tryParse(_escalaCtrl.text) ?? _d.escala,
    );
    setState(() => _d = novo);
    widget.onChanged(novo);
  }

  void _atualizarBarramentoAuto() {
    final corr = double.tryParse(_corrGeralCtrl.text) ?? _d.correnteGeral;
    final barrAuto = TabelaBarramento.calcularBarramento(corr);
    _barramentoCtrl.text = barrAuto;
    _syncDiagrama();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Container(
          color: AppColors.secondary,
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: AppColors.primary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Informacoes'),
              Tab(text: 'Circuitos'),
              Tab(text: 'Visual'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _TabInfomacoes(
                d: _d,
                nomeCtrl: _nomeCtrl,
                docCtrl: _docCtrl,
                dataCtrl: _dataCtrl,
                revCtrl: _revCtrl,
                vemDoCtrl: _vemDoCtrl,
                corrGeralCtrl: _corrGeralCtrl,
                caboGeralCtrl: _caboGeralCtrl,
                corrDRCtrl: _corrDRCtrl,
                dpskACtrl: _dpskACtrl,
                dpsVCtrl: _dpsVCtrl,
                barramentoCtrl: _barramentoCtrl,
                fdCtrl: _fdCtrl,
                onChanged: (d) {
                  setState(() => _d = d);
                  widget.onChanged(d);
                },
                onSync: _syncDiagrama,
                onAutoBarramento: _atualizarBarramentoAuto,
              ),
              _TabCircuitos(
                d: _d,
                projeto: widget.projeto,
                onChanged: (d) {
                  setState(() => _d = d);
                  widget.onChanged(d);
                },
              ),
              _TabVisual(
                d: _d,
                escalaCtrl: _escalaCtrl,
                onChanged: (d) {
                  setState(() => _d = d);
                  widget.onChanged(d);
                },
                onSync: _syncDiagrama,
              ),
            ],
          ),
        ),
        // Botão Desenhar — SafeArea para não ficar por trás do navbar do sistema
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _syncDiagrama();
                  widget.onDesenhar();
                },
                icon: const Icon(Icons.draw_outlined),
                label: const Text(
                  'DESENHAR DIAGRAMA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Informações
// ─────────────────────────────────────────────────────────────────────────────
class _TabInfomacoes extends StatelessWidget {
  final DiagramaUnifilar d;
  final TextEditingController nomeCtrl, docCtrl, dataCtrl, revCtrl, vemDoCtrl;
  final TextEditingController corrGeralCtrl, caboGeralCtrl, corrDRCtrl;
  final TextEditingController dpskACtrl, dpsVCtrl, barramentoCtrl, fdCtrl;
  final ValueChanged<DiagramaUnifilar> onChanged;
  final VoidCallback onSync;
  final VoidCallback onAutoBarramento;

  const _TabInfomacoes({
    required this.d,
    required this.nomeCtrl,
    required this.docCtrl,
    required this.dataCtrl,
    required this.revCtrl,
    required this.vemDoCtrl,
    required this.corrGeralCtrl,
    required this.caboGeralCtrl,
    required this.corrDRCtrl,
    required this.dpskACtrl,
    required this.dpsVCtrl,
    required this.barramentoCtrl,
    required this.fdCtrl,
    required this.onChanged,
    required this.onSync,
    required this.onAutoBarramento,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel('Identificacao'),
          _row([
            _field(nomeCtrl, 'Nome do Projeto', Icons.folder_open, onSync),
            _field(docCtrl, 'No. Documento', Icons.numbers, onSync),
          ]),
          const SizedBox(height: 10),
          _row([
            _field(dataCtrl, 'Data', Icons.calendar_today, onSync),
            _field(revCtrl, 'Revisao', Icons.loop, onSync, tipo: TextInputType.number),
          ]),
          const SizedBox(height: 16),

          _secLabel('Entrada do Quadro'),
          _field(vemDoCtrl, 'Vem do (origem)', Icons.input, onSync),
          const SizedBox(height: 10),

          // Disjuntor Geral
          _boxCard('DISJ. GERAL', AppColors.secondary, [
            _row([
              _field(corrGeralCtrl, 'Corrente (A)', Icons.electric_bolt, onSync,
                  tipo: TextInputType.number),
              _field(caboGeralCtrl, 'Cabo (mm2)', Icons.cable, onSync,
                  tipo: TextInputType.number),
            ]),
            const SizedBox(height: 10),
            _faseGeralRow(context),
          ]),
          const SizedBox(height: 10),

          // DR geral
          _checkCard(
            context,
            'DR Geral',
            d.temDR,
            onToggle: (v) => onChanged(d.copyWith(temDR: v)),
            child: _field(corrDRCtrl, 'Corrente DR (A)', Icons.shield, onSync,
                tipo: TextInputType.number),
          ),
          const SizedBox(height: 10),

          // DPS
          _checkCard(
            context,
            'DPS',
            d.temDPS,
            onToggle: (v) => onChanged(d.copyWith(temDPS: v)),
            child: _row([
              _field(dpskACtrl, 'kA', Icons.flash_on, onSync, tipo: TextInputType.number),
              _field(dpsVCtrl, 'V', Icons.electric_meter, onSync, tipo: TextInputType.number),
            ]),
          ),
          const SizedBox(height: 10),

          // Barramento — com botão Auto destacado
          _secLabel('Barramento'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_fix_high, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    const Text(
                      'Calculado automaticamente pelas cargas',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _field(barramentoCtrl, 'Barramento (cobre)',
                          Icons.view_column, onSync),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onAutoBarramento,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Recalcular', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Checkboxes
          _secLabel('Exibicao'),
          Wrap(spacing: 8, children: [
            FilterChip(
              label: const Text('Quadro aterrado'),
              selected: d.quadroAterrado,
              onSelected: (v) => onChanged(d.copyWith(quadroAterrado: v)),
            ),
            FilterChip(
              label: const Text('Exibir Terra'),
              selected: d.exibirTerra,
              onSelected: (v) => onChanged(d.copyWith(exibirTerra: v)),
            ),
            FilterChip(
              label: const Text('Exibir Neutro'),
              selected: d.exibirNeutro,
              onSelected: (v) => onChanged(d.copyWith(exibirNeutro: v)),
            ),
          ]),
          const SizedBox(height: 16),

          // Potência
          _secLabel('Potencia'),
          _row([
            _dropdownField<UnidadePotencia>(
              'Circuitos',
              d.unidadeCircuito,
              UnidadePotencia.values
                  .where((u) => u == UnidadePotencia.va || u == UnidadePotencia.w)
                  .toList(),
              (v) => v!.label,
              (v) => onChanged(d.copyWith(unidadeCircuito: v!)),
            ),
            _dropdownField<UnidadePotencia>(
              'Quadro',
              d.unidadeQuadro,
              UnidadePotencia.values
                  .where((u) => u == UnidadePotencia.kva || u == UnidadePotencia.kw)
                  .toList(),
              (v) => v!.label,
              (v) => onChanged(d.copyWith(unidadeQuadro: v!)),
            ),
          ]),
          const SizedBox(height: 10),
          _field(fdCtrl, 'Fator de Demanda (%)', Icons.percent, onSync,
              tipo: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _faseGeralRow(BuildContext context) {
    return DropdownButtonFormField<FaseUnifilar>(
      initialValue: d.faseGeral,
      decoration: const InputDecoration(
        labelText: 'Fases do Alimentador Geral',
        prefixIcon: Icon(Icons.electrical_services),
      ),
      items: FaseUnifilar.values
          .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
          .toList(),
      onChanged: (v) => onChanged(d.copyWith(faseGeral: v!)),
    );
  }

  Widget _checkCard(
    BuildContext context,
    String titulo,
    bool value, {
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(titulo,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Switch(
              value: value,
              onChanged: onToggle,
              activeThumbColor: AppColors.primary,
            ),
          ]),
          if (value) ...[const SizedBox(height: 8), child],
        ],
      ),
    );
  }

  Widget _boxCard(String titulo, Color color, List<Widget> children) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Circuitos — com botão para recarregar das cargas do projeto
// ─────────────────────────────────────────────────────────────────────────────
class _TabCircuitos extends StatelessWidget {
  final DiagramaUnifilar d;
  final Projeto projeto;
  final ValueChanged<DiagramaUnifilar> onChanged;

  const _TabCircuitos({
    required this.d,
    required this.projeto,
    required this.onChanged,
  });

  void _adicionarCircuito(BuildContext context) {
    final novo = CircuitoUnifilar(
      id: const Uuid().v4(),
      fase: FaseUnifilar.rst,
      corrente: 10,
      curva: CurvaDisjuntor.c,
      utilizaDR: false,
      bitola: 2.5,
      potencia: 0,
      unidadePotencia: d.unidadeCircuito,
      tensao: 380,
      codigo: 'CIRC. ${d.circuitos.length + 1}',
      descricao: '',
    );
    final novos = [...d.circuitos, novo];
    onChanged(d.copyWith(circuitos: novos));
  }

  void _editarCircuito(BuildContext context, int idx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95),
      builder: (_) => _CircuitoFormSheet(
        circuito: d.circuitos[idx],
        numero: idx + 1,
        unidadePadrao: d.unidadeCircuito,
        onSave: (c) {
          final novos = [...d.circuitos];
          novos[idx] = c;
          onChanged(d.copyWith(circuitos: novos));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = d.potenciaTotalkVA;

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        color: Colors.white,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${d.circuitos.length} circuito(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text('Total: ${total.toStringAsFixed(2)} kVA',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          // Botão de adicionar manualmente
          ElevatedButton.icon(
            onPressed: () => _adicionarCircuito(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: d.circuitos.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.cable, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('Nenhuma carga no projeto',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text(
                    'Adicione cargas na aba "Cargas" e\nvolte para ver o diagrama atualizado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                itemCount: d.circuitos.length,
                onReorder: (old, neu) {
                  final novos = [...d.circuitos];
                  final item = novos.removeAt(old);
                  novos.insert(neu > old ? neu - 1 : neu, item);
                  final recodificados = novos.asMap().entries.map((e) {
                    final c = e.value;
                    if (c.codigo.startsWith('CIRC.')) {
                      return c.copyWith(codigo: 'CIRC. ${e.key + 1}');
                    }
                    return c;
                  }).toList();
                  onChanged(d.copyWith(circuitos: recodificados));
                },
                itemBuilder: (ctx, i) {
                  final c = d.circuitos[i];
                  return _CircuitoCard(
                    key: ValueKey(c.id),
                    circuito: c,
                    numero: i + 1,
                    onTap: () => _editarCircuito(context, i),
                    onDelete: () {
                      final novos = [...d.circuitos]..removeAt(i);
                      onChanged(d.copyWith(circuitos: novos));
                    },
                  );
                },
              ),
      ),
    ]);
  }
}

class _CircuitoCard extends StatelessWidget {
  final CircuitoUnifilar circuito;
  final int numero;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CircuitoCard({
    super.key,
    required this.circuito,
    required this.numero,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = circuito;
    final potStr = c.potenciaVA >= 1000
        ? '${(c.potenciaVA / 1000).toStringAsFixed(2)} kVA'
        : '${c.potenciaVA.toStringAsFixed(0)} VA';
    final faseColor = _faseColor(c.fase);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: faseColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            c.fase.label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w800, color: faseColor),
          ),
        ),
        title: Text(
          '${c.codigo} — ${c.descricao.isEmpty ? "(sem descricao)" : c.descricao}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${c.corrente.toStringAsFixed(0)}A (${c.curva.label})  •  #${c.bitola}mm2'
          '  •  $potStr  •  ${c.tensao.toStringAsFixed(0)}V'
          '${c.utilizaDR ? "  •  DR" : ""}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
            onPressed: onTap,
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'Excluir',
          ),
          const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
        ]),
        onTap: onTap,
      ),
    );
  }

  Color _faseColor(FaseUnifilar f) {
    switch (f) {
      case FaseUnifilar.r:   return const Color(0xFFEF5350);
      case FaseUnifilar.s:   return const Color(0xFF42A5F5);
      case FaseUnifilar.t:   return const Color(0xFF66BB6A);
      case FaseUnifilar.rs:  return const Color(0xFFFF7043);
      case FaseUnifilar.rt:  return const Color(0xFFAB47BC);
      case FaseUnifilar.st:  return const Color(0xFF26C6DA);
      case FaseUnifilar.rst: return const Color(0xFF1A1A2E);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulário de circuito (bottom sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _CircuitoFormSheet extends StatefulWidget {
  final CircuitoUnifilar circuito;
  final int numero;
  final UnidadePotencia unidadePadrao;
  final ValueChanged<CircuitoUnifilar> onSave;

  const _CircuitoFormSheet({
    required this.circuito,
    required this.numero,
    required this.unidadePadrao,
    required this.onSave,
  });

  @override
  State<_CircuitoFormSheet> createState() => _CircuitoFormSheetState();
}

class _CircuitoFormSheetState extends State<_CircuitoFormSheet> {
  late FaseUnifilar _fase;
  late CurvaDisjuntor _curva;
  late bool _utilizaDR;
  late UnidadePotencia _unidade;
  late TextEditingController _codigoCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _corrCtrl;
  late TextEditingController _bitolaCtrl;
  late TextEditingController _potenciaCtrl;
  late TextEditingController _tensaoCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.circuito;
    _fase = c.fase;
    _curva = c.curva;
    _utilizaDR = c.utilizaDR;
    _unidade = c.unidadePotencia;
    _codigoCtrl = TextEditingController(text: c.codigo);
    _descCtrl = TextEditingController(text: c.descricao);
    _corrCtrl = TextEditingController(text: c.corrente.toStringAsFixed(0));
    _bitolaCtrl = TextEditingController(text: c.bitola.toString());
    _potenciaCtrl = TextEditingController(text: c.potencia.toStringAsFixed(0));
    _tensaoCtrl = TextEditingController(text: c.tensao.toStringAsFixed(0));
  }

  @override
  void dispose() {
    for (final c in [
      _codigoCtrl,
      _descCtrl,
      _corrCtrl,
      _bitolaCtrl,
      _potenciaCtrl,
      _tensaoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sugerirTensao() {
    final tensao = _fase.isTrifasico ? '380' : '220';
    if (_tensaoCtrl.text.isEmpty) {
      _tensaoCtrl.text = tensao;
    }
  }

  void _salvar() {
    final c = widget.circuito.copyWith(
      codigo: _codigoCtrl.text.isEmpty
          ? 'CIRC. ${widget.numero}'
          : _codigoCtrl.text,
      descricao: _descCtrl.text,
      fase: _fase,
      corrente: double.tryParse(_corrCtrl.text) ?? 10,
      curva: _curva,
      utilizaDR: _utilizaDR,
      bitola: double.tryParse(_bitolaCtrl.text) ?? 2.5,
      potencia: double.tryParse(_potenciaCtrl.text) ?? 0,
      unidadePotencia: _unidade,
      tensao: double.tryParse(_tensaoCtrl.text) ??
          (_fase.isTrifasico ? 380 : 220),
    );
    widget.onSave(c);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              Text('Circuito ${widget.numero}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(children: [
                // Código + Descrição
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _codigoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Codigo',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Descricao',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Fase
                DropdownButtonFormField<FaseUnifilar>(
                  initialValue: _fase,
                  decoration: const InputDecoration(
                    labelText: 'Fase(s)',
                    prefixIcon: Icon(Icons.electrical_services),
                  ),
                  items: FaseUnifilar.values
                      .map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(
                                '${f.label}  (${f.polos} polo${f.polos > 1 ? "s" : ""})'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _fase = v!);
                    _sugerirTensao();
                  },
                ),
                const SizedBox(height: 12),

                // Corrente + Curva
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _corrCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Corrente (A)',
                        prefixIcon: Icon(Icons.bolt),
                        suffixText: 'A',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<CurvaDisjuntor>(
                      initialValue: _curva,
                      decoration: const InputDecoration(
                        labelText: 'Curva',
                        prefixIcon: Icon(Icons.show_chart),
                      ),
                      items: CurvaDisjuntor.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('Curva ${c.label}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _curva = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Bitola + Tensão
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bitolaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Bitola',
                        prefixIcon: Icon(Icons.cable),
                        suffixText: 'mm2',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tensaoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Tensao',
                        prefixIcon: Icon(Icons.flash_on),
                        suffixText: 'V',
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // Potência + Unidade
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: TextFormField(
                      controller: _potenciaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Potencia',
                        prefixIcon: Icon(Icons.power),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<UnidadePotencia>(
                      initialValue: _unidade,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: UnidadePotencia.values
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Text(u.label),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _unidade = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),

                // DR
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _utilizaDR
                        ? AppColors.success.withValues(alpha: 0.06)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _utilizaDR
                          ? AppColors.success.withValues(alpha: 0.3)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(children: [
                    const Text('Utiliza DR neste circuito?',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: _utilizaDR,
                      onChanged: (v) =>
                          setState(() => _utilizaDR = v),
                      activeThumbColor: AppColors.success,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Visual
// ─────────────────────────────────────────────────────────────────────────────
class _TabVisual extends StatelessWidget {
  final DiagramaUnifilar d;
  final TextEditingController escalaCtrl;
  final ValueChanged<DiagramaUnifilar> onChanged;
  final VoidCallback onSync;

  const _TabVisual({
    required this.d,
    required this.escalaCtrl,
    required this.onChanged,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secLabel('Escala'),
          _field(escalaCtrl, 'Escala', Icons.zoom_in, onSync,
              tipo: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),

          _secLabel('Orientacao da Folha A4'),
          ...OrientacaoFolha.values.map((o) {
            final sel = d.orientacao == o;
            return InkWell(
              onTap: () => onChanged(d.copyWith(orientacao: o)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(
                    sel
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: sel ? AppColors.primary : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(o.label),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),

          _secLabel('Estilo do Canto'),
          Row(
            children: EstiloCanto.values.map((e) {
              final sel = d.estiloCanto == e;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(d.copyWith(estiloCanto: e)),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(
                          sel || e == EstiloCanto.arredondado ? 10 : 2),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.label,
                      style: TextStyle(
                        color: sel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _secLabel('Outras opcoes'),
          SwitchListTile(
            value: d.centralizar,
            onChanged: (v) => onChanged(d.copyWith(centralizar: v)),
            title: const Text('Centralizar diagrama na folha'),
            activeThumbColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers compartilhados entre as tabs
// ─────────────────────────────────────────────────────────────────────────────
Widget _secLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    ));

Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children
        .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
        .toList()
      ..removeLast());

Widget _field(
  TextEditingController ctrl,
  String label,
  IconData icon,
  VoidCallback onChanged, {
  TextInputType tipo = TextInputType.text,
}) =>
    TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      onChanged: (_) => onChanged(),
    );

Widget _dropdownField<T>(
  String label,
  T value,
  List<T> items,
  String Function(T?) display,
  ValueChanged<T?> onChanged,
) =>
    DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((v) => DropdownMenuItem<T>(value: v, child: Text(display(v))))
          .toList(),
      onChanged: onChanged,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Mantido por compatibilidade: UnifilarScreen (navega como tela separada)
// Agora redireciona para UnifilarTab
// ─────────────────────────────────────────────────────────────────────────────
class UnifilarScreen extends StatelessWidget {
  final Projeto projeto;
  const UnifilarScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagrama Unifilar',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('NBR 5410',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
      body: UnifilarTab(projeto: projeto),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// CargasScreen — adaptativa por tipo de quadro
// ════════════════════════════════════════════════════════════════════════════
class CargasScreen extends StatelessWidget {
  final Projeto projeto;
  const CargasScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final cargas = prov.projetoAtual?.cargas ?? [];
    final ativas = cargas.where((c) => c.ativo).toList();
    final tipo = prov.projetoAtual?.tipoQuadro ?? TipoQuadro.qd;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (cargas.isNotEmpty) _buildPrevia(ativas, tipo),
          Expanded(
            child: cargas.isEmpty
                ? _buildEmpty(context, tipo)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: cargas.length,
                    itemBuilder: (ctx, i) =>
                        _CargaCard(carga: cargas[i], tipoQuadro: tipo),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCargaSheet(context, tipo),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_labelAdd(tipo),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _labelAdd(TipoQuadro t) {
    switch (t) {
      case TipoQuadro.qgbt:         return 'Add Alimentador';
      case TipoQuadro.qf:           return 'Add Equipamento';
      case TipoQuadro.painelEletrico: return 'Add Componente';
      default:                      return 'Add Carga';
    }
  }

  Widget _buildPrevia(List<Carga> ativas, TipoQuadro tipo) {
    final potTotal = ativas.fold(0.0, (s, c) => s + c.potenciaAtiva) / 1000;
    final iTotal   = ativas.fold(0.0, (s, c) => s + c.corrente);
    final qtd      = ativas.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1B3D), Color(0xFF1a2e5a)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: const Color(0xFF0B1B3D).withValues(alpha: 0.25),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        _previaItem(Icons.bolt, 'Potência', '${potTotal.toStringAsFixed(2)} kW',
            const Color(0xFFFF7A00)),
        _previaDiv(),
        _previaItem(Icons.cable, _labelQtd(tipo), '$qtd', Colors.white),
        _previaDiv(),
        _previaItem(Icons.electric_bolt, 'Corrente', '${iTotal.toStringAsFixed(1)} A',
            const Color(0xFFFF7A00)),
      ]),
    );
  }

  String _labelQtd(TipoQuadro t) {
    switch (t) {
      case TipoQuadro.qgbt:         return 'Alimentadores';
      case TipoQuadro.qf:           return 'Equipamentos';
      case TipoQuadro.painelEletrico: return 'Componentes';
      default:                      return 'Circuitos';
    }
  }

  Widget _previaItem(IconData icon, String label, String value, Color color) =>
      Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65), fontSize: 10)),
      ]));

  Widget _previaDiv() => Container(
      width: 1, height: 36,
      color: Colors.white.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _buildEmpty(BuildContext context, TipoQuadro tipo) {
    final (icon, titulo, subtitulo) = _emptyContent(tipo);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle),
          child: Icon(icon, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(titulo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _addCargaSheet(context, tipo),
          icon: const Icon(Icons.add),
          label: Text(_labelAdd(tipo)),
        ),
      ]),
    );
  }

  (IconData, String, String) _emptyContent(TipoQuadro t) {
    switch (t) {
      case TipoQuadro.qgbt:
        return (Icons.device_hub, 'Nenhum alimentador cadastrado',
            'Adicione os quadros e alimentadores\nque este QGBT alimenta');
      case TipoQuadro.qf:
        return (Icons.precision_manufacturing, 'Nenhum equipamento cadastrado',
            'Adicione os motores e equipamentos\nindustriais deste quadro de força');
      case TipoQuadro.painelEletrico:
        return (Icons.developer_board, 'Nenhum componente cadastrado',
            'Adicione os componentes de\ncomando e automação deste painel');
      default:
        return (Icons.cable, 'Nenhuma carga cadastrada',
            'Adicione os circuitos e equipamentos\ndo seu quadro elétrico');
    }
  }

  void _addCargaSheet(BuildContext context, TipoQuadro tipo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.96),
      builder: (_) => _CargaFormSheet(projetoId: projeto.id, tipoQuadro: tipo),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Card de Carga
// ════════════════════════════════════════════════════════════════════════════
class _CargaCard extends StatelessWidget {
  final Carga carga;
  final TipoQuadro tipoQuadro;
  const _CargaCard({required this.carga, required this.tipoQuadro});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final hasAlerts = carga.alertas.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(carga.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
              color: AppColors.error, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => prov.excluirCarga(carga.id),
        child: GestureDetector(
          onTap: () => _editarCarga(context),
          child: Container(
            decoration: BoxDecoration(
              color: carga.ativo ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: hasAlerts
                  ? Border.all(color: AppColors.warning.withValues(alpha: 0.4))
                  : null,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  // Ícone do tipo
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: _cardColor().withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.center,
                    child: Text(_cardIcon(), style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Expanded(
                          child: Text(carga.descricao,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: carga.ativo
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                decoration: carga.ativo
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (hasAlerts)
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 16),
                      ]),
                      Row(children: [
                        _pill(_subtipoPill(),
                            _cardColor()),
                        const SizedBox(width: 4),
                        _pill(carga.ligacao.label,
                            AppColors.secondary.withValues(alpha: 0.7)),
                        if (carga.utilizaDR) ...[
                          const SizedBox(width: 4),
                          _pill(carga.drTexto, AppColors.success),
                        ],
                      ]),
                    ]),
                  ),
                  Switch(
                    value: carga.ativo,
                    onChanged: (_) => prov.toggleCargaAtiva(carga.id),
                    activeThumbColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ]),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(children: [
                  _metricItem('P. Ativa',
                      '${(carga.potenciaAtiva / 1000).toStringAsFixed(2)} kW'),
                  _metricItem('Corrente',
                      '${carga.corrente.toStringAsFixed(1)} A'),
                  _metricItem('Disjuntor',
                      '${carga.disjuntorSugerido} A'),
                  _metricItem('Condutor',
                      '${carga.condutorSugerido} mm²'),
                ]),
                if (hasAlerts) ...[
                  const SizedBox(height: 6),
                  for (final a in carga.alertas) _alertRow(a),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editarCarga(context),
                      icon: const Icon(Icons.edit_outlined,
                          size: 15, color: AppColors.primary),
                      label: const Text('Editar',
                          style: TextStyle(fontSize: 11, color: AppColors.primary)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    Container(width: 1, height: 18, color: AppColors.divider),
                    TextButton.icon(
                      onPressed: () async {
                        await context.read<AppProvider>().duplicarCarga(carga);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Carga duplicada!'),
                                duration: Duration(seconds: 1)),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined,
                          size: 15, color: AppColors.secondary),
                      label: const Text('Duplicar',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.secondary)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                    Container(width: 1, height: 18, color: AppColors.divider),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Excluir?'),
                            content: Text(
                                'Deseja excluir "${carga.descricao}"?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, false),
                                  child: const Text('Cancelar')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Excluir',
                                    style: TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          await context
                              .read<AppProvider>()
                              .excluirCarga(carga.id);
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 15, color: AppColors.error),
                      label: const Text('Excluir',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.error)),
                      style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  String _cardIcon() {
    if (carga.subtipoQGBT != null) return carga.subtipoQGBT!.icone;
    if (carga.subtipoQF != null) return carga.subtipoQF!.icone;
    if (carga.subtipoPainel != null) return carga.subtipoPainel!.icone;
    return carga.tipo.icone;
  }

  String _subtipoPill() {
    if (carga.subtipoQGBT != null) return carga.subtipoQGBT!.label.split('(').first.trim();
    if (carga.subtipoQF != null) return carga.subtipoQF!.label;
    if (carga.subtipoPainel != null) return carga.subtipoPainel!.label;
    return carga.tipo.label.split('–').first.trim();
  }

  Color _cardColor() {
    switch (tipoQuadro) {
      case TipoQuadro.qgbt:         return const Color(0xFF1565C0);
      case TipoQuadro.qf:           return const Color(0xFF7B1FA2);
      case TipoQuadro.painelEletrico: return const Color(0xFF00695C);
      default:
        switch (carga.tipo) {
          case TipoCarga.motor:        return const Color(0xFF7B1FA2);
          case TipoCarga.tug:          return AppColors.primary;
          case TipoCarga.tue:          return const Color(0xFFE65100);
          case TipoCarga.arCondicionado: return const Color(0xFF0288D1);
          case TipoCarga.resistencia:  return const Color(0xFFC62828);
          case TipoCarga.iluminacao:   return const Color(0xFFF9A825);
          case TipoCarga.generico:     return AppColors.secondary;
        }
    }
  }

  Widget _pill(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: color)));

  Widget _metricItem(String label, String value) => Expanded(
      child: Column(children: [
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]));

  Widget _alertRow(String msg) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 12, color: AppColors.warning),
        const SizedBox(width: 4),
        Expanded(
            child: Text(msg,
                style: const TextStyle(fontSize: 10, color: AppColors.warning))),
      ]));

  void _editarCarga(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.96),
      builder: (sheetCtx) =>
          _CargaFormSheet(cargaExistente: carga, projetoId: '', tipoQuadro: tipoQuadro),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Helpers NBR 5410
// ════════════════════════════════════════════════════════════════════════════
List<double> _tensoesPorLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico: return [127.0, 220.0];
    case LigacaoCarga.bifasico:   return [220.0, 380.0];
    case LigacaoCarga.trifasico:  return [220.0, 380.0];
  }
}

List<FaseCarga> _fasesPorLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico: return [FaseCarga.a, FaseCarga.b, FaseCarga.c];
    case LigacaoCarga.bifasico:   return [FaseCarga.ab, FaseCarga.ac, FaseCarga.bc];
    case LigacaoCarga.trifasico:  return [FaseCarga.abc];
  }
}

double _tensaoPadraoLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico: return 220.0;
    case LigacaoCarga.bifasico:   return 220.0;
    case LigacaoCarga.trifasico:  return 380.0;
  }
}

FaseCarga _fasePadraoLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico: return FaseCarga.a;
    case LigacaoCarga.bifasico:   return FaseCarga.ab;
    case LigacaoCarga.trifasico:  return FaseCarga.abc;
  }
}

String _rotTensao(double v) =>
    v == v.truncateToDouble() ? '${v.toInt()} V' : '$v V';

const List<int> _valoresBtu = [9000, 12000, 18000, 24000, 30000, 36000, 48000, 60000];
double _btuParaWatts(int btu) => btu * 0.29307;

// ════════════════════════════════════════════════════════════════════════════
// Form Sheet — adaptativo por tipo de quadro
// ════════════════════════════════════════════════════════════════════════════
class _CargaFormSheet extends StatefulWidget {
  final String projetoId;
  final Carga? cargaExistente;
  final TipoQuadro tipoQuadro;
  const _CargaFormSheet(
      {required this.projetoId,
      required this.tipoQuadro,
      this.cargaExistente});

  @override
  State<_CargaFormSheet> createState() => _CargaFormSheetState();
}

class _CargaFormSheetState extends State<_CargaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late bool _editMode;

  // QD
  late TipoCarga _tipo;
  late LigacaoCarga _ligacao;
  late FaseCarga _fase;
  late double _tensao;
  late TipoPartida _partida;
  late int _btuSelecionado;
  // DR
  late bool _utilizaDR;
  late String _sensibilidadeDR;

  // QGBT
  late SubtipoQGBT _subtipoQGBT;
  // QF
  late SubtipoQF _subtipoQF;
  // Painel
  late SubtipoPainel _subtipoPainel;

  // Controllers
  late TextEditingController _descCtrl;
  late TextEditingController _potCtrl;

  late TextEditingController _fpCtrl;
  late TextEditingController _fdCtrl;
  late TextEditingController _compCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _rendCtrl;
  late TextEditingController _fsCtrl;
  late TextEditingController _especCtrl;
  late TextEditingController _drOutroCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _fabricanteCtrl;
  late TextEditingController _correnteCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.cargaExistente;
    _editMode  = c != null;

    // QD defaults
    _tipo    = c?.tipo ?? TipoCarga.tug;
    _ligacao = c?.ligacao ?? LigacaoCarga.monofasico;
    _partida = c?.tipoPartida ?? TipoPartida.direta;

    final tensaoCarregada = c?.tensao ?? _tensaoPadraoLigacao(_ligacao);
    final opcoesIniciais  = _tensoesPorLigacao(_ligacao);
    _tensao = opcoesIniciais.contains(tensaoCarregada)
        ? tensaoCarregada : opcoesIniciais.first;

    final faseCarregada = c?.fase ?? _fasePadraoLigacao(_ligacao);
    final fasesIniciais = _fasesPorLigacao(_ligacao);
    _fase = fasesIniciais.contains(faseCarregada)
        ? faseCarregada : fasesIniciais.first;

    if (c != null && c.capacidadeBtu > 0) {
      _btuSelecionado = _valoresBtu.reduce((a, b) =>
          (a - c.capacidadeBtu.round()).abs() <
                  (b - c.capacidadeBtu.round()).abs()
              ? a
              : b);
    } else {
      _btuSelecionado = 12000;
    }

    // DR
    _utilizaDR       = c?.utilizaDR ?? false;
    _sensibilidadeDR = c?.sensibilidadeDR ?? '30mA';

    // QGBT
    _subtipoQGBT = c?.subtipoQGBT ?? SubtipoQGBT.qd;
    // QF
    _subtipoQF = c?.subtipoQF ?? SubtipoQF.motor;
    // Painel
    _subtipoPainel = c?.subtipoPainel ?? SubtipoPainel.contator;

    // Controllers
    _descCtrl      = TextEditingController(text: c?.descricao ?? '');
    _potCtrl       = TextEditingController(
        text: (_tipo == TipoCarga.arCondicionado && c != null)
            ? _btuSelecionado.toString()
            : (c?.potenciaNominal != null && c!.potenciaNominal != 0
                ? c.potenciaNominal.toString()
                : ''));

    _fpCtrl        = TextEditingController(
        text: (c?.fatorPotencia != null ? c!.fatorPotencia.toString() : ''));
    _fdCtrl        = TextEditingController(
        text: (c?.fatorDemanda != null ? c!.fatorDemanda.toString() : ''));
    _compCtrl      = TextEditingController(
        text: (c?.comprimentoRamal != null && c!.comprimentoRamal != 20
            ? c.comprimentoRamal.toString()
            : ''));
    _notasCtrl     = TextEditingController(text: c?.notas ?? '');
    _rendCtrl      = TextEditingController(
        text: (c?.rendimento != null ? c!.rendimento.toString() : ''));
    _fsCtrl        = TextEditingController(
        text: (c?.fatorServico != null ? c!.fatorServico.toString() : ''));
    _drOutroCtrl   = TextEditingController(
        text: (c?.sensibilidadeDROutro != null && c!.sensibilidadeDROutro != 30
            ? c.sensibilidadeDROutro.toString()
            : ''));
    _modeloCtrl    = TextEditingController(text: c?.modelo ?? '');
    _fabricanteCtrl = TextEditingController(text: c?.fabricante ?? '');
    _correnteCtrl  = TextEditingController(
        text: (c?.correnteNominal != null && c!.correnteNominal != 0
            ? c.correnteNominal.toString()
            : ''));

    final tipoEspecStr = c != null && c.tipo == TipoCarga.generico
        ? (RegExp(r'\[TIPO:([^\]]+)\]').firstMatch(c.notas)?.group(1) ?? '')
        : '';
    _especCtrl = TextEditingController(text: tipoEspecStr);
  }

  @override
  void dispose() {
    for (final ctrl in [
      _descCtrl, _potCtrl, _fpCtrl, _fdCtrl, _compCtrl,
      _notasCtrl, _rendCtrl, _fsCtrl, _especCtrl, _drOutroCtrl,
      _modeloCtrl, _fabricanteCtrl, _correnteCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onLigacaoChanged(LigacaoCarga novaLigacao) {
    setState(() {
      _ligacao = novaLigacao;
      final tensoes = _tensoesPorLigacao(novaLigacao);
      final fases   = _fasesPorLigacao(novaLigacao);
      if (!tensoes.contains(_tensao)) _tensao = tensoes.first;
      if (!fases.contains(_fase))     _fase   = fases.first;
    });
  }

  void _setDefaultsForTipo(TipoCarga novoTipo) {
    setState(() {
      _tipo = novoTipo;
      switch (novoTipo) {
        case TipoCarga.tug:
          _onLigacaoChanged(LigacaoCarga.monofasico);
          break;
        case TipoCarga.motor:
          _onLigacaoChanged(LigacaoCarga.trifasico);
          _tensao = 380.0;
          _fase   = FaseCarga.abc;
          break;
        case TipoCarga.arCondicionado:
          _btuSelecionado = 12000;
          _onLigacaoChanged(LigacaoCarga.monofasico);
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                    child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                )),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 4, 20,
                      MediaQuery.of(context).viewInsets.bottom +
                          MediaQuery.of(context).viewPadding.bottom + 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildFormBody(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormBody(BuildContext context) {
    switch (widget.tipoQuadro) {
      case TipoQuadro.qgbt:   return _buildQGBTForm();
      case TipoQuadro.qf:     return _buildQFForm();
      case TipoQuadro.painelEletrico: return _buildPainelForm();
      default:                return _buildQDForm(context);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form QD (existente + DR)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildQDForm(BuildContext context) {
    final tensoes = _tensoesPorLigacao(_ligacao);
    final fases   = _fasesPorLigacao(_ligacao);
    final isAC    = _tipo == TipoCarga.arCondicionado;
    final isMotor = _tipo == TipoCarga.motor;
    final isTugTue = _tipo == TipoCarga.tug || _tipo == TipoCarga.tue;

    return [
      _formHeader('QD – Quadro de Distribuição'),

      // Tipo de carga
      DropdownButtonFormField<TipoCarga>(
        value: _tipo,
        decoration: const InputDecoration(
            labelText: 'Tipo de Carga', prefixIcon: Icon(Icons.category)),
        items: TipoCarga.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => _setDefaultsForTipo(v!),
      ),
      const SizedBox(height: 12),

      // Genérico spec
      if (_tipo == TipoCarga.generico) ...[
        _infoBox(
          'Carga Genérica — especifique abaixo',
          child: TextFormField(
            controller: _especCtrl,
            decoration: const InputDecoration(
              labelText: 'Tipo da carga (aparecerá no PDF)',
              hintText: 'Ex: Compressor, Bomba, Forno...',
              prefixIcon: Icon(Icons.edit),
              filled: true, fillColor: Colors.white,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Especifique o tipo' : null,
          ),
        ),
        const SizedBox(height: 12),
      ],

      // Descrição
      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Descrição do Circuito',
          hintText: 'Ex: Iluminação Sala, Tomadas Cozinha...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
      ),
      const SizedBox(height: 12),

      // Potência
      isAC
          ? _btuDropdown()
          : TextFormField(
              controller: _potCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isMotor ? 'Potência (cv)' : 'Potência (W)',
                hintText: isMotor ? 'Ex: 5.5' : 'Ex: 1500',
                prefixIcon: const Icon(Icons.bolt),
                suffixText: isMotor ? 'cv' : 'W',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
      const SizedBox(height: 12),

      // Ligação
      DropdownButtonFormField<LigacaoCarga>(
        value: _ligacao,
        decoration: const InputDecoration(
            labelText: 'Ligação',
            prefixIcon: Icon(Icons.account_tree_outlined)),
        items: LigacaoCarga.values.map((l) => DropdownMenuItem(
          value: l, child: Text(l.label),
        )).toList(),
        onChanged: (v) => _onLigacaoChanged(v!),
      ),
      const SizedBox(height: 12),

      // Tensão
      DropdownButtonFormField<double>(
        value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
        decoration: const InputDecoration(
          labelText: 'Tensão (NBR 5410)',
          prefixIcon: Icon(Icons.flash_on),
          helperText: 'Opções conforme tipo de ligação',
        ),
        items: tensoes.map((v) => DropdownMenuItem<double>(
          value: v, child: Text(_rotTensao(v)),
        )).toList(),
        onChanged: (v) => setState(() => _tensao = v!),
      ),
      const SizedBox(height: 12),

      // Fase
      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(
          labelText: 'Fase(s) Alocada(s)',
          prefixIcon: Icon(Icons.electrical_services),
          helperText: 'Opções conforme tipo de ligação',
        ),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(
          value: f, child: Text('Fase ${f.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),
      _NbrInfoBanner(ligacao: _ligacao, tensao: _tensao),
      const SizedBox(height: 12),

      // FP + FD
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fator de Potência',
              hintText: 'Ex: 0.92',
              prefixIcon: Icon(Icons.tune),
            ),
            validator: (v) {
              final d = double.tryParse(v ?? '');
              if (d == null) return 'Inválido';
              if (d < 0.01 || d > 1.0) return '0,01–1,00';
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fdCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fator Demanda',
              hintText: 'Ex: 100',
              prefixIcon: Icon(Icons.percent),
              suffixText: '%',
            ),
            validator: (v) {
              final d = double.tryParse(v ?? '');
              if (d == null) return 'Inválido';
              if (d <= 0 || d > 100) return '1–100%';
              return null;
            },
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Motor params
      if (isMotor) ...[
        _infoBox('Parâmetros do Motor',
            color: const Color(0xFF7B1FA2),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _rendCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Rendimento η',
                      hintText: 'Ex: 0.92',
                    ),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d != null && (d <= 0 || d > 1)) return '0,1–1,0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _fsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Fator Serviço',
                      hintText: 'Ex: 1.15',
                    ),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d != null && d < 1.0) return '≥ 1,0';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<TipoPartida>(
                value: _partida,
                decoration:
                    const InputDecoration(labelText: 'Tipo de Partida'),
                items: TipoPartida.values.map((p) => DropdownMenuItem(
                  value: p, child: Text(p.label),
                )).toList(),
                onChanged: (v) => setState(() => _partida = v!),
              ),
            ])),
        const SizedBox(height: 12),
      ],

      // Comprimento ramal
      TextFormField(
        controller: _compCtrl,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Comprimento do Ramal (m)',
          hintText: 'Ex: 20',
          prefixIcon: Icon(Icons.straighten),
          suffixText: 'm',
          helperText: 'Necessário para cálculo de ΔV%',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final d = double.tryParse(v);
          if (d != null && d <= 0) return 'Informe valor > 0';
          return null;
        },
      ),
      const SizedBox(height: 12),

      // ── PROTEÇÃO DR (TUG e TUE) ──────────────────────────────────────
      if (isTugTue) ...[
        _sectionLabel('Proteção DR', Icons.shield_outlined, AppColors.success),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Utiliza DR?
            Row(children: [
              const Expanded(
                  child: Text('Utiliza DR?',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              Switch(
                value: _utilizaDR,
                onChanged: (v) => setState(() => _utilizaDR = v),
                activeColor: AppColors.success,
              ),
            ]),
            if (_utilizaDR) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _sensibilidadeDR,
                decoration: const InputDecoration(
                    labelText: 'Sensibilidade do DR',
                    prefixIcon: Icon(Icons.shield)),
                items: ['30mA', '100mA', '300mA', 'outro']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == 'outro' ? 'Outro valor' : s),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _sensibilidadeDR = v!),
              ),
              if (_sensibilidadeDR == 'outro') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _drOutroCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sensibilidade (mA)',
                    hintText: 'Ex: 500',
                    prefixIcon: Icon(Icons.numbers),
                    suffixText: 'mA',
                  ),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0) return 'Informe valor válido';
                    return null;
                  },
                ),
              ],
            ],
          ]),
        ),
        const SizedBox(height: 12),
      ],

      // Notas
      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notas Técnicas',
          hintText: 'Observações adicionais...',
          prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form QGBT
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildQGBTForm() {
    final tensoes = _tensoesPorLigacao(_ligacao);
    final fases   = _fasesPorLigacao(_ligacao);

    return [
      _formHeader('QGBT – Quadro Geral de Baixa Tensão'),

      // Subtipo
      DropdownButtonFormField<SubtipoQGBT>(
        value: _subtipoQGBT,
        decoration: const InputDecoration(
            labelText: 'Tipo de Alimentador',
            prefixIcon: Icon(Icons.device_hub)),
        items: SubtipoQGBT.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _subtipoQGBT = v!),
      ),
      const SizedBox(height: 12),

      // Descrição / Nome
      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Nome / Identificação',
          hintText: 'Ex: QD-Piso 1, QF-Produção...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
      ),
      const SizedBox(height: 12),

      // Potência
      TextFormField(
        controller: _potCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Potência Instalada (W)',
          hintText: 'Ex: 5000',
          prefixIcon: Icon(Icons.bolt),
          suffixText: 'W',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
      ),
      const SizedBox(height: 12),

      // Corrente + FP
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _correnteCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Corrente (A)',
              hintText: 'Ex: 25.5',
              prefixIcon: Icon(Icons.electric_bolt),
              suffixText: 'A',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'FP',
              hintText: 'Ex: 0.92',
              prefixIcon: Icon(Icons.tune),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Ligação
      DropdownButtonFormField<LigacaoCarga>(
        value: _ligacao,
        decoration: const InputDecoration(
            labelText: 'Ligação',
            prefixIcon: Icon(Icons.account_tree_outlined)),
        items: LigacaoCarga.values.map((l) => DropdownMenuItem(
          value: l, child: Text(l.label),
        )).toList(),
        onChanged: (v) => _onLigacaoChanged(v!),
      ),
      const SizedBox(height: 12),

      // Tensão
      DropdownButtonFormField<double>(
        value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
        decoration: const InputDecoration(
            labelText: 'Tensão', prefixIcon: Icon(Icons.flash_on)),
        items: tensoes.map((v) => DropdownMenuItem<double>(
          value: v, child: Text(_rotTensao(v)),
        )).toList(),
        onChanged: (v) => setState(() => _tensao = v!),
      ),
      const SizedBox(height: 12),

      // Fase
      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(
            labelText: 'Fase(s)', prefixIcon: Icon(Icons.electrical_services)),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(
          value: f, child: Text('Fase ${f.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      // Disjuntor + Cabo
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _fdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Disjuntor (A)',
              hintText: 'Ex: 63',
              prefixIcon: Icon(Icons.electric_meter),
              suffixText: 'A',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _rendCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cabo (mm²)',
              hintText: 'Ex: 10',
              prefixIcon: Icon(Icons.cable),
              suffixText: 'mm²',
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Distância
      TextFormField(
        controller: _compCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Distância / Comprimento (m)',
          hintText: 'Ex: 30',
          prefixIcon: Icon(Icons.straighten),
          suffixText: 'm',
        ),
      ),
      const SizedBox(height: 12),

      // Notas
      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações',
          hintText: 'Informações adicionais...',
          prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form QF (industrial)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildQFForm() {
    final fases   = _fasesPorLigacao(_ligacao);

    return [
      _formHeader('QF – Quadro de Força'),

      // Subtipo equipamento
      DropdownButtonFormField<SubtipoQF>(
        value: _subtipoQF,
        decoration: const InputDecoration(
            labelText: 'Tipo de Equipamento',
            prefixIcon: Icon(Icons.precision_manufacturing)),
        items: SubtipoQF.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _subtipoQF = v!),
      ),
      const SizedBox(height: 12),

      // Descrição
      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Identificação / Nome',
          hintText: 'Ex: Motor Bomba 1, Compressor AR...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe a identificação' : null,
      ),
      const SizedBox(height: 12),

      // Potência (cv)
      TextFormField(
        controller: _potCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Potência (cv)',
          hintText: 'Ex: 5.5',
          prefixIcon: Icon(Icons.bolt),
          suffixText: 'cv',
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
      ),
      const SizedBox(height: 12),

      // Corrente nominal
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _correnteCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Corrente Nominal (A)',
              hintText: 'Ex: 12.5',
              prefixIcon: Icon(Icons.electric_bolt),
              suffixText: 'A',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fator de Potência',
              hintText: 'Ex: 0.87',
              prefixIcon: Icon(Icons.tune),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Rendimento + Fator Serviço
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _rendCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rendimento η',
              hintText: 'Ex: 0.92',
              prefixIcon: Icon(Icons.speed),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fator Serviço',
              hintText: 'Ex: 1.15',
              prefixIcon: Icon(Icons.settings),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Método de partida
      DropdownButtonFormField<TipoPartida>(
        value: _partida,
        decoration: const InputDecoration(
            labelText: 'Método de Partida',
            prefixIcon: Icon(Icons.play_circle_outline)),
        items: TipoPartida.values.map((p) => DropdownMenuItem(
          value: p, child: Text(p.label),
        )).toList(),
        onChanged: (v) => setState(() => _partida = v!),
      ),
      const SizedBox(height: 12),

      // Ligação + Tensão
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<LigacaoCarga>(
            value: _ligacao,
            decoration: const InputDecoration(labelText: 'Ligação',
                prefixIcon: Icon(Icons.account_tree_outlined)),
            items: LigacaoCarga.values.map((l) => DropdownMenuItem(
              value: l, child: Text(l.label),
            )).toList(),
            onChanged: (v) => _onLigacaoChanged(v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<double>(
            value: _tensoesPorLigacao(_ligacao).contains(_tensao)
                ? _tensao : _tensoesPorLigacao(_ligacao).first,
            decoration: const InputDecoration(labelText: 'Tensão',
                prefixIcon: Icon(Icons.flash_on)),
            items: _tensoesPorLigacao(_ligacao).map((v) => DropdownMenuItem<double>(
              value: v, child: Text(_rotTensao(v)),
            )).toList(),
            onChanged: (v) => setState(() => _tensao = v!),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Fase
      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(
            labelText: 'Fase(s)', prefixIcon: Icon(Icons.electrical_services)),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(
          value: f, child: Text('Fase ${f.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      // Comprimento
      TextFormField(
        controller: _compCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Comprimento do Ramal (m)',
          hintText: 'Ex: 25',
          prefixIcon: Icon(Icons.straighten),
          suffixText: 'm',
        ),
      ),
      const SizedBox(height: 12),

      // FD
      TextFormField(
        controller: _fdCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Fator de Demanda (%)',
          hintText: 'Ex: 100',
          prefixIcon: Icon(Icons.percent),
          suffixText: '%',
        ),
      ),
      const SizedBox(height: 12),

      // Notas
      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações',
          hintText: 'Método de partida, regime de trabalho...',
          prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Form Painel Elétrico
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildPainelForm() {
    final tensoes = _tensoesPorLigacao(_ligacao);
    final fases   = _fasesPorLigacao(_ligacao);

    return [
      _formHeader('Painel Elétrico – Comando e Automação'),

      // Subtipo
      DropdownButtonFormField<SubtipoPainel>(
        value: _subtipoPainel,
        decoration: const InputDecoration(
            labelText: 'Tipo de Componente',
            prefixIcon: Icon(Icons.developer_board)),
        items: SubtipoPainel.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _subtipoPainel = v!),
      ),
      const SizedBox(height: 12),

      // Descrição
      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Identificação / Tag',
          hintText: 'Ex: INV-01, CLP-Linha-A...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Informe a identificação' : null,
      ),
      const SizedBox(height: 12),

      // Modelo + Fabricante
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _modeloCtrl,
            decoration: const InputDecoration(
              labelText: 'Modelo',
              hintText: 'Ex: CFW300',
              prefixIcon: Icon(Icons.devices),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fabricanteCtrl,
            decoration: const InputDecoration(
              labelText: 'Fabricante',
              hintText: 'Ex: WEG, Siemens...',
              prefixIcon: Icon(Icons.factory),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Potência + Corrente
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _potCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Potência (W)',
              hintText: 'Ex: 500',
              prefixIcon: Icon(Icons.bolt),
              suffixText: 'W',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _correnteCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Corrente (A)',
              hintText: 'Ex: 2.5',
              prefixIcon: Icon(Icons.electric_bolt),
              suffixText: 'A',
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Tensão
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<double>(
            value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
            decoration: const InputDecoration(labelText: 'Tensão',
                prefixIcon: Icon(Icons.flash_on)),
            items: tensoes.map((v) => DropdownMenuItem<double>(
              value: v, child: Text(_rotTensao(v)),
            )).toList(),
            onChanged: (v) => setState(() => _tensao = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<LigacaoCarga>(
            value: _ligacao,
            decoration: const InputDecoration(labelText: 'Nº Fases',
                prefixIcon: Icon(Icons.account_tree_outlined)),
            items: LigacaoCarga.values.map((l) => DropdownMenuItem(
              value: l, child: Text(l.label),
            )).toList(),
            onChanged: (v) => _onLigacaoChanged(v!),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Fase
      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(
            labelText: 'Fase(s)', prefixIcon: Icon(Icons.electrical_services)),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(
          value: f, child: Text('Fase ${f.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      // FP
      TextFormField(
        controller: _fpCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Fator de Potência',
          hintText: 'Ex: 0.92',
          prefixIcon: Icon(Icons.tune),
        ),
      ),
      const SizedBox(height: 12),

      // Notas
      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações',
          hintText: 'Especificações técnicas...',
          prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Widgets helper
  // ─────────────────────────────────────────────────────────────────────────
  Widget _formHeader(String titulo) => Column(children: [
        Row(children: [
          Text(
            _editMode ? 'Editar' : 'Novo',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (_editMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _excluir,
            ),
        ]),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 14),
      ]);

  Widget _sectionLabel(String titulo, IconData icon, Color cor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(titulo,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
        ]),
      );

  Widget _infoBox(String titulo,
      {required Widget child, Color color = AppColors.primary}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info_outline, size: 14, color: color),
            const SizedBox(width: 4),
            Text(titulo,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget _salvarBtn() => Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _salvar,
            icon: Icon(_editMode ? Icons.save_outlined : Icons.add_circle_outline),
            label: Text(_editMode ? 'Atualizar' : 'Adicionar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]);

  Widget _btuDropdown() => DropdownButtonFormField<int>(
        value: _btuSelecionado,
        decoration: const InputDecoration(
          labelText: 'Capacidade (BTU/h)',
          prefixIcon: Icon(Icons.ac_unit),
          helperText: 'Converte para W internamente',
        ),
        items: _valoresBtu.map((btu) => DropdownMenuItem<int>(
          value: btu,
          child: Text(
            '${(btu / 1000).toStringAsFixed(0)} mil BTU/h'
            '  ≈ ${_btuParaWatts(btu).toStringAsFixed(0)} W',
            style: const TextStyle(fontSize: 13),
          ),
        )).toList(),
        onChanged: (v) => setState(() => _btuSelecionado = v!),
      );

  // ─────────────────────────────────────────────────────────────────────────
  // Salvar
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _salvar() async {
    // Força exibição de todos os erros de validação antes de prosseguir
    final formValido = _formKey.currentState!.validate();
    if (!formValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrija os campos marcados em vermelho'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final prov = context.read<AppProvider>();

    final double potNominal;
    if (_tipo == TipoCarga.arCondicionado &&
        widget.tipoQuadro == TipoQuadro.qd) {
      potNominal = _btuParaWatts(_btuSelecionado);
    } else {
      potNominal = double.tryParse(_potCtrl.text) ?? 0;
    }

    final notasFinais = _tipo == TipoCarga.generico &&
            _especCtrl.text.trim().isNotEmpty
        ? '[TIPO:${_especCtrl.text.trim()}] ${_notasCtrl.text}'.trim()
        : _notasCtrl.text;

    // Subtipo correto por tipo de quadro
    SubtipoQGBT? sqgbt;
    SubtipoQF? sqf;
    SubtipoPainel? spainel;
    switch (widget.tipoQuadro) {
      case TipoQuadro.qgbt:
        sqgbt = _subtipoQGBT;
        break;
      case TipoQuadro.qf:
        sqf = _subtipoQF;
        break;
      case TipoQuadro.painelEletrico:
        spainel = _subtipoPainel;
        break;
      default:
        break;
    }

    // Tipo de carga correto por quadro
    TipoCarga tipoFinal = _tipo;
    if (widget.tipoQuadro == TipoQuadro.qgbt) {
      tipoFinal = TipoCarga.generico;
    } else if (widget.tipoQuadro == TipoQuadro.qf) {
      tipoFinal = TipoCarga.motor;
    } else if (widget.tipoQuadro == TipoQuadro.painelEletrico) {
      tipoFinal = TipoCarga.generico;
    }

    final carga = Carga(
      id:              widget.cargaExistente?.id ?? const Uuid().v4(),
      descricao:       _descCtrl.text.trim().isEmpty
          ? 'Sem descrição' : _descCtrl.text.trim(),
      tipo:            tipoFinal,
      quantidade:      1,
      potenciaNominal: potNominal,
      ligacao:         _ligacao,
      tensao:          _tensao,
      fatorPotencia:   double.tryParse(_fpCtrl.text) ?? 0.92,
      fatorDemanda:    double.tryParse(_fdCtrl.text) ?? 100,
      fase:            _fase,
      notas:           notasFinais,
      rendimento:      double.tryParse(_rendCtrl.text) ?? 0.90,
      fatorServico:    double.tryParse(_fsCtrl.text) ?? 1.15,
      correnteNominal: double.tryParse(_correnteCtrl.text) ?? 0,
      tipoPartida:     _partida,
      capacidadeBtu:   _tipo == TipoCarga.arCondicionado
          ? _btuSelecionado.toDouble() : 0,
      comprimentoRamal: double.tryParse(_compCtrl.text) ?? 20,
      // DR
      utilizaDR:        _utilizaDR,
      sensibilidadeDR:  _sensibilidadeDR,
      sensibilidadeDROutro: double.tryParse(_drOutroCtrl.text) ?? 30,
      // Subtipos
      subtipoQGBT: sqgbt,
      subtipoQF:   sqf,
      subtipoPainel: spainel,
      modelo:      _modeloCtrl.text,
      fabricante:  _fabricanteCtrl.text,
      // Preserva status ativo da carga original ao editar
      ativo:       widget.cargaExistente?.ativo ?? true,
    );

    if (_editMode) {
      await prov.atualizarCarga(carga);
    } else {
      await prov.adicionarCarga(carga);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir?'),
        content: const Text('Esta carga será removida do projeto.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && widget.cargaExistente != null && mounted) {
      await context.read<AppProvider>().excluirCarga(widget.cargaExistente!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Widget NBR 5410 Banner
// ════════════════════════════════════════════════════════════════════════════
class _NbrInfoBanner extends StatelessWidget {
  final LigacaoCarga ligacao;
  final double tensao;
  const _NbrInfoBanner({required this.ligacao, required this.tensao});

  @override
  Widget build(BuildContext context) {
    final (icon, cor, texto) = _info();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: cor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: TextStyle(
                  fontSize: 11, color: cor, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }

  (IconData, Color, String) _info() {
    switch (ligacao) {
      case LigacaoCarga.monofasico:
        return (Icons.info_outline, const Color(0xFF0277BD),
            'NBR 5410 — Monofásico: 127 V ou 220 V  ·  Fase individual (A, B ou C)');
      case LigacaoCarga.bifasico:
        return (Icons.info_outline, const Color(0xFF558B2F),
            'NBR 5410 — Bifásico: 220 V ou 380 V  ·  Duas fases: A+B, A+C ou B+C');
      case LigacaoCarga.trifasico:
        return (Icons.warning_amber_rounded, const Color(0xFFE65100),
            'NBR 5410 — Trifásico: 220 V ou 380 V  ·  127 V não permitido  ·  Obrigatório ABC');
    }
  }
}

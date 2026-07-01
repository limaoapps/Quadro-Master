import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../theme/app_theme.dart';

class CargasScreen extends StatelessWidget {
  final Projeto projeto;
  const CargasScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final cargas = prov.projetoAtual?.cargas ?? [];
    final ativas = cargas.where((c) => c.ativo).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Prévia de totais ──────────────────────────────────────
          if (cargas.isNotEmpty) _buildPrevia(ativas),
          // ── Lista de cargas ───────────────────────────────────────
          Expanded(
            child: cargas.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: cargas.length,
                    itemBuilder: (ctx, i) => _CargaCard(carga: cargas[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCargaSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Carga', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildPrevia(List<Carga> ativas) {
    final potTotal = ativas.fold(0.0, (s, c) => s + c.potenciaAtiva) / 1000;
    final iTotal   = ativas.fold(0.0, (s, c) => s + c.corrente);
    final qtdCirc  = ativas.length;

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
        boxShadow: [BoxShadow(color: const Color(0xFF0B1B3D).withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _previaItem(
            icon: Icons.bolt,
            label: 'Potência',
            value: '${potTotal.toStringAsFixed(2)} kW',
            color: const Color(0xFFFF7A00),
          ),
          _previaDiv(),
          _previaItem(
            icon: Icons.cable,
            label: 'Circuitos',
            value: '$qtdCirc',
            color: Colors.white,
          ),
          _previaDiv(),
          _previaItem(
            icon: Icons.electric_bolt,
            label: 'Corrente',
            value: '${iTotal.toStringAsFixed(1)} A',
            color: const Color(0xFFFF7A00),
          ),
        ],
      ),
    );
  }

  Widget _previaItem({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Text(value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _previaDiv() => Container(
    width: 1, height: 36,
    color: Colors.white.withValues(alpha: 0.2),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cable, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Nenhuma carga cadastrada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Adicione os circuitos e equipamentos\ndo seu quadro elétrico',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _addCargaSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Carga'),
          ),
        ],
      ),
    );
  }

  void _addCargaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.96,
      ),
      builder: (_) => _CargaFormSheet(projetoId: projeto.id),
    );
  }
}

class _CargaCard extends StatelessWidget {
  final Carga carga;
  const _CargaCard({required this.carga});

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
          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => prov.excluirCarga(carga.id),
        child: GestureDetector(
          onTap: () => _editarCarga(context),
          child: Container(
            decoration: BoxDecoration(
              color: carga.ativo ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: hasAlerts ? Border.all(color: AppColors.warning.withValues(alpha: 0.4)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Tipo icon
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: _colorForTipo(carga.tipo).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(carga.tipo.icone, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(carga.descricao,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: carga.ativo ? AppColors.textPrimary : AppColors.textSecondary,
                                      decoration: carga.ativo ? null : TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasAlerts)
                                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                              ],
                            ),
                            Row(
                              children: [
                                _pill(carga.tipo.label.split('–').first.trim(), _colorForTipo(carga.tipo)),
                                const SizedBox(width: 4),
                                _pill(carga.ligacao.label, AppColors.secondary.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                _pill('Fase ${carga.fase.label}', _faseColor(carga.fase)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: carga.ativo,
                        onChanged: (_) => prov.toggleCargaAtiva(carga.id),
                        activeThumbColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metricItem('P. Ativa', '${(carga.potenciaAtiva / 1000).toStringAsFixed(2)} kW'),
                      _metricItem('Corrente', '${carga.corrente.toStringAsFixed(1)} A'),
                      _metricItem('Disjuntor', '${carga.disjuntorSugerido} A'),
                      _metricItem('Condutor', '${carga.condutorSugerido} mm²'),
                    ],
                  ),
                  if (hasAlerts) ...[
                    const SizedBox(height: 6),
                    for (final a in carga.alertas)
                      _alertRow(a),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editarCarga(context),
                        icon: const Icon(Icons.edit_outlined, size: 15, color: AppColors.primary),
                        label: const Text('Editar', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Container(width: 1, height: 18, color: AppColors.divider),
                      TextButton.icon(
                        onPressed: () async {
                          await context.read<AppProvider>().duplicarCarga(carga);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Carga duplicada!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_outlined, size: 15, color: AppColors.secondary),
                        label: const Text('Duplicar', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Container(width: 1, height: 18, color: AppColors.divider),
                      TextButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Excluir carga?'),
                              content: Text('Deseja excluir "${carga.descricao}"?\n\nEsta ação não pode ser desfeita.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Excluir',
                                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await context.read<AppProvider>().excluirCarga(carga.id);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                        label: const Text('Excluir', style: TextStyle(fontSize: 11, color: AppColors.error)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _metricItem(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    ),
  );

  Widget _alertRow(String msg) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 12, color: AppColors.warning),
        const SizedBox(width: 4),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 10, color: AppColors.warning))),
      ],
    ),
  );

  Color _colorForTipo(TipoCarga t) {
    switch (t) {
      case TipoCarga.motor: return const Color(0xFF7B1FA2);
      case TipoCarga.tug: return AppColors.primary;
      case TipoCarga.tue: return const Color(0xFFE65100);
      case TipoCarga.arCondicionado: return const Color(0xFF0288D1);
      case TipoCarga.resistencia: return const Color(0xFFC62828);
      case TipoCarga.iluminacao: return const Color(0xFFF9A825);
      case TipoCarga.generico: return AppColors.secondary;
    }
  }

  Color _faseColor(FaseCarga f) {
    switch (f) {
      case FaseCarga.a:   return AppColors.phaseA;
      case FaseCarga.b:   return AppColors.phaseB;
      case FaseCarga.c:   return AppColors.phaseC;
      case FaseCarga.abc: return AppColors.success;
      case FaseCarga.ab:  return const Color(0xFF1565C0); // Azul escuro — A+B
      case FaseCarga.ac:  return const Color(0xFF6A1B9A); // Roxo — A+C
      case FaseCarga.bc:  return const Color(0xFF00695C); // Verde escuro — B+C
    }
  }

  void _editarCarga(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.96,
      ),
      builder: (_) => _CargaFormSheet(cargaExistente: carga, projetoId: ''),
    );
  }
}

// ════════════════════════════════════════
// FORM SHEET – Cadastro/Edição de Carga
// NBR 5410 compliant: tensão dropdown, fase smart filter, BTU para A/C
// ════════════════════════════════════════

/// Regras NBR 5410 — tensões permitidas por ligação
List<double> _tensoesPorLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico:
      return [127.0, 220.0];
    case LigacaoCarga.bifasico:
      return [220.0, 380.0];
    case LigacaoCarga.trifasico:
      return [220.0, 380.0];
  }
}

/// Regras NBR 5410 — fases permitidas por ligação
List<FaseCarga> _fasesPorLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico:
      // Somente fases individuais (A, B ou C) — não ABC
      return [FaseCarga.a, FaseCarga.b, FaseCarga.c];
    case LigacaoCarga.bifasico:
      // Somente combinações de DUAS fases: A+B, A+C ou B+C
      return [FaseCarga.ab, FaseCarga.ac, FaseCarga.bc];
    case LigacaoCarga.trifasico:
      // Somente trifásico completo (A+B+C)
      return [FaseCarga.abc];
  }
}

/// Tensão padrão recomendada por ligação (NBR 5410)
double _tensaoPadraoLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico:
      return 220.0;
    case LigacaoCarga.bifasico:
      return 220.0;
    case LigacaoCarga.trifasico:
      return 380.0;
  }
}

/// Fase padrão por ligação
FaseCarga _fasePadraoLigacao(LigacaoCarga ligacao) {
  switch (ligacao) {
    case LigacaoCarga.monofasico:
      return FaseCarga.a;
    case LigacaoCarga.bifasico:
      return FaseCarga.ab; // padrão: A+B para bifásico
    case LigacaoCarga.trifasico:
      return FaseCarga.abc;
  }
}

/// Rótulo da tensão (exibe como inteiro quando sem decimais)
String _rotTensao(double v) => v == v.truncateToDouble() ? '${v.toInt()} V' : '$v V';

/// Valores padrão de BTU/h para ar-condicionado (séries comerciais brasileiras)
const List<int> _valoresBtu = [
  9000, 12000, 18000, 24000, 30000, 36000, 48000, 60000
];

/// Converte BTU/h → Watts (1 BTU/h = 0,29307 W)
double _btuParaWatts(int btu) => btu * 0.29307;

class _CargaFormSheet extends StatefulWidget {
  final String projetoId;
  final Carga? cargaExistente;
  const _CargaFormSheet({required this.projetoId, this.cargaExistente});

  @override
  State<_CargaFormSheet> createState() => _CargaFormSheetState();
}

class _CargaFormSheetState extends State<_CargaFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Estado principal
  late TipoCarga _tipo;
  late LigacaoCarga _ligacao;
  late FaseCarga _fase;
  late double _tensao;
  late TipoPartida _partida;
  late bool _editMode;

  // BTU — armazenado como int (9000, 12000, …)
  late int _btuSelecionado;

  // Controllers de texto
  late TextEditingController _descCtrl;
  late TextEditingController _potCtrl;
  late TextEditingController _qtdCtrl;
  late TextEditingController _fpCtrl;
  late TextEditingController _fdCtrl;
  late TextEditingController _compCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _rendCtrl;
  late TextEditingController _fsCtrl;
  late TextEditingController _especCtrl;

  @override
  void initState() {
    super.initState();
    final c = widget.cargaExistente;
    _editMode = c != null;
    _tipo    = c?.tipo    ?? TipoCarga.tug;
    _ligacao = c?.ligacao ?? LigacaoCarga.monofasico;
    _partida = c?.tipoPartida ?? TipoPartida.direta;

    // ── Tensão: valida contra as opções permitidas ao carregar ──────────
    final tensaoCarregada = c?.tensao ?? _tensaoPadraoLigacao(_ligacao);
    final opcoesIniciais  = _tensoesPorLigacao(_ligacao);
    _tensao = opcoesIniciais.contains(tensaoCarregada)
        ? tensaoCarregada
        : opcoesIniciais.first;

    // ── Fase: valida contra as fases permitidas ao carregar ─────────────
    final faseCarregada = c?.fase ?? _fasePadraoLigacao(_ligacao);
    final fasesIniciais = _fasesPorLigacao(_ligacao);
    _fase = fasesIniciais.contains(faseCarregada)
        ? faseCarregada
        : fasesIniciais.first;

    // ── BTU: tenta mapear capacidadeBtu para valor da lista ─────────────
    if (c != null && c.capacidadeBtu > 0) {
      // Encontra o valor mais próximo na lista de BTU
      _btuSelecionado = _valoresBtu.reduce((a, b) =>
          (a - c.capacidadeBtu.round()).abs() < (b - c.capacidadeBtu.round()).abs() ? a : b);
    } else {
      _btuSelecionado = 12000;
    }

    // ── Controllers ─────────────────────────────────────────────────────
    _descCtrl = TextEditingController(text: c?.descricao ?? '');
    _qtdCtrl  = TextEditingController(text: (c?.quantidade ?? 1).toString());
    _fpCtrl   = TextEditingController(text: (c?.fatorPotencia ?? 0.92).toString());
    _fdCtrl   = TextEditingController(text: (c?.fatorDemanda ?? 100).toString());
    _compCtrl = TextEditingController(text: (c?.comprimentoRamal ?? 20).toString());
    _notasCtrl = TextEditingController(text: c?.notas ?? '');
    _rendCtrl = TextEditingController(text: (c?.rendimento ?? 0.90).toString());
    _fsCtrl   = TextEditingController(text: (c?.fatorServico ?? 1.15).toString());
    // Para carga genérica: extrai o tipo especificado das notas [TIPO:xxx]
    final tipoEspecStr = c != null && c.tipo == TipoCarga.generico
        ? (RegExp(r'\[TIPO:([^\]]+)\]').firstMatch(c.notas)?.group(1) ?? '')
        : '';
    _especCtrl = TextEditingController(text: tipoEspecStr);

    // Potência: para A/C carregado, exibe BTU em vez de Watts
    if (_tipo == TipoCarga.arCondicionado) {
      _potCtrl = TextEditingController(text: _btuSelecionado.toString());
    } else {
      _potCtrl = TextEditingController(text: (c?.potenciaNominal ?? 100).toString());
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose(); _potCtrl.dispose(); _qtdCtrl.dispose();
    _fpCtrl.dispose();   _fdCtrl.dispose();  _compCtrl.dispose();
    _notasCtrl.dispose(); _rendCtrl.dispose(); _fsCtrl.dispose();
    _especCtrl.dispose();
    super.dispose();
  }

  // ── Quando ligação muda: auto-corrige tensão e fase se inválidos ──────
  void _onLigacaoChanged(LigacaoCarga novaLigacao) {
    setState(() {
      _ligacao = novaLigacao;
      final tensoes = _tensoesPorLigacao(novaLigacao);
      final fases   = _fasesPorLigacao(novaLigacao);
      if (!tensoes.contains(_tensao)) _tensao = tensoes.first;
      if (!fases.contains(_fase))     _fase   = fases.first;
    });
  }

  // ── Defaults por tipo de carga ────────────────────────────────────────
  void _setDefaultsForTipo(TipoCarga novoTipo) {
    setState(() {
      _tipo = novoTipo;
      switch (novoTipo) {
        case TipoCarga.tug:
          _fpCtrl.text = '1.0';
          _potCtrl.text = '100';
          _onLigacaoChanged(LigacaoCarga.monofasico);
          break;
        case TipoCarga.motor:
          _fpCtrl.text = '0.87';
          _rendCtrl.text = '0.92';
          _onLigacaoChanged(LigacaoCarga.trifasico);
          // trifásico → força ABC
          _tensao = 380.0;
          _fase   = FaseCarga.abc;
          break;
        case TipoCarga.arCondicionado:
          _fpCtrl.text = '0.95';
          _btuSelecionado = 12000;
          _onLigacaoChanged(LigacaoCarga.monofasico);
          break;
        case TipoCarga.resistencia:
          _fpCtrl.text = '1.0';
          break;
        case TipoCarga.iluminacao:
          _fpCtrl.text = '0.95';
          _onLigacaoChanged(LigacaoCarga.monofasico);
          break;
        default:
          _fpCtrl.text = '0.92';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tensoes = _tensoesPorLigacao(_ligacao);
    final fases   = _fasesPorLigacao(_ligacao);
    final isAC    = _tipo == TipoCarga.arCondicionado;
    final isMotor = _tipo == TipoCarga.motor;

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
            // Handle bar fixo
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              )),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 4, 20,
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).viewPadding.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              // Título + botão excluir
              Row(
                children: [
                  Text(
                    _editMode ? 'Editar Carga' : 'Nova Carga',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_editMode)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: _excluir,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── TIPO DE CARGA ──────────────────────────────────────────
              DropdownButtonFormField<TipoCarga>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Carga',
                  prefixIcon: Icon(Icons.category),
                ),
                items: TipoCarga.values.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text('${t.icone}  ${t.label}'),
                )).toList(),
                onChanged: (v) => _setDefaultsForTipo(v!),
              ),
              const SizedBox(height: 12),

              // ── ESPECIFICAR (apenas para tipo Genérico) ─────────────────
              if (_tipo == TipoCarga.generico) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Carga Genérica — especifique abaixo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _especCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Tipo da carga (aparecerá no PDF)',
                          hintText: 'Ex: Compressor, Bomba d\'água, Forno...',
                          prefixIcon: Icon(Icons.edit),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Especifique o tipo da carga genérica' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── DESCRIÇÃO ──────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrição do Circuito',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 12),

              // ── POTÊNCIA / BTU e QUANTIDADE ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Potência: BTU dropdown para A/C | texto livre para outros
                  Expanded(
                    flex: 2,
                    child: isAC
                        ? _btuDropdown()
                        : TextFormField(
                            controller: _potCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: isMotor ? 'Potência (cv)' : 'Potência (W)',
                              prefixIcon: const Icon(Icons.bolt),
                              suffixText: isMotor ? 'cv' : 'W',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Obrigatório' : null,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _qtdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Qtd',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Obrig.';
                        if ((int.tryParse(v) ?? 0) < 1) return '≥ 1';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── LIGAÇÃO ────────────────────────────────────────────────
              DropdownButtonFormField<LigacaoCarga>(
                value: _ligacao,
                decoration: const InputDecoration(
                  labelText: 'Ligação',
                  prefixIcon: Icon(Icons.account_tree_outlined),
                ),
                items: LigacaoCarga.values.map((l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.label),
                )).toList(),
                onChanged: (v) => _onLigacaoChanged(v!),
              ),
              const SizedBox(height: 12),

              // ── TENSÃO (dropdown filtrado por NBR 5410) ────────────────
              DropdownButtonFormField<double>(
                value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
                decoration: const InputDecoration(
                  labelText: 'Tensão (NBR 5410)',
                  prefixIcon: Icon(Icons.flash_on),
                  helperText: 'Opções conforme tipo de ligação',
                ),
                items: tensoes.map((v) => DropdownMenuItem<double>(
                  value: v,
                  child: Text(_rotTensao(v)),
                )).toList(),
                onChanged: (v) => setState(() => _tensao = v!),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),

              // ── FASE (dropdown filtrado por NBR 5410) ──────────────────
              DropdownButtonFormField<FaseCarga>(
                value: fases.contains(_fase) ? _fase : fases.first,
                decoration: const InputDecoration(
                  labelText: 'Fase(s) Alocada(s)',
                  prefixIcon: Icon(Icons.electrical_services),
                  helperText: 'Opções conforme tipo de ligação',
                ),
                items: fases.map((f) => DropdownMenuItem<FaseCarga>(
                  value: f,
                  child: Text('Fase ${f.label}'),
                )).toList(),
                onChanged: (v) => setState(() => _fase = v!),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),

              // ── BANNER informativo NBR 5410 ────────────────────────────
              _NbrInfoBanner(ligacao: _ligacao, tensao: _tensao),
              const SizedBox(height: 12),

              // ── FP e FD ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fpCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fator de Potência',
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Fator Demanda',
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
                ],
              ),
              const SizedBox(height: 12),

              // ── PARÂMETROS DO MOTOR ────────────────────────────────────
              if (isMotor) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚙️  Parâmetros do Motor',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _rendCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rendimento η',
                                suffixText: 'ex: 0.92',
                              ),
                              validator: (v) {
                                final d = double.tryParse(v ?? '');
                                if (d == null || d <= 0 || d > 1) return '0,1–1,0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _fsCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Fator Serviço',
                                suffixText: 'ex: 1.15',
                              ),
                              validator: (v) {
                                final d = double.tryParse(v ?? '');
                                if (d == null || d < 1.0) return '≥ 1,0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TipoPartida>(
                        value: _partida,
                        decoration: const InputDecoration(labelText: 'Tipo de Partida'),
                        items: TipoPartida.values.map((p) => DropdownMenuItem(
                          value: p, child: Text(p.label),
                        )).toList(),
                        onChanged: (v) => setState(() => _partida = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── COMPRIMENTO DO RAMAL ───────────────────────────────────
              TextFormField(
                controller: _compCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Comprimento do Ramal (m)',
                  prefixIcon: Icon(Icons.straighten),
                  suffixText: 'm',
                  helperText: 'Necessário para cálculo de ΔV%',
                ),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) return 'Informe valor > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── NOTAS TÉCNICAS ─────────────────────────────────────────
              TextFormField(
                controller: _notasCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas Técnicas',
                  prefixIcon: Icon(Icons.note_alt),
                ),
              ),
              const SizedBox(height: 20),

              // ── BOTÃO SALVAR ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: Icon(_editMode ? Icons.save_outlined : Icons.add_circle_outline),
                  label: Text(_editMode ? 'Atualizar Carga' : 'Adicionar Carga'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ── Widget dropdown de BTU/h (Ar-Condicionado) ────────────────────────
  Widget _btuDropdown() {
    return DropdownButtonFormField<int>(
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
      validator: (_) => null,
    );
  }

  // ── Persiste a carga no provider ──────────────────────────────────────
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AppProvider>();

    // Para A/C, a potência nominal é calculada a partir dos BTU/h
    final double potNominal;
    if (_tipo == TipoCarga.arCondicionado) {
      potNominal = _btuParaWatts(_btuSelecionado);
    } else {
      potNominal = double.tryParse(_potCtrl.text) ?? 0;
    }

    // Para tipo genérico: guarda especificação nas notas para uso no PDF
    final notasFinais = _tipo == TipoCarga.generico && _especCtrl.text.trim().isNotEmpty
        ? '[TIPO:${_especCtrl.text.trim()}] ${_notasCtrl.text}'.trim()
        : _notasCtrl.text;

    final carga = Carga(
      id:             widget.cargaExistente?.id ?? const Uuid().v4(),
      descricao:      _descCtrl.text.trim().isEmpty ? _tipo.label : _descCtrl.text.trim(),
      tipo:           _tipo,
      quantidade:     int.tryParse(_qtdCtrl.text) ?? 1,
      potenciaNominal: potNominal,
      ligacao:        _ligacao,
      tensao:         _tensao,
      fatorPotencia:  double.tryParse(_fpCtrl.text) ?? 0.92,
      fatorDemanda:   double.tryParse(_fdCtrl.text) ?? 100,
      fase:           _fase,
      notas:          notasFinais,
      rendimento:     double.tryParse(_rendCtrl.text) ?? 0.90,
      fatorServico:   double.tryParse(_fsCtrl.text) ?? 1.15,
      tipoPartida:    _partida,
      capacidadeBtu:  _tipo == TipoCarga.arCondicionado
                          ? _btuSelecionado.toDouble()
                          : 0,
      comprimentoRamal: double.tryParse(_compCtrl.text) ?? 20,
    );

    if (_editMode) {
      await prov.atualizarCarga(carga);
    } else {
      await prov.adicionarCarga(carga);
    }
    if (mounted) Navigator.pop(context);
  }

  // ── Confirma e exclui a carga ─────────────────────────────────────────
  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir carga?'),
        content: const Text('Esta carga será removida do projeto.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && widget.cargaExistente != null && mounted) {
      final prov = context.read<AppProvider>();
      await prov.excluirCarga(widget.cargaExistente!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ════════════════════════════════════════
// Widget informativo NBR 5410
// ════════════════════════════════════════
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
      child: Row(
        children: [
          Icon(icon, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _info() {
    switch (ligacao) {
      case LigacaoCarga.monofasico:
        return (
          Icons.info_outline,
          const Color(0xFF0277BD),
          'NBR 5410 — Monofásico: 127 V ou 220 V  ·  '
          'Fase individual (A, B ou C)',
        );
      case LigacaoCarga.bifasico:
        return (
          Icons.info_outline,
          const Color(0xFF558B2F),
          'NBR 5410 — Bifásico: 220 V ou 380 V  ·  '
          'Duas fases: A+B, A+C ou B+C',
        );
      case LigacaoCarga.trifasico:
        return (
          Icons.warning_amber_rounded,
          const Color(0xFFE65100),
          'NBR 5410 — Trifásico: 220 V ou 380 V  ·  '
          '127 V não permitido  ·  Obrigatório ABC',
        );
    }
  }
}

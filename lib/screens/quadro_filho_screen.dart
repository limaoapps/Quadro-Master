import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/alimentador.dart';
import '../models/carga.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// QuadroFilhoScreen
// Tela de gerenciamento de cargas de um QuadroFilho (QD, QF, Painel, CCM).
// Aberta a partir de AlimentadoresScreen ao tocar num alimentador.
// ══════════════════════════════════════════════════════════════════════════════
class QuadroFilhoScreen extends StatelessWidget {
  final Alimentador alimentador;
  final Projeto projeto;

  const QuadroFilhoScreen({
    super.key,
    required this.alimentador,
    required this.projeto,
  });

  // ── Helpers de ligação/tensão/fase (replicados de CargasScreen) ──────────
  static List<double> _tensoesPorLigacao(LigacaoCarga l) {
    switch (l) {
      case LigacaoCarga.monofasico: return [127.0, 220.0];
      case LigacaoCarga.bifasico:   return [220.0, 380.0];
      case LigacaoCarga.trifasico:  return [220.0, 380.0];
    }
  }

  static List<FaseCarga> _fasesPorLigacao(LigacaoCarga l) {
    switch (l) {
      case LigacaoCarga.monofasico: return [FaseCarga.a, FaseCarga.b, FaseCarga.c];
      case LigacaoCarga.bifasico:   return [FaseCarga.ab, FaseCarga.ac, FaseCarga.bc];
      case LigacaoCarga.trifasico:  return [FaseCarga.abc];
    }
  }

  static double _tensaoPadraoLigacao(LigacaoCarga l) {
    switch (l) {
      case LigacaoCarga.monofasico: return 220.0;
      case LigacaoCarga.bifasico:   return 220.0;
      case LigacaoCarga.trifasico:  return 380.0;
    }
  }

  static FaseCarga _fasePadraoLigacao(LigacaoCarga l) {
    switch (l) {
      case LigacaoCarga.monofasico: return FaseCarga.a;
      case LigacaoCarga.bifasico:   return FaseCarga.ab;
      case LigacaoCarga.trifasico:  return FaseCarga.abc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    // Busca o alimentador atualizado do provider (para refletir mudanças em tempo real)
    final alimAtual = prov.projetoAtual?.alimentadores
        .firstWhere((a) => a.id == alimentador.id, orElse: () => alimentador);
    final qf = alimAtual?.quadroFilho;
    final tipo = alimentador.tipoDestino;
    final cargas = qf?.cargas ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, tipo),
      body: Column(
        children: [
          // ── Painel de resultados automáticos ────────────────────────────
          _buildPainelResultados(alimAtual),

          // ── Lista de cargas ──────────────────────────────────────────────
          Expanded(
            child: cargas.isEmpty
                ? _buildEmpty(context, tipo)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: cargas.length,
                    itemBuilder: (ctx, i) => _CargaFilhoCard(
                      carga: cargas[i],
                      tipo: tipo,
                      alimentadorId: alimentador.id,
                      quadroFilho: qf!,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCargaSheet(context, tipo, qf),
        backgroundColor: _corTipo(tipo),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add ${_labelTipo(tipo)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
  AppBar _buildAppBar(BuildContext context, TipoQuadroFilho tipo) {
    return AppBar(
      backgroundColor: _corTipo(tipo),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alimentador.quadroFilho?.nome ??
                '${tipo.sigla} – ${alimentador.destino.isNotEmpty ? alimentador.destino : alimentador.nome}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Alimentador: ${alimentador.nome}  ·  ${tipo.label.split('(').first.trim()}',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          tooltip: 'Configurar quadro',
          onPressed: () => _configSheet(context),
        ),
      ],
    );
  }

  // ── Painel de resultados automáticos ─────────────────────────────────────
  Widget _buildPainelResultados(Alimentador? alim) {
    final temDados = (alim?.corrente ?? 0) > 0;
    final qf = alim?.quadroFilho;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_corTipo(alimentador.tipoDestino), _corTipoEscuro(alimentador.tipoDestino)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _corTipo(alimentador.tipoDestino).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                alimentador.tipoDestino.sigla,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Dimensionamento Automático',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: temDados
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: temDados
                      ? Colors.green.withValues(alpha: 0.6)
                      : Colors.orange.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                temDados ? 'Calculado' : 'Aguardando cargas',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: temDados ? Colors.greenAccent : Colors.orange[200],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Métricas
          if (temDados) ...[
            Row(children: [
              _MetricItem(
                label: 'P. Aparente',
                value: '${(alim?.potenciaAparenteKva ?? 0).toStringAsFixed(1)} kVA',
                icon: Icons.flash_on,
              ),
              const SizedBox(width: 6),
              _MetricItem(
                label: 'I. Projeto',
                value: '${(alim?.corrente ?? 0).toStringAsFixed(1)} A',
                icon: Icons.electric_bolt,
              ),
              const SizedBox(width: 6),
              _MetricItem(
                label: 'Disjuntor',
                value: '${alim?.disjuntor ?? 0} A',
                icon: Icons.security,
                highlight: true,
              ),
              const SizedBox(width: 6),
              _MetricItem(
                label: 'Cabo',
                value: '${(alim?.condutor ?? 0).toStringAsFixed(1)} mm²',
                icon: Icons.cable,
              ),
            ]),
            const SizedBox(height: 8),
            // Legenda fases/tensão
            Row(children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 12),
              const SizedBox(width: 4),
              Text(
                '${qf?.tensao.toStringAsFixed(0) ?? "-"} V  ·  '
                '${qf?.numFases ?? "-"} fases  ·  '
                '${qf?.cargas.where((c) => c.ativo).length ?? 0} circuito(s) ativo(s)',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ]),
          ] else ...[
            Row(children: [
              const Icon(Icons.add_circle_outline, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Adicione circuitos para calcular automaticamente o disjuntor, cabos e corrente de projeto.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Estado vazio ─────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, TipoQuadroFilho tipo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _corTipo(tipo).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconeTipo(tipo), size: 38, color: _corTipo(tipo)),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum circuito cadastrado',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _textoVazioTipo(tipo),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 8),
          // Instrução de retorno automático
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Ao adicionar circuitos, o disjuntor, cabo e corrente do alimentador serão calculados automaticamente.',
                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addCargaSheet(
              context,
              tipo,
              alimentador.quadroFilho,
            ),
            icon: Icon(_iconeTipo(tipo)),
            label: Text('Adicionar ${_labelTipo(tipo)}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _corTipo(tipo),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheet para adicionar carga ────────────────────────────────────────────
  void _addCargaSheet(BuildContext context, TipoQuadroFilho tipo, QuadroFilho? qf) {
    if (qf == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.96),
      builder: (_) => _CargaFilhoFormSheet(
        alimentadorId: alimentador.id,
        quadroFilho: qf,
        tipoQuadro: tipo,
      ),
    );
  }

  // ── Sheet de configuração do quadro filho ─────────────────────────────────
  void _configSheet(BuildContext context) {
    final qf = alimentador.quadroFilho;
    if (qf == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuadroFilhoConfigSheet(
        alimentadorId: alimentador.id,
        quadroFilho: qf,
      ),
    );
  }

  // ── Helpers visuais por tipo ──────────────────────────────────────────────
  Color _corTipo(TipoQuadroFilho t) {
    switch (t) {
      case TipoQuadroFilho.qd:    return const Color(0xFF1565C0);
      case TipoQuadroFilho.qf:    return const Color(0xFF6A1B9A);
      case TipoQuadroFilho.painel: return const Color(0xFF00695C);
      case TipoQuadroFilho.ccm:   return const Color(0xFFBF360C);
      case TipoQuadroFilho.qgbt:  return const Color(0xFF0B1B3D);
      case TipoQuadroFilho.outro: return const Color(0xFF37474F);
    }
  }

  Color _corTipoEscuro(TipoQuadroFilho t) {
    switch (t) {
      case TipoQuadroFilho.qd:    return const Color(0xFF0D47A1);
      case TipoQuadroFilho.qf:    return const Color(0xFF4A148C);
      case TipoQuadroFilho.painel: return const Color(0xFF004D40);
      case TipoQuadroFilho.ccm:   return const Color(0xFF8D2B0C);
      case TipoQuadroFilho.qgbt:  return const Color(0xFF071225);
      case TipoQuadroFilho.outro: return const Color(0xFF263238);
    }
  }

  IconData _iconeTipo(TipoQuadroFilho t) {
    switch (t) {
      case TipoQuadroFilho.qd:    return Icons.electrical_services;
      case TipoQuadroFilho.qf:    return Icons.precision_manufacturing;
      case TipoQuadroFilho.painel: return Icons.developer_board;
      case TipoQuadroFilho.ccm:   return Icons.factory;
      case TipoQuadroFilho.qgbt:  return Icons.electric_bolt;
      case TipoQuadroFilho.outro: return Icons.cable;
    }
  }

  String _labelTipo(TipoQuadroFilho t) {
    switch (t) {
      case TipoQuadroFilho.qd:    return 'Circuito';
      case TipoQuadroFilho.qf:    return 'Equipamento';
      case TipoQuadroFilho.painel: return 'Componente';
      case TipoQuadroFilho.ccm:   return 'Motor/CCM';
      case TipoQuadroFilho.qgbt:  return 'Alimentador';
      case TipoQuadroFilho.outro: return 'Carga';
    }
  }

  String _textoVazioTipo(TipoQuadroFilho t) {
    switch (t) {
      case TipoQuadroFilho.qd:
        return 'Adicione iluminação, tomadas, motores e equipamentos do quadro de distribuição.';
      case TipoQuadroFilho.qf:
        return 'Adicione os motores, bombas e equipamentos industriais deste quadro de força.';
      case TipoQuadroFilho.painel:
        return 'Adicione os componentes de comando, inversores, CLPs e automação do painel.';
      case TipoQuadroFilho.ccm:
        return 'Adicione os centros de controle de motores e seus circuitos.';
      case TipoQuadroFilho.qgbt:
        return 'Adicione os alimentadores deste sub-QGBT.';
      case TipoQuadroFilho.outro:
        return 'Adicione as cargas deste quadro.';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _CargaFilhoCard — card de carga dentro do QuadroFilho
// ══════════════════════════════════════════════════════════════════════════════
class _CargaFilhoCard extends StatelessWidget {
  final Carga carga;
  final TipoQuadroFilho tipo;
  final String alimentadorId;
  final QuadroFilho quadroFilho;

  const _CargaFilhoCard({
    required this.carga,
    required this.tipo,
    required this.alimentadorId,
    required this.quadroFilho,
  });

  Color get _corTipo {
    switch (tipo) {
      case TipoQuadroFilho.qd:    return const Color(0xFF1565C0);
      case TipoQuadroFilho.qf:    return const Color(0xFF6A1B9A);
      case TipoQuadroFilho.painel: return const Color(0xFF00695C);
      case TipoQuadroFilho.ccm:   return const Color(0xFFBF360C);
      case TipoQuadroFilho.qgbt:  return const Color(0xFF0B1B3D);
      case TipoQuadroFilho.outro: return const Color(0xFF37474F);
    }
  }

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
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => _excluirCarga(context, prov),
        child: GestureDetector(
          onTap: () => _editarCarga(context),
          child: Container(
            decoration: BoxDecoration(
              color: carga.ativo ? Colors.white : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: hasAlerts
                  ? Border.all(color: AppColors.warning.withValues(alpha: 0.4))
                  : Border.all(color: _corTipo.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(children: [
                    // Ícone
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _corTipo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
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
                              child: Text(
                                carga.descricao,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: carga.ativo
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  decoration: carga.ativo ? null : TextDecoration.lineThrough,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasAlerts)
                              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          ]),
                          Row(children: [
                            _pill(_subtipoPill(), _corTipo),
                            const SizedBox(width: 4),
                            _pill(carga.ligacao.label, AppColors.secondary.withValues(alpha: 0.7)),
                            if (carga.utilizaDR) ...[
                              const SizedBox(width: 4),
                              _pill(carga.drTexto, AppColors.success),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    Switch(
                      value: carga.ativo,
                      onChanged: (_) => _toggleAtiva(context, prov),
                      activeThumbColor: _corTipo,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ]),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // Métricas calculadas
                  Row(children: [
                    _metricItem('P. Ativa', '${(carga.potenciaAtiva / 1000).toStringAsFixed(2)} kW'),
                    _metricItem('Corrente', '${carga.corrente.toStringAsFixed(1)} A'),
                    _metricItem('Disjuntor', '${carga.disjuntorSugerido} A'),
                    _metricItem('Condutor', '${carga.condutorSugerido} mm²'),
                  ]),
                  if (hasAlerts) ...[
                    const SizedBox(height: 6),
                    for (final a in carga.alertas) _alertRow(a),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  // Ações
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () => _editarCarga(context),
                        icon: Icon(Icons.edit_outlined, size: 15, color: _corTipo),
                        label: Text('Editar', style: TextStyle(fontSize: 11, color: _corTipo)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Container(width: 1, height: 18, color: AppColors.divider),
                      TextButton.icon(
                        onPressed: () => _duplicarCarga(context, prov),
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
                              title: const Text('Excluir?'),
                              content: Text('Deseja excluir "${carga.descricao}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Excluir', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await _excluirCarga(context, context.read<AppProvider>());
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

  Widget _pill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _metricItem(String label, String value) => Expanded(
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]),
  );

  Widget _alertRow(String msg) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      const Icon(Icons.info_outline, size: 12, color: AppColors.warning),
      const SizedBox(width: 4),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 10, color: AppColors.warning))),
    ]),
  );

  Future<void> _excluirCarga(BuildContext context, AppProvider prov) async {
    // Atualiza a lista de cargas do quadro filho e salva via provider
    final qf = quadroFilho;
    qf.cargas.removeWhere((c) => c.id == carga.id);
    await prov.salvarQuadroFilho(alimentadorId, qf);
  }

  Future<void> _duplicarCarga(BuildContext context, AppProvider prov) async {
    final novoId = const Uuid().v4();
    final map = {...carga.toMap(), 'id': novoId, 'descricao': '${carga.descricao} (cópia)'};
    final nova = Carga.fromMap(map);
    final qf = quadroFilho;
    qf.cargas.add(nova);
    await prov.salvarQuadroFilho(alimentadorId, qf);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Circuito duplicado!'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _toggleAtiva(BuildContext context, AppProvider prov) async {
    final qf = quadroFilho;
    final idx = qf.cargas.indexWhere((c) => c.id == carga.id);
    if (idx >= 0) {
      qf.cargas[idx] = Carga.fromMap({...carga.toMap(), 'ativo': !carga.ativo});
    }
    await prov.salvarQuadroFilho(alimentadorId, qf);
  }

  void _editarCarga(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.96),
      builder: (_) => _CargaFilhoFormSheet(
        alimentadorId: alimentadorId,
        quadroFilho: quadroFilho,
        tipoQuadro: tipo,
        cargaExistente: carga,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _CargaFilhoFormSheet — formulário adaptativo por tipo de quadro filho
// Reutiliza toda a lógica já existente em CargasScreen/_CargaFormSheet
// mas salva via prov.salvarQuadroFilho() ao invés de prov.adicionarCarga()
// ══════════════════════════════════════════════════════════════════════════════
class _CargaFilhoFormSheet extends StatefulWidget {
  final String alimentadorId;
  final QuadroFilho quadroFilho;
  final TipoQuadroFilho tipoQuadro;
  final Carga? cargaExistente;

  const _CargaFilhoFormSheet({
    required this.alimentadorId,
    required this.quadroFilho,
    required this.tipoQuadro,
    this.cargaExistente,
  });

  @override
  State<_CargaFilhoFormSheet> createState() => _CargaFilhoFormSheetState();
}

class _CargaFilhoFormSheetState extends State<_CargaFilhoFormSheet> {
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
  // QF
  late SubtipoQF _subtipoQF;
  // Painel
  late SubtipoPainel _subtipoPainel;

  // Controllers
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
  late TextEditingController _drOutroCtrl;
  late TextEditingController _modeloCtrl;
  late TextEditingController _fabricanteCtrl;
  late TextEditingController _correnteCtrl;

  static const List<int> _valoresBtu = [9000, 12000, 18000, 24000, 30000, 36000, 48000, 60000];
  static double _btuParaWatts(int btu) => btu * 0.29307;

  @override
  void initState() {
    super.initState();
    final c = widget.cargaExistente;
    _editMode = c != null;

    _tipo    = c?.tipo ?? TipoCarga.tug;
    _ligacao = c?.ligacao ?? LigacaoCarga.monofasico;
    _partida = c?.tipoPartida ?? TipoPartida.direta;

    final tensaoCarregada = c?.tensao ?? QuadroFilhoScreen._tensaoPadraoLigacao(_ligacao);
    final opcoesIniciais  = QuadroFilhoScreen._tensoesPorLigacao(_ligacao);
    _tensao = opcoesIniciais.contains(tensaoCarregada) ? tensaoCarregada : opcoesIniciais.first;

    final faseCarregada = c?.fase ?? QuadroFilhoScreen._fasePadraoLigacao(_ligacao);
    final fasesIniciais = QuadroFilhoScreen._fasesPorLigacao(_ligacao);
    _fase = fasesIniciais.contains(faseCarregada) ? faseCarregada : fasesIniciais.first;

    if (c != null && c.capacidadeBtu > 0) {
      _btuSelecionado = _valoresBtu.reduce((a, b) =>
          (a - c.capacidadeBtu.round()).abs() < (b - c.capacidadeBtu.round()).abs() ? a : b);
    } else {
      _btuSelecionado = 12000;
    }

    _utilizaDR       = c?.utilizaDR ?? false;
    _sensibilidadeDR = c?.sensibilidadeDR ?? '30mA';
    _subtipoQF       = c?.subtipoQF ?? SubtipoQF.motor;
    _subtipoPainel   = c?.subtipoPainel ?? SubtipoPainel.contator;

    _descCtrl       = TextEditingController(text: c?.descricao ?? '');
    _potCtrl        = TextEditingController(
        text: (_tipo == TipoCarga.arCondicionado && c != null)
            ? _btuSelecionado.toString()
            : (c?.potenciaNominal != null && c!.potenciaNominal != 0
                ? c.potenciaNominal.toString() : ''));
    _qtdCtrl        = TextEditingController(
        text: (c?.quantidade != null && c!.quantidade != 1) ? c.quantidade.toString() : '');
    _fpCtrl         = TextEditingController(text: c?.fatorPotencia.toString() ?? '');
    _fdCtrl         = TextEditingController(text: c?.fatorDemanda.toString() ?? '');
    _compCtrl       = TextEditingController(
        text: (c?.comprimentoRamal != null && c!.comprimentoRamal != 20)
            ? c.comprimentoRamal.toString() : '');
    _notasCtrl      = TextEditingController(text: c?.notas ?? '');
    _rendCtrl       = TextEditingController(text: c?.rendimento.toString() ?? '');
    _fsCtrl         = TextEditingController(text: c?.fatorServico.toString() ?? '');
    _drOutroCtrl    = TextEditingController(
        text: (c?.sensibilidadeDROutro != null && c!.sensibilidadeDROutro != 30)
            ? c.sensibilidadeDROutro.toString() : '');
    _modeloCtrl     = TextEditingController(text: c?.modelo ?? '');
    _fabricanteCtrl = TextEditingController(text: c?.fabricante ?? '');
    _correnteCtrl   = TextEditingController(
        text: (c?.correnteNominal != null && c!.correnteNominal != 0)
            ? c.correnteNominal.toString() : '');

    final tipoEspecStr = c != null && c.tipo == TipoCarga.generico
        ? (RegExp(r'\[TIPO:([^\]]+)\]').firstMatch(c.notas)?.group(1) ?? '') : '';
    _especCtrl = TextEditingController(text: tipoEspecStr);
  }

  @override
  void dispose() {
    for (final ctrl in [
      _descCtrl, _potCtrl, _qtdCtrl, _fpCtrl, _fdCtrl, _compCtrl,
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
      final tensoes = QuadroFilhoScreen._tensoesPorLigacao(novaLigacao);
      final fases   = QuadroFilhoScreen._fasesPorLigacao(novaLigacao);
      if (!tensoes.contains(_tensao)) _tensao = tensoes.first;
      if (!fases.contains(_fase))     _fase   = fases.first;
    });
  }

  void _setDefaultsParaTipo(TipoCarga novoTipo) {
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
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20, 4, 20,
                    MediaQuery.of(context).viewInsets.bottom +
                        MediaQuery.of(context).viewPadding.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildFormBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormBody() {
    switch (widget.tipoQuadro) {
      case TipoQuadroFilho.qf:
      case TipoQuadroFilho.ccm:
        return _buildQFForm();
      case TipoQuadroFilho.painel:
        return _buildPainelForm();
      default:
        return _buildQDForm();
    }
  }

  // ── Cabeçalho do formulário ───────────────────────────────────────────────
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
      child: Text(
        titulo,
        style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
      ),
    ),
    const SizedBox(height: 14),
  ]);

  Widget _salvarBtn() => Row(children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: _salvar,
        icon: Icon(_editMode ? Icons.save_outlined : Icons.add_circle_outline),
        label: Text(_editMode ? 'Atualizar Circuito' : 'Adicionar Circuito'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  ]);

  String _rotTensao(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()} V' : '$v V';

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
        '${(btu / 1000).toStringAsFixed(0)} mil BTU/h  ≈ ${_btuParaWatts(btu).toStringAsFixed(0)} W',
        style: const TextStyle(fontSize: 13),
      ),
    )).toList(),
    onChanged: (v) => setState(() => _btuSelecionado = v!),
  );

  // ── Form QD (padrão) ─────────────────────────────────────────────────────
  List<Widget> _buildQDForm() {
    final tensoes = QuadroFilhoScreen._tensoesPorLigacao(_ligacao);
    final fases   = QuadroFilhoScreen._fasesPorLigacao(_ligacao);
    final isAC    = _tipo == TipoCarga.arCondicionado;
    final isMotor = _tipo == TipoCarga.motor;
    final isTugTue = _tipo == TipoCarga.tug || _tipo == TipoCarga.tue;

    return [
      _formHeader('${widget.tipoQuadro.sigla} – Circuito'),

      DropdownButtonFormField<TipoCarga>(
        value: _tipo,
        decoration: const InputDecoration(labelText: 'Tipo de Carga', prefixIcon: Icon(Icons.category)),
        items: TipoCarga.values.map((t) => DropdownMenuItem(
          value: t,
          child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => _setDefaultsParaTipo(v!),
      ),
      const SizedBox(height: 12),

      if (_tipo == TipoCarga.generico) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: TextFormField(
            controller: _especCtrl,
            decoration: const InputDecoration(
              labelText: 'Tipo da carga (aparecerá no PDF)',
              hintText: 'Ex: Compressor, Bomba, Forno...',
              prefixIcon: Icon(Icons.edit),
              filled: true, fillColor: Colors.white,
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Especifique o tipo' : null,
          ),
        ),
        const SizedBox(height: 12),
      ],

      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Descrição do Circuito',
          hintText: 'Ex: Iluminação Sala, Tomadas Cozinha...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
      ),
      const SizedBox(height: 12),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: isAC
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
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _qtdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Qtd', hintText: '1', prefixIcon: Icon(Icons.numbers),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if ((int.tryParse(v) ?? 0) < 1) return '≥ 1';
              return null;
            },
          ),
        ),
      ]),
      const SizedBox(height: 12),

      DropdownButtonFormField<LigacaoCarga>(
        value: _ligacao,
        decoration: const InputDecoration(labelText: 'Ligação', prefixIcon: Icon(Icons.account_tree_outlined)),
        items: LigacaoCarga.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
        onChanged: (v) => _onLigacaoChanged(v!),
      ),
      const SizedBox(height: 12),

      DropdownButtonFormField<double>(
        value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
        decoration: const InputDecoration(
          labelText: 'Tensão (NBR 5410)',
          prefixIcon: Icon(Icons.flash_on),
          helperText: 'Opções conforme tipo de ligação',
        ),
        items: tensoes.map((v) => DropdownMenuItem<double>(value: v, child: Text(_rotTensao(v)))).toList(),
        onChanged: (v) => setState(() => _tensao = v!),
      ),
      const SizedBox(height: 12),

      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(
          labelText: 'Fase(s) Alocada(s)',
          prefixIcon: Icon(Icons.electrical_services),
          helperText: 'Opções conforme tipo de ligação',
        ),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(value: f, child: Text('Fase ${f.label}'))).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fator de Potência', hintText: 'Ex: 0.92', prefixIcon: Icon(Icons.tune),
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
              labelText: 'Fator Demanda', hintText: 'Ex: 100',
              prefixIcon: Icon(Icons.percent), suffixText: '%',
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

      if (isMotor) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _rendCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rendimento η', hintText: 'Ex: 0.92'),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Fator Serviço', hintText: 'Ex: 1.15'),
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
              decoration: const InputDecoration(labelText: 'Tipo de Partida'),
              items: TipoPartida.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
              onChanged: (v) => setState(() => _partida = v!),
            ),
          ]),
        ),
        const SizedBox(height: 12),
      ],

      TextFormField(
        controller: _compCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

      // DR para TUG e TUE
      if (isTugTue) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                const Text('Proteção DR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                const Spacer(),
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
                    prefixIcon: Icon(Icons.shield),
                  ),
                  items: ['30mA', '100mA', '300mA', 'outro'].map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == 'outro' ? 'Outro valor' : s),
                  )).toList(),
                  onChanged: (v) => setState(() => _sensibilidadeDR = v!),
                ),
                if (_sensibilidadeDR == 'outro') ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _drOutroCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sensibilidade (mA)', hintText: 'Ex: 500',
                      prefixIcon: Icon(Icons.numbers), suffixText: 'mA',
                    ),
                    validator: (v) {
                      final d = double.tryParse(v ?? '');
                      if (d == null || d <= 0) return 'Informe valor válido';
                      return null;
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],

      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notas Técnicas', hintText: 'Observações adicionais...', prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ── Form QF / CCM ─────────────────────────────────────────────────────────
  List<Widget> _buildQFForm() {
    final fases   = QuadroFilhoScreen._fasesPorLigacao(_ligacao);

    return [
      _formHeader('${widget.tipoQuadro.sigla} – Equipamento'),

      DropdownButtonFormField<SubtipoQF>(
        value: _subtipoQF,
        decoration: const InputDecoration(
          labelText: 'Tipo de Equipamento', prefixIcon: Icon(Icons.precision_manufacturing),
        ),
        items: SubtipoQF.values.map((t) => DropdownMenuItem(
          value: t, child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _subtipoQF = v!),
      ),
      const SizedBox(height: 12),

      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Identificação / Nome',
          hintText: 'Ex: Motor Bomba 1, Compressor AR...',
          prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a identificação' : null,
      ),
      const SizedBox(height: 12),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _potCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Potência (cv)', hintText: 'Ex: 5.5',
              prefixIcon: Icon(Icons.bolt), suffixText: 'cv',
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _qtdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qtd', hintText: '1', prefixIcon: Icon(Icons.numbers)),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _rendCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Rendimento η', hintText: 'Ex: 0.92', prefixIcon: Icon(Icons.speed)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fsCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fator Serviço', hintText: 'Ex: 1.15', prefixIcon: Icon(Icons.settings)),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      DropdownButtonFormField<TipoPartida>(
        value: _partida,
        decoration: const InputDecoration(labelText: 'Método de Partida', prefixIcon: Icon(Icons.play_circle_outline)),
        items: TipoPartida.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
        onChanged: (v) => setState(() => _partida = v!),
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: DropdownButtonFormField<LigacaoCarga>(
            value: _ligacao,
            decoration: const InputDecoration(labelText: 'Ligação', prefixIcon: Icon(Icons.account_tree_outlined)),
            items: LigacaoCarga.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
            onChanged: (v) => _onLigacaoChanged(v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<double>(
            value: QuadroFilhoScreen._tensoesPorLigacao(_ligacao).contains(_tensao)
                ? _tensao : QuadroFilhoScreen._tensoesPorLigacao(_ligacao).first,
            decoration: const InputDecoration(labelText: 'Tensão', prefixIcon: Icon(Icons.flash_on)),
            items: QuadroFilhoScreen._tensoesPorLigacao(_ligacao).map((v) => DropdownMenuItem<double>(
              value: v, child: Text(_rotTensao(v)),
            )).toList(),
            onChanged: (v) => setState(() => _tensao = v!),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(labelText: 'Fase(s)', prefixIcon: Icon(Icons.electrical_services)),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(value: f, child: Text('Fase ${f.label}'))).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fator de Potência', hintText: 'Ex: 0.87', prefixIcon: Icon(Icons.tune)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fdCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fator Demanda (%)', hintText: 'Ex: 100', prefixIcon: Icon(Icons.percent), suffixText: '%'),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      TextFormField(
        controller: _compCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Comprimento do Ramal (m)', hintText: 'Ex: 25', prefixIcon: Icon(Icons.straighten), suffixText: 'm',
        ),
      ),
      const SizedBox(height: 12),

      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações', hintText: 'Regime de trabalho, método de partida...', prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ── Form Painel ───────────────────────────────────────────────────────────
  List<Widget> _buildPainelForm() {
    final tensoes = QuadroFilhoScreen._tensoesPorLigacao(_ligacao);
    final fases   = QuadroFilhoScreen._fasesPorLigacao(_ligacao);

    return [
      _formHeader('Painel – Componente de Comando'),

      DropdownButtonFormField<SubtipoPainel>(
        value: _subtipoPainel,
        decoration: const InputDecoration(labelText: 'Tipo de Componente', prefixIcon: Icon(Icons.developer_board)),
        items: SubtipoPainel.values.map((t) => DropdownMenuItem(
          value: t, child: Text('${t.icone}  ${t.label}'),
        )).toList(),
        onChanged: (v) => setState(() => _subtipoPainel = v!),
      ),
      const SizedBox(height: 12),

      TextFormField(
        controller: _descCtrl,
        decoration: const InputDecoration(
          labelText: 'Identificação / Tag', hintText: 'Ex: INV-01, CLP-Linha-A...', prefixIcon: Icon(Icons.edit_note),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a identificação' : null,
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _modeloCtrl,
            decoration: const InputDecoration(labelText: 'Modelo', hintText: 'Ex: CFW300', prefixIcon: Icon(Icons.devices)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fabricanteCtrl,
            decoration: const InputDecoration(labelText: 'Fabricante', hintText: 'Ex: WEG, Siemens...', prefixIcon: Icon(Icons.factory)),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _potCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Potência (W)', hintText: 'Ex: 500', prefixIcon: Icon(Icons.bolt), suffixText: 'W'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _correnteCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Corrente (A)', hintText: 'Ex: 2.5', prefixIcon: Icon(Icons.electric_bolt), suffixText: 'A'),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: DropdownButtonFormField<double>(
            value: tensoes.contains(_tensao) ? _tensao : tensoes.first,
            decoration: const InputDecoration(labelText: 'Tensão', prefixIcon: Icon(Icons.flash_on)),
            items: tensoes.map((v) => DropdownMenuItem<double>(value: v, child: Text(_rotTensao(v)))).toList(),
            onChanged: (v) => setState(() => _tensao = v!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<LigacaoCarga>(
            value: _ligacao,
            decoration: const InputDecoration(labelText: 'Nº Fases', prefixIcon: Icon(Icons.account_tree_outlined)),
            items: LigacaoCarga.values.map((l) => DropdownMenuItem(value: l, child: Text(l.label))).toList(),
            onChanged: (v) => _onLigacaoChanged(v!),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      DropdownButtonFormField<FaseCarga>(
        value: fases.contains(_fase) ? _fase : fases.first,
        decoration: const InputDecoration(labelText: 'Fase(s)', prefixIcon: Icon(Icons.electrical_services)),
        items: fases.map((f) => DropdownMenuItem<FaseCarga>(value: f, child: Text('Fase ${f.label}'))).toList(),
        onChanged: (v) => setState(() => _fase = v!),
      ),
      const SizedBox(height: 12),

      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _qtdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantidade', hintText: '1', prefixIcon: Icon(Icons.numbers)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _fpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fator de Potência', hintText: 'Ex: 0.92', prefixIcon: Icon(Icons.tune)),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      TextFormField(
        controller: _notasCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Observações', hintText: 'Especificações técnicas...', prefixIcon: Icon(Icons.note_alt),
        ),
      ),
      const SizedBox(height: 20),
      _salvarBtn(),
      const SizedBox(height: 8),
    ];
  }

  // ── Salvar ────────────────────────────────────────────────────────────────
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AppProvider>();

    final double potNominal;
    if (_tipo == TipoCarga.arCondicionado) {
      potNominal = _btuParaWatts(_btuSelecionado);
    } else {
      potNominal = double.tryParse(_potCtrl.text) ?? 0;
    }

    final notasFinais = _tipo == TipoCarga.generico && _especCtrl.text.trim().isNotEmpty
        ? '[TIPO:${_especCtrl.text.trim()}] ${_notasCtrl.text}'.trim()
        : _notasCtrl.text;

    SubtipoQF? sqf;
    SubtipoPainel? spainel;
    TipoCarga tipoFinal = _tipo;

    switch (widget.tipoQuadro) {
      case TipoQuadroFilho.qf:
      case TipoQuadroFilho.ccm:
        sqf = _subtipoQF;
        tipoFinal = TipoCarga.motor;
        break;
      case TipoQuadroFilho.painel:
        spainel = _subtipoPainel;
        tipoFinal = TipoCarga.generico;
        break;
      default:
        break;
    }

    final novaCarga = Carga(
      id:               widget.cargaExistente?.id ?? const Uuid().v4(),
      descricao:        _descCtrl.text.trim().isEmpty ? 'Sem descrição' : _descCtrl.text.trim(),
      tipo:             tipoFinal,
      quantidade:       int.tryParse(_qtdCtrl.text) ?? 1,
      potenciaNominal:  potNominal,
      ligacao:          _ligacao,
      tensao:           _tensao,
      fatorPotencia:    double.tryParse(_fpCtrl.text) ?? 0.92,
      fatorDemanda:     double.tryParse(_fdCtrl.text) ?? 100,
      fase:             _fase,
      notas:            notasFinais,
      rendimento:       double.tryParse(_rendCtrl.text) ?? 0.90,
      fatorServico:     double.tryParse(_fsCtrl.text) ?? 1.15,
      correnteNominal:  double.tryParse(_correnteCtrl.text) ?? 0,
      tipoPartida:      _partida,
      capacidadeBtu:    _tipo == TipoCarga.arCondicionado ? _btuSelecionado.toDouble() : 0,
      comprimentoRamal: double.tryParse(_compCtrl.text) ?? 20,
      utilizaDR:        _utilizaDR,
      sensibilidadeDR:  _sensibilidadeDR,
      sensibilidadeDROutro: double.tryParse(_drOutroCtrl.text) ?? 30,
      subtipoQF:        sqf,
      subtipoPainel:    spainel,
      modelo:           _modeloCtrl.text,
      fabricante:       _fabricanteCtrl.text,
    );

    // Salva na lista de cargas do QuadroFilho
    final qf = widget.quadroFilho;
    if (_editMode) {
      final idx = qf.cargas.indexWhere((c) => c.id == novaCarga.id);
      if (idx >= 0) {
        qf.cargas[idx] = novaCarga;
      } else {
        qf.cargas.add(novaCarga);
      }
    } else {
      qf.cargas.add(novaCarga);
    }

    // Persiste via provider → cascade automático: QuadroFilho → Alimentador → QGBT
    await prov.salvarQuadroFilho(widget.alimentadorId, qf);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir?'),
        content: const Text('Este circuito será removido do quadro.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && widget.cargaExistente != null && mounted) {
      final qf = widget.quadroFilho;
      qf.cargas.removeWhere((c) => c.id == widget.cargaExistente!.id);
      await context.read<AppProvider>().salvarQuadroFilho(widget.alimentadorId, qf);
      if (mounted) Navigator.pop(context);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _QuadroFilhoConfigSheet — configuração de tensão, fases e reserva
// ══════════════════════════════════════════════════════════════════════════════
class _QuadroFilhoConfigSheet extends StatefulWidget {
  final String alimentadorId;
  final QuadroFilho quadroFilho;

  const _QuadroFilhoConfigSheet({
    required this.alimentadorId,
    required this.quadroFilho,
  });

  @override
  State<_QuadroFilhoConfigSheet> createState() => _QuadroFilhoConfigSheetState();
}

class _QuadroFilhoConfigSheetState extends State<_QuadroFilhoConfigSheet> {
  late double _tensao;
  late int _numFases;
  late double _reserva;
  final _nomeCtrl = TextEditingController();

  static const List<double> _tensoes = [127, 220, 380, 440];
  static const List<int> _fases = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _tensao   = widget.quadroFilho.tensao;
    _numFases = widget.quadroFilho.numFases;
    _reserva  = widget.quadroFilho.reservaPercent;
    _nomeCtrl.text = widget.quadroFilho.nome;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Configurar Quadro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Text('Define tensão, fases e margem para dimensionamento.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 18),

            // Nome
            TextFormField(
              controller: _nomeCtrl,
              decoration: InputDecoration(
                labelText: 'Nome do Quadro',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Tensão
            const Text('Tensão de Alimentação',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _tensoes.map((t) {
                final sel = _tensao == t;
                return GestureDetector(
                  onTap: () => setState(() => _tensao = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? AppColors.primary : AppColors.divider,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '${t.toStringAsFixed(0)} V',
                      style: TextStyle(
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Número de fases
            const Text('Número de Fases',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: _fases.map((f) {
                final sel = _numFases == f;
                final label = f == 1 ? '1F' : f == 2 ? '2F' : '3F+N';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _numFases = f),
                    child: Container(
                      margin: EdgeInsets.only(right: f < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.secondary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel ? AppColors.secondary : AppColors.divider,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Margem de reserva
            Row(children: [
              const Icon(Icons.tune, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Margem para Disjuntor',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _reserva == 0 ? 'Sem margem' : '+${_reserva.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ]),
            Slider(
              value: _reserva,
              min: 0, max: 50, divisions: 10,
              activeColor: AppColors.primary,
              label: _reserva == 0 ? 'Sem margem' : '+${_reserva.toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _reserva = v),
            ),
            const SizedBox(height: 20),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Aplicar Configuração'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    final prov = context.read<AppProvider>();
    final qfAtualizado = QuadroFilho(
      id:                  widget.quadroFilho.id,
      nome:                _nomeCtrl.text.trim().isEmpty ? widget.quadroFilho.nome : _nomeCtrl.text.trim(),
      tipo:                widget.quadroFilho.tipo,
      cargas:              widget.quadroFilho.cargas,
      observacoes:         widget.quadroFilho.observacoes,
      tensao:              _tensao,
      numFases:            _numFases,
      fatorPotenciaGeral:  widget.quadroFilho.fatorPotenciaGeral,
      reservaPercent:      _reserva,
    );
    await prov.salvarQuadroFilho(widget.alimentadorId, qfAtualizado);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuração aplicada!'), duration: Duration(seconds: 1)),
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widget auxiliar: _MetricItem (painel de resultados)
// ══════════════════════════════════════════════════════════════════════════════
class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: highlight ? Border.all(color: Colors.white.withValues(alpha: 0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: highlight ? Colors.white : Colors.white60),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

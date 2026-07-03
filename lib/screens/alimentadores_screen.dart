import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/alimentador.dart';
import '../theme/app_theme.dart';
import 'quadro_filho_screen.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AlimentadoresScreen
// Tela principal do QGBT: lista de alimentadores + painel de totais.
// ══════════════════════════════════════════════════════════════════════════════
class AlimentadoresScreen extends StatelessWidget {
  final Projeto projeto;
  const AlimentadoresScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<AppProvider>();
    final alims  = prov.projetoAtual?.alimentadores ?? [];
    final resQGBT = prov.resultadoQGBT;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Banner QGBT ─────────────────────────────────────────────────
          _buildBannerQGBT(context, alims, resQGBT),
          // ── Lista ───────────────────────────────────────────────────────
          Expanded(
            child: alims.isEmpty
                ? _buildEmpty(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                    itemCount: alims.length,
                    itemBuilder: (ctx, i) =>
                        _AlimentadorCard(alimentador: alims[i], projeto: projeto),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addAlimentadorSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo Alimentador',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Banner consolidado QGBT ─────────────────────────────────────────────
  Widget _buildBannerQGBT(
      BuildContext context, List<Alimentador> alims, ResultadoQGBT? res) {
    final dimensionados = alims.where((a) => a.corrente > 0).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1B3D), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.electric_bolt, color: Color(0xFFFF7A00), size: 12),
                SizedBox(width: 4),
                Text('QGBT', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
            const SizedBox(width: 8),
            const Text('Quadro Geral de Baixa Tensão',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            const Spacer(),
            _StatusChip(
              label: '$dimensionados/${alims.length} dim.',
              ok: dimensionados == alims.length && alims.isNotEmpty,
            ),
          ]),
          const SizedBox(height: 10),
          // Métricas
          if (res != null) ...[
            Row(children: [
              _MetricTile(
                label: 'P. Aparente',
                value: '${res.totalPotenciaAparenteKva.toStringAsFixed(1)} kVA',
                icon: Icons.flash_on,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'I Total',
                value: '${res.totalCorrenteProjeto.toStringAsFixed(1)} A',
                icon: Icons.electrical_services,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Disj. Geral',
                value: '${res.disjuntorGeral} A',
                icon: Icons.security,
                highlight: true,
              ),
              const SizedBox(width: 8),
              _MetricTile(
                label: 'Cabo Ent.',
                value: '${res.condutorEntrada.toStringAsFixed(1)} mm²',
                icon: Icons.cable,
              ),
            ]),
          ] else ...[
            Row(children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                alims.isEmpty
                    ? 'Adicione alimentadores para calcular o QGBT'
                    : 'Dimensione os quadros para calcular automaticamente',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_tree_outlined, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Nenhum alimentador cadastrado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Cada alimentador representa uma saída do QGBT.\nAo abrir o alimentador, você cadastra as cargas do quadro destino.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addAlimentadorSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Primeiro Alimentador'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sheet para adicionar/editar alimentador ──────────────────────────────
  void _addAlimentadorSheet(BuildContext context, {Alimentador? existente}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlimentadorFormSheet(
        projeto: projeto,
        alimentadorExistente: existente,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _AlimentadorCard
// ══════════════════════════════════════════════════════════════════════════════
class _AlimentadorCard extends StatelessWidget {
  final Alimentador alimentador;
  final Projeto projeto;

  const _AlimentadorCard({required this.alimentador, required this.projeto});

  Color get _corStatus {
    if (!alimentador.temQuadro) return AppColors.textSecondary;
    if (alimentador.corrente == 0) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final a = alimentador;
    final temDados = a.corrente > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirQuadroFilho(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Linha 1: badge + nome + tipo + status ───────────────
              Row(children: [
                // Número / badge
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      a.nome.length <= 3 ? a.nome : a.nome.substring(0, 2),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nome,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (a.destino.isNotEmpty)
                        Text(a.destino,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Badge tipo quadro destino
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(a.tipoDestino.sigla,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(width: 6),
                // Indicador de status
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: _corStatus, shape: BoxShape.circle),
                ),
              ]),

              const SizedBox(height: 10),

              // ── Linha 2: dados elétricos automáticos ────────────────
              if (temDados) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      _ElecValue(label: 'Potência', value: '${a.potenciaAparenteKva.toStringAsFixed(1)} kVA'),
                      _divV(),
                      _ElecValue(label: 'Corrente', value: '${a.corrente.toStringAsFixed(1)} A'),
                      _divV(),
                      _ElecValue(label: 'Disjuntor', value: '${a.disjuntor} A', destaque: true),
                      _divV(),
                      _ElecValue(label: 'Cabo', value: '${a.condutor.toStringAsFixed(1)} mm²'),
                      _divV(),
                      _ElecValue(label: 'Circuitos', value: '${a.numCircuitos}'),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: !a.temQuadro
                        ? Colors.orange.withValues(alpha: 0.08)
                        : Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !a.temQuadro
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      !a.temQuadro ? Icons.touch_app_outlined : Icons.hourglass_empty,
                      size: 14,
                      color: !a.temQuadro ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      !a.temQuadro
                          ? 'Toque para abrir e cadastrar as cargas do ${a.tipoDestino.sigla}'
                          : 'Quadro sem cargas — adicione circuitos para calcular',
                      style: TextStyle(
                        fontSize: 11,
                        color: !a.temQuadro ? Colors.orange[800] : Colors.blue[800],
                      ),
                    ),
                  ]),
                ),
              ],

              // ── Linha 3: ações ──────────────────────────────────────
              const SizedBox(height: 8),
              Row(children: [
                _ActionBtn(
                  icon: Icons.open_in_new,
                  label: 'Abrir ${a.tipoDestino.sigla}',
                  color: AppColors.primary,
                  onTap: () => _abrirQuadroFilho(context),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  color: AppColors.secondary,
                  onTap: () => _editarAlimentador(context),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  label: 'Excluir',
                  color: AppColors.error,
                  onTap: () => _excluir(context),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divV() => Container(
    width: 1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: AppColors.divider,
  );

  void _abrirQuadroFilho(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuadroFilhoScreen(
          alimentador: alimentador,
          projeto: projeto,
        ),
      ),
    );
  }

  void _editarAlimentador(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlimentadorFormSheet(
        projeto: projeto,
        alimentadorExistente: alimentador,
      ),
    );
  }

  Future<void> _excluir(BuildContext context) async {
    final prov = context.read<AppProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir alimentador?'),
        content: Text(
          'Excluir "${alimentador.nome}" irá remover também todas as cargas do quadro associado.\n\nEssa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await prov.excluirAlimentador(alimentador.id);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _AlimentadorFormSheet — adicionar / editar alimentador
// ══════════════════════════════════════════════════════════════════════════════
class _AlimentadorFormSheet extends StatefulWidget {
  final Projeto projeto;
  final Alimentador? alimentadorExistente;

  const _AlimentadorFormSheet({
    required this.projeto,
    this.alimentadorExistente,
  });

  @override
  State<_AlimentadorFormSheet> createState() => _AlimentadorFormSheetState();
}

class _AlimentadorFormSheetState extends State<_AlimentadorFormSheet> {
  final _formKey   = GlobalKey<FormState>();
  final _nomeCtrl  = TextEditingController();
  final _destCtrl  = TextEditingController();
  final _obsCtrl   = TextEditingController();

  TipoQuadroFilho _tipo = TipoQuadroFilho.qd;

  @override
  void initState() {
    super.initState();
    final a = widget.alimentadorExistente;
    if (a != null) {
      _nomeCtrl.text = a.nome;
      _destCtrl.text = a.destino;
      _obsCtrl.text  = a.observacoes;
      _tipo = a.tipoDestino;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _destCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.alimentadorExistente != null;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Editar Alimentador' : 'Novo Alimentador',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cada alimentador é uma saída protegida do QGBT que alimenta um quadro.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Nome do alimentador
              TextFormField(
                controller: _nomeCtrl,
                decoration: _dec('Nome do Alimentador', hint: 'Ex: Q1, Q2-3, Alim. Bloco A'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              // Destino / descrição
              TextFormField(
                controller: _destCtrl,
                decoration: _dec('Destino / Descrição', hint: 'Ex: Bloco A – 3º Andar, Casa de Bombas'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Tipo do quadro destino
              const Text('Tipo do Quadro de Destino',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: TipoQuadroFilho.values.map((t) {
                  final sel = _tipo == t;
                  return GestureDetector(
                    onTap: () => setState(() => _tipo = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(t.icone, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(t.sigla,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? Colors.white : AppColors.textPrimary,
                            )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Observações
              TextFormField(
                controller: _obsCtrl,
                decoration: _dec('Observações', hint: 'Opcional'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEdit ? 'Salvar Alterações' : 'Criar Alimentador'),
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
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AppProvider>();
    final existente = widget.alimentadorExistente;

    if (existente != null) {
      // Editar preservando quadroFilho
      final atualizado = Alimentador(
        id: existente.id,
        nome: _nomeCtrl.text.trim(),
        destino: _destCtrl.text.trim(),
        tipoDestino: _tipo,
        observacoes: _obsCtrl.text.trim(),
        ordem: existente.ordem,
        quadroFilho: existente.quadroFilho,
      );
      await prov.atualizarAlimentador(atualizado);
    } else {
      // Criar novo
      final novoId = const Uuid().v4();
      final novo = Alimentador(
        id: novoId,
        nome: _nomeCtrl.text.trim(),
        destino: _destCtrl.text.trim(),
        tipoDestino: _tipo,
        observacoes: _obsCtrl.text.trim(),
        ordem: (prov.projetoAtual?.alimentadores.length ?? 0),
        // QuadroFilho criado automaticamente (vazio) já mapeado ao tipo
        quadroFilho: QuadroFilho(
          id: const Uuid().v4(),
          nome: '${_tipo.sigla} – ${_destCtrl.text.trim().isNotEmpty ? _destCtrl.text.trim() : _nomeCtrl.text.trim()}',
          tipo: _tipo,
          tensao: widget.projeto.tensao.valor,
          numFases: widget.projeto.numFases.index + 1,
        ),
      );
      await prov.adicionarAlimentador(novo);
    }

    if (mounted) Navigator.pop(context);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ══════════════════════════════════════════════════════════════════════════════
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: highlight
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 12,
                color: highlight ? AppColors.primary : Colors.white54),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: highlight ? AppColors.primary : Colors.white,
                )),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool ok;
  const _StatusChip({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ok ? AppColors.success.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ok ? AppColors.success.withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ok ? AppColors.success : Colors.orange,
          )),
    );
  }
}

class _ElecValue extends StatelessWidget {
  final String label;
  final String value;
  final bool destaque;
  const _ElecValue({required this.label, required this.value, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: destaque ? AppColors.primary : AppColors.textPrimary,
              )),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

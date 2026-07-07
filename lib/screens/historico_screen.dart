import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/cliente.dart';
import '../theme/app_theme.dart';
import '../utils/masks.dart';
import '../services/cep_service.dart';
import 'projeto_screen.dart';
import 'perfil_screen.dart';
import 'clientes_screen.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _termoBusca = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, prov, _) {
        if (prov.carregando) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtra projetos pelo termo de busca
        final todosProjetos = prov.projetos;
        final projetosFiltrados = _termoBusca.isEmpty
            ? todosProjetos
            : todosProjetos
                .where((p) =>
                    p.nome.toLowerCase().contains(_termoBusca.toLowerCase()) ||
                    p.tipoQuadro.sigla
                        .toLowerCase()
                        .contains(_termoBusca.toLowerCase()) ||
                    (p.contratante.razaoSocial
                        .toLowerCase()
                        .contains(_termoBusca.toLowerCase())))
                .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 72,
                collapsedHeight: kToolbarHeight,
                pinned: true,
                backgroundColor: AppColors.secondary,
                toolbarHeight: kToolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 12),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quadro Master', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const Text('ABNT NBR 5410', style: TextStyle(fontSize: 9, color: Colors.white60)),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.85)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, right: 16),
                        child: Icon(Icons.electric_bolt, size: 36, color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'empresa')  _abrirConfiguracoes(context);
                      if (value == 'perfil')   _abrirPerfil(context);
                      if (value == 'clientes') _abrirClientes(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'perfil',
                        child: Row(
                          children: [
                            Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'empresa',
                        child: Row(
                          children: [
                            Icon(Icons.business_outlined, color: AppColors.secondary, size: 20),
                            SizedBox(width: 10),
                            Text('Empresa Executora', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'clientes',
                        child: Row(
                          children: [
                            Icon(Icons.people_outlined, color: Color(0xFF00897B), size: 20),
                            SizedBox(width: 10),
                            Text('Clientes', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Card crachá do usuário
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _CardCracha(prov: prov),
                ),
              ),
              // Barra de busca
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _termoBusca = v),
                    decoration: InputDecoration(
                      hintText: 'Pesquisar projetos...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _termoBusca = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _termoBusca.isEmpty
                              ? '${todosProjetos.length} projeto${todosProjetos.length != 1 ? "s" : ""}'
                              : '${projetosFiltrados.length} resultado${projetosFiltrados.length != 1 ? "s" : ""} para "$_termoBusca"',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      _buildFiltroChip(),
                    ],
                  ),
                ),
              ),
              if (projetosFiltrados.isEmpty)
                SliverFillRemaining(
                  child: _termoBusca.isNotEmpty
                      ? _buildSemResultados()
                      : _buildEmpty(context),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ProjetoCard(projeto: projetosFiltrados[i]),
                    childCount: projetosFiltrados.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _novoProjetoDialog(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Novo Projeto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildFiltroChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sort, size: 14, color: AppColors.primary),
          SizedBox(width: 4),
          Text('Recentes', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSemResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 40, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum projeto encontrado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tente outro termo de busca',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.electric_bolt, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Nenhum projeto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Use o botão + abaixo para criar\nseu primeiro projeto elétrico',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Icon(Icons.arrow_downward_rounded, size: 28, color: AppColors.primary.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  void _novoProjetoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (_) => _NovoProjetoSheet(),
    );
  }

  void _abrirConfiguracoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      builder: (_) => _ConfiguracoesSheet(),
    );
  }

  void _abrirPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PerfilScreen()),
    );
  }

  void _abrirClientes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClientesScreen()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Crachá — apresentação do profissional
// ─────────────────────────────────────────────────────────────────────────────
class _CardCracha extends StatelessWidget {
  final AppProvider prov;
  const _CardCracha({required this.prov});

  @override
  Widget build(BuildContext context) {
    final perfil = prov.perfilUsuario;
    final projetos = prov.projetos;
    final temDados = perfil.nome.isNotEmpty || perfil.registro.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.88)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.secondary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // ── Área do crachá ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              children: [
                // Foto circular
                _buildAvatar(perfil),
                const SizedBox(height: 12),

                // Nome
                Text(
                  temDados ? (perfil.nome.isNotEmpty ? perfil.nome : 'Profissional') : 'Toque em ⚙ para configurar',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Cargo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    perfil.cargoLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 8),

                // Registro + CPF
                if (perfil.registro.isNotEmpty || perfil.cpf.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (perfil.registro.isNotEmpty) ...[
                        const Icon(Icons.workspace_premium_outlined, size: 12, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text('${perfil.registroLabel}: ${perfil.registro}',
                          style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                      if (perfil.registro.isNotEmpty && perfil.cpf.isNotEmpty)
                        const Text('  ·  ', style: TextStyle(color: Colors.white38)),
                      if (perfil.cpf.isNotEmpty) ...[
                        const Icon(Icons.badge_outlined, size: 12, color: Colors.white60),
                        const SizedBox(width: 4),
                        Text('CPF: ${perfil.cpf}',
                          style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ],
                    ],
                  ),
              ],
            ),
          ),

          // ── Divisor + estatísticas rápidas ────────────────────────
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(
                  icon: Icons.folder_outlined,
                  valor: '${projetos.length}',
                  rotulo: 'Projetos',
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                _statItem(
                  icon: Icons.check_circle_outline,
                  valor: '${projetos.where((p) => p.status == StatusProjeto.concluido).length}',
                  rotulo: 'Concluídos',
                ),
                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.15)),
                _statItem(
                  icon: Icons.edit_outlined,
                  valor: '${projetos.where((p) => p.status == StatusProjeto.elaboracao).length}',
                  rotulo: 'Em andamento',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({required IconData icon, required String valor, required String rotulo}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white60),
        const SizedBox(height: 3),
        Text(valor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(rotulo,
            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _buildAvatar(perfil) {
    if (perfil.fotoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(perfil.fotoBase64 as String);
        return Container(
          width: 74, height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: ClipOval(child: Image.memory(bytes, fit: BoxFit.cover)),
        );
      } catch (_) {}
    }
    return Container(
      width: 74, height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.18),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: const Icon(Icons.person, size: 38, color: AppColors.primary),
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
class _ProjetoCard extends StatelessWidget {
  final Projeto projeto;
  const _ProjetoCard({required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final statusColors = {
      StatusProjeto.elaboracao: AppColors.warning,
      StatusProjeto.concluido: AppColors.success,
      StatusProjeto.revisao: AppColors.primary,
    };
    final sc = statusColors[projeto.status]!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: Key(projeto.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => prov.excluirProjeto(projeto.id),
        child: GestureDetector(
          onTap: () async {
            await prov.abrirProjeto(projeto);
            if (context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjetoScreen()));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.electrical_services, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(projeto.nome, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text(projeto.tipoQuadro.sigla, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(projeto.status.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(Icons.flash_on, projeto.tensao.label),
                      const SizedBox(width: 8),
                      _infoChip(Icons.cable, '${projeto.cargas.length} circuitos'),
                      const SizedBox(width: 8),
                      if (projeto.contratante.razaoSocial.isNotEmpty)
                        Expanded(
                          child: _infoChip(Icons.business, projeto.contratante.razaoSocial),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        'Modificado: ${fmt.format(projeto.modificadoEm)}',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _menuOpcoes(context, projeto),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
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

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir projeto?'),
        content: Text('O projeto "${projeto.nome}" será excluído permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _menuOpcoes(BuildContext context, Projeto p) {
    final prov = context.read<AppProvider>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('Duplicar projeto'),
              onTap: () async {
                Navigator.pop(context);
                await prov.duplicarProjeto(p);
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Marcar como Concluído'),
              onTap: () async {
                Navigator.pop(context);
                await prov.atualizarStatus(p.id, StatusProjeto.concluido);
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: AppColors.warning),
              title: const Text('Marcar em Revisão'),
              onTap: () async {
                Navigator.pop(context);
                await prov.atualizarStatus(p.id, StatusProjeto.revisao);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Excluir', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _confirmDelete(context);
                if (ok == true) await prov.excluirProjeto(p.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NovoProjetoSheet extends StatefulWidget {
  @override
  State<_NovoProjetoSheet> createState() => _NovoProjetoSheetState();
}

class _NovoProjetoSheetState extends State<_NovoProjetoSheet> {
  final _nomeCtrl = TextEditingController();
  TipoQuadro _tipo = TipoQuadro.qd;
  TensaoAlimentacao _tensao = TensaoAlimentacao.v220;
  NumeroFases _fases = NumeroFases.trifasico;
  Cliente? _clienteSelecionado;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final prov = context.watch<AppProvider>();
    final temClientes = prov.clientes.isNotEmpty;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(maxHeight: screenH * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Novo Projeto',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    // Nome do projeto
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Projeto',
                        hintText: 'Ex: QD-01 Térreo, QF Bombas...',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),

                    // Tipo de quadro
                    DropdownButtonFormField<TipoQuadro>(
                      value: _tipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Quadro',
                        prefixIcon: Icon(Icons.electrical_services),
                      ),
                      items: TipoQuadro.values.map((t) => DropdownMenuItem(
                        value: t, child: Text(t.label),
                      )).toList(),
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                    const SizedBox(height: 12),

                    // Tensão + Fases
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<TensaoAlimentacao>(
                          value: _tensao,
                          decoration: const InputDecoration(
                            labelText: 'Tensão',
                            prefixIcon: Icon(Icons.flash_on),
                          ),
                          items: TensaoAlimentacao.values.map((t) => DropdownMenuItem(
                            value: t, child: Text(t.label),
                          )).toList(),
                          onChanged: (v) => setState(() => _tensao = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<NumeroFases>(
                          value: _fases,
                          decoration: const InputDecoration(labelText: 'Fases'),
                          items: NumeroFases.values.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.label.split('–').first.trim()),
                          )).toList(),
                          onChanged: (v) => setState(() => _fases = v!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Seletor de cliente ──────────────────────────
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('Contratante',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const Spacer(),
                        if (!temClientes)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientesScreen()));
                            },
                            child: const Text(
                              'Cadastrar clientes →',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, decoration: TextDecoration.underline),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (temClientes) ...[
                      // Card cliente selecionado ou botão para selecionar
                      if (_clienteSelecionado != null)
                        _buildClienteSelecionadoCard()
                      else
                        _buildBotaoSelecionarCliente(context),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Sem clientes cadastrados. Você pode adicionar depois em Configurações → Clientes.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _criar,
                        child: const Text('Criar Projeto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoSelecionarCliente(BuildContext context) {
    return GestureDetector(
      onTap: () => _selecionarCliente(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.primary.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Selecionar cliente cadastrado...',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteSelecionadoCard() {
    final c = _clienteSelecionado!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(c.iniciais,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.razaoSocial,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
                if (c.documento.isNotEmpty || c.cidade.isNotEmpty)
                  Text(
                    [if (c.documento.isNotEmpty) c.documento, if (c.cidade.isNotEmpty) c.cidade].join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 18, color: AppColors.primary),
            tooltip: 'Trocar cliente',
            onPressed: () => _selecionarCliente(context),
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            tooltip: 'Remover',
            onPressed: () => setState(() => _clienteSelecionado = null),
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarCliente(BuildContext context) async {
    final cliente = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => const ClienteSeletorSheet(),
    );
    if (cliente != null) setState(() => _clienteSelecionado = cliente);
  }

  Future<void> _criar() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    final prov = context.read<AppProvider>();
    final p = await prov.novoProjeto();
    // Preenche dados do cliente selecionado (se houver)
    final contratante = _clienteSelecionado?.toEmpresaContratante();
    final updated = p.copyWith(
      nome: _nomeCtrl.text.trim(),
      tipoQuadro: _tipo,
      tensao: _tensao,
      numFases: _fases,
      contratante: contratante,
    );
    await prov.atualizarProjeto(updated);
    await prov.abrirProjeto(updated);
    if (mounted) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjetoScreen()));
    }
  }
}

class _ConfiguracoesSheet extends StatefulWidget {
  @override
  State<_ConfiguracoesSheet> createState() => _ConfiguracoesSheetState();
}

class _ConfiguracoesSheetState extends State<_ConfiguracoesSheet> {
  final _formKey = GlobalKey<FormState>();
  late EmpresaExecutora _empresa;

  // tipo
  TipoPessoa _tipoPessoa = TipoPessoa.juridica;
  CargoResponsavel _cargo = CargoResponsavel.engenheiro;

  // logo
  String? _logoBase64;

  // controllers
  late TextEditingController _razaoCtrl;
  late TextEditingController _docCtrl;
  late TextEditingController _registroCtrl;
  late TextEditingController _respCtrl;
  late TextEditingController _cepCtrl;
  late TextEditingController _ruaCtrl;
  late TextEditingController _numCtrl;
  late TextEditingController _bairroCtrl;
  late TextEditingController _cidadeCtrl;
  late TextEditingController _estadoCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _emailCtrl;
  bool _buscandoCep = false;

  @override
  void initState() {
    super.initState();
    _empresa = context.read<AppProvider>().empresaExecutora;
    _tipoPessoa = _empresa.tipoPessoa == 'fisica' ? TipoPessoa.fisica : TipoPessoa.juridica;
    _cargo = CargoResponsavel.values.firstWhere(
      (c) => c.name == _empresa.cargo, orElse: () => CargoResponsavel.engenheiro);
    _logoBase64 = _empresa.logoBase64.isNotEmpty ? _empresa.logoBase64 : null;
    _razaoCtrl = TextEditingController(text: _empresa.razaoSocial);
    _docCtrl    = TextEditingController(text: _empresa.documento);
    _registroCtrl = TextEditingController(text: _empresa.registro);
    _respCtrl   = TextEditingController(text: _empresa.responsavel);
    _cepCtrl    = TextEditingController(text: _empresa.cep);
    _ruaCtrl    = TextEditingController(text: _empresa.rua);
    _numCtrl    = TextEditingController(text: _empresa.numero);
    _bairroCtrl = TextEditingController(text: _empresa.bairro);
    _cidadeCtrl = TextEditingController(text: _empresa.cidade);
    _estadoCtrl = TextEditingController(text: _empresa.estado);
    _telCtrl    = TextEditingController(text: _empresa.telefone);
    _emailCtrl  = TextEditingController(text: _empresa.email);
  }

  bool get _isPF => _tipoPessoa == TipoPessoa.fisica;
  bool get _registroEhCpf => _cargo == CargoResponsavel.tecnico || _cargo == CargoResponsavel.profissional;

  Future<void> _selecionarLogo() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _logoBase64 = base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar imagem. Verifique as permissões.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _buscarCep(String cep) async {
    if (!Validators.cepValido(cep)) return;
    setState(() => _buscandoCep = true);
    final end = await CepService.buscarCep(cep);
    setState(() => _buscandoCep = false);
    if (end == null || end.erro) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CEP não encontrado'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    _ruaCtrl.text    = end.logradouro;
    _bairroCtrl.text = end.bairro;
    _cidadeCtrl.text = end.cidade;
    _estadoCtrl.text = end.estado.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      constraints: BoxConstraints(maxHeight: screenH * 0.92),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar fixo no topo
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const Text('Empresa Executora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('Dados que aparecem no cabeçalho do relatório', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),

              // ── Logo da empresa ──────────────────────────────────────
              _sectionLabel('Logo da Empresa'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selecionarLogo,
                child: Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _logoBase64 != null
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.divider,
                      width: _logoBase64 != null ? 2 : 1,
                    ),
                  ),
                  child: _logoBase64 != null
                      ? Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(_logoBase64!),
                                  height: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _logoBase64 = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.primary.withValues(alpha: 0.6)),
                            const SizedBox(height: 6),
                            const Text('Toque para adicionar logo',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            const Text('PNG, JPG – até 400×400px',
                              style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de pessoa
              _sectionLabel('Tipo de Pessoa'),
              DropdownButtonFormField<TipoPessoa>(
                value: _tipoPessoa,
                decoration: const InputDecoration(labelText: 'Tipo de Pessoa', prefixIcon: Icon(Icons.person_outline)),
                items: TipoPessoa.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                onChanged: (v) => setState(() { _tipoPessoa = v!; _docCtrl.clear(); }),
              ),
              const SizedBox(height: 10),

              // Razão Social
              TextFormField(
                controller: _razaoCtrl,
                decoration: InputDecoration(
                  labelText: _isPF ? 'Nome Completo' : 'Razão Social / Nome Fantasia',
                  prefixIcon: const Icon(Icons.business, size: 18),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 10),

              // CPF / CNPJ dinâmico
              TextFormField(
                controller: _docCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_isPF ? CpfInputFormatter() : CnpjInputFormatter()],
                decoration: InputDecoration(
                  labelText: _isPF ? 'CPF' : 'CNPJ',
                  hintText: _isPF ? '000.000.000-00' : '00.000.000/0000-00',
                  prefixIcon: const Icon(Icons.badge, size: 18),
                ),
                validator: (v) => Validators.validarCpfOuCnpj(v, _isPF),
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 10),

              // Cargo
              _sectionLabel('Dados Profissionais'),
              DropdownButtonFormField<CargoResponsavel>(
                value: _cargo,
                decoration: const InputDecoration(labelText: 'Cargo', prefixIcon: Icon(Icons.work_outline)),
                items: CargoResponsavel.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                onChanged: (v) => setState(() { _cargo = v!; _registroCtrl.clear(); }),
              ),
              const SizedBox(height: 10),

              // CREA / CRT / CPF dinâmico
              TextFormField(
                controller: _registroCtrl,
                keyboardType: _registroEhCpf ? TextInputType.number : TextInputType.text,
                inputFormatters: _registroEhCpf ? [CpfInputFormatter()] : [CreaInputFormatter()],
                decoration: InputDecoration(
                  labelText: _cargo.registroLabel,
                  hintText: _cargo.registroHint,
                  prefixIcon: const Icon(Icons.verified, size: 18),
                  helperText: _registroEhCpf ? 'Validação de CPF ativa' : 'Ex: 123456-7/SP',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  if (_registroEhCpf && !Validators.cpfValido(v)) return 'CPF inválido';
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
              ),
              const SizedBox(height: 10),

              // Responsável Técnico
              TextFormField(
                controller: _respCtrl,
                decoration: const InputDecoration(labelText: 'Responsável Técnico', prefixIcon: Icon(Icons.person, size: 18)),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // ── Endereço ────────────────────────────────────
              _sectionLabel('Endereço'),

              // CEP + botão buscar
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CepInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'CEP (opcional)',
                      hintText: '00000-000',
                      prefixIcon: const Icon(Icons.pin_drop, size: 18),
                      suffixIcon: _buscandoCep
                          ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: const Icon(Icons.search), onPressed: () => _buscarCep(_cepCtrl.text)),
                    ),
                    onChanged: (v) { if (Validators.cepValido(v)) _buscarCep(v); },
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ruaCtrl,
                decoration: const InputDecoration(labelText: 'Logradouro / Rua', prefixIcon: Icon(Icons.location_on, size: 18)),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _numCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número', prefixIcon: Icon(Icons.tag, size: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _bairroCtrl,
                    decoration: const InputDecoration(labelText: 'Bairro'),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cidadeCtrl,
                    decoration: const InputDecoration(labelText: 'Cidade', prefixIcon: Icon(Icons.location_city, size: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _estadoCtrl,
                    decoration: const InputDecoration(labelText: 'UF'),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Contato ─────────────────────────────────────
              _sectionLabel('Contato'),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _telCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [TelefoneInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Telefone', hintText: '(00) 00000-0000', prefixIcon: Icon(Icons.phone, size: 18)),
                    validator: Validators.validarTelefone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email, size: 18)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('Salvar Configurações'),
                ),
              ),
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

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final nova = EmpresaExecutora(
      razaoSocial:  _razaoCtrl.text,
      documento:    _docCtrl.text,
      registro:     _registroCtrl.text,
      responsavel:  _respCtrl.text,
      cargo:        _cargo.name,
      tipoPessoa:   _tipoPessoa.name,
      cep:          _cepCtrl.text,
      rua:          _ruaCtrl.text,
      numero:       _numCtrl.text,
      bairro:       _bairroCtrl.text,
      cidade:       _cidadeCtrl.text,
      estado:       _estadoCtrl.text,
      telefone:     _telCtrl.text,
      email:        _emailCtrl.text,
      logoBase64:   _logoBase64 ?? '',
    );
    await context.read<AppProvider>().atualizarEmpresaExecutora(nova);
    if (mounted) Navigator.pop(context);
  }
}

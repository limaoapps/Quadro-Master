import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../theme/app_theme.dart';
import 'projeto_dados_screen.dart';
import 'cargas_screen.dart';
import 'analise_screen.dart';
import 'relatorio_screen.dart';
import 'alimentadores_screen.dart';

class ProjetoScreen extends StatefulWidget {
  const ProjetoScreen({super.key});

  @override
  State<ProjetoScreen> createState() => _ProjetoScreenState();
}

class _ProjetoScreenState extends State<ProjetoScreen> {
  int _currentIndex = 0;

  List<_TabItem> _buildTabs(TipoQuadro tipo) => [
    const _TabItem(icon: Icons.info_outline,         label: 'Projeto'),
    tipo == TipoQuadro.qgbt
        ? const _TabItem(icon: Icons.account_tree,   label: 'Alimentadores')
        : const _TabItem(icon: Icons.cable,          label: 'Cargas'),
    const _TabItem(icon: Icons.analytics_outlined,   label: 'Análise'),
    const _TabItem(icon: Icons.description_outlined, label: 'Relatório'),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final projeto = prov.projetoAtual;
    if (projeto == null) return const SizedBox.shrink();

    // Para QGBT: aba "Cargas" mostra AlimentadoresScreen
    final isQGBT = projeto.tipoQuadro == TipoQuadro.qgbt;
    final tabs = _buildTabs(projeto.tipoQuadro);

    final screens = [
      ProjetoDadosScreen(
        projeto: projeto,
        onSaved: () => setState(() => _currentIndex = 1),
      ),
      isQGBT
          ? AlimentadoresScreen(projeto: projeto)
          : CargasScreen(projeto: projeto),
      AnaliseScreen(projeto: projeto),
      RelatorioScreen(projeto: projeto),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () {
            prov.fecharProjeto();
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projeto.nome,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_tipoSigla(projeto.tipoQuadro)} · ${_tensaoLabel(projeto.tensao)} · ${_fasesLabel(projeto.numFases)}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            onPressed: () async {
              await prov.salvarProjetoAtual();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Projeto salvo!'), duration: Duration(seconds: 1)),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Excluir projeto?'),
                    content: const Text('Tem certeza que deseja excluir este projeto?\n\nEsta ação não pode ser desfeita.'),
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
                  final id = prov.projetoAtual?.id ?? '';
                  prov.fecharProjeto();
                  await prov.excluirProjeto(id);
                  if (context.mounted) Navigator.pop(context);
                }
              } else if (value == 'duplicate') {
                if (prov.projetoAtual != null) {
                  await prov.duplicarProjeto(prov.projetoAtual!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Projeto duplicado!'), duration: Duration(seconds: 2)),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Duplicar projeto', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Text('Excluir projeto',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: List.generate(tabs.length, (i) {
                final selected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            tabs[i].icon,
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

String _tipoSigla(TipoQuadro t) {
  switch (t) {
    case TipoQuadro.qd:            return 'QD';
    case TipoQuadro.qf:            return 'QF';
    case TipoQuadro.qgbt:          return 'QGBT';
    case TipoQuadro.painelEletrico: return 'PE';
  }
}

String _tensaoLabel(TensaoAlimentacao t) {
  switch (t) {
    case TensaoAlimentacao.v127: return '127 V';
    case TensaoAlimentacao.v220: return '220 V';
    case TensaoAlimentacao.v380: return '380 V';
    case TensaoAlimentacao.v440: return '440 V';
  }
}

String _fasesLabel(NumeroFases f) {
  switch (f) {
    case NumeroFases.monofasico: return '1F';
    case NumeroFases.bifasico: return '2F';
    case NumeroFases.trifasico: return '3F+N';
  }
}

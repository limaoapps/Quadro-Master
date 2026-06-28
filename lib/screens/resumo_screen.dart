import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/resultado_projeto.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';

class ResumoScreen extends StatelessWidget {
  final Projeto projeto;
  const ResumoScreen({super.key, required this.projeto});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final resultado = prov.resultado;

    if (prov.projetoAtual?.cargas.isEmpty ?? true) {
      return _buildSemCargas();
    }
    if (resultado == null) return const SizedBox.shrink();

    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alertas
          if (resultado.alertas.isNotEmpty) ...[
            _sectionTitle('⚠️ Alertas e Recomendações'),
            ...resultado.alertas.map((a) => AlertBadge(
              message: a,
              color: a.contains('FP') || a.contains('ANEEL') ? AppColors.error : AppColors.warning,
            )),
            const SizedBox(height: 16),
          ],

          // Potências totais
          _sectionTitle('Potências Totais'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              MetricCard(label: 'Potência Ativa', value: resultado.totalPotenciaAtiva.toStringAsFixed(2), unit: 'kW', icon: Icons.bolt, color: AppColors.primary),
              MetricCard(label: 'Potência Reativa', value: resultado.totalPotenciaReativa.toStringAsFixed(2), unit: 'kVAr', icon: Icons.rotate_right, color: const Color(0xFF7B1FA2)),
              MetricCard(label: 'Potência Aparente', value: resultado.totalPotenciaAparente.toStringAsFixed(2), unit: 'kVA', icon: Icons.power, color: const Color(0xFF0288D1)),
              MetricCard(label: 'Fator de Potência', value: resultado.fatorPotenciaMedio.toStringAsFixed(3), unit: 'cos φ', icon: Icons.tune, color: resultado.fatorPotenciaMedio >= 0.92 ? AppColors.success : AppColors.error),
            ],
          ),
          const SizedBox(height: 16),

          // Correntes por fase
          _sectionTitle('Correntes por Fase'),
          _buildFaseCard(resultado),
          const SizedBox(height: 16),

          // Correntes calculadas
          _sectionTitle('Correntes Calculadas'),
          _buildCorrentesCard(resultado),
          const SizedBox(height: 16),

          // Disjuntor geral
          _sectionTitle('Proteção do Quadro'),
          _buildDisjuntorCard(resultado, projeto),
          const SizedBox(height: 16),

          // Planilha de cargas
          _sectionTitle('Planilha de Circuitos', subtitle: '${resultado.numCircuitos} circuitos ativos'),
          _buildTabelaCargas(context),
          const SizedBox(height: 16),

          // Correção de FP
          if (resultado.necessitaCorrecaoFP) ...[
            _sectionTitle('Correção do Fator de Potência'),
            _buildFPCard(resultado),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSemCargas() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.bar_chart, size: 48, color: AppColors.textSecondary),
        SizedBox(height: 12),
        Text('Cadastre cargas para ver o resumo', style: TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );

  Widget _sectionTitle(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SectionHeader(title: title, subtitle: subtitle),
  );

  Widget _buildFaseCard(ResultadoProjeto r) {
    final maxI = [r.correnteFaseA, r.correnteFaseB, r.correnteFaseC].reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PhaseIndicator(label: 'FASE A', corrente: r.correnteFaseA, maxCorrente: maxI, color: AppColors.phaseA),
              PhaseIndicator(label: 'FASE B', corrente: r.correnteFaseB, maxCorrente: maxI, color: AppColors.phaseB),
              PhaseIndicator(label: 'FASE C', corrente: r.correnteFaseC, maxCorrente: maxI, color: AppColors.phaseC),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: r.desbalanceamentoPercent > 10
                  ? AppColors.error.withValues(alpha: 0.08)
                  : r.desbalanceamentoPercent > 2
                      ? AppColors.warning.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  r.desbalanceamentoPercent > 10 ? Icons.error : r.desbalanceamentoPercent > 2 ? Icons.warning_amber : Icons.check_circle,
                  size: 16,
                  color: r.desbalanceamentoPercent > 10 ? AppColors.error : r.desbalanceamentoPercent > 2 ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Desbalanceamento: ${r.desbalanceamentoPercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: r.desbalanceamentoPercent > 10 ? AppColors.error : r.desbalanceamentoPercent > 2 ? AppColors.warning : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrentesCard(ResultadoProjeto r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _row('Corrente Total', '${r.correnteTotal.toStringAsFixed(2)} A'),
          const Divider(height: 16),
          _row('Corrente de Neutro', '${r.correnteNeutro.toStringAsFixed(2)} A', sub: 'Sistema desequilibrado'),
          const Divider(height: 16),
          _row(
            'Corrente de Projeto (×1,25)',
            '${r.correnteProjeto.toStringAsFixed(2)} A',
            highlight: true,
            sub: 'NBR 5410 – margem de segurança 25%',
          ),
        ],
      ),
    );
  }

  Widget _buildDisjuntorCard(ResultadoProjeto r, Projeto p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.electric_bolt, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disjuntor Geral', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text('${r.disjuntorPolos}P × ${r.disjuntorGeral} A',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const Text('MCCB – Caixa Moldada / Curva D', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _infoItem('Icc Mínimo', '≥ 10 kA', Icons.warning_amber)),
              Expanded(child: _infoItem('DR Recomendado', '300 mA', Icons.security)),
              Expanded(child: _infoItem('Nº Circuitos', '${r.numCircuitos}', Icons.cable)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabelaCargas(BuildContext context) {
    final prov = context.read<AppProvider>();
    final cargas = prov.projetoAtual?.cargas.where((c) => c.ativo).toList() ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
          columnSpacing: 16,
          headingTextStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          dataTextStyle: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Circuito')),
            DataColumn(label: Text('Fase')),
            DataColumn(label: Text('P.Ativa\n(W)')),
            DataColumn(label: Text('Corrente\n(A)')),
            DataColumn(label: Text('Disj.\n(A)')),
            DataColumn(label: Text('Cond.\n(mm²)')),
            DataColumn(label: Text('ΔV\n(%)')),
          ],
          rows: cargas.asMap().entries.map((e) {
            final i = e.key + 1;
            final c = e.value;
            final dvAlert = c.quedaTensaoPercent > 4.0;
            return DataRow(
              color: WidgetStateProperty.resolveWith((states) => i.isEven ? AppColors.background : Colors.white),
              cells: [
                DataCell(Text('$i', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(c.descricao, overflow: TextOverflow.ellipsis, maxLines: 1),
                  ),
                ),
                DataCell(_faseChip(c.fase)),
                DataCell(Text(c.potenciaAtiva.toStringAsFixed(0))),
                DataCell(Text(c.corrente.toStringAsFixed(1))),
                DataCell(Text('${c.disjuntorSugerido}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
                DataCell(Text('${c.condutorSugerido}')),
                DataCell(Text(
                  c.quedaTensaoPercent.toStringAsFixed(1),
                  style: TextStyle(color: dvAlert ? AppColors.error : AppColors.success, fontWeight: FontWeight.w600),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFPCard(ResultadoProjeto r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.battery_charging_full, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              const Text('Banco de Capacitores Recomendado', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          _row('FP Atual', r.fatorPotenciaMedio.toStringAsFixed(3)),
          _row('FP Desejado', '0,920 (mínimo ANEEL)'),
          _row('Potência Capacitiva', '${r.capacitorKvar.toStringAsFixed(2)} kVAr', highlight: true),
          _row('Ligação', 'Trifásico – Triângulo (por fase)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Fórmula: Q_cap = P × (tan φ₁ – tan φ₂)\nConforme NBR 5410 e regulamentação ANEEL',
              style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false, String? sub}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (sub != null) Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 16 : 13,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _infoItem(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, size: 18, color: AppColors.textSecondary),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ],
  );

  Widget _faseChip(fase) {
    final colors = {
      0: AppColors.phaseA, 1: AppColors.phaseB, 2: AppColors.phaseC,
      3: AppColors.success,
      4: const Color(0xFF1565C0), // AB
      5: const Color(0xFF6A1B9A), // AC
      6: const Color(0xFF00695C), // BC
    };
    final c = colors[fase.index] ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(fase.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

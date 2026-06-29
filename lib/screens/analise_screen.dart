import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../models/resultado_projeto.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AnaliseScreen — Módulos 1-13 de Análise Técnica Profissional
// ─────────────────────────────────────────────────────────────────────────────
class AnaliseScreen extends StatefulWidget {
  final Projeto projeto;
  const AnaliseScreen({super.key, required this.projeto});

  @override
  State<AnaliseScreen> createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen> {
  // Módulo 9 — tarifa
  final _tarifaCtrl = TextEditingController(text: '0.80');
  double _tarifaKwh = 0.80;

  @override
  void dispose() {
    _tarifaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final resultado = prov.resultado;

    if (prov.projetoAtual?.cargas.isEmpty ?? true) {
      return _buildVazio();
    }
    if (resultado == null) return const SizedBox.shrink();

    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Módulo 12: Painel Executivo ────────────────────────
          _painelExecutivo(resultado),
          const SizedBox(height: 20),

          // ── Módulo 10: Índice Geral ─────────────────────────────
          _indiceGeral(resultado),
          const SizedBox(height: 20),

          // ── Módulo 1: Taxa de Ocupação do Quadro ────────────────
          _secao('1. Taxa de Ocupação do Quadro', Icons.grid_view_rounded),
          _taxaOcupacao(resultado),
          const SizedBox(height: 16),

          // ── Módulo 2: Reserva de Carga ──────────────────────────
          _secao('2. Reserva de Carga', Icons.battery_charging_full),
          _reservaCarga(resultado),
          const SizedBox(height: 16),

          // ── Módulo 3+4: Balanceamento Visual ───────────────────
          _secao('3. Balanceamento Visual das Fases', Icons.bar_chart),
          _balanceamentoVisual(resultado),
          const SizedBox(height: 16),

          // ── Módulo 5: Utilização do Disjuntor Geral ─────────────
          _secao('4. Utilização do Disjuntor Geral', Icons.electric_bolt),
          _utilizacaoDisjuntor(resultado),
          const SizedBox(height: 16),

          // ── Módulo 6: Distribuição por Categoria ────────────────
          _secao('5. Distribuição de Cargas por Categoria', Icons.pie_chart),
          _distribuicaoCategorias(resultado),
          const SizedBox(height: 16),

          // ── Módulo 7: Capacidade de Interrupção ─────────────────
          _secao('6. Capacidade de Interrupção (Icc)', Icons.flash_off),
          _capacidadeInterrupcao(resultado),
          const SizedBox(height: 16),

          // ── Módulo 8: Seletividade ──────────────────────────────
          _secao('7. Análise de Seletividade', Icons.account_tree),
          _seletividade(resultado),
          const SizedBox(height: 16),

          // ── Módulo 9: Estimativa de Consumo ─────────────────────
          _secao('8. Estimativa de Consumo de Energia', Icons.electric_meter),
          _consumoEnergia(resultado),
          const SizedBox(height: 16),

          // ── Módulo 11: Diagnóstico Automático ───────────────────
          _secao('9. Diagnóstico Técnico Automático', Icons.plagiarism_outlined),
          _diagnostico(resultado),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 12 — Painel Executivo
  // ─────────────────────────────────────────────────────────────────────────
  Widget _painelExecutivo(ResultadoProjeto r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _secao('Painel Executivo', Icons.dashboard_rounded),
        LayoutBuilder(builder: (ctx, constraints) {
          final w = (constraints.maxWidth - 10) / 2;
          Widget card(String label, String value, IconData icon, Color color) =>
              _execCard(label, value, icon, color, w);
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              card('P. Instalada',   '${r.totalPotenciaAtiva.toStringAsFixed(1)} kW',    Icons.bolt,                  _cor(r.totalPotenciaAtiva > 0 ? 'ok' : 'warn')),
              card('P. Demandada',   '${r.totalPotenciaDemandada.toStringAsFixed(1)} kW', Icons.power,                 AppColors.primary),
              card('I. Projeto',     '${r.correnteProjeto.toStringAsFixed(1)} A',         Icons.electric_bolt,         _cor(r.utilizacaoDisjuntor > 95 ? 'error' : r.utilizacaoDisjuntor > 85 ? 'warn' : 'ok')),
              card('Disjuntor',      '${r.disjuntorPolos}P×${r.disjuntorGeral}A',         Icons.security,              _cor(r.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error' : r.classificacaoDisjuntor == ClassificacaoDisjuntor.alta ? 'warn' : 'ok')),
              card('Circuitos',      '${r.numCircuitos}',                                  Icons.cable,                 AppColors.secondary),
              card('FP Médio',       r.fatorPotenciaMedio.toStringAsFixed(3),             Icons.tune,                  _cor(r.fatorPotenciaMedio >= 0.92 ? 'ok' : r.fatorPotenciaMedio >= 0.85 ? 'warn' : 'error')),
              card('Desbalanc.',     '${r.desbalanceamentoPercent.toStringAsFixed(1)}%',  Icons.balance,               _cor(r.desbalanceamentoPercent <= 5 ? 'ok' : r.desbalanceamentoPercent <= 10 ? 'warn' : 'error')),
              card('Res. Quadro',    '${r.percentReservaQuadro.toStringAsFixed(0)}%',     Icons.grid_view,             _cor(r.percentReservaQuadro >= 20 ? 'ok' : r.percentReservaQuadro >= 10 ? 'warn' : 'error')),
              card('Res. Carga',     '${r.percentReservaCarga.toStringAsFixed(0)}%',      Icons.battery_charging_full, _cor(r.percentReservaCarga >= 20 ? 'ok' : r.percentReservaCarga >= 15 ? 'warn' : 'error')),
              card('ΔV Máx.',        '${r.quedaTensaoMax.toStringAsFixed(1)}%',           Icons.compress,              _cor(r.quedaTensaoMax <= 4 ? 'ok' : r.quedaTensaoMax <= 7 ? 'warn' : 'error')),
              card('Capacitores',    r.necessitaCorrecaoFP ? '${r.capacitorKvar.toStringAsFixed(1)} kVAr' : 'OK', Icons.battery_full, r.necessitaCorrecaoFP ? AppColors.warning : AppColors.success),
              card('Índice',         '${r.indiceGeral.toStringAsFixed(0)}/100',           Icons.star_rounded,          _cor(r.indiceGeral >= 75 ? 'ok' : r.indiceGeral >= 45 ? 'warn' : 'error')),
            ],
          );
        }),
      ],
    );
  }

  Widget _execCard(String label, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0,2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 10 — Índice Geral
  // ─────────────────────────────────────────────────────────────────────────
  Widget _indiceGeral(ResultadoProjeto r) {
    final cor = _cor(r.indiceGeral >= 75 ? 'ok' : r.indiceGeral >= 45 ? 'warn' : 'error');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(cor),
      child: Row(
        children: [
          // Gauge circular simples
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: r.indiceGeral / 100,
                  strokeWidth: 8,
                  backgroundColor: cor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(cor),
                ),
                Text(
                  r.indiceGeral.toStringAsFixed(0),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ÍNDICE GERAL DO PROJETO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(r.classificacaoIndice.label,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cor)),
                const SizedBox(height: 4),
                Text(
                  'Pontuação: ${r.indiceGeral.toStringAsFixed(0)}/100  ·  '
                  '${r.diagnosticoConformes.length} conformidades  ·  '
                  '${r.diagnosticoProblemas.length} pendências',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 1 — Taxa de Ocupação
  // ─────────────────────────────────────────────────────────────────────────
  Widget _taxaOcupacao(ResultadoProjeto r) {
    final cor = _cor(r.percentOcupacao > 90 ? 'error' : r.percentOcupacao > 80 ? 'warn' : 'ok');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quadroInfo('Disponíveis', '${r.modulosDisponiveis}', AppColors.textSecondary, Icons.grid_view),
              _quadroInfo('Utilizados',  '${r.modulosUtilizados}',  AppColors.primary,       Icons.check_box),
              _quadroInfo('Livres',      '${r.modulosLivres}',      AppColors.success,       Icons.check_box_outline_blank),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de ocupação
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ocupação', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
                  Text('${r.percentOcupacao.toStringAsFixed(0)}%  (Reserva: ${r.percentReservaQuadro.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
                ],
              ),
              const SizedBox(height: 6),
              _barra(r.percentOcupacao / 100, cor),
            ],
          ),
          if (r.percentOcupacao > 80) ...[
            const SizedBox(height: 10),
            _alerta(
              r.percentOcupacao > 90
                  ? 'Recomenda-se utilizar um quadro com maior capacidade.'
                  : 'Atenção: o quadro possui pouca reserva para futuras ampliações.',
              r.percentOcupacao > 90 ? AppColors.error : AppColors.warning,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 2 — Reserva de Carga
  // ─────────────────────────────────────────────────────────────────────────
  Widget _reservaCarga(ResultadoProjeto r) {
    final cor = _cor(r.percentReservaCarga < 15 ? 'error' : r.percentReservaCarga < 25 ? 'warn' : 'ok');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quadroInfo('Capacidade\n(I máx)', '${r.correnteMaximaQuadro.toStringAsFixed(0)} A', AppColors.textSecondary, Icons.power),
              _quadroInfo('Corrente\nUtilizada', '${r.correnteProjeto.toStringAsFixed(1)} A', AppColors.primary, Icons.electric_bolt),
              _quadroInfo('Reserva\nDisponível', '${r.correnteRestante.toStringAsFixed(1)} A', AppColors.success, Icons.add_circle_outline),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Utilização', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
                  Text('${(100 - r.percentReservaCarga).toStringAsFixed(0)}%  (Reserva: ${r.percentReservaCarga.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
                ],
              ),
              const SizedBox(height: 6),
              _barra((100 - r.percentReservaCarga) / 100, cor),
            ],
          ),
          if (r.percentReservaCarga < 15) ...[
            const SizedBox(height: 10),
            _alerta('Reserva de carga inferior a 15% – limitar novas instalações.', AppColors.error),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulos 3+4 — Balanceamento Visual
  // ─────────────────────────────────────────────────────────────────────────
  Widget _balanceamentoVisual(ResultadoProjeto r) {
    final maxI = [r.correnteFaseA, r.correnteFaseB, r.correnteFaseC].reduce(max);
    final cor = _classBal(r.desbalanceamentoPercent);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        children: [
          // Barras horizontais por fase
          _faseBarra('Fase A', r.correnteFaseA, maxI, AppColors.phaseA),
          const SizedBox(height: 8),
          _faseBarra('Fase B', r.correnteFaseB, maxI, AppColors.phaseB),
          const SizedBox(height: 8),
          _faseBarra('Fase C', r.correnteFaseC, maxI, AppColors.phaseC),
          const SizedBox(height: 14),
          // Métricas
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _metricaRow('Corrente Média', '${r.correnteMedia.toStringAsFixed(2)} A'),
                _metricaRow('Diferença Máxima', '${r.diferencaMaxima.toStringAsFixed(2)} A'),
                _metricaRow('Desbalanceamento', '${r.desbalanceamentoPercent.toStringAsFixed(1)}%'),
                _metricaRow('Classificação', r.classificacaoBalanceamento.label,
                  valueColor: cor),
              ],
            ),
          ),
          if (r.alertaMotores) ...[
            const SizedBox(height: 10),
            _alerta('Motores trifásicos detectados: desbalanceamento >2% pode causar aquecimento e redução da vida útil.', AppColors.warning),
          ],
        ],
      ),
    );
  }

  Widget _faseBarra(String label, double corrente, double maxI, Color cor) {
    final frac = maxI > 0 ? (corrente / maxI).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(width: 52, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: cor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(cor),
              minHeight: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text('${corrente.toStringAsFixed(1)} A',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor),
            textAlign: TextAlign.right),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 5 — Utilização do Disjuntor Geral
  // ─────────────────────────────────────────────────────────────────────────
  Widget _utilizacaoDisjuntor(ResultadoProjeto r) {
    final cor = _cor(r.classificacaoDisjuntor == ClassificacaoDisjuntor.critica ? 'error'
        : r.classificacaoDisjuntor == ClassificacaoDisjuntor.alta ? 'warn' : 'ok');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quadroInfo('Disjuntor\nGeral', '${r.disjuntorGeral} A', AppColors.textSecondary, Icons.security),
              _quadroInfo('Corrente\nde Projeto', '${r.correnteProjeto.toStringAsFixed(1)} A', AppColors.primary, Icons.electric_bolt),
              _quadroInfo('Utilização', '${r.utilizacaoDisjuntor.toStringAsFixed(0)}%', cor, Icons.speed),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Carga do Disjuntor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor)),
                  Text(r.classificacaoDisjuntor.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cor)),
                ],
              ),
              const SizedBox(height: 6),
              _barra(r.utilizacaoDisjuntor / 100, cor),
            ],
          ),
          const SizedBox(height: 10),
          // Legenda das classificações
          Wrap(
            spacing: 8, runSpacing: 4,
            children: [
              _chip('≤70%  Excelente', AppColors.success),
              _chip('70–85%  Boa',     const Color(0xFF1976D2)),
              _chip('85–95%  Alta',    AppColors.warning),
              _chip('>95%  Crítica',   AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 6 — Distribuição por Categoria
  // ─────────────────────────────────────────────────────────────────────────
  Widget _distribuicaoCategorias(ResultadoProjeto r) {
    if (r.distribuicaoCategorias.isEmpty) {
      return _semDados('Nenhuma carga ativa cadastrada');
    }
    final total = r.distribuicaoCategorias
        .fold(0.0, (s, c) => s + c.potenciaDemandada);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(AppColors.primary),
      child: Column(
        children: [
          ...r.distribuicaoCategorias.map((cat) {
            final frac = total > 0 ? cat.potenciaDemandada / total : 0.0;
            final cor = _randomCatColor(cat.nome);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${cat.icone} ', style: const TextStyle(fontSize: 16)),
                      Expanded(child: Text(cat.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      Text('${cat.percentualTotal.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _barra(frac, cor, height: 10),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Instalada: ${(cat.potenciaInstalada / 1000).toStringAsFixed(2)} kW',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text('Demandada: ${(cat.potenciaDemandada / 1000).toStringAsFixed(2)} kW',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _randomCatColor(String nome) {
    final colors = [
      AppColors.primary, const Color(0xFF7B1FA2), const Color(0xFF0288D1),
      const Color(0xFF558B2F), const Color(0xFFE65100), const Color(0xFFC62828),
      AppColors.secondary,
    ];
    return colors[nome.hashCode.abs() % colors.length];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 7 — Capacidade de Interrupção
  // ─────────────────────────────────────────────────────────────────────────
  Widget _capacidadeInterrupcao(ResultadoProjeto r) {
    final ok = r.disjuntorAdequadoIcc;
    final cor = ok ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quadroInfo('Icc Estimada', '${(r.correnteCurtoEstimada * 1000).toStringAsFixed(1)} A', AppColors.error, Icons.bolt),
              _quadroInfo('Cap. Interrupção', '${r.capacidadeInterrupcao.toStringAsFixed(0)} kA', AppColors.success, Icons.security),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded, color: cor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ok
                        ? 'Adequado — capacidade de interrupção (${r.capacidadeInterrupcao.toStringAsFixed(0)} kA) compatível com a corrente de curto estimada.'
                        : 'Atenção — capacidade de interrupção pode ser insuficiente. Verificar com o fornecedor de energia.',
                    style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 8 — Seletividade
  // ─────────────────────────────────────────────────────────────────────────
  Widget _seletividade(ResultadoProjeto r) {
    final ok = r.seletividadeOk;
    final cor = ok ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(cor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.warning_amber_rounded, color: cor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok
                      ? 'Coordenação adequada — todos os disjuntores de circuito são menores que o disjuntor geral (${r.disjuntorGeral} A).'
                      : 'Possível problema de seletividade — verifique os circuitos abaixo:',
                  style: TextStyle(fontSize: 12, color: cor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: 10),
            ...r.problemasSelectividade.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right, size: 16, color: AppColors.error),
                  Expanded(child: Text(p, style: const TextStyle(fontSize: 11, color: AppColors.error))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 9 — Estimativa de Consumo
  // ─────────────────────────────────────────────────────────────────────────
  Widget _consumoEnergia(ResultadoProjeto r) {
    // Cálculo com horas padrão (8h/dia, 22 dias/mês)
    const horasDia = 8.0;
    const diasMes  = 22;
    final prov = context.read<AppProvider>();
    final cargas = prov.projetoAtual?.cargas.where((c) => c.ativo).toList() ?? [];

    final consumoDiario  = (r.totalPotenciaDemandada) * horasDia;        // kWh/dia
    final consumoMensal  = consumoDiario * diasMes;
    final consumoAnual   = consumoMensal * 12;
    final custoDiario    = consumoDiario * _tarifaKwh;
    final custoMensal    = consumoMensal * _tarifaKwh;
    final custoAnual     = consumoAnual  * _tarifaKwh;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarifa input
          Row(
            children: [
              const Icon(Icons.attach_money, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Tarifa de energia (R\$/kWh):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextFormField(
                  controller: _tarifaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onChanged: (v) {
                    setState(() => _tarifaKwh = double.tryParse(v) ?? 0.80);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Premissa: ${horasDia.toStringAsFixed(0)}h/dia × $diasMes dias/mês',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          // Tabela de consumo
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _consumoRow('Consumo Diário',  '${consumoDiario.toStringAsFixed(2)} kWh', _tarifaKwh > 0 ? 'R\$ ${custoDiario.toStringAsFixed(2)}' : null, false),
                const Divider(height: 1),
                _consumoRow('Consumo Mensal',  '${consumoMensal.toStringAsFixed(1)} kWh',  _tarifaKwh > 0 ? 'R\$ ${custoMensal.toStringAsFixed(2)}' : null, false),
                const Divider(height: 1),
                _consumoRow('Consumo Anual',   '${consumoAnual.toStringAsFixed(1)} kWh',   _tarifaKwh > 0 ? 'R\$ ${custoAnual.toStringAsFixed(2)}' : null, true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Top 5 cargas por consumo
          if (cargas.isNotEmpty) ...[
            const Text('Top consumidores (por demanda ativa):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ...(() {
              final sorted = List.of(cargas)
                ..sort((a, b) => b.potenciaAtiva.compareTo(a.potenciaAtiva));
              return sorted.take(5).map((c) {
                final pct = r.totalPotenciaDemandada > 0
                    ? (c.potenciaAtiva / (r.totalPotenciaDemandada * 1000)) * 100 : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(_iconeCategoria(c.tipo), style: const TextStyle(fontSize: 14)),
                      Expanded(child: Text(c.descricao, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                      Text('${(c.potenciaAtiva / 1000).toStringAsFixed(2)} kW  (${pct.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                );
              }).toList();
            })(),
          ],
        ],
      ),
    );
  }

  Widget _consumoRow(String label, String kwh, String? custo, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: highlight ? FontWeight.w700 : FontWeight.w400))),
          Text(kwh, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: highlight ? AppColors.primary : AppColors.textPrimary)),
          if (custo != null) ...[
            const SizedBox(width: 12),
            Text(custo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo 11 — Diagnóstico Automático
  // ─────────────────────────────────────────────────────────────────────────
  Widget _diagnostico(ResultadoProjeto r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(AppColors.secondary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.plagiarism_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DIAGNÓSTICO TÉCNICO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Gerado automaticamente pelo sistema', style: TextStyle(fontSize: 10, color: Colors.white60)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Conformidades
          if (r.diagnosticoConformes.isNotEmpty) ...[
            _diagSub('Conformidades', AppColors.success),
            ...r.diagnosticoConformes.map((c) => _diagItem(c, AppColors.success, Icons.check_circle_outline)),
            const SizedBox(height: 10),
          ],

          // Problemas
          if (r.diagnosticoProblemas.isNotEmpty) ...[
            _diagSub('Pendências / Problemas', AppColors.error),
            ...r.diagnosticoProblemas.map((p) => _diagItem(p, AppColors.error, Icons.cancel_outlined)),
            const SizedBox(height: 10),
          ],

          // Recomendações
          if (r.diagnosticoRecomendacoes.isNotEmpty) ...[
            _diagSub('Recomendações Técnicas', AppColors.warning),
            ...r.diagnosticoRecomendacoes.map((rec) => _diagItem(rec, AppColors.warning, Icons.lightbulb_outline)),
          ],
        ],
      ),
    );
  }

  Widget _diagSub(String label, Color cor) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(label.toUpperCase(),
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cor, letterSpacing: 0.8)),
  );

  Widget _diagItem(String texto, Color cor, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: cor),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), height: 1.4))),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers visuais
  // ─────────────────────────────────────────────────────────────────────────
  Widget _secao(String titulo, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    ),
  );

  Widget _barra(double value, Color cor, {double height = 14}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: cor.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(cor),
      ),
    );
  }

  Widget _alerta(String msg, Color cor) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: cor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: cor.withValues(alpha: 0.25))),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: cor, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w500))),
      ],
    ),
  );

  Widget _metricaRow(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary)),
      ],
    ),
  );

  Widget _quadroInfo(String label, String value, Color cor, IconData icon) => Column(
    children: [
      Icon(icon, size: 20, color: cor),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cor)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ],
  );

  Widget _chip(String label, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12), border: Border.all(color: cor.withValues(alpha: 0.3))),
    child: Text(label, style: TextStyle(fontSize: 10, color: cor, fontWeight: FontWeight.w600)),
  );

  BoxDecoration _card(Color cor) => BoxDecoration(
    color: cor == AppColors.secondary ? AppColors.secondary : Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: cor.withValues(alpha: cor == AppColors.secondary ? 0 : 0.15)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
  );

  Color _cor(String status) {
    switch (status) {
      case 'ok':    return AppColors.success;
      case 'warn':  return AppColors.warning;
      case 'error': return AppColors.error;
      default:      return AppColors.primary;
    }
  }

  Color _classBal(double desbal) {
    if (desbal <= 2)  return AppColors.success;
    if (desbal <= 5)  return const Color(0xFF1976D2);
    if (desbal <= 10) return AppColors.warning;
    return AppColors.error;
  }

  Widget _semDados(String msg) => Container(
    padding: const EdgeInsets.all(20),
    alignment: Alignment.center,
    child: Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
  );

  Widget _buildVazio() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.analytics_outlined, size: 48, color: AppColors.textSecondary),
        SizedBox(height: 12),
        Text('Cadastre cargas para ver a análise técnica', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    ),
  );

  /// Retorna o ícone emoji para cada tipo de carga (sem depender de getter .icone)
  String _iconeCategoria(TipoCarga tipo) {
    switch (tipo) {
      case TipoCarga.tug:          return '🔌';
      case TipoCarga.tue:          return '⚡';
      case TipoCarga.motor:        return '⚙️';
      case TipoCarga.arCondicionado: return '❄️';
      case TipoCarga.resistencia:  return '🌡️';
      case TipoCarga.iluminacao:   return '💡';
      case TipoCarga.generico:     return '📦';
    }
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/projeto.dart';
import '../models/carga.dart';
import '../models/resultado_projeto.dart';
import '../models/alimentador.dart';
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

  Widget _sliderReserva() {
    final prov = context.read<AppProvider>();
    final reserva = context.select<AppProvider, double>((p) => p.reservaPercent);
    final corSlider = reserva == 0
        ? AppColors.textSecondary
        : reserva <= 15
            ? AppColors.success
            : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Margem de Reserva para Disjuntor Geral',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: corSlider.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reserva == 0 ? 'Sem margem' : '+${reserva.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: corSlider),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Aumenta a corrente de projeto antes de selecionar o disjuntor geral, garantindo folga para ampliações futuras.',
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          Slider(
            value: reserva,
            min: 0,
            max: 50,
            divisions: 10,
            activeColor: corSlider,
            label: reserva == 0 ? 'Sem margem' : '+${reserva.toStringAsFixed(0)}%',
            onChanged: (v) => prov.setReservaPercent(v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0% (padrão NR-10)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const Text('50%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
          if (reserva > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Com +${reserva.toStringAsFixed(0)}% de margem, o disjuntor geral selecionado será maior, garantindo folga real na instalação.',
                      style: const TextStyle(fontSize: 10, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    // ── QGBT: exibe análise consolidada dos alimentadores ────────────────────
    if (prov.projetoAtual?.tipoQuadro == TipoQuadro.qgbt) {
      return _buildQGBTAnalise(context, prov);
    }

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
          _sliderReserva(),
          const SizedBox(height: 10),
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
            final fdAplicado = cat.fatorDemandaAplicado; // já em % (0-100)
            final fdColor = fdAplicado >= 100
                ? AppColors.textSecondary
                : fdAplicado >= 75
                    ? AppColors.warning
                    : AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${cat.icone} ', style: const TextStyle(fontSize: 16)),
                      Expanded(child: Text(cat.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                      // Badge do FD aplicado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: fdColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: fdColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'FD ${fdAplicado.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fdColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('${cat.percentualTotal.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _barra(frac, cor, height: 10),
                  const SizedBox(height: 3),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Módulo FD — Painel de Fatores de Demanda por Grupo (editável)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _painelFatoresDemanda(AppProvider prov, ResultadoProjeto r) {
    final fd = prov.projetoAtual?.fatoresDemanda ?? FatoresDemandaGrupo();

    // Identificar quais grupos têm cargas instaladas
    final Map<TipoCarga, double> instaladaPorGrupo = {};
    for (final cat in r.distribuicaoCategorias) {
      // Mapear nome da categoria de volta para TipoCarga
      for (final tipo in TipoCarga.values) {
        if (_nomeTipoCarga(tipo) == cat.nome) {
          instaladaPorGrupo[tipo] = cat.potenciaInstalada;
        }
      }
    }

    // Verificar alerta de motores reserva
    final numReserva = prov.projetoAtual?.cargas
        .where((c) => c.tipo == TipoCarga.motor && c.motorReserva)
        .length ?? 0;

    if (instaladaPorGrupo.isEmpty) {
      return _semDados('Nenhuma carga cadastrada para configurar FD');
    }

    // Calcular sugestão automática usando FdAutoEngine
    final sugestao = FdAutoEngine.calcularSugestoes(
      prov.projetoAtual?.cargas ?? [],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com botão "Aplicar Sugestão"
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'FD calculado automaticamente por grupo (NBR 5410). '
                          'Aceite o valor sugerido ou ajuste manualmente.',
                          style: TextStyle(fontSize: 10, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botão "Aplicar Todos"
              GestureDetector(
                onTap: () => prov.atualizarFatoresDemanda(sugestao),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high, size: 14, color: Colors.white),
                      SizedBox(height: 2),
                      Text('Auto NBR', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alerta motores reserva
          if (numReserva > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline, size: 14, color: Color(0xFFE65100)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$numReserva motor(es) em reserva (stand-by) excluído(s) do cálculo de demanda',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFE65100), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Linha de grupos
          ...instaladaPorGrupo.entries.map((entry) {
            final tipo = entry.key;
            final potInstalada = entry.value;
            final fdAtual = fd.fatorParaTipo(tipo);
            final fdSugerido = sugestao.fatorParaTipo(tipo);
            final potDemandada = potInstalada * fdAtual / 100.0;

            // Contar para critério
            final qtdGrupo = (prov.projetoAtual?.cargas ?? [])
                .where((c) => c.tipo == tipo && !(c.tipo == TipoCarga.motor && c.motorReserva))
                .fold(0, (s, c) => s + c.quantidade);

            return _grupoFDRow(
              prov: prov,
              fd: fd,
              tipo: tipo,
              potInstalada: potInstalada,
              potDemandada: potDemandada,
              fdAtual: fdAtual,
              fdSugerido: fdSugerido,
              qtdGrupo: qtdGrupo,
            );
          }),
        ],
      ),
    );
  }

  /// Row de edição de FD para um grupo individual
  Widget _grupoFDRow({
    required AppProvider prov,
    required FatoresDemandaGrupo fd,
    required TipoCarga tipo,
    required double potInstalada,
    required double potDemandada,
    required double fdAtual,
    required double fdSugerido,
    required int qtdGrupo,
  }) {
    final icone = _iconeCategoria(tipo);
    final nome  = _nomeTipoCarga(tipo);

    return StatefulBuilder(
      builder: (ctx, setLocal) {
        final fdNow = fd.fatorParaTipo(tipo);
        final potD  = potInstalada * fdNow / 100.0;
        final isSugestaoAtiva = fdNow.round() == fdSugerido.round();
        final cor = fdNow >= 100
            ? AppColors.textSecondary
            : fdNow >= 75
                ? AppColors.warning
                : AppColors.primary;

        // Critério descritivo
        final criterio = FdAutoEngine.descricaoCriterio(tipo, qtdGrupo, potInstalada);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSugestaoAtiva
                  ? AppColors.success.withValues(alpha: 0.4)
                  : AppColors.divider,
              width: isSugestaoAtiva ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título do grupo + FD atual + botão "Usar NBR"
              Row(
                children: [
                  Text('$icone ', style: const TextStyle(fontSize: 18)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nome,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(criterio,
                          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  // Badge FD sugerido (se diferente do atual)
                  if (!isSugestaoAtiva) ...[
                    GestureDetector(
                      onTap: () {
                        final novoFd = _atualizarFD(fd, tipo, fdSugerido);
                        prov.atualizarFatoresDemanda(novoFd);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'NBR ${fdSugerido.toStringAsFixed(0)}% ↑',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Badge FD atual
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSugestaoAtiva
                          ? AppColors.success.withValues(alpha: 0.12)
                          : cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${fdNow.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSugestaoAtiva ? AppColors.success : cor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Linha instalada → demandada
              Text(
                'Instalada: ${(potInstalada/1000).toStringAsFixed(2)} kW  →  Demandada: ${(potD/1000).toStringAsFixed(2)} kW',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              // Slider
              Row(
                children: [
                  const Text('0', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: fdNow.clamp(0.0, 100.0),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: isSugestaoAtiva ? AppColors.success : (cor == AppColors.textSecondary ? AppColors.primary : cor),
                      label: '${fdNow.toStringAsFixed(0)}%',
                      onChanged: (v) {
                        final novoFd = _atualizarFD(fd, tipo, v);
                        prov.atualizarFatoresDemanda(novoFd);
                      },
                    ),
                  ),
                  const Text('100%', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),

              // Botões rápidos de FD (incluindo o sugerido em destaque)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [25, 50, 60, 70, 75, 80, 100].map((v) {
                  final isSelected = fdNow.round() == v;
                  final isSug = fdSugerido.round() == v;
                  return GestureDetector(
                    onTap: () {
                      final novoFd = _atualizarFD(fd, tipo, v.toDouble());
                      prov.atualizarFatoresDemanda(novoFd);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isSug ? AppColors.success : AppColors.primary)
                            : (isSug ? AppColors.success.withValues(alpha: 0.10) : AppColors.primary.withValues(alpha: 0.07)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isSug ? AppColors.success : AppColors.primary)
                              : (isSug ? AppColors.success.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.2)),
                          width: isSug ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        isSug ? '$v%✓' : '$v%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : (isSug ? AppColors.success : AppColors.primary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cria um FatoresDemandaGrupo com o valor atualizado para o tipo informado
  FatoresDemandaGrupo _atualizarFD(FatoresDemandaGrupo fd, TipoCarga tipo, double valor) {
    switch (tipo) {
      case TipoCarga.iluminacao:     return fd.copyWith(iluminacao: valor);
      case TipoCarga.tug:            return fd.copyWith(tug: valor);
      case TipoCarga.tue:            return fd.copyWith(tue: valor);
      case TipoCarga.motor:          return fd.copyWith(motor: valor);
      case TipoCarga.arCondicionado: return fd.copyWith(arCondicionado: valor);
      case TipoCarga.resistencia:    return fd.copyWith(resistencia: valor);
      case TipoCarga.generico:       return fd.copyWith(generico: valor);
    }
  }

  /// Nome legível do TipoCarga para matching com DistribuicaoCategoria
  String _nomeTipoCarga(TipoCarga tipo) {
    switch (tipo) {
      case TipoCarga.iluminacao:     return 'Iluminação';
      case TipoCarga.tug:            return 'TUG';
      case TipoCarga.tue:            return 'TUE';
      case TipoCarga.motor:          return 'Motor';
      case TipoCarga.arCondicionado: return 'Ar-Cond.';
      case TipoCarga.resistencia:    return 'Resistência';
      case TipoCarga.generico:       return 'Genérico';
    }
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

  // ─────────────────────────────────────────────────────────────────────────
  // Análise QGBT — consolidação hierárquica dos alimentadores
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildQGBTAnalise(BuildContext context, AppProvider prov) {
    final resQGBT  = prov.resultadoQGBT;
    final alims    = prov.projetoAtual?.alimentadores ?? [];
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;

    if (alims.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1B3D).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_tree_outlined, size: 40, color: Color(0xFF0B1B3D)),
            ),
            const SizedBox(height: 16),
            const Text('Nenhum alimentador cadastrado',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              'Acesse a aba "Alimentadores" e cadastre\nos quadros alimentados pelo QGBT.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (resQGBT == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              '${alims.length} alimentador(es) cadastrado(s)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione circuitos nos quadros de destino\npara calcular automaticamente o QGBT.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, bottomPad + 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho QGBT ─────────────────────────────────────────────
          _qgbtCabecalho(resQGBT),
          const SizedBox(height: 16),

          // ── Painel Executivo QGBT ───────────────────────────────────────
          _secao('Painel Executivo QGBT', Icons.dashboard_rounded),
          _qgbtPainelExecutivo(resQGBT),
          const SizedBox(height: 20),

          // ── Margem de Reserva ────────────────────────────────────────────
          _secao('Margem de Reserva do Disjuntor Geral', Icons.tune),
          _sliderReserva(),
          const SizedBox(height: 20),

          // ── Tabela de alimentadores ─────────────────────────────────────
          _secao('Alimentadores e Quadros Alimentados', Icons.account_tree),
          _qgbtTabelaAlimentadores(resQGBT),
          const SizedBox(height: 20),

          // ── Distribuição por alimentador ────────────────────────────────
          _secao('Distribuição de Carga por Alimentador', Icons.bar_chart),
          _qgbtDistribuicao(resQGBT),
          const SizedBox(height: 20),

          // ── Diagnóstico automático QGBT ─────────────────────────────────
          _secao('Diagnóstico Técnico QGBT', Icons.plagiarism_outlined),
          _qgbtDiagnostico(resQGBT),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _qgbtCabecalho(ResultadoQGBT r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1B3D), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0B1B3D).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.5)),
              ),
              child: const Row(children: [
                Icon(Icons.electric_bolt, color: Color(0xFFFF7A00), size: 12),
                SizedBox(width: 4),
                Text('QGBT', style: TextStyle(color: Color(0xFFFF7A00), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
            const SizedBox(width: 8),
            const Text('Análise Técnica Consolidada',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
              ),
              child: Text(
                '${r.numAlimentadoresDimensionados}/${r.numAlimentadores} dim.',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _qgbtMetric('P. Total', '${r.totalPotenciaAparenteKva.toStringAsFixed(1)} kVA', Icons.flash_on),
            const SizedBox(width: 8),
            _qgbtMetric('I. Total', '${r.totalCorrenteProjeto.toStringAsFixed(1)} A', Icons.electric_bolt),
            const SizedBox(width: 8),
            _qgbtMetric('Disj. Geral', '${r.disjuntorGeral} A', Icons.security, highlight: true),
            const SizedBox(width: 8),
            _qgbtMetric('Cabo Entr.', '${r.condutorEntrada.toStringAsFixed(1)} mm²', Icons.cable),
          ]),
        ],
      ),
    );
  }

  Widget _qgbtMetric(String label, String value, IconData icon, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFFF7A00).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: highlight ? Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: highlight ? const Color(0xFFFF7A00) : Colors.white54),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800,
                  color: highlight ? const Color(0xFFFF7A00) : Colors.white,
                ),
                overflow: TextOverflow.ellipsis),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _qgbtPainelExecutivo(ResultadoQGBT r) {
    final pAtiva = r.totalPotenciaAtivaKw;
    final pAparen = r.totalPotenciaAparenteKva;
    final fp = pAparen > 0 ? pAtiva / pAparen : 0.0;
    final fpCor = fp >= 0.92 ? AppColors.success : fp >= 0.85 ? AppColors.warning : AppColors.error;

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = (constraints.maxWidth - 10) / 2;
      Widget card(String label, String value, IconData icon, Color color) =>
          _execCard(label, value, icon, color, w);
      return Wrap(
        spacing: 10, runSpacing: 10,
        children: [
          card('P. Ativa Total',     '${pAtiva.toStringAsFixed(1)} kW',          Icons.bolt,                  AppColors.primary),
          card('P. Aparente Total',  '${pAparen.toStringAsFixed(1)} kVA',         Icons.flash_on,              AppColors.secondary),
          card('Corrente Total',     '${r.totalCorrenteProjeto.toStringAsFixed(1)} A', Icons.electric_bolt,    _cor(r.totalCorrenteProjeto > 0 ? 'ok' : 'warn')),
          card('Disjuntor Geral',    '${r.disjuntorGeral} A',                     Icons.security,              AppColors.primary),
          card('Cabo de Entrada',    '${r.condutorEntrada.toStringAsFixed(1)} mm²', Icons.cable,               AppColors.secondary),
          card('Fator de Potência',  fp.toStringAsFixed(3),                        Icons.tune,                  fpCor),
          card('Alimentadores',      '${r.numAlimentadores}',                      Icons.account_tree,          AppColors.secondary),
          card('Dimensionados',      '${r.numAlimentadoresDimensionados}/${r.numAlimentadores}', Icons.check_circle_outline, _cor(r.numAlimentadoresDimensionados == r.numAlimentadores ? 'ok' : 'warn')),
        ],
      );
    });
  }

  Widget _qgbtTabelaAlimentadores(ResultadoQGBT r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          // Cabeçalho da tabela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1B3D).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const SizedBox(width: 28),
              Expanded(flex: 3, child: _thCell('Alimentador / Destino')),
              Expanded(flex: 2, child: _thCell('P. Ap. (kVA)')),
              Expanded(flex: 2, child: _thCell('I (A)')),
              Expanded(flex: 2, child: _thCell('Disj. (A)')),
              Expanded(flex: 2, child: _thCell('Cabo (mm²)')),
            ]),
          ),
          // Linhas
          ...r.alimentadores.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            final isLast = i == r.alimentadores.length - 1;
            final temDados = a.corrente > 0;
            return Container(
              decoration: BoxDecoration(
                color: temDados ? Colors.white : Colors.orange.withValues(alpha: 0.04),
                borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(12)) : null,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                // Status dot
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: temDados ? AppColors.success : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                // Alimentador info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (a.destino.isNotEmpty)
                        Text(a.destino,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(a.tipoDestino.sigla,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: _tdCell(temDados ? a.potenciaAparenteKva.toStringAsFixed(1) : '—')),
                Expanded(flex: 2, child: _tdCell(temDados ? a.corrente.toStringAsFixed(1) : '—')),
                Expanded(flex: 2, child: _tdCell(temDados ? '${a.disjuntor}' : '—', bold: true, color: temDados ? AppColors.primary : null)),
                Expanded(flex: 2, child: _tdCell(temDados ? a.condutor.toStringAsFixed(1) : '—')),
              ]),
            );
          }),
          // Linha total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1B3D).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
            ),
            child: Row(children: [
              const SizedBox(width: 28),
              const Expanded(flex: 3, child: Text('TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
              Expanded(flex: 2, child: _tdCell(r.totalPotenciaAparenteKva.toStringAsFixed(1), bold: true, color: AppColors.primary)),
              Expanded(flex: 2, child: _tdCell(r.totalCorrenteProjeto.toStringAsFixed(1), bold: true, color: AppColors.primary)),
              Expanded(flex: 2, child: _tdCell('${r.disjuntorGeral}', bold: true, color: const Color(0xFFFF7A00))),
              Expanded(flex: 2, child: _tdCell(r.condutorEntrada.toStringAsFixed(1), bold: true, color: AppColors.primary)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _thCell(String t) => Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary));
  Widget _tdCell(String t, {bool bold = false, Color? color}) => Text(t,
      style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? AppColors.textPrimary));

  Widget _qgbtDistribuicao(ResultadoQGBT r) {
    final totalPot = r.totalPotenciaAparenteKva;
    if (totalPot == 0) {
      return _semDados('Nenhum alimentador dimensionado ainda');
    }
    final colors = [
      const Color(0xFF1565C0), const Color(0xFF6A1B9A), const Color(0xFF00695C),
      const Color(0xFFBF360C), const Color(0xFFE65100), const Color(0xFF0277BD),
      const Color(0xFF558B2F), const Color(0xFF37474F),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(
        children: r.alimentadores.asMap().entries
            .where((e) => e.value.corrente > 0)
            .map((entry) {
          final a = entry.value;
          final cor = colors[entry.key % colors.length];
          final frac = totalPot > 0 ? (a.potenciaAparenteKva / totalPot).clamp(0.0, 1.0) : 0.0;
          final pct = (frac * 100);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(a.tipoDestino.sigla, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cor)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${a.nome}${a.destino.isNotEmpty ? ' – ${a.destino}' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${pct.toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cor)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 10,
                    backgroundColor: cor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(cor),
                  ),
                ),
                const SizedBox(height: 2),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${a.potenciaAparenteKva.toStringAsFixed(1)} kVA  ·  ${a.corrente.toStringAsFixed(1)} A',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('Disj: ${a.disjuntor} A  ·  Cabo: ${a.condutor.toStringAsFixed(1)} mm²',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _qgbtDiagnostico(ResultadoQGBT r) {
    final alimNaoDim = r.alimentadores.where((a) => a.corrente == 0).toList();
    final conformidades = <String>[];
    final problemas = <String>[];
    final recomendacoes = <String>[];

    if (r.numAlimentadoresDimensionados == r.numAlimentadores && r.numAlimentadores > 0) {
      conformidades.add('Todos os alimentadores estão dimensionados — QGBT calculado com dados completos.');
    }
    if (r.totalCorrenteProjeto > 0) {
      conformidades.add('Corrente total calculada: ${r.totalCorrenteProjeto.toStringAsFixed(1)} A.');
    }
    if (r.disjuntorGeral > 0) {
      conformidades.add('Disjuntor geral selecionado: ${r.disjuntorGeral} A (conforme NBR 5410).');
    }

    for (final a in alimNaoDim) {
      problemas.add('Alimentador "${a.nome}" não dimensionado — adicione circuitos ao ${a.tipoDestino.sigla}.');
    }
    if (r.totalPotenciaAparenteKva > 1000) {
      recomendacoes.add('Potência total superior a 1 MVA — verificar necessidade de banco de capacitores para correção do FP.');
    }
    if (r.numAlimentadores > 12) {
      recomendacoes.add('QGBT com muitos alimentadores — considere subdividi-lo em QGBTs secundários para facilitar a manutenção.');
    }
    recomendacoes.add('Verifique o dimensionamento dos barramentos com base na corrente total de ${r.totalCorrenteProjeto.toStringAsFixed(1)} A.');
    recomendacoes.add('Confirme que o cabo de entrada (${r.condutorEntrada.toStringAsFixed(1)} mm²) atende à seção mínima conforme NBR 5410 para a corrente de projeto.');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.plagiarism_outlined, color: Color(0xFFFF7A00), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DIAGNÓSTICO TÉCNICO QGBT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Gerado automaticamente pelo sistema', style: TextStyle(fontSize: 10, color: Colors.white60)),
              ],
            ),
          ]),
          const SizedBox(height: 14),
          if (conformidades.isNotEmpty) ...[
            _diagSub('Conformidades', AppColors.success),
            ...conformidades.map((c) => _diagItem(c, AppColors.success, Icons.check_circle_outline)),
            const SizedBox(height: 10),
          ],
          if (problemas.isNotEmpty) ...[
            _diagSub('Pendências', AppColors.error),
            ...problemas.map((p) => _diagItem(p, AppColors.error, Icons.cancel_outlined)),
            const SizedBox(height: 10),
          ],
          if (recomendacoes.isNotEmpty) ...[
            _diagSub('Recomendações Técnicas', AppColors.warning),
            ...recomendacoes.map((rec) => _diagItem(rec, AppColors.warning, Icons.lightbulb_outline)),
          ],
        ],
      ),
    );
  }

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

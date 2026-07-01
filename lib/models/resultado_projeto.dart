import 'dart:math';
import 'carga.dart';

class ResultadoPorFase {
  final double potenciaAtiva;
  final double potenciaReativa;
  final double potenciaAparente;
  final double corrente;

  ResultadoPorFase({
    required this.potenciaAtiva,
    required this.potenciaReativa,
    required this.potenciaAparente,
    required this.corrente,
  });
}

// ─────────────────────────────────────────────────────────────
// Distribuição de carga por categoria (módulo 6)
// ─────────────────────────────────────────────────────────────
class DistribuicaoCategoria {
  final String nome;
  final String icone;
  final double potenciaInstalada;  // W
  final double potenciaDemandada;  // W
  final double percentualTotal;

  DistribuicaoCategoria({
    required this.nome,
    required this.icone,
    required this.potenciaInstalada,
    required this.potenciaDemandada,
    required this.percentualTotal,
  });
}

// ─────────────────────────────────────────────────────────────
// Estimativa de consumo por carga (módulo 9)
// ─────────────────────────────────────────────────────────────
class EstimaConsumo {
  final String descricao;
  final double consumoDiarioKwh;
  final double consumoMensalKwh;
  final double consumoAnualKwh;
  final double custoDiario;
  final double custoMensal;
  final double custoAnual;

  EstimaConsumo({
    required this.descricao,
    required this.consumoDiarioKwh,
    required this.consumoMensalKwh,
    required this.consumoAnualKwh,
    this.custoDiario = 0,
    this.custoMensal = 0,
    this.custoAnual = 0,
  });
}

// ─────────────────────────────────────────────────────────────
// Classificações (enums semânticos)
// ─────────────────────────────────────────────────────────────
enum ClassificacaoBalanceamento { excelente, muitoBom, aceitavel, ruim }
enum ClassificacaoDisjuntor { excelente, boa, alta, critica }
enum ClassificacaoIndice { excelente, muitoBom, bom, regular, necessitaRevisao }

extension ClassBal on ClassificacaoBalanceamento {
  String get label {
    switch (this) {
      case ClassificacaoBalanceamento.excelente:  return 'Excelente';
      case ClassificacaoBalanceamento.muitoBom:   return 'Muito Bom';
      case ClassificacaoBalanceamento.aceitavel:  return 'Aceitável';
      case ClassificacaoBalanceamento.ruim:       return 'Ruim';
    }
  }
}

extension ClassDis on ClassificacaoDisjuntor {
  String get label {
    switch (this) {
      case ClassificacaoDisjuntor.excelente: return 'Excelente';
      case ClassificacaoDisjuntor.boa:       return 'Boa';
      case ClassificacaoDisjuntor.alta:      return 'Alta';
      case ClassificacaoDisjuntor.critica:   return 'Crítica';
    }
  }
}

extension ClassIdx on ClassificacaoIndice {
  String get label {
    switch (this) {
      case ClassificacaoIndice.excelente:       return 'Excelente';
      case ClassificacaoIndice.muitoBom:        return 'Muito Bom';
      case ClassificacaoIndice.bom:             return 'Bom';
      case ClassificacaoIndice.regular:         return 'Regular';
      case ClassificacaoIndice.necessitaRevisao: return 'Necessita Revisão';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Resultado principal — inclui todos os módulos de análise
// ─────────────────────────────────────────────────────────────
class ResultadoProjeto {
  // ── Totais ──────────────────────────────────────────────────
  final double totalPotenciaAtiva;      // kW
  final double totalPotenciaReativa;    // kVAr
  final double totalPotenciaAparente;   // kVA
  final double fatorPotenciaMedio;
  final double totalPotenciaDemandada;  // kW

  // ── Por fase ────────────────────────────────────────────────
  final ResultadoPorFase faseA;
  final ResultadoPorFase faseB;
  final ResultadoPorFase faseC;

  // ── Correntes ───────────────────────────────────────────────
  final double correnteFaseA;
  final double correnteFaseB;
  final double correnteFaseC;
  final double correnteNeutro;
  final double correnteTotal;
  final double correnteProjeto;

  // ── Desbalanceamento ────────────────────────────────────────
  final double desbalanceamentoPercent;
  final double correnteMedia;
  final double diferencaMaxima;
  final ClassificacaoBalanceamento classificacaoBalanceamento;
  final bool alertaMotores;

  // ── Disjuntor geral ─────────────────────────────────────────
  final int disjuntorGeral;
  final int disjuntorPolos;
  final double utilizacaoDisjuntor;       // %
  final ClassificacaoDisjuntor classificacaoDisjuntor;

  // ── Fator de potência ────────────────────────────────────────
  final bool necessitaCorrecaoFP;
  final double capacitorKvar;

  // ── Módulo 1: Taxa de ocupação do quadro ────────────────────
  final int modulosDisponiveis;
  final int modulosUtilizados;
  final int modulosLivres;
  final double percentOcupacao;
  final double percentReservaQuadro;

  // ── Módulo 2: Reserva de carga ──────────────────────────────
  final double correnteMaximaQuadro;    // = disjuntorGeral (A)
  final double correnteRestante;
  final double percentReservaCarga;

  // ── Módulo 7: Análise de curto-circuito ─────────────────────
  final double correnteCurtoEstimada;   // kA
  final double capacidadeInterrupcao;   // kA (padrão 10 kA)
  final bool disjuntorAdequadoIcc;

  // ── Módulo 8: Seletividade ───────────────────────────────────
  final bool seletividadeOk;
  final List<String> problemasSelectividade;

  // ── Módulo 6: Distribuição por categoria ────────────────────
  final List<DistribuicaoCategoria> distribuicaoCategorias;

  // ── Módulo 10: Índice geral ──────────────────────────────────
  final double indiceGeral;             // 0–100
  final ClassificacaoIndice classificacaoIndice;

  // ── Módulo 11: Diagnóstico ───────────────────────────────────
  final List<String> diagnosticoConformes;
  final List<String> diagnosticoProblemas;
  final List<String> diagnosticoRecomendacoes;

  // ── Alertas gerais ───────────────────────────────────────────
  final List<String> alertas;

  // ── Número de circuitos ──────────────────────────────────────
  final int numCircuitos;

  // ── Queda de tensão máxima ───────────────────────────────────
  final double quedaTensaoMax;

  ResultadoProjeto({
    required this.totalPotenciaAtiva,
    required this.totalPotenciaReativa,
    required this.totalPotenciaAparente,
    required this.fatorPotenciaMedio,
    required this.totalPotenciaDemandada,
    required this.faseA,
    required this.faseB,
    required this.faseC,
    required this.correnteFaseA,
    required this.correnteFaseB,
    required this.correnteFaseC,
    required this.correnteNeutro,
    required this.correnteTotal,
    required this.correnteProjeto,
    required this.desbalanceamentoPercent,
    required this.correnteMedia,
    required this.diferencaMaxima,
    required this.classificacaoBalanceamento,
    required this.alertaMotores,
    required this.disjuntorGeral,
    required this.disjuntorPolos,
    required this.utilizacaoDisjuntor,
    required this.classificacaoDisjuntor,
    required this.necessitaCorrecaoFP,
    required this.capacitorKvar,
    required this.modulosDisponiveis,
    required this.modulosUtilizados,
    required this.modulosLivres,
    required this.percentOcupacao,
    required this.percentReservaQuadro,
    required this.correnteMaximaQuadro,
    required this.correnteRestante,
    required this.percentReservaCarga,
    required this.correnteCurtoEstimada,
    required this.capacidadeInterrupcao,
    required this.disjuntorAdequadoIcc,
    required this.seletividadeOk,
    required this.problemasSelectividade,
    required this.distribuicaoCategorias,
    required this.indiceGeral,
    required this.classificacaoIndice,
    required this.diagnosticoConformes,
    required this.diagnosticoProblemas,
    required this.diagnosticoRecomendacoes,
    required this.alertas,
    required this.numCircuitos,
    required this.quedaTensaoMax,
  });

  // ─────────────────────────────────────────────────────────────
  // Helpers estáticos
  // ─────────────────────────────────────────────────────────────
  static int _disjuntorPadrao(double iProj) {
    final series = [10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800, 1000];
    for (final s in series) {
      if (s >= iProj) return s;
    }
    return 1000;
  }

  /// Estima módulos usados por circuito (disjuntores simples=1, 2P=2, 3P=3)
  static int _modulosPorCarga(Carga c) {
    switch (c.ligacao) {
      case LigacaoCarga.trifasico: return 3;
      case LigacaoCarga.bifasico:  return 2;
      case LigacaoCarga.monofasico: return 1;
    }
  }

  /// Estima capacidade de quadro em módulos (baseado no disjuntor geral)
  static int _modulosQuadro(int dijGeral) {
    if (dijGeral <= 40)  return 12;
    if (dijGeral <= 63)  return 18;
    if (dijGeral <= 100) return 24;
    if (dijGeral <= 160) return 36;
    if (dijGeral <= 250) return 48;
    return 64;
  }

  static ClassificacaoBalanceamento _classBal(double desbal) {
    if (desbal <= 2)  return ClassificacaoBalanceamento.excelente;
    if (desbal <= 5)  return ClassificacaoBalanceamento.muitoBom;
    if (desbal <= 10) return ClassificacaoBalanceamento.aceitavel;
    return ClassificacaoBalanceamento.ruim;
  }

  static ClassificacaoDisjuntor _classDij(double util) {
    if (util <= 70) return ClassificacaoDisjuntor.excelente;
    if (util <= 85) return ClassificacaoDisjuntor.boa;
    if (util <= 95) return ClassificacaoDisjuntor.alta;
    return ClassificacaoDisjuntor.critica;
  }

  static ClassificacaoIndice _classIdx(double idx) {
    if (idx >= 88) return ClassificacaoIndice.excelente;
    if (idx >= 75) return ClassificacaoIndice.muitoBom;
    if (idx >= 60) return ClassificacaoIndice.bom;
    if (idx >= 45) return ClassificacaoIndice.regular;
    return ClassificacaoIndice.necessitaRevisao;
  }

  // ─────────────────────────────────────────────────────────────
  // Factory principal
  // ─────────────────────────────────────────────────────────────
  static ResultadoProjeto calcular({
    required List<Carga> cargas,
    required int numFases,
    required double tensaoLinha,
    required double tensaoFase,
    double tarifaKwh = 0,
    double reservaPercent = 0,
  }) {
    double pAtivaA = 0, pReativaA = 0;
    double pAtivaB = 0, pReativaB = 0;
    double pAtivaC = 0, pReativaC = 0;
    double pAtivaTotal = 0, pReativaTotal = 0;
    double pDemandada = 0;
    double quedaMax = 0;
    final alertas = <String>[];

    // ── Acumuladores por categoria ──────────────────────────────
    final Map<TipoCarga, double> catInstalada = {};
    final Map<TipoCarga, double> catDemandada = {};

    // ── Verificação de seletividade ─────────────────────────────
    final problemasSelectividade = <String>[];

    // ── Contagem de módulos ─────────────────────────────────────
    int modulos = 0;

    // ── Detecção de motores trifásicos ──────────────────────────
    bool temMotorTrifasico = false;

    for (final c in cargas) {
      if (!c.ativo) continue;
      final pa = c.potenciaAtiva;
      final pr = c.potenciaReativa;
      pAtivaTotal  += pa;
      pReativaTotal += pr;
      pDemandada   += pa;
      modulos      += _modulosPorCarga(c);

      if (c.quedaTensaoPercent > quedaMax) quedaMax = c.quedaTensaoPercent;

      if (c.tipo == TipoCarga.motor && c.ligacao == LigacaoCarga.trifasico) {
        temMotorTrifasico = true;
      }

      // Distribui por fase usando getters temA/temB/temC
      final nf = c.fase.numFases.toDouble();
      if (c.fase.temA) { pAtivaA += pa / nf; pReativaA += pr / nf; }
      if (c.fase.temB) { pAtivaB += pa / nf; pReativaB += pr / nf; }
      if (c.fase.temC) { pAtivaC += pa / nf; pReativaC += pr / nf; }

      // Categorias
      catInstalada[c.tipo] = (catInstalada[c.tipo] ?? 0) + c.potenciaNominal * c.quantidade;
      catDemandada[c.tipo] = (catDemandada[c.tipo] ?? 0) + pa;

      for (final alerta in c.alertas) {
        alertas.add('${c.descricao}: $alerta');
      }
    }

    final pApATotal = sqrt(pAtivaTotal * pAtivaTotal + pReativaTotal * pReativaTotal);
    final fp = pApATotal > 0 ? pAtivaTotal / pApATotal : 1.0;

    double sA = sqrt(pAtivaA * pAtivaA + pReativaA * pReativaA);
    double sB = sqrt(pAtivaB * pAtivaB + pReativaB * pReativaB);
    double sC = sqrt(pAtivaC * pAtivaC + pReativaC * pReativaC);

    double iA = sA / (tensaoFase > 0 ? tensaoFase : 127);
    double iB = sB / (tensaoFase > 0 ? tensaoFase : 127);
    double iC = sC / (tensaoFase > 0 ? tensaoFase : 127);

    // ── Desbalanceamento ─────────────────────────────────────────
    double iMedia = (iA + iB + iC) / 3;
    final desvios = [iA, iB, iC].map((i) => (i - iMedia).abs()).toList();
    double difMax = desvios.reduce((a, b) => a > b ? a : b);
    double desbal = iMedia > 0 ? (difMax / iMedia) * 100 : 0;

    // ── Corrente total ───────────────────────────────────────────
    double iTotal;
    if (numFases == 2) {
      iTotal = pApATotal / (sqrt(3) * tensaoLinha);
    } else {
      iTotal = pApATotal / (tensaoFase > 0 ? tensaoFase : 127);
    }

    // ── Corrente de neutro ───────────────────────────────────────
    double iNeutro = sqrt(
      iA * iA + iB * iB + iC * iC - iA * iB - iB * iC - iA * iC,
    );

    double iProj = iTotal * 1.25;
    // Aplica margem de reserva adicional configurada pelo usuário
    final double iProjComReserva = reservaPercent > 0
        ? iProj * (1 + reservaPercent / 100)
        : iProj;
    int dijGeral = _disjuntorPadrao(iProjComReserva);
    int polos = numFases == 2 ? 3 : 1;

    // ── Módulo 5: Utilização do disjuntor ────────────────────────
    double utilDij = dijGeral > 0 ? (iProj / dijGeral) * 100 : 0;
    final classDij = _classDij(utilDij);

    // ── Módulo 1: Taxa de ocupação ───────────────────────────────
    // +1 módulo para disjuntor geral (polos)
    final modUsados   = modulos + polos;
    final modDisponi  = _modulosQuadro(dijGeral);
    final modLivres   = (modDisponi - modUsados).clamp(0, modDisponi);
    final percOcup    = modDisponi > 0 ? (modUsados / modDisponi) * 100 : 0.0;
    final percResQua  = 100 - percOcup;

    // ── Módulo 2: Reserva de carga ───────────────────────────────
    final iMaxQuadro  = dijGeral.toDouble();
    final iRestante   = (iMaxQuadro - iProj).clamp(0.0, iMaxQuadro);
    final percResCar  = iMaxQuadro > 0 ? (iRestante / iMaxQuadro) * 100 : 0.0;

    // ── Módulo 7: Curto-circuito ─────────────────────────────────
    // Estimativa simplificada: Icc ≈ Vfase / (0,05 × Zref)
    final iccEstimado = tensaoFase / (0.3); // kA simplificado
    const capInterrup = 10.0; // kA — valor de projeto
    final dijOkIcc = capInterrup >= iccEstimado * 0.001;

    // ── Módulo 8: Seletividade ───────────────────────────────────
    bool seletOk = true;
    for (final c in cargas) {
      if (!c.ativo) continue;
      if (c.disjuntorSugerido >= dijGeral) {
        seletOk = false;
        problemasSelectividade.add(
          '${c.descricao}: disjuntor ${c.disjuntorSugerido}A ≥ geral ${dijGeral}A',
        );
      }
    }

    // ── Módulo 6: Distribuição por categoria ─────────────────────
    final distribuicao = <DistribuicaoCategoria>[];
    final Map<TipoCarga, String> catNomes = {
      TipoCarga.iluminacao:   'Iluminação',
      TipoCarga.tug:          'TUG – Tomadas Gerais',
      TipoCarga.tue:          'TUE – Tomadas Específicas',
      TipoCarga.motor:        'Motores Elétricos',
      TipoCarga.arCondicionado: 'Ar-Condicionado',
      TipoCarga.resistencia:  'Resistências/Aquecedores',
      TipoCarga.generico:     'Equipamentos Gerais',
    };
    final Map<TipoCarga, String> catIcones = {
      TipoCarga.iluminacao:   '💡',
      TipoCarga.tug:          '🔌',
      TipoCarga.tue:          '⚡',
      TipoCarga.motor:        '⚙️',
      TipoCarga.arCondicionado: '❄️',
      TipoCarga.resistencia:  '🌡️',
      TipoCarga.generico:     '📦',
    };
    for (final tipo in TipoCarga.values) {
      final inst = catInstalada[tipo] ?? 0;
      if (inst <= 0) continue;
      final dem  = catDemandada[tipo] ?? 0;
      final perc = pAtivaTotal > 0 ? (dem / pAtivaTotal) * 100 : 0.0;
      distribuicao.add(DistribuicaoCategoria(
        nome: catNomes[tipo] ?? tipo.label,
        icone: catIcones[tipo] ?? '📦',
        potenciaInstalada: inst,
        potenciaDemandada: dem,
        percentualTotal: perc,
      ));
    }
    // Ordena por potência demandada decrescente
    distribuicao.sort((a, b) => b.potenciaDemandada.compareTo(a.potenciaDemandada));

    // ── Alertas de balanceamento ─────────────────────────────────
    final classBal = _classBal(desbal);
    final alertaMotores = temMotorTrifasico && desbal > 2;
    if (desbal > 10) {
      alertas.add('Desbalanceamento excessivo (${desbal.toStringAsFixed(1)}%) – redistribuir cargas entre fases');
    } else if (desbal > 2) {
      alertas.add('Desbalanceamento (${desbal.toStringAsFixed(1)}%) > 2% – atenção para motores');
    }
    if (alertaMotores) {
      alertas.add('Motores trifásicos detectados com desbalanceamento ${desbal.toStringAsFixed(1)}% – risco de aquecimento e redução da vida útil');
    }

    // ── Correção de FP ───────────────────────────────────────────
    bool needFP = fp < 0.92;
    double qCap = 0;
    if (needFP) {
      double ang1 = acos(fp.clamp(0.01, 1.0));
      double ang2 = acos(0.92);
      qCap = (pAtivaTotal / 1000) * (tan(ang1) - tan(ang2));
      alertas.add('FP médio (${fp.toStringAsFixed(2)}) < 0,92 – banco de capacitores: ${qCap.toStringAsFixed(1)} kVAr');
    }
    if (pAtivaTotal / 1000 > 75 && needFP) {
      alertas.add('Instalação >75 kW sujeita à regulamentação de FP pela ANEEL');
    }

    // ── Alertas de quadro ────────────────────────────────────────
    if (percOcup > 90) {
      alertas.add('Quadro com ocupação ${percOcup.toStringAsFixed(0)}% – recomenda-se quadro de maior capacidade');
    } else if (percOcup > 80) {
      alertas.add('Quadro com ocupação ${percOcup.toStringAsFixed(0)}% – pouca reserva para futuras ampliações');
    }
    if (percResCar < 15) {
      alertas.add('Reserva de corrente ${percResCar.toStringAsFixed(1)}% < 15% – limitar futuras ampliações');
    }
    if (utilDij > 95) {
      alertas.add('Disjuntor geral com utilização ${utilDij.toStringAsFixed(0)}% (crítica) – considerar aumento de capacidade');
    }
    if (!seletOk) {
      alertas.add('Problema de seletividade detectado – verificar coordenação das proteções');
    }

    // ── Módulo 10: Índice Geral (0–100) ─────────────────────────
    // Critérios com pesos
    double pontos = 0;
    // Balanceamento (20 pts)
    pontos += switch (classBal) {
      ClassificacaoBalanceamento.excelente => 20,
      ClassificacaoBalanceamento.muitoBom  => 16,
      ClassificacaoBalanceamento.aceitavel => 10,
      ClassificacaoBalanceamento.ruim      => 0,
    };
    // FP (15 pts)
    if (fp >= 0.92) {
      pontos += 15;
    } else if (fp >= 0.85) {
      pontos += 8;
    }
    // Queda de tensão (15 pts)
    if (quedaMax <= 2) {
      pontos += 15;
    } else if (quedaMax <= 4) {
      pontos += 10;
    } else if (quedaMax <= 7) {
      pontos += 4;
    }
    // Disjuntor (15 pts)
    pontos += switch (classDij) {
      ClassificacaoDisjuntor.excelente => 15,
      ClassificacaoDisjuntor.boa       => 12,
      ClassificacaoDisjuntor.alta      => 6,
      ClassificacaoDisjuntor.critica   => 0,
    };
    // Reserva quadro (10 pts)
    if (percReservaQuadro(percResQua) >= 20) pontos += 10;
    else if (percResQua >= 10) pontos += 5;
    // Reserva carga (10 pts)
    if (percResCar >= 20) pontos += 10;
    else if (percResCar >= 15) pontos += 5;
    // Seletividade (10 pts)
    if (seletOk) pontos += 10;
    else pontos += 3;
    // Curto-circuito (5 pts)
    if (dijOkIcc) pontos += 5;

    final indice = pontos.clamp(0, 100).toDouble();
    final classIdx = _classIdx(indice);

    // ── Módulo 11: Diagnóstico ───────────────────────────────────
    final conforMes = <String>[];
    final problemas = <String>[];
    final recomend  = <String>[];

    // Itens de diagnóstico
    if (classBal == ClassificacaoBalanceamento.excelente || classBal == ClassificacaoBalanceamento.muitoBom) {
      conforMes.add('Balanceamento entre fases dentro dos limites recomendados (${desbal.toStringAsFixed(1)}%)');
    } else {
      problemas.add('Desbalanceamento de fases acima do recomendado (${desbal.toStringAsFixed(1)}%) – redistribuir cargas');
    }

    if (fp >= 0.92) {
      conforMes.add('Fator de potência (${fp.toStringAsFixed(3)}) atende aos requisitos mínimos ANEEL');
    } else {
      problemas.add('Fator de potência (${fp.toStringAsFixed(3)}) abaixo de 0,92 – instalar banco de capacitores');
    }

    if (quedaMax <= 4) {
      conforMes.add('Queda de tensão máxima (${quedaMax.toStringAsFixed(1)}%) dentro do limite de 4% (NBR 5410)');
    } else {
      problemas.add('Queda de tensão ${quedaMax.toStringAsFixed(1)}% supera 4% – aumentar seção dos condutores');
    }

    if (classDij == ClassificacaoDisjuntor.excelente || classDij == ClassificacaoDisjuntor.boa) {
      conforMes.add('Disjuntor geral ${dijGeral}A corretamente especificado (utilização ${utilDij.toStringAsFixed(0)}%)');
    } else if (classDij == ClassificacaoDisjuntor.critica) {
      problemas.add('Utilização do disjuntor geral crítica (${utilDij.toStringAsFixed(0)}%) – rever dimensionamento');
    }

    if (seletOk) {
      conforMes.add('Coordenação e seletividade das proteções adequadas');
    } else {
      problemas.add('Problemas de seletividade – verificar coordenação dos disjuntores');
    }

    if (percResQua >= 20) {
      conforMes.add('Reserva adequada no quadro (${percResQua.toStringAsFixed(0)}% de módulos livres)');
    } else if (percResQua < 10) {
      problemas.add('Quadro com ocupação elevada – reserva de apenas ${percResQua.toStringAsFixed(0)}%');
    }

    if (percResCar >= 20) {
      conforMes.add('Reserva de corrente adequada (${percResCar.toStringAsFixed(0)}%) para futuras ampliações');
    } else if (percResCar < 15) {
      problemas.add('Baixa reserva de corrente (${percResCar.toStringAsFixed(0)}%) – ampliar capacidade do quadro');
    }

    if (dijOkIcc) {
      conforMes.add('Capacidade de interrupção adequada à corrente de curto estimada');
    } else {
      problemas.add('Capacidade de interrupção pode ser insuficiente para a corrente de curto estimada');
    }

    // Recomendações fixas (boas práticas NBR 5410 / NR-10)
    recomend.add('Instalar DPS Classe II para proteção contra surtos de tensão');
    recomend.add('Realizar inspeções periódicas conforme NR-10 e ABNT NBR 5410');
    recomend.add('Manter diagrama unifilar atualizado com todas as cargas instaladas');
    if (needFP) {
      recomend.add('Instalar banco de capacitores de ${qCap.toStringAsFixed(1)} kVAr para correção do FP');
    }
    if (!seletOk) {
      recomend.add('Revisar coordenação das proteções para garantir seletividade total');
    }
    if (percResQua < 20) {
      recomend.add('Considerar quadro com maior número de módulos para reserva futura');
    }

    return ResultadoProjeto(
      totalPotenciaAtiva:      pAtivaTotal / 1000,
      totalPotenciaReativa:    pReativaTotal / 1000,
      totalPotenciaAparente:   pApATotal / 1000,
      fatorPotenciaMedio:      fp,
      totalPotenciaDemandada:  pDemandada / 1000,
      faseA: ResultadoPorFase(potenciaAtiva: pAtivaA/1000, potenciaReativa: pReativaA/1000, potenciaAparente: sA/1000, corrente: iA),
      faseB: ResultadoPorFase(potenciaAtiva: pAtivaB/1000, potenciaReativa: pReativaB/1000, potenciaAparente: sB/1000, corrente: iB),
      faseC: ResultadoPorFase(potenciaAtiva: pAtivaC/1000, potenciaReativa: pReativaC/1000, potenciaAparente: sC/1000, corrente: iC),
      correnteFaseA:           iA,
      correnteFaseB:           iB,
      correnteFaseC:           iC,
      correnteNeutro:          iNeutro,
      correnteTotal:           iTotal,
      correnteProjeto:         iProj,
      desbalanceamentoPercent: desbal,
      correnteMedia:           iMedia,
      diferencaMaxima:         difMax,
      classificacaoBalanceamento: classBal,
      alertaMotores:           alertaMotores,
      disjuntorGeral:          dijGeral,
      disjuntorPolos:          polos,
      utilizacaoDisjuntor:     utilDij,
      classificacaoDisjuntor:  classDij,
      necessitaCorrecaoFP:     needFP,
      capacitorKvar:           qCap,
      modulosDisponiveis:      modDisponi,
      modulosUtilizados:       modUsados,
      modulosLivres:           modLivres,
      percentOcupacao:         percOcup,
      percentReservaQuadro:    percResQua,
      correnteMaximaQuadro:    iMaxQuadro,
      correnteRestante:        iRestante,
      percentReservaCarga:     percResCar,
      correnteCurtoEstimada:   iccEstimado * 0.001, // → kA
      capacidadeInterrupcao:   capInterrup,
      disjuntorAdequadoIcc:    dijOkIcc,
      seletividadeOk:          seletOk,
      problemasSelectividade:  problemasSelectividade,
      distribuicaoCategorias:  distribuicao,
      indiceGeral:             indice,
      classificacaoIndice:     classIdx,
      diagnosticoConformes:    conforMes,
      diagnosticoProblemas:    problemas,
      diagnosticoRecomendacoes: recomend,
      alertas:                 alertas,
      numCircuitos:            cargas.where((c) => c.ativo).length,
      quedaTensaoMax:          quedaMax,
    );
  }

  // Getter auxiliar para evitar warning de variável não usada
  static double percReservaQuadro(double v) => v;
}

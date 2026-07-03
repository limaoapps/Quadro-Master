import 'carga.dart';
import 'resultado_projeto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TipoQuadroFilho — tipos de quadro que um alimentador pode servir
// ─────────────────────────────────────────────────────────────────────────────
enum TipoQuadroFilho { qd, qf, painel, ccm, qgbt, outro }

extension TipoQuadroFilhoExt on TipoQuadroFilho {
  String get label {
    switch (this) {
      case TipoQuadroFilho.qd:    return 'Quadro de Distribuição (QD)';
      case TipoQuadroFilho.qf:    return 'Quadro de Força (QF)';
      case TipoQuadroFilho.painel: return 'Painel Elétrico';
      case TipoQuadroFilho.ccm:   return 'Centro de Controle de Motores (CCM)';
      case TipoQuadroFilho.qgbt:  return 'Outro QGBT';
      case TipoQuadroFilho.outro: return 'Outro';
    }
  }
  String get sigla {
    switch (this) {
      case TipoQuadroFilho.qd:    return 'QD';
      case TipoQuadroFilho.qf:    return 'QF';
      case TipoQuadroFilho.painel: return 'PE';
      case TipoQuadroFilho.ccm:   return 'CCM';
      case TipoQuadroFilho.qgbt:  return 'QGBT';
      case TipoQuadroFilho.outro: return 'OUT';
    }
  }
  String get icone {
    switch (this) {
      case TipoQuadroFilho.qd:    return '🔵';
      case TipoQuadroFilho.qf:    return '⚙️';
      case TipoQuadroFilho.painel: return '🖥️';
      case TipoQuadroFilho.ccm:   return '🏭';
      case TipoQuadroFilho.qgbt:  return '⚡';
      case TipoQuadroFilho.outro: return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QuadroFilho — quadro alimentado por um alimentador do QGBT.
// Contém as cargas finais e calcula seus próprios resultados.
// ─────────────────────────────────────────────────────────────────────────────
class QuadroFilho {
  String id;
  String nome;                  // Ex: "QD Bloco A"
  TipoQuadroFilho tipo;
  List<Carga> cargas;
  String observacoes;
  double tensao;                // V — herdada do QGBT por padrão
  int numFases;                 // 1, 2 ou 3
  double fatorPotenciaGeral;
  double reservaPercent;        // margem do disjuntor filho (0–50)

  QuadroFilho({
    required this.id,
    required this.nome,
    this.tipo = TipoQuadroFilho.qd,
    List<Carga>? cargas,
    this.observacoes = '',
    this.tensao = 220,
    this.numFases = 3,
    this.fatorPotenciaGeral = 0.85,
    this.reservaPercent = 0,
  }) : cargas = cargas ?? [];

  // ── Calcula os resultados do quadro filho ────────────────────────────────
  ResultadoProjeto? get resultado {
    final ativas = cargas.where((c) => c.ativo).toList();
    if (ativas.isEmpty) return null;
    // tensaoFase: para 220V monof → 220; 380V trif → 220; 440V → 254
    final double tensaoFase = numFases == 3 ? (tensao == 380 ? 220 : tensao == 440 ? 254 : tensao) : tensao;
    return ResultadoProjeto.calcular(
      cargas: ativas,
      numFases: numFases,
      tensaoLinha: tensao,
      tensaoFase: tensaoFase,
      reservaPercent: reservaPercent,
    );
  }

  // ── Grandezas calculadas (usadas pelo alimentador do QGBT) ───────────────
  double get potenciaAtivaKw   => resultado?.totalPotenciaAtiva   ?? 0;
  double get potenciaAparenteKva => resultado?.totalPotenciaAparente ?? 0;
  double get correnteProjeto   => resultado?.correnteProjeto       ?? 0;
  int    get disjuntorSugerido => resultado?.disjuntorGeral         ?? 0;
  double get condutorSugerido  {
    final i = correnteProjeto;
    if (i <= 0)   return 0;
    if (i <= 13)  return 1.5;
    if (i <= 18)  return 2.5;
    if (i <= 24)  return 4.0;
    if (i <= 32)  return 6.0;
    if (i <= 43)  return 10.0;
    if (i <= 57)  return 16.0;
    if (i <= 75)  return 25.0;
    if (i <= 92)  return 35.0;
    if (i <= 120) return 50.0;
    if (i <= 150) return 70.0;
    if (i <= 180) return 95.0;
    if (i <= 210) return 120.0;
    if (i <= 240) return 150.0;
    return 185.0;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'tipo': tipo.index,
    'cargas': cargas.map((c) => c.toMap()).toList(),
    'observacoes': observacoes,
    'tensao': tensao,
    'numFases': numFases,
    'fatorPotenciaGeral': fatorPotenciaGeral,
    'reservaPercent': reservaPercent,
  };

  factory QuadroFilho.fromMap(Map<String, dynamic> m) => QuadroFilho(
    id: m['id'] ?? '',
    nome: m['nome'] ?? '',
    tipo: TipoQuadroFilho.values[
      ((m['tipo'] ?? 0) as int).clamp(0, TipoQuadroFilho.values.length - 1)
    ],
    cargas: (m['cargas'] as List<dynamic>? ?? [])
        .map((c) => Carga.fromMap(c as Map<String, dynamic>))
        .toList(),
    observacoes: m['observacoes'] ?? '',
    tensao: (m['tensao'] ?? 220).toDouble(),
    numFases: m['numFases'] ?? 3,
    fatorPotenciaGeral: (m['fatorPotenciaGeral'] ?? 0.85).toDouble(),
    reservaPercent: (m['reservaPercent'] ?? 0).toDouble(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Alimentador — saída protegida do QGBT
// Possui um QuadroFilho; seus valores elétricos são calculados
// automaticamente a partir do quadro filho.
// ─────────────────────────────────────────────────────────────────────────────
class Alimentador {
  String id;
  String nome;           // Ex: "Q1", "Alimentador Bloco A"
  String destino;        // Descrição livre, ex: "Bloco A – 3º Andar"
  TipoQuadroFilho tipoDestino;
  String observacoes;
  int ordem;            // Posição na lista (ordenação manual)

  // Quadro filho associado (criado automaticamente ao salvar)
  QuadroFilho? quadroFilho;

  Alimentador({
    required this.id,
    required this.nome,
    this.destino = '',
    this.tipoDestino = TipoQuadroFilho.qd,
    this.observacoes = '',
    this.ordem = 0,
    this.quadroFilho,
  });

  // ── Grandezas automáticas (provenientes do quadro filho) ─────────────────
  double get potenciaAtivaKw      => quadroFilho?.potenciaAtivaKw      ?? 0;
  double get potenciaAparenteKva  => quadroFilho?.potenciaAparenteKva   ?? 0;
  double get corrente             => quadroFilho?.correnteProjeto        ?? 0;
  int    get disjuntor            => quadroFilho?.disjuntorSugerido      ?? 0;
  double get condutor             => quadroFilho?.condutorSugerido       ?? 0;
  int    get numCircuitos         => quadroFilho?.cargas.where((c) => c.ativo).length ?? 0;

  bool get temQuadro => quadroFilho != null;
  bool get temCargas => (quadroFilho?.cargas.isNotEmpty) ?? false;

  String get descricaoElectrica {
    if (!temQuadro || corrente == 0) return 'Aguardando dimensionamento';
    return '${potenciaAparenteKva.toStringAsFixed(1)} kVA · '
           '${corrente.toStringAsFixed(1)} A · '
           '${disjuntor} A · '
           '${condutor.toStringAsFixed(1)} mm²';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'destino': destino,
    'tipoDestino': tipoDestino.index,
    'observacoes': observacoes,
    'ordem': ordem,
    'quadroFilho': quadroFilho?.toMap(),
  };

  factory Alimentador.fromMap(Map<String, dynamic> m) => Alimentador(
    id: m['id'] ?? '',
    nome: m['nome'] ?? '',
    destino: m['destino'] ?? '',
    tipoDestino: TipoQuadroFilho.values[
      ((m['tipoDestino'] ?? 0) as int).clamp(0, TipoQuadroFilho.values.length - 1)
    ],
    observacoes: m['observacoes'] ?? '',
    ordem: m['ordem'] ?? 0,
    quadroFilho: m['quadroFilho'] != null
        ? QuadroFilho.fromMap(m['quadroFilho'] as Map<String, dynamic>)
        : null,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ResultadoQGBT — resultado consolidado de todos os alimentadores
// ─────────────────────────────────────────────────────────────────────────────
class ResultadoQGBT {
  final double totalPotenciaAtivaKw;
  final double totalPotenciaAparenteKva;
  final double totalCorrenteProjeto;
  final int disjuntorGeral;
  final double condutorEntrada;
  final int numAlimentadores;
  final int numAlimentadoresDimensionados;
  final List<Alimentador> alimentadores;

  ResultadoQGBT({
    required this.totalPotenciaAtivaKw,
    required this.totalPotenciaAparenteKva,
    required this.totalCorrenteProjeto,
    required this.disjuntorGeral,
    required this.condutorEntrada,
    required this.numAlimentadores,
    required this.numAlimentadoresDimensionados,
    required this.alimentadores,
  });

  static ResultadoQGBT calcular(List<Alimentador> alimentadores, {double reservaPercent = 0}) {
    double pAtiva  = 0;
    double pAparen = 0;
    double iTotal  = 0;

    for (final a in alimentadores) {
      pAtiva  += a.potenciaAtivaKw;
      pAparen += a.potenciaAparenteKva;
      iTotal  += a.corrente;
    }

    // Corrente de projeto com margem NBR 5410 (×1,25) já aplicada no filho;
    // aqui aplicamos apenas a reserva extra configurável
    final iProj = iTotal * (1 + reservaPercent / 100);

    int dijGeral = _disjuntorPadrao(iProj);

    double cond = _condutorPadrao(iProj);

    return ResultadoQGBT(
      totalPotenciaAtivaKw:          pAtiva,
      totalPotenciaAparenteKva:      pAparen,
      totalCorrenteProjeto:          iTotal,
      disjuntorGeral:                dijGeral,
      condutorEntrada:               cond,
      numAlimentadores:              alimentadores.length,
      numAlimentadoresDimensionados: alimentadores.where((a) => a.corrente > 0).length,
      alimentadores:                 alimentadores,
    );
  }

  static int _disjuntorPadrao(double i) {
    const series = [16,20,25,32,40,50,63,80,100,125,160,200,250,315,400,500,630,800,1000,1250,1600,2000];
    for (final s in series) { if (s >= i) return s; }
    return 2000;
  }

  static double _condutorPadrao(double i) {
    if (i <= 13)  return 1.5;
    if (i <= 18)  return 2.5;
    if (i <= 24)  return 4.0;
    if (i <= 32)  return 6.0;
    if (i <= 43)  return 10.0;
    if (i <= 57)  return 16.0;
    if (i <= 75)  return 25.0;
    if (i <= 92)  return 35.0;
    if (i <= 120) return 50.0;
    if (i <= 150) return 70.0;
    if (i <= 180) return 95.0;
    if (i <= 210) return 120.0;
    if (i <= 240) return 150.0;
    return 185.0;
  }
}

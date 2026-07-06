// lib/models/unifilar.dart
// Modelo de dados para o Diagrama Unifilar NBR 5410

import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum FaseUnifilar {
  r('R', 1),
  s('S', 1),
  t('T', 1),
  rs('R+S', 2),
  rt('R+T', 2),
  st('S+T', 2),
  rst('R+S+T', 3);

  final String label;
  final int polos; // número de polos do disjuntor
  const FaseUnifilar(this.label, this.polos);

  bool get isTrifasico => polos == 3;
  double get tensaoPadrao => polos == 3 ? 380.0 : 220.0;
}

enum CurvaDisjuntor { b, c, d }

extension CurvaDisjuntorExt on CurvaDisjuntor {
  String get label {
    switch (this) {
      case CurvaDisjuntor.b: return 'B';
      case CurvaDisjuntor.c: return 'C';
      case CurvaDisjuntor.d: return 'D';
    }
  }
}

enum OrientacaoFolha {
  retrato('Vertical (Retrato)'),
  paisagem('Horizontal (Paisagem)');

  final String label;
  const OrientacaoFolha(this.label);
}

enum EstiloCanto {
  arredondado('Arredondado'),
  quadrado('Quadrado');

  final String label;
  const EstiloCanto(this.label);
}

enum UnidadePotencia {
  va('VA'),
  kva('kVA'),
  w('W'),
  kw('kW');

  final String label;
  const UnidadePotencia(this.label);

  double toWatts(double valor) {
    switch (this) {
      case UnidadePotencia.va:  return valor;
      case UnidadePotencia.kva: return valor * 1000;
      case UnidadePotencia.w:   return valor;
      case UnidadePotencia.kw:  return valor * 1000;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabela de barramento de cobre (NBR / fabricante)
// ─────────────────────────────────────────────────────────────────────────────
class TabelaBarramento {
  static String calcularBarramento(double correnteA) {
    if (correnteA <= 63)  return '1/2" x 1/8" (12,7 x 3,18 mm)';
    if (correnteA <= 100) return '3/4" x 1/8" (19,1 x 3,18 mm)';
    if (correnteA <= 150) return '1" x 1/8" (25,4 x 3,18 mm)';
    if (correnteA <= 200) return '1" x 3/16" (25,4 x 4,76 mm)';
    if (correnteA <= 300) return '1.1/4" x 3/16" (31,8 x 4,76 mm)';
    if (correnteA <= 400) return '1.1/2" x 1/4" (38,1 x 6,35 mm)';
    if (correnteA <= 600) return '2" x 1/4" (50,8 x 6,35 mm)';
    return '3" x 1/4" (76,2 x 6,35 mm)';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de circuito individual
// ─────────────────────────────────────────────────────────────────────────────
class CircuitoUnifilar {
  final String id;
  final FaseUnifilar fase;
  final double corrente;       // A
  final CurvaDisjuntor curva;
  final bool utilizaDR;
  final double bitola;         // mm²
  final double potencia;       // valor na unidade abaixo
  final UnidadePotencia unidadePotencia;
  final double tensao;         // V
  final String codigo;         // "CIRC. N" — auto
  final String descricao;      // texto livre

  const CircuitoUnifilar({
    required this.id,
    required this.fase,
    required this.corrente,
    required this.curva,
    required this.utilizaDR,
    required this.bitola,
    required this.potencia,
    required this.unidadePotencia,
    required this.tensao,
    required this.codigo,
    required this.descricao,
  });

  /// Potência em VA para somas
  double get potenciaVA => unidadePotencia.toWatts(potencia);

  Map<String, dynamic> toMap() => {
    'id': id,
    'fase': fase.name,
    'corrente': corrente,
    'curva': curva.name,
    'utilizaDR': utilizaDR,
    'bitola': bitola,
    'potencia': potencia,
    'unidadePotencia': unidadePotencia.name,
    'tensao': tensao,
    'codigo': codigo,
    'descricao': descricao,
  };

  factory CircuitoUnifilar.fromMap(Map<String, dynamic> m) => CircuitoUnifilar(
    id: m['id'] ?? '',
    fase: FaseUnifilar.values.firstWhere(
      (e) => e.name == m['fase'], orElse: () => FaseUnifilar.rst),
    corrente: (m['corrente'] as num?)?.toDouble() ?? 10,
    curva: CurvaDisjuntor.values.firstWhere(
      (e) => e.name == m['curva'], orElse: () => CurvaDisjuntor.c),
    utilizaDR: m['utilizaDR'] ?? false,
    bitola: (m['bitola'] as num?)?.toDouble() ?? 2.5,
    potencia: (m['potencia'] as num?)?.toDouble() ?? 0,
    unidadePotencia: UnidadePotencia.values.firstWhere(
      (e) => e.name == m['unidadePotencia'], orElse: () => UnidadePotencia.va),
    tensao: (m['tensao'] as num?)?.toDouble() ?? 220,
    codigo: m['codigo'] ?? '',
    descricao: m['descricao'] ?? '',
  );

  CircuitoUnifilar copyWith({
    String? id, FaseUnifilar? fase, double? corrente, CurvaDisjuntor? curva,
    bool? utilizaDR, double? bitola, double? potencia,
    UnidadePotencia? unidadePotencia, double? tensao,
    String? codigo, String? descricao,
  }) => CircuitoUnifilar(
    id: id ?? this.id,
    fase: fase ?? this.fase,
    corrente: corrente ?? this.corrente,
    curva: curva ?? this.curva,
    utilizaDR: utilizaDR ?? this.utilizaDR,
    bitola: bitola ?? this.bitola,
    potencia: potencia ?? this.potencia,
    unidadePotencia: unidadePotencia ?? this.unidadePotencia,
    tensao: tensao ?? this.tensao,
    codigo: codigo ?? this.codigo,
    descricao: descricao ?? this.descricao,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo do Diagrama Unifilar completo
// ─────────────────────────────────────────────────────────────────────────────
class DiagramaUnifilar {
  // Identificação
  final String nomeProjeto;
  final String numeroDocumento;   // formato LT-XXNNNNN
  final String data;
  final int revisao;

  // Entrada do quadro
  final String vemDo;             // origem da alimentação
  final double correnteGeral;     // A
  final double caboGeral;         // mm²
  final FaseUnifilar faseGeral;   // fases do alimentador geral

  // DR geral (opcional)
  final bool temDR;
  final double correnteDR;

  // DPS (opcional)
  final bool temDPS;
  final double dpskA;
  final double dpsV;

  // Barramento
  final String barramento;        // calculado ou editado manualmente

  // Checkboxes de exibição
  final bool quadroAterrado;
  final bool exibirTerra;
  final bool exibirNeutro;

  // Unidades de potência
  final UnidadePotencia unidadeCircuito;   // VA / W
  final UnidadePotencia unidadeQuadro;    // kVA / kW

  // Visual
  final double escala;
  final OrientacaoFolha orientacao;
  final EstiloCanto estiloCanto;
  final bool centralizar;

  // Fator de demanda (para o Resumo)
  final double fatorDemanda;      // 0.01 a 1.0 (100% = 1.0)

  // Dados do rodapé / cliente (preenchidos dos dados do projeto)
  final String clienteNome;
  final String clienteDocumento;
  final String clienteEndereco;
  final String clienteTelefone;
  final String clienteEmail;

  // Circuitos
  final List<CircuitoUnifilar> circuitos;

  const DiagramaUnifilar({
    required this.nomeProjeto,
    required this.numeroDocumento,
    required this.data,
    required this.revisao,
    required this.vemDo,
    required this.correnteGeral,
    required this.caboGeral,
    required this.faseGeral,
    required this.temDR,
    required this.correnteDR,
    required this.temDPS,
    required this.dpskA,
    required this.dpsV,
    required this.barramento,
    required this.quadroAterrado,
    required this.exibirTerra,
    required this.exibirNeutro,
    required this.unidadeCircuito,
    required this.unidadeQuadro,
    required this.escala,
    required this.orientacao,
    required this.estiloCanto,
    required this.centralizar,
    required this.fatorDemanda,
    required this.clienteNome,
    required this.clienteDocumento,
    required this.clienteEndereco,
    required this.clienteTelefone,
    required this.clienteEmail,
    required this.circuitos,
  });

  /// Potência total do quadro em VA
  double get potenciaTotalVA =>
      circuitos.fold(0.0, (sum, c) => sum + c.potenciaVA);

  /// Potência total em kVA
  double get potenciaTotalkVA => potenciaTotalVA / 1000;

  /// Potência demandada em kW
  double get potenciaDemandadakW =>
      potenciaTotalkVA * fatorDemanda * 0.9; // FP médio 0.90

  /// Corrente total estimada (soma das correntes dos circuitos)
  double get correnteTotalEstimada =>
      circuitos.fold(0.0, (sum, c) => sum + c.corrente);

  Map<String, dynamic> toMap() => {
    'nomeProjeto': nomeProjeto,
    'numeroDocumento': numeroDocumento,
    'data': data,
    'revisao': revisao,
    'vemDo': vemDo,
    'correnteGeral': correnteGeral,
    'caboGeral': caboGeral,
    'faseGeral': faseGeral.name,
    'temDR': temDR,
    'correnteDR': correnteDR,
    'temDPS': temDPS,
    'dpskA': dpskA,
    'dpsV': dpsV,
    'barramento': barramento,
    'quadroAterrado': quadroAterrado,
    'exibirTerra': exibirTerra,
    'exibirNeutro': exibirNeutro,
    'unidadeCircuito': unidadeCircuito.name,
    'unidadeQuadro': unidadeQuadro.name,
    'escala': escala,
    'orientacao': orientacao.name,
    'estiloCanto': estiloCanto.name,
    'centralizar': centralizar,
    'fatorDemanda': fatorDemanda,
    'clienteNome': clienteNome,
    'clienteDocumento': clienteDocumento,
    'clienteEndereco': clienteEndereco,
    'clienteTelefone': clienteTelefone,
    'clienteEmail': clienteEmail,
    'circuitos': circuitos.map((c) => c.toMap()).toList(),
  };

  factory DiagramaUnifilar.fromMap(Map<String, dynamic> m) => DiagramaUnifilar(
    nomeProjeto: m['nomeProjeto'] ?? '',
    numeroDocumento: m['numeroDocumento'] ?? '',
    data: m['data'] ?? '',
    revisao: m['revisao'] ?? 0,
    vemDo: m['vemDo'] ?? '',
    correnteGeral: (m['correnteGeral'] as num?)?.toDouble() ?? 40,
    caboGeral: (m['caboGeral'] as num?)?.toDouble() ?? 10,
    faseGeral: FaseUnifilar.values.firstWhere(
      (e) => e.name == m['faseGeral'], orElse: () => FaseUnifilar.rst),
    temDR: m['temDR'] ?? false,
    correnteDR: (m['correnteDR'] as num?)?.toDouble() ?? 40,
    temDPS: m['temDPS'] ?? false,
    dpskA: (m['dpskA'] as num?)?.toDouble() ?? 45,
    dpsV: (m['dpsV'] as num?)?.toDouble() ?? 380,
    barramento: m['barramento'] ?? '',
    quadroAterrado: m['quadroAterrado'] ?? true,
    exibirTerra: m['exibirTerra'] ?? true,
    exibirNeutro: m['exibirNeutro'] ?? true,
    unidadeCircuito: UnidadePotencia.values.firstWhere(
      (e) => e.name == m['unidadeCircuito'], orElse: () => UnidadePotencia.va),
    unidadeQuadro: UnidadePotencia.values.firstWhere(
      (e) => e.name == m['unidadeQuadro'], orElse: () => UnidadePotencia.kva),
    escala: (m['escala'] as num?)?.toDouble() ?? 1.0,
    orientacao: OrientacaoFolha.values.firstWhere(
      (e) => e.name == m['orientacao'], orElse: () => OrientacaoFolha.retrato),
    estiloCanto: EstiloCanto.values.firstWhere(
      (e) => e.name == m['estiloCanto'], orElse: () => EstiloCanto.arredondado),
    centralizar: m['centralizar'] ?? true,
    fatorDemanda: (m['fatorDemanda'] as num?)?.toDouble() ?? 1.0,
    clienteNome: m['clienteNome'] ?? '',
    clienteDocumento: m['clienteDocumento'] ?? '',
    clienteEndereco: m['clienteEndereco'] ?? '',
    clienteTelefone: m['clienteTelefone'] ?? '',
    clienteEmail: m['clienteEmail'] ?? '',
    circuitos: (m['circuitos'] as List<dynamic>? ?? [])
        .map((c) => CircuitoUnifilar.fromMap(c as Map<String, dynamic>))
        .toList(),
  );

  String toJson() => jsonEncode(toMap());
  factory DiagramaUnifilar.fromJson(String s) =>
      DiagramaUnifilar.fromMap(jsonDecode(s));

  DiagramaUnifilar copyWith({
    String? nomeProjeto, String? numeroDocumento, String? data, int? revisao,
    String? vemDo, double? correnteGeral, double? caboGeral, FaseUnifilar? faseGeral,
    bool? temDR, double? correnteDR, bool? temDPS, double? dpskA, double? dpsV,
    String? barramento, bool? quadroAterrado, bool? exibirTerra, bool? exibirNeutro,
    UnidadePotencia? unidadeCircuito, UnidadePotencia? unidadeQuadro,
    double? escala, OrientacaoFolha? orientacao, EstiloCanto? estiloCanto,
    bool? centralizar, double? fatorDemanda,
    String? clienteNome, String? clienteDocumento, String? clienteEndereco,
    String? clienteTelefone, String? clienteEmail,
    List<CircuitoUnifilar>? circuitos,
  }) => DiagramaUnifilar(
    nomeProjeto: nomeProjeto ?? this.nomeProjeto,
    numeroDocumento: numeroDocumento ?? this.numeroDocumento,
    data: data ?? this.data,
    revisao: revisao ?? this.revisao,
    vemDo: vemDo ?? this.vemDo,
    correnteGeral: correnteGeral ?? this.correnteGeral,
    caboGeral: caboGeral ?? this.caboGeral,
    faseGeral: faseGeral ?? this.faseGeral,
    temDR: temDR ?? this.temDR,
    correnteDR: correnteDR ?? this.correnteDR,
    temDPS: temDPS ?? this.temDPS,
    dpskA: dpskA ?? this.dpskA,
    dpsV: dpsV ?? this.dpsV,
    barramento: barramento ?? this.barramento,
    quadroAterrado: quadroAterrado ?? this.quadroAterrado,
    exibirTerra: exibirTerra ?? this.exibirTerra,
    exibirNeutro: exibirNeutro ?? this.exibirNeutro,
    unidadeCircuito: unidadeCircuito ?? this.unidadeCircuito,
    unidadeQuadro: unidadeQuadro ?? this.unidadeQuadro,
    escala: escala ?? this.escala,
    orientacao: orientacao ?? this.orientacao,
    estiloCanto: estiloCanto ?? this.estiloCanto,
    centralizar: centralizar ?? this.centralizar,
    fatorDemanda: fatorDemanda ?? this.fatorDemanda,
    clienteNome: clienteNome ?? this.clienteNome,
    clienteDocumento: clienteDocumento ?? this.clienteDocumento,
    clienteEndereco: clienteEndereco ?? this.clienteEndereco,
    clienteTelefone: clienteTelefone ?? this.clienteTelefone,
    clienteEmail: clienteEmail ?? this.clienteEmail,
    circuitos: circuitos ?? this.circuitos,
  );

  // ─── Geração automática de número de documento ───────────────────────────
  static String gerarNumeroDocumento() {
    final now = DateTime.now();
    final letras = String.fromCharCodes([
      65 + (now.month % 26),
      65 + (now.day % 26),
    ]);
    final numero = (now.millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    return 'LT-$letras$numero';
  }
}

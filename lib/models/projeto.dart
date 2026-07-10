import 'dart:convert';
import 'carga.dart';
import 'alimentador.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FatoresDemandaGrupo — FD centralizado por categoria no nível do Quadro
// ─────────────────────────────────────────────────────────────────────────────
class FatoresDemandaGrupo {
  double iluminacao;     // % aplicado sobre total do grupo Iluminação
  double tug;            // % aplicado sobre total do grupo TUG
  double tue;            // % aplicado sobre total do grupo TUE
  double motor;          // % aplicado sobre total do grupo Motores (em operação)
  double arCondicionado; // % aplicado sobre total do grupo Ar-Condicionado
  double resistencia;    // % aplicado sobre total do grupo Resistências
  double generico;       // % aplicado sobre total do grupo Genérico

  FatoresDemandaGrupo({
    this.iluminacao    = 100,
    this.tug           = 100,
    this.tue           = 100,
    this.motor         = 100,
    this.arCondicionado = 100,
    this.resistencia   = 100,
    this.generico      = 100,
  });

  double fatorParaTipo(TipoCarga tipo) {
    switch (tipo) {
      case TipoCarga.iluminacao:     return iluminacao;
      case TipoCarga.tug:            return tug;
      case TipoCarga.tue:            return tue;
      case TipoCarga.motor:          return motor;
      case TipoCarga.arCondicionado: return arCondicionado;
      case TipoCarga.resistencia:    return resistencia;
      case TipoCarga.generico:       return generico;
    }
  }

  Map<String, dynamic> toMap() => {
    'iluminacao': iluminacao,
    'tug': tug,
    'tue': tue,
    'motor': motor,
    'arCondicionado': arCondicionado,
    'resistencia': resistencia,
    'generico': generico,
  };

  factory FatoresDemandaGrupo.fromMap(Map<String, dynamic> m) =>
      FatoresDemandaGrupo(
        iluminacao:     (m['iluminacao']     ?? 100).toDouble(),
        tug:            (m['tug']            ?? 100).toDouble(),
        tue:            (m['tue']            ?? 100).toDouble(),
        motor:          (m['motor']          ?? 100).toDouble(),
        arCondicionado: (m['arCondicionado'] ?? 100).toDouble(),
        resistencia:    (m['resistencia']    ?? 100).toDouble(),
        generico:       (m['generico']       ?? 100).toDouble(),
      );

  FatoresDemandaGrupo copyWith({
    double? iluminacao, double? tug, double? tue, double? motor,
    double? arCondicionado, double? resistencia, double? generico,
  }) => FatoresDemandaGrupo(
    iluminacao:     iluminacao     ?? this.iluminacao,
    tug:            tug            ?? this.tug,
    tue:            tue            ?? this.tue,
    motor:          motor          ?? this.motor,
    arCondicionado: arCondicionado ?? this.arCondicionado,
    resistencia:    resistencia    ?? this.resistencia,
    generico:       generico       ?? this.generico,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FdAutoEngine — Sugere FD automático por grupo com base em tabelas de referência
// Fontes: NBR 5410:2004, Mamede Filho "Instalações Elétricas Industriais", ABNT
// ─────────────────────────────────────────────────────────────────────────────
class FdAutoEngine {
  // Motores — NBR 5410 Tabela 41 / Mamede Filho Cap. 4
  // Baseia-se no número de motores em operação simultânea
  static double fdMotores(int numMotoresEmOperacao) {
    if (numMotoresEmOperacao <= 0) return 100;
    if (numMotoresEmOperacao == 1) return 100; // 1 motor: FD = 100%
    if (numMotoresEmOperacao == 2) return 100; // 2 motores: FD = 100%
    if (numMotoresEmOperacao == 3) return 91;  // 3 motores: FD = 91%
    if (numMotoresEmOperacao == 4) return 84;  // 4 motores: FD = 84%
    if (numMotoresEmOperacao == 5) return 78;  // 5 motores: FD = 78%
    if (numMotoresEmOperacao == 6) return 74;  // 6 motores: FD = 74%
    if (numMotoresEmOperacao <= 8) return 71;  // 7-8 motores: FD = 71%
    if (numMotoresEmOperacao <= 10) return 68; // 9-10 motores: FD = 68%
    return 65;                                 // > 10 motores: FD = 65%
  }

  // Iluminação — NBR 5410:2004 seção 9.4.1 / Norma ABNT
  // Baseia-se na potência total instalada do grupo
  static double fdIluminacao(double potenciaInstaladadaW) {
    final kw = potenciaInstaladadaW / 1000.0;
    if (kw <= 0) return 100;
    if (kw <= 2)    return 100; // Até 2 kW: 100%
    if (kw <= 5)    return 90;  // 2–5 kW: 90%
    if (kw <= 10)   return 80;  // 5–10 kW: 80%
    if (kw <= 25)   return 75;  // 10–25 kW: 75%
    if (kw <= 50)   return 70;  // 25–50 kW: 70%
    return 65;                  // > 50 kW: 65%
  }

  // TUG (Tomadas de Uso Geral) — NBR 5410:2004 seção 9.4.2
  // Baseia-se no número de circuitos TUG
  static double fdTUG(int numCircuitos) {
    if (numCircuitos <= 0) return 100;
    if (numCircuitos == 1) return 100;
    if (numCircuitos == 2) return 100;
    if (numCircuitos <= 4) return 90;  // 3–4 circuitos: 90%
    if (numCircuitos <= 6) return 80;  // 5–6 circuitos: 80%
    if (numCircuitos <= 10) return 70; // 7–10 circuitos: 70%
    return 65;                          // > 10 circuitos: 65%
  }

  // TUE (Tomadas de Uso Específico) — sempre 100% (uso dedicado)
  static double fdTUE(int numCircuitos) {
    if (numCircuitos <= 2) return 100;
    if (numCircuitos <= 4) return 90;
    return 80;
  }

  // Ar-Condicionado — baseado no número de unidades
  static double fdArCondicionado(int numUnidades) {
    if (numUnidades <= 0) return 100;
    if (numUnidades <= 2) return 100; // 1-2 unidades: 100%
    if (numUnidades <= 4) return 90;  // 3-4 unidades: 90%
    if (numUnidades <= 6) return 80;  // 5-6 unidades: 80%
    return 75;                         // > 6 unidades: 75%
  }

  // Resistência (aquecimento, chuveiro, forno) — uso simultâneo alto
  static double fdResistencia(int numCircuitos) {
    if (numCircuitos <= 2) return 100;
    if (numCircuitos <= 4) return 90;
    return 80;
  }

  // Genérico — conservador
  static double fdGenerico(int numCircuitos) {
    if (numCircuitos <= 2) return 100;
    if (numCircuitos <= 5) return 90;
    return 80;
  }

  /// Calcula FD sugerido para cada grupo a partir da lista de cargas
  /// Retorna um FatoresDemandaGrupo com os valores sugeridos pelas tabelas
  static FatoresDemandaGrupo calcularSugestoes(List<Carga> cargas) {
    // Contar por grupo
    final Map<TipoCarga, int> contagens = {};
    final Map<TipoCarga, double> potencias = {};

    for (final c in cargas) {
      // Motores em reserva não entram na contagem de operação
      if (c.tipo == TipoCarga.motor && c.motorReserva) continue;
      contagens[c.tipo] = (contagens[c.tipo] ?? 0) + c.quantidade;
      potencias[c.tipo] = (potencias[c.tipo] ?? 0) + c.potenciaAtiva;
    }

    return FatoresDemandaGrupo(
      iluminacao:     fdIluminacao(potencias[TipoCarga.iluminacao] ?? 0),
      tug:            fdTUG(contagens[TipoCarga.tug] ?? 0),
      tue:            fdTUE(contagens[TipoCarga.tue] ?? 0),
      motor:          fdMotores(contagens[TipoCarga.motor] ?? 0),
      arCondicionado: fdArCondicionado(contagens[TipoCarga.arCondicionado] ?? 0),
      resistencia:    fdResistencia(contagens[TipoCarga.resistencia] ?? 0),
      generico:       fdGenerico(contagens[TipoCarga.generico] ?? 0),
    );
  }

  /// Descrição textual do critério aplicado (para exibição na UI)
  static String descricaoCriterio(TipoCarga tipo, int quantidade, double potenciaW) {
    switch (tipo) {
      case TipoCarga.motor:
        return 'NBR 5410 Tab.41 — $quantidade motor(es) em operação';
      case TipoCarga.iluminacao:
        final kw = (potenciaW / 1000).toStringAsFixed(1);
        return 'NBR 5410 §9.4.1 — ${kw} kW instalados';
      case TipoCarga.tug:
        return 'NBR 5410 §9.4.2 — $quantidade circuito(s) TUG';
      case TipoCarga.tue:
        return 'TUE dedicado — $quantidade circuito(s)';
      case TipoCarga.arCondicionado:
        return 'Uso simultâneo — $quantidade unidade(s)';
      case TipoCarga.resistencia:
        return 'Uso simultâneo — $quantidade circuito(s)';
      case TipoCarga.generico:
        return 'Critério conservador — $quantidade circuito(s)';
    }
  }
}

enum TipoQuadro { qd, qf, qgbt, painelEletrico }
enum NumeroFases { monofasico, bifasico, trifasico }
enum TensaoAlimentacao { v127, v220, v380, v440 }

extension TipoQuadroExt on TipoQuadro {
  String get label {
    switch (this) {
      case TipoQuadro.qd:           return 'QD – Quadro de Distribuição';
      case TipoQuadro.qf:           return 'QF – Quadro de Força';
      case TipoQuadro.qgbt:         return 'QGBT – Quadro Geral de BT';
      case TipoQuadro.painelEletrico: return 'Painel Elétrico';
    }
  }
  String get sigla {
    switch (this) {
      case TipoQuadro.qd:           return 'QD';
      case TipoQuadro.qf:           return 'QF';
      case TipoQuadro.qgbt:         return 'QGBT';
      case TipoQuadro.painelEletrico: return 'PE';
    }
  }
  String get descricao {
    switch (this) {
      case TipoQuadro.qd:           return 'Circuitos de iluminação, tomadas e cargas finais';
      case TipoQuadro.qf:           return 'Motores e equipamentos industriais';
      case TipoQuadro.qgbt:         return 'Alimenta outros quadros e alimentadores';
      case TipoQuadro.painelEletrico: return 'Equipamentos de comando e automação';
    }
  }
}

extension NumeroFasesExt on NumeroFases {
  String get label {
    switch (this) {
      case NumeroFases.monofasico: return '1F – Monofásico';
      case NumeroFases.bifasico: return '2F – Bifásico';
      case NumeroFases.trifasico: return '3F+N – Trifásico com Neutro';
    }
  }
}

extension TensaoAlimentacaoExt on TensaoAlimentacao {
  String get label {
    switch (this) {
      case TensaoAlimentacao.v127: return '127 V';
      case TensaoAlimentacao.v220: return '220 V';
      case TensaoAlimentacao.v380: return '380 V';
      case TensaoAlimentacao.v440: return '440 V';
    }
  }
  double get valor {
    switch (this) {
      case TensaoAlimentacao.v127: return 127.0;
      case TensaoAlimentacao.v220: return 220.0;
      case TensaoAlimentacao.v380: return 380.0;
      case TensaoAlimentacao.v440: return 440.0;
    }
  }
  double get tensaoFase {
    switch (this) {
      case TensaoAlimentacao.v127: return 127.0;
      case TensaoAlimentacao.v220: return 127.0;
      case TensaoAlimentacao.v380: return 220.0;
      case TensaoAlimentacao.v440: return 254.0;
    }
  }
}

enum TipoPessoa { fisica, juridica }
enum CargoResponsavel { engenheiro, tecnico, profissional }

/// Tipo de documento de responsabilidade técnica
/// ART  → Anotação de Responsabilidade Técnica (CREA — Engenheiro/Técnico)
/// RRT  → Registro de Responsabilidade Técnica (CAU — Arquiteto)
enum TipoDocumentoART { art, rrt }

extension TipoDocumentoARTExt on TipoDocumentoART {
  String get label {
    switch (this) {
      case TipoDocumentoART.art: return 'ART';
      case TipoDocumentoART.rrt: return 'RRT';
    }
  }
  String get labelCompleto {
    switch (this) {
      case TipoDocumentoART.art: return 'ART – Anotação de Responsabilidade Técnica';
      case TipoDocumentoART.rrt: return 'RRT – Registro de Responsabilidade Técnica';
    }
  }
  String get orgaoEmissor {
    switch (this) {
      case TipoDocumentoART.art: return 'CREA';
      case TipoDocumentoART.rrt: return 'CAU';
    }
  }
  String get hint {
    switch (this) {
      case TipoDocumentoART.art: return '0000000000000 (13 dígitos)';
      case TipoDocumentoART.rrt: return 'RRT-2024-00012345';
    }
  }
}

extension TipoPessoaExt on TipoPessoa {
  String get label => this == TipoPessoa.fisica ? 'Pessoa Física' : 'Pessoa Jurídica';
}

extension CargoResponsavelExt on CargoResponsavel {
  String get label {
    switch (this) {
      case CargoResponsavel.engenheiro: return 'Engenheiro';
      case CargoResponsavel.tecnico: return 'Técnico';
      case CargoResponsavel.profissional: return 'Profissional';
    }
  }
  String get registroLabel {
    switch (this) {
      case CargoResponsavel.engenheiro: return 'CREA nº / UF';
      case CargoResponsavel.tecnico: return 'CRT (CPF do Técnico)';
      case CargoResponsavel.profissional: return 'CPF do Profissional';
    }
  }
  String get registroHint {
    switch (this) {
      case CargoResponsavel.engenheiro: return 'Ex: 123456-7/SP';
      case CargoResponsavel.tecnico: return 'CPF: 000.000.000-00';
      case CargoResponsavel.profissional: return 'CPF: 000.000.000-00';
    }
  }
}

class EmpresaExecutora {
  String razaoSocial;
  String documento;        // CPF ou CNPJ (com máscara)
  String registro;         // CREA, CRT ou CPF dependendo do cargo
  String responsavel;
  String cargo;            // engenheiro | tecnico | profissional
  String tipoPessoa;       // fisica | juridica
  String cep;
  String rua;
  String numero;
  String bairro;
  String cidade;
  String estado;
  String telefone;
  String email;
  String site;
  String logoBase64;       // Logo da empresa em base64

  EmpresaExecutora({
    this.razaoSocial = '',
    this.documento = '',
    this.registro = '',
    this.responsavel = '',
    this.cargo = 'engenheiro',
    this.tipoPessoa = 'juridica',
    this.cep = '',
    this.rua = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.telefone = '',
    this.email = '',
    this.site = '',
    this.logoBase64 = '',
  });

  // Compat: legado usa campo 'cnpj' e 'crea' e 'endereco'
  String get enderecoCompleto {
    final parts = <String>[];
    if (rua.isNotEmpty) parts.add(rua);
    if (numero.isNotEmpty) parts.add('nº $numero');
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) parts.add(cidade);
    if (estado.isNotEmpty) parts.add(estado);
    if (cep.isNotEmpty) parts.add('CEP $cep');
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'razaoSocial': razaoSocial, 'documento': documento, 'registro': registro,
    'responsavel': responsavel, 'cargo': cargo, 'tipoPessoa': tipoPessoa,
    'cep': cep, 'rua': rua, 'numero': numero, 'bairro': bairro,
    'cidade': cidade, 'estado': estado,
    'telefone': telefone, 'email': email, 'site': site,
    'logoBase64': logoBase64,
    // legado
    'cnpj': documento, 'crea': registro, 'endereco': enderecoCompleto,
  };

  factory EmpresaExecutora.fromMap(Map<String, dynamic> m) => EmpresaExecutora(
    razaoSocial: m['razaoSocial'] ?? '',
    documento: m['documento'] ?? m['cnpj'] ?? '',
    registro: m['registro'] ?? m['crea'] ?? '',
    responsavel: m['responsavel'] ?? '',
    cargo: m['cargo'] ?? 'engenheiro',
    tipoPessoa: m['tipoPessoa'] ?? 'juridica',
    cep: m['cep'] ?? '',
    rua: m['rua'] ?? '',
    numero: m['numero'] ?? '',
    bairro: m['bairro'] ?? '',
    cidade: m['cidade'] ?? '',
    estado: m['estado'] ?? '',
    telefone: m['telefone'] ?? '',
    email: m['email'] ?? '',
    site: m['site'] ?? '',
    logoBase64: m['logoBase64'] ?? '',
  );
}

class EmpresaContratante {
  String razaoSocial;
  String documento;        // CPF ou CNPJ com máscara
  String tipoPessoa;       // fisica | juridica
  String responsavel;
  String telefone;
  String email;
  String cep;
  String rua;
  String numero;
  String bairro;
  String cidade;
  String estado;
  String art;              // número do documento ART ou RRT
  TipoDocumentoART tipoArt; // qual tipo de documento (ART ou RRT)

  EmpresaContratante({
    this.razaoSocial = '',
    this.documento = '',
    this.tipoPessoa = 'juridica',
    this.responsavel = '',
    this.telefone = '',
    this.email = '',
    this.cep = '',
    this.rua = '',
    this.numero = '',
    this.bairro = '',
    this.cidade = '',
    this.estado = '',
    this.art = '',
    this.tipoArt = TipoDocumentoART.art,
  });

  String get enderecoCompleto {
    final parts = <String>[];
    if (rua.isNotEmpty) parts.add(rua);
    if (numero.isNotEmpty) parts.add('nº $numero');
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) parts.add(cidade);
    if (estado.isNotEmpty) parts.add(estado);
    if (cep.isNotEmpty) parts.add('CEP $cep');
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'razaoSocial': razaoSocial, 'documento': documento, 'tipoPessoa': tipoPessoa,
    'responsavel': responsavel, 'telefone': telefone, 'email': email,
    'cep': cep, 'rua': rua, 'numero': numero, 'bairro': bairro,
    'cidade': cidade, 'estado': estado, 'art': art,
    'tipoArt': tipoArt.name,   // 'art' | 'rrt'
    // legado
    'cnpj': documento, 'endereco': enderecoCompleto,
  };

  factory EmpresaContratante.fromMap(Map<String, dynamic> m) => EmpresaContratante(
    razaoSocial: m['razaoSocial'] ?? '',
    documento: m['documento'] ?? m['cnpj'] ?? '',
    tipoPessoa: m['tipoPessoa'] ?? 'juridica',
    responsavel: m['responsavel'] ?? '',
    telefone: m['telefone'] ?? '',
    email: m['email'] ?? '',
    cep: m['cep'] ?? '',
    rua: m['rua'] ?? '',
    numero: m['numero'] ?? '',
    bairro: m['bairro'] ?? '',
    cidade: m['cidade'] ?? '',
    estado: m['estado'] ?? '',
    art: m['art'] ?? '',
    // retrocompat: dados antigos sem tipoArt → assume ART
    tipoArt: TipoDocumentoART.values.firstWhere(
      (t) => t.name == (m['tipoArt'] ?? ''),
      orElse: () => TipoDocumentoART.art,
    ),
  );
}

enum StatusProjeto { elaboracao, concluido, revisao }

extension StatusProjetoExt on StatusProjeto {
  String get label {
    switch (this) {
      case StatusProjeto.elaboracao: return 'Em Elaboração';
      case StatusProjeto.concluido: return 'Concluído';
      case StatusProjeto.revisao: return 'Em Revisão';
    }
  }
}

class Projeto {
  String id;
  String nome;
  TipoQuadro tipoQuadro;
  TensaoAlimentacao tensao;
  NumeroFases numFases;
  double fatorPotenciaGeral;
  String observacoes;
  EmpresaExecutora executora;
  EmpresaContratante contratante;
  List<Carga> cargas;
  DateTime criadoEm;
  DateTime modificadoEm;
  StatusProjeto status;

  // ── QGBT: lista de alimentadores hierárquicos ──────────────────────────
  List<Alimentador> alimentadores;

  // ── FD centralizado por grupo no nível do Quadro ─────────────────
  FatoresDemandaGrupo fatoresDemanda;

  Projeto({
    required this.id,
    required this.nome,
    this.tipoQuadro = TipoQuadro.qd,
    this.tensao = TensaoAlimentacao.v220,
    this.numFases = NumeroFases.trifasico,
    this.fatorPotenciaGeral = 0.85,
    this.observacoes = '',
    EmpresaExecutora? executora,
    EmpresaContratante? contratante,
    List<Carga>? cargas,
    List<Alimentador>? alimentadores,
    FatoresDemandaGrupo? fatoresDemanda,
    DateTime? criadoEm,
    DateTime? modificadoEm,
    this.status = StatusProjeto.elaboracao,
  })  : executora = executora ?? EmpresaExecutora(),
        contratante = contratante ?? EmpresaContratante(),
        cargas = cargas ?? [],
        alimentadores = alimentadores ?? [],
        fatoresDemanda = fatoresDemanda ?? FatoresDemandaGrupo(),
        criadoEm = criadoEm ?? DateTime.now(),
        modificadoEm = modificadoEm ?? DateTime.now();

  // Retorna o ResultadoQGBT calculado automaticamente (apenas para QGBT)
  ResultadoQGBT? get resultadoQGBT {
    if (tipoQuadro != TipoQuadro.qgbt || alimentadores.isEmpty) return null;
    return ResultadoQGBT.calcular(alimentadores);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'tipoQuadro': tipoQuadro.index,
    'tensao': tensao.index,
    'numFases': numFases.index,
    'fatorPotenciaGeral': fatorPotenciaGeral,
    'observacoes': observacoes,
    'executora': executora.toMap(),
    'contratante': contratante.toMap(),
    'cargas': cargas.map((c) => c.toMap()).toList(),
    'alimentadores': alimentadores.map((a) => a.toMap()).toList(),
    'fatoresDemanda': fatoresDemanda.toMap(),
    'criadoEm': criadoEm.toIso8601String(),
    'modificadoEm': modificadoEm.toIso8601String(),
    'status': status.index,
  };

  factory Projeto.fromMap(Map<String, dynamic> m) {
    return Projeto(
      id: m['id'],
      nome: m['nome'],
      tipoQuadro: TipoQuadro.values[((m['tipoQuadro'] ?? 0) as int).clamp(0, TipoQuadro.values.length - 1)],
      tensao: TensaoAlimentacao.values[m['tensao'] ?? 1],
      numFases: NumeroFases.values[m['numFases'] ?? 2],
      fatorPotenciaGeral: (m['fatorPotenciaGeral'] ?? 0.85).toDouble(),
      observacoes: m['observacoes'] ?? '',
      executora: EmpresaExecutora.fromMap(m['executora'] ?? {}),
      contratante: EmpresaContratante.fromMap(m['contratante'] ?? {}),
      cargas: (m['cargas'] as List<dynamic>? ?? [])
          .map((c) => Carga.fromMap(c as Map<String, dynamic>))
          .toList(),
      alimentadores: (m['alimentadores'] as List<dynamic>? ?? [])
          .map((a) => Alimentador.fromMap(a as Map<String, dynamic>))
          .toList(),
      fatoresDemanda: m['fatoresDemanda'] != null
          ? FatoresDemandaGrupo.fromMap(m['fatoresDemanda'] as Map<String, dynamic>)
          : FatoresDemandaGrupo(),
      criadoEm: DateTime.parse(m['criadoEm'] ?? DateTime.now().toIso8601String()),
      modificadoEm: DateTime.parse(m['modificadoEm'] ?? DateTime.now().toIso8601String()),
      status: StatusProjeto.values[m['status'] ?? 0],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Projeto.fromJson(String source) => Projeto.fromMap(jsonDecode(source));

  Projeto copyWith({String? nome, TipoQuadro? tipoQuadro, TensaoAlimentacao? tensao,
    NumeroFases? numFases, double? fatorPotenciaGeral, String? observacoes,
    EmpresaExecutora? executora, EmpresaContratante? contratante,
    List<Carga>? cargas, List<Alimentador>? alimentadores,
    FatoresDemandaGrupo? fatoresDemanda, StatusProjeto? status}) {
    return Projeto(
      id: id,
      nome: nome ?? this.nome,
      tipoQuadro: tipoQuadro ?? this.tipoQuadro,
      tensao: tensao ?? this.tensao,
      numFases: numFases ?? this.numFases,
      fatorPotenciaGeral: fatorPotenciaGeral ?? this.fatorPotenciaGeral,
      observacoes: observacoes ?? this.observacoes,
      executora: executora ?? this.executora,
      contratante: contratante ?? this.contratante,
      cargas: cargas ?? this.cargas,
      alimentadores: alimentadores ?? this.alimentadores,
      fatoresDemanda: fatoresDemanda ?? this.fatoresDemanda,
      criadoEm: criadoEm,
      modificadoEm: DateTime.now(),
      status: status ?? this.status,
    );
  }
}

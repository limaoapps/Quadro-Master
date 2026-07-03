import 'dart:convert';
import 'carga.dart';

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
  String art;

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
    DateTime? criadoEm,
    DateTime? modificadoEm,
    this.status = StatusProjeto.elaboracao,
  })  : executora = executora ?? EmpresaExecutora(),
        contratante = contratante ?? EmpresaContratante(),
        cargas = cargas ?? [],
        criadoEm = criadoEm ?? DateTime.now(),
        modificadoEm = modificadoEm ?? DateTime.now();

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
    List<Carga>? cargas, StatusProjeto? status}) {
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
      criadoEm: criadoEm,
      modificadoEm: DateTime.now(),
      status: status ?? this.status,
    );
  }
}

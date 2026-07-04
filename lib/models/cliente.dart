import 'dart:convert';
import 'projeto.dart'; // TipoPessoa, TipoDocumentoART

// ─────────────────────────────────────────────────────────────────────────────
// Cliente — cadastro reutilizável de contratantes/clientes
// Persiste separado dos projetos; pode ser vinculado a qualquer projeto
// para pré-preencher EmpresaContratante automaticamente.
// ─────────────────────────────────────────────────────────────────────────────
class Cliente {
  String id;
  String razaoSocial;       // nome ou razão social
  String documento;         // CPF ou CNPJ (com máscara)
  String tipoPessoa;        // 'fisica' | 'juridica'
  String responsavel;       // nome do responsável/contato
  String telefone;
  String email;
  String cep;
  String rua;
  String numero;
  String bairro;
  String cidade;
  String estado;
  String art;               // número ART ou RRT
  String tipoArt;           // 'art' | 'rrt'
  String observacoes;
  DateTime criadoEm;
  DateTime modificadoEm;

  Cliente({
    required this.id,
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
    this.tipoArt = 'art',
    this.observacoes = '',
    DateTime? criadoEm,
    DateTime? modificadoEm,
  })  : criadoEm    = criadoEm    ?? DateTime.now(),
        modificadoEm = modificadoEm ?? DateTime.now();

  // ── Helpers ───────────────────────────────────────────────
  String get enderecoCompleto {
    final parts = <String>[];
    if (rua.isNotEmpty)    parts.add(rua);
    if (numero.isNotEmpty) parts.add('nº $numero');
    if (bairro.isNotEmpty) parts.add(bairro);
    if (cidade.isNotEmpty) parts.add(cidade);
    if (estado.isNotEmpty) parts.add(estado);
    if (cep.isNotEmpty)    parts.add('CEP $cep');
    return parts.join(', ');
  }

  /// Iniciais para avatar
  String get iniciais {
    final words = razaoSocial.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  TipoDocumentoART get tipoArtEnum =>
      TipoDocumentoART.values.firstWhere(
        (t) => t.name == tipoArt,
        orElse: () => TipoDocumentoART.art,
      );

  /// Converte para EmpresaContratante para preenchimento rápido
  EmpresaContratante toEmpresaContratante() => EmpresaContratante(
    razaoSocial: razaoSocial,
    documento:   documento,
    tipoPessoa:  tipoPessoa,
    responsavel: responsavel,
    telefone:    telefone,
    email:       email,
    cep:         cep,
    rua:         rua,
    numero:      numero,
    bairro:      bairro,
    cidade:      cidade,
    estado:      estado,
    art:         art,
    tipoArt:     tipoArtEnum,
  );

  // ── Serialização ──────────────────────────────────────────
  Map<String, dynamic> toMap() => {
    'id':           id,
    'razaoSocial':  razaoSocial,
    'documento':    documento,
    'tipoPessoa':   tipoPessoa,
    'responsavel':  responsavel,
    'telefone':     telefone,
    'email':        email,
    'cep':          cep,
    'rua':          rua,
    'numero':       numero,
    'bairro':       bairro,
    'cidade':       cidade,
    'estado':       estado,
    'art':          art,
    'tipoArt':      tipoArt,
    'observacoes':  observacoes,
    'criadoEm':     criadoEm.toIso8601String(),
    'modificadoEm': modificadoEm.toIso8601String(),
  };

  factory Cliente.fromMap(Map<String, dynamic> m) => Cliente(
    id:           m['id'] ?? '',
    razaoSocial:  m['razaoSocial'] ?? '',
    documento:    m['documento'] ?? '',
    tipoPessoa:   m['tipoPessoa'] ?? 'juridica',
    responsavel:  m['responsavel'] ?? '',
    telefone:     m['telefone'] ?? '',
    email:        m['email'] ?? '',
    cep:          m['cep'] ?? '',
    rua:          m['rua'] ?? '',
    numero:       m['numero'] ?? '',
    bairro:       m['bairro'] ?? '',
    cidade:       m['cidade'] ?? '',
    estado:       m['estado'] ?? '',
    art:          m['art'] ?? '',
    tipoArt:      m['tipoArt'] ?? 'art',
    observacoes:  m['observacoes'] ?? '',
    criadoEm:     DateTime.tryParse(m['criadoEm'] ?? '') ?? DateTime.now(),
    modificadoEm: DateTime.tryParse(m['modificadoEm'] ?? '') ?? DateTime.now(),
  );

  String toJson() => jsonEncode(toMap());
  factory Cliente.fromJson(String source) => Cliente.fromMap(jsonDecode(source));

  Cliente copyWith({
    String? razaoSocial, String? documento, String? tipoPessoa,
    String? responsavel, String? telefone, String? email,
    String? cep, String? rua, String? numero, String? bairro,
    String? cidade, String? estado, String? art, String? tipoArt,
    String? observacoes,
  }) => Cliente(
    id:           id,
    razaoSocial:  razaoSocial  ?? this.razaoSocial,
    documento:    documento    ?? this.documento,
    tipoPessoa:   tipoPessoa   ?? this.tipoPessoa,
    responsavel:  responsavel  ?? this.responsavel,
    telefone:     telefone     ?? this.telefone,
    email:        email        ?? this.email,
    cep:          cep          ?? this.cep,
    rua:          rua          ?? this.rua,
    numero:       numero       ?? this.numero,
    bairro:       bairro       ?? this.bairro,
    cidade:       cidade       ?? this.cidade,
    estado:       estado       ?? this.estado,
    art:          art          ?? this.art,
    tipoArt:      tipoArt      ?? this.tipoArt,
    observacoes:  observacoes  ?? this.observacoes,
    criadoEm:     criadoEm,
    modificadoEm: DateTime.now(),
  );
}

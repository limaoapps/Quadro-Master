// ─────────────────────────────────────────────────────────────────────────────
// PerfilUsuario — dados do profissional responsável (engenheiro / técnico)
// ─────────────────────────────────────────────────────────────────────────────
class PerfilUsuario {
  String nome;
  String cpf;
  String registro;    // CREA, CRT ou CPF conforme cargo
  String cargo;       // 'engenheiro' | 'tecnico' | 'profissional'
  String fotoBase64;  // imagem do usuário em base64

  PerfilUsuario({
    this.nome = '',
    this.cpf = '',
    this.registro = '',
    this.cargo = 'engenheiro',
    this.fotoBase64 = '',
  });

  /// Label amigável do cargo
  String get cargoLabel {
    switch (cargo) {
      case 'tecnico':      return 'Técnico Eletricista';
      case 'profissional': return 'Profissional Habilitado';
      default:             return 'Engenheiro Eletricista';
    }
  }

  /// Rótulo do registro conforme cargo
  String get registroLabel {
    switch (cargo) {
      case 'tecnico':      return 'CRT';
      case 'profissional': return 'CPF';
      default:             return 'CREA';
    }
  }

  bool get temFoto => fotoBase64.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'cpf': cpf,
    'registro': registro,
    'cargo': cargo,
    'fotoBase64': fotoBase64,
  };

  factory PerfilUsuario.fromMap(Map<String, dynamic> m) => PerfilUsuario(
    nome: m['nome'] ?? '',
    cpf: m['cpf'] ?? '',
    registro: m['registro'] ?? '',
    cargo: m['cargo'] ?? 'engenheiro',
    fotoBase64: m['fotoBase64'] ?? '',
  );
}

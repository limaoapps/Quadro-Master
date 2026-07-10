import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// Enums base
// ─────────────────────────────────────────────────────────────────────────────
enum TipoCarga { tug, tue, motor, arCondicionado, resistencia, iluminacao, generico }
enum LigacaoCarga { monofasico, bifasico, trifasico }
// FaseCarga: a=0, b=1, c=2, abc=3, ab=4, ac=5, bc=6
enum FaseCarga { a, b, c, abc, ab, ac, bc }
enum TipoPartida { direta, estrelaDelta, softStarter, vfd }
enum TecnologiaLuminaria { led, fluorescente, vaporSodio, vaporMetalico, incandescente, outro }

// ─────────────────────────────────────────────────────────────────────────────
// Subtipo QGBT – alimentadores
// ─────────────────────────────────────────────────────────────────────────────
enum SubtipoQGBT {
  qd,
  qf,
  painelEletrico,
  ccm,
  alimentadorGeral,
  alimentadorSecundario,
  outroAlimentador,
}

extension SubtipoQGBTExt on SubtipoQGBT {
  String get label {
    switch (this) {
      case SubtipoQGBT.qd:                 return 'Quadro de Distribuição (QD)';
      case SubtipoQGBT.qf:                 return 'Quadro de Força (QF)';
      case SubtipoQGBT.painelEletrico:     return 'Painel Elétrico';
      case SubtipoQGBT.ccm:               return 'Centro de Controle de Motores (CCM)';
      case SubtipoQGBT.alimentadorGeral:   return 'Alimentador Geral';
      case SubtipoQGBT.alimentadorSecundario: return 'Alimentador Secundário';
      case SubtipoQGBT.outroAlimentador:   return 'Outro Alimentador';
    }
  }
  String get icone {
    switch (this) {
      case SubtipoQGBT.qd:                 return '🟦';
      case SubtipoQGBT.qf:                 return '⚙️';
      case SubtipoQGBT.painelEletrico:     return '🖥️';
      case SubtipoQGBT.ccm:               return '🏭';
      case SubtipoQGBT.alimentadorGeral:   return '🔋';
      case SubtipoQGBT.alimentadorSecundario: return '🔌';
      case SubtipoQGBT.outroAlimentador:   return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtipo QF – industriais
// ─────────────────────────────────────────────────────────────────────────────
enum SubtipoQF {
  motor,
  bomba,
  compressor,
  exaustor,
  ventiladorIndustrial,
  elevador,
  maquinaIndustrial,
  prensa,
  esteira,
  guincho,
  ponteRolante,
  outroEquipamento,
}

extension SubtipoQFExt on SubtipoQF {
  String get label {
    switch (this) {
      case SubtipoQF.motor:               return 'Motor Elétrico';
      case SubtipoQF.bomba:               return 'Bomba';
      case SubtipoQF.compressor:          return 'Compressor';
      case SubtipoQF.exaustor:            return 'Exaustor';
      case SubtipoQF.ventiladorIndustrial: return 'Ventilador Industrial';
      case SubtipoQF.elevador:            return 'Elevador';
      case SubtipoQF.maquinaIndustrial:   return 'Máquina Industrial';
      case SubtipoQF.prensa:              return 'Prensa';
      case SubtipoQF.esteira:             return 'Esteira';
      case SubtipoQF.guincho:             return 'Guincho';
      case SubtipoQF.ponteRolante:        return 'Ponte Rolante';
      case SubtipoQF.outroEquipamento:    return 'Outro Equipamento';
    }
  }
  String get icone {
    switch (this) {
      case SubtipoQF.motor:               return '⚙️';
      case SubtipoQF.bomba:               return '💧';
      case SubtipoQF.compressor:          return '🌀';
      case SubtipoQF.exaustor:            return '🌬️';
      case SubtipoQF.ventiladorIndustrial: return '💨';
      case SubtipoQF.elevador:            return '🏗️';
      case SubtipoQF.maquinaIndustrial:   return '🏭';
      case SubtipoQF.prensa:              return '🔩';
      case SubtipoQF.esteira:             return '➡️';
      case SubtipoQF.guincho:             return '⛓️';
      case SubtipoQF.ponteRolante:        return '🏗️';
      case SubtipoQF.outroEquipamento:    return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtipo Painel Elétrico – automação/comando
// ─────────────────────────────────────────────────────────────────────────────
enum SubtipoPainel {
  inversorFrequencia,
  softStarter,
  contator,
  rele,
  releTermico,
  clp,
  ihm,
  fonte24v,
  transformadorComando,
  disjuntor,
  fusivel,
  fonteChaveada,
  outroEquipamento,
}

extension SubtipoPainelExt on SubtipoPainel {
  String get label {
    switch (this) {
      case SubtipoPainel.inversorFrequencia:    return 'Inversor de Frequência';
      case SubtipoPainel.softStarter:           return 'Soft Starter';
      case SubtipoPainel.contator:              return 'Contator';
      case SubtipoPainel.rele:                  return 'Relé';
      case SubtipoPainel.releTermico:           return 'Relé Térmico';
      case SubtipoPainel.clp:                   return 'CLP';
      case SubtipoPainel.ihm:                   return 'IHM';
      case SubtipoPainel.fonte24v:              return 'Fonte 24V';
      case SubtipoPainel.transformadorComando:  return 'Transformador de Comando';
      case SubtipoPainel.disjuntor:             return 'Disjuntor';
      case SubtipoPainel.fusivel:               return 'Fusível';
      case SubtipoPainel.fonteChaveada:         return 'Fonte Chaveada';
      case SubtipoPainel.outroEquipamento:      return 'Outro Equipamento';
    }
  }
  String get icone {
    switch (this) {
      case SubtipoPainel.inversorFrequencia:    return '🔄';
      case SubtipoPainel.softStarter:           return '🚀';
      case SubtipoPainel.contator:              return '⚡';
      case SubtipoPainel.rele:                  return '🔌';
      case SubtipoPainel.releTermico:           return '🌡️';
      case SubtipoPainel.clp:                   return '💻';
      case SubtipoPainel.ihm:                   return '🖥️';
      case SubtipoPainel.fonte24v:              return '🔋';
      case SubtipoPainel.transformadorComando:  return '🔁';
      case SubtipoPainel.disjuntor:             return '⚙️';
      case SubtipoPainel.fusivel:               return '🔐';
      case SubtipoPainel.fonteChaveada:         return '⚡';
      case SubtipoPainel.outroEquipamento:      return '📦';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extensions existentes
// ─────────────────────────────────────────────────────────────────────────────
extension TipoCargaExt on TipoCarga {
  String get label {
    switch (this) {
      case TipoCarga.tug:          return 'TUG – Tomada Uso Geral';
      case TipoCarga.tue:          return 'TUE – Tomada Uso Específico';
      case TipoCarga.motor:        return 'Motor Elétrico';
      case TipoCarga.arCondicionado: return 'Ar-Condicionado';
      case TipoCarga.resistencia:  return 'Resistência/Aquecedor';
      case TipoCarga.iluminacao:   return 'Iluminação';
      case TipoCarga.generico:     return 'Carga Genérica';
    }
  }
  String get icone {
    switch (this) {
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

extension LigacaoExt on LigacaoCarga {
  String get label {
    switch (this) {
      case LigacaoCarga.monofasico: return 'Monofásico';
      case LigacaoCarga.bifasico:   return 'Bifásico';
      case LigacaoCarga.trifasico:  return 'Trifásico';
    }
  }
}

extension FaseExt on FaseCarga {
  String get label {
    switch (this) {
      case FaseCarga.a:   return 'A';
      case FaseCarga.b:   return 'B';
      case FaseCarga.c:   return 'C';
      case FaseCarga.abc: return 'A+B+C';
      case FaseCarga.ab:  return 'A+B';
      case FaseCarga.ac:  return 'A+C';
      case FaseCarga.bc:  return 'B+C';
    }
  }
  bool get temA => this == FaseCarga.a || this == FaseCarga.abc || this == FaseCarga.ab || this == FaseCarga.ac;
  bool get temB => this == FaseCarga.b || this == FaseCarga.abc || this == FaseCarga.ab || this == FaseCarga.bc;
  bool get temC => this == FaseCarga.c || this == FaseCarga.abc || this == FaseCarga.ac || this == FaseCarga.bc;
  int get numFases {
    switch (this) {
      case FaseCarga.a:
      case FaseCarga.b:
      case FaseCarga.c:   return 1;
      case FaseCarga.ab:
      case FaseCarga.ac:
      case FaseCarga.bc:  return 2;
      case FaseCarga.abc: return 3;
    }
  }
}

extension TipoPartidaExt on TipoPartida {
  String get label {
    switch (this) {
      case TipoPartida.direta:       return 'Partida Direta';
      case TipoPartida.estrelaDelta: return 'Estrela-Triângulo (Y-Δ)';
      case TipoPartida.softStarter:  return 'Soft Starter';
      case TipoPartida.vfd:          return 'Inversor de Frequência (VFD)';
    }
  }
  double get fatorIp {
    switch (this) {
      case TipoPartida.direta:       return 7.0;
      case TipoPartida.estrelaDelta: return 2.5;
      case TipoPartida.softStarter:  return 3.0;
      case TipoPartida.vfd:          return 1.1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ResultadoCalculo (mantido para compatibilidade)
// ─────────────────────────────────────────────────────────────────────────────
class ResultadoCalculo {
  final double potenciaAtiva;
  final double potenciaReativa;
  final double potenciaAparente;
  final double corrente;
  final double correntePartida;
  final int disjuntor;
  final double condutor;
  final String alertas;
  final double quedaTensao;

  ResultadoCalculo({
    required this.potenciaAtiva,
    required this.potenciaReativa,
    required this.potenciaAparente,
    required this.corrente,
    this.correntePartida = 0,
    required this.disjuntor,
    required this.condutor,
    this.alertas = '',
    this.quedaTensao = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Classe Carga – expandida com DR, subtipos e campos específicos
// ─────────────────────────────────────────────────────────────────────────────
class Carga {
  String id;
  String descricao;
  TipoCarga tipo;
  int quantidade;
  double potenciaNominal;
  LigacaoCarga ligacao;
  double tensao;
  double fatorPotencia;
  FaseCarga fase;
  String notas;
  // Motor específico
  double rendimento;
  double fatorServico;
  double correnteNominal;
  TipoPartida tipoPartida;
  String regimeServico;
  double rotacao;
  // Ar-condicionado
  double capacidadeBtu;
  // Iluminação
  int quantidadeLuminarias;
  TecnologiaLuminaria tecnologiaLuminaria;
  // Comprimento para queda de tensão
  double comprimentoRamal;
  bool ativo;

  // ── NOVO: Proteção DR (para TUG e TUE) ───────────────────────────────
  bool utilizaDR;
  String sensibilidadeDR; // '30mA', '100mA', '300mA', 'outro'
  double sensibilidadeDROutro; // valor em mA quando 'outro'

  // ── NOVO: Subtipos especiais por tipo de quadro ───────────────────────
  // QGBT
  SubtipoQGBT? subtipoQGBT;
  // QF (industrial)
  SubtipoQF? subtipoQF;
  String metodoPadrao; // método de partida textual para QF
  // Motor reserva (stand-by) — exclui o motor do cálculo de demanda simultânea
  bool motorReserva;
  // Painel Elétrico
  SubtipoPainel? subtipoPainel;
  String modelo;
  String fabricante;

  Carga({
    required this.id,
    required this.descricao,
    required this.tipo,
    this.quantidade = 1,
    required this.potenciaNominal,
    this.ligacao = LigacaoCarga.monofasico,
    this.tensao = 220,
    this.fatorPotencia = 0.92,
    this.fase = FaseCarga.a,
    this.notas = '',
    this.rendimento = 0.90,
    this.fatorServico = 1.15,
    this.correnteNominal = 0,
    this.tipoPartida = TipoPartida.direta,
    this.regimeServico = 'S1',
    this.rotacao = 1800,
    this.capacidadeBtu = 0,
    this.quantidadeLuminarias = 1,
    this.tecnologiaLuminaria = TecnologiaLuminaria.led,
    this.comprimentoRamal = 20,
    this.ativo = true,
    // DR
    this.utilizaDR = false,
    this.sensibilidadeDR = '30mA',
    this.sensibilidadeDROutro = 30,
    // Subtipos
    this.subtipoQGBT,
    this.subtipoQF,
    this.metodoPadrao = '',
    this.subtipoPainel,
    this.modelo = '',
    this.fabricante = '',
    this.motorReserva = false,
  });

  double get potenciaAtiva {
    // Motores reserva são excluídos do cálculo de potência ativa (não operam simultaneamente)
    if (tipo == TipoCarga.motor && motorReserva) return 0.0;
    switch (tipo) {
      case TipoCarga.tug:
        return quantidade * potenciaNominal;
      case TipoCarga.motor:
        final pKw = potenciaNominal * 0.7355;
        return (pKw * fatorServico / rendimento) * 1000;
      case TipoCarga.resistencia:
        return potenciaNominal * quantidade;
      default:
        return potenciaNominal * quantidade;
    }
  }

  double get potenciaReativa {
    final fp = fatorPotencia.clamp(0.01, 1.0);
    final angulo = acos(fp);
    return potenciaAtiva * tan(angulo);
  }

  double get potenciaAparente {
    final fp = fatorPotencia.clamp(0.01, 1.0);
    return potenciaAtiva / fp;
  }

  double get corrente {
    if (ligacao == LigacaoCarga.trifasico) {
      return potenciaAparente / (sqrt(3) * tensao);
    } else if (ligacao == LigacaoCarga.bifasico) {
      return potenciaAparente / (sqrt(3) * tensao);
    } else {
      return potenciaAparente / tensao;
    }
  }

  double get correntePartida {
    if (tipo == TipoCarga.motor) {
      return corrente * tipoPartida.fatorIp;
    }
    return corrente;
  }

  int get disjuntorSugerido {
    final iProj = corrente * 1.25;
    final series = [6, 10, 16, 20, 25, 32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630];
    for (final s in series) {
      if (s >= iProj) return s;
    }
    return 630;
  }

  double get condutorSugerido {
    final iProj = corrente * 1.25;
    if (iProj <= 13)  return 1.5;
    if (iProj <= 18)  return 2.5;
    if (iProj <= 24)  return 4.0;
    if (iProj <= 32)  return 6.0;
    if (iProj <= 43)  return 10.0;
    if (iProj <= 57)  return 16.0;
    if (iProj <= 75)  return 25.0;
    if (iProj <= 92)  return 35.0;
    if (iProj <= 120) return 50.0;
    if (iProj <= 150) return 70.0;
    if (iProj <= 180) return 95.0;
    if (iProj <= 210) return 120.0;
    if (iProj <= 240) return 150.0;
    return 185.0;
  }

  double get quedaTensaoPercent {
    final r = 0.01724 * comprimentoRamal / condutorSugerido;
    final x = 0.00008 * comprimentoRamal;
    final fp = fatorPotencia;
    final sp = sqrt(1 - fp * fp);
    if (ligacao == LigacaoCarga.trifasico) {
      return (sqrt(3) * corrente * comprimentoRamal * (r * fp + x * sp)) / tensao * 100;
    } else {
      return (2 * corrente * comprimentoRamal * (r * fp + x * sp)) / tensao * 100;
    }
  }

  List<String> get alertas {
    final lista = <String>[];
    if (tipo == TipoCarga.motor && rendimento < 0.5) {
      lista.add('η não informado – adotado η=90% (IE2) por padrão');
    }
    if (tipo == TipoCarga.motor && fatorServico == 1.15) {
      lista.add('FS padrão 1,15 adotado');
    }
    if (quedaTensaoPercent > 4.0) {
      lista.add('ΔV=${quedaTensaoPercent.toStringAsFixed(1)}% supera limite de 4%');
    }
    return lista;
  }

  // ── Texto DR para exibição ────────────────────────────────────────────
  String get drTexto {
    if (!utilizaDR) return 'Sem DR';
    if (sensibilidadeDR == 'outro') {
      return 'DR ${sensibilidadeDROutro.toStringAsFixed(0)} mA';
    }
    return 'DR $sensibilidadeDR';
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'descricao': descricao, 'tipo': tipo.index,
    'quantidade': quantidade, 'potenciaNominal': potenciaNominal,
    'ligacao': ligacao.index, 'tensao': tensao,
    'fatorPotencia': fatorPotencia,
    'fase': fase.index, 'notas': notas,
    'rendimento': rendimento, 'fatorServico': fatorServico,
    'correnteNominal': correnteNominal, 'tipoPartida': tipoPartida.index,
    'regimeServico': regimeServico, 'rotacao': rotacao,
    'capacidadeBtu': capacidadeBtu,
    'quantidadeLuminarias': quantidadeLuminarias,
    'tecnologiaLuminaria': tecnologiaLuminaria.index,
    'comprimentoRamal': comprimentoRamal, 'ativo': ativo,
    // DR
    'utilizaDR': utilizaDR,
    'sensibilidadeDR': sensibilidadeDR,
    'sensibilidadeDROutro': sensibilidadeDROutro,
    // Subtipos
    'subtipoQGBT': subtipoQGBT?.index,
    'subtipoQF': subtipoQF?.index,
    'metodoPadrao': metodoPadrao,
    'subtipoPainel': subtipoPainel?.index,
    'modelo': modelo,
    'fabricante': fabricante,
    'motorReserva': motorReserva,
  };

  factory Carga.fromMap(Map<String, dynamic> m) => Carga(
    id: m['id'],
    descricao: m['descricao'],
    tipo: TipoCarga.values[m['tipo'] ?? 0],
    quantidade: m['quantidade'] ?? 1,
    potenciaNominal: (m['potenciaNominal'] ?? 0).toDouble(),
    ligacao: LigacaoCarga.values[m['ligacao'] ?? 0],
    tensao: (m['tensao'] ?? 220).toDouble(),
    fatorPotencia: (m['fatorPotencia'] ?? 0.92).toDouble(),
    fase: FaseCarga.values[m['fase'] ?? 0],
    notas: m['notas'] ?? '',
    rendimento: (m['rendimento'] ?? 0.90).toDouble(),
    fatorServico: (m['fatorServico'] ?? 1.15).toDouble(),
    correnteNominal: (m['correnteNominal'] ?? 0).toDouble(),
    tipoPartida: TipoPartida.values[m['tipoPartida'] ?? 0],
    regimeServico: m['regimeServico'] ?? 'S1',
    rotacao: (m['rotacao'] ?? 1800).toDouble(),
    capacidadeBtu: (m['capacidadeBtu'] ?? 0).toDouble(),
    quantidadeLuminarias: m['quantidadeLuminarias'] ?? 1,
    tecnologiaLuminaria: TecnologiaLuminaria.values[m['tecnologiaLuminaria'] ?? 0],
    comprimentoRamal: (m['comprimentoRamal'] ?? 20).toDouble(),
    ativo: m['ativo'] ?? true,
    // DR
    utilizaDR: m['utilizaDR'] ?? false,
    sensibilidadeDR: m['sensibilidadeDR'] ?? '30mA',
    sensibilidadeDROutro: (m['sensibilidadeDROutro'] ?? 30).toDouble(),
    // Subtipos
    subtipoQGBT: m['subtipoQGBT'] != null
        ? SubtipoQGBT.values[m['subtipoQGBT']] : null,
    subtipoQF: m['subtipoQF'] != null
        ? SubtipoQF.values[m['subtipoQF']] : null,
    metodoPadrao: m['metodoPadrao'] ?? '',
    subtipoPainel: m['subtipoPainel'] != null
        ? SubtipoPainel.values[m['subtipoPainel']] : null,
    modelo: m['modelo'] ?? '',
    fabricante: m['fabricante'] ?? '',
    motorReserva: m['motorReserva'] ?? false,
  );
}

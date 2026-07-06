// lib/widgets/unifilar_svg_builder.dart
// Gerador de SVG vetorial para Diagrama Unifilar NBR 5410

import '../models/unifilar.dart';

class UnifilarSvgBuilder {
  // ─── Dimensões A4 em pontos (1pt = 1px @ 96dpi → A4 = 794x1123)
  static const double a4w = 794.0;
  static const double a4h = 1123.0;

  // Margens da folha
  static const double margem = 28.0;
  static const double seloH = 110.0;   // Altura do rodapé/selo
  static const double resumoH = 44.0;  // Altura do bloco de resumo

  // Dimensões dos símbolos (em escala 1:1)
  static const double disjtW = 16.0;   // Largura disjuntor
  static const double disjtH = 28.0;   // Altura disjuntor
  static const double drW = 26.0;      // Largura bloco DR
  static const double drH = 16.0;      // Altura bloco DR
  static const double stepH = 36.0;    // Espaçamento entre circuitos
  static const double barW = 6.0;      // Largura do barramento
  static const double colFase = 26.0;  // Largura coluna de fases
  static const double colBarr = 30.0;  // Margem do barramento à esquerda
  static const double wireLen = 70.0;  // Comprimento do fio horizontal após disjuntor+DR

  String build(DiagramaUnifilar d) {
    final bool paisagem = d.orientacao == OrientacaoFolha.paisagem;
    final double W = paisagem ? a4h : a4w;
    final double H = paisagem ? a4w : a4h;
    final double sc = d.escala.clamp(0.5, 2.0);

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${W.toInt()}" height="${H.toInt()}" '
      'viewBox="0 0 $W $H" '
      'font-family="Arial,Helvetica,sans-serif">',
    );

    // Fundo branco
    buf.writeln('<rect width="$W" height="$H" fill="white"/>');

    // Moldura externa
    final r = d.estiloCanto == EstiloCanto.arredondado ? 6.0 : 0.0;
    buf.writeln(
      '<rect x="$margem" y="$margem" '
      'width="${W - 2 * margem}" height="${H - 2 * margem}" '
      'fill="none" stroke="#222" stroke-width="1.5" rx="$r" ry="$r"/>',
    );

    // ── Área útil do desenho ──────────────────────────────────────────────
    final drawX = margem + 8;
    final drawY = margem + 8;
    final drawW = W - 2 * margem - 16;
    final drawH = H - 2 * margem - seloH - 16;

    // ── RESUMO ────────────────────────────────────────────────────────────
    _buildResumo(buf, d, drawX, drawY, drawW, sc);

    // ── AREA DO QUADRO ────────────────────────────────────────────────────
    final quadroY = drawY + resumoH + 8;
    final quadroH = drawH - resumoH - 8;
    _buildAreaQuadro(buf, d, drawX, quadroY, drawW, quadroH, sc);

    // ── RODAPÉ / SELO ─────────────────────────────────────────────────────
    _buildSelo(buf, d, margem, H - margem - seloH, W - 2 * margem, seloH);

    buf.writeln('</svg>');
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RESUMO
  // ─────────────────────────────────────────────────────────────────────────
  void _buildResumo(StringBuffer buf, DiagramaUnifilar d,
      double x, double y, double w, double sc) {
    final kW = d.potenciaDemandadakW;
    final kWStr = kW.toStringAsFixed(2);

    buf.writeln('<text x="${x + w / 2}" y="${y + 12}" '
        'text-anchor="middle" font-size="10" font-weight="bold" fill="#111">'
        'RESUMO DE CARGA INSTALADA ${kWStr}kW (Demandada)</text>');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ÁREA DO QUADRO (caixa tracejada)
  // ─────────────────────────────────────────────────────────────────────────
  void _buildAreaQuadro(StringBuffer buf, DiagramaUnifilar d,
      double ax, double ay, double aw, double ah, double sc) {
    final kVA = d.potenciaTotalkVA.toStringAsFixed(2);

    // Caixa tracejada
    buf.writeln('<rect x="$ax" y="${ay + 16}" '
        'width="$aw" height="${ah - 16}" '
        'fill="none" stroke="#333" stroke-width="1" stroke-dasharray="6,4"/>');

    // Label topo
    buf.writeln('<text x="${ax + aw / 2}" y="${ay + 12}" '
        'text-anchor="middle" font-size="9" font-weight="bold" fill="#333">'
        'ÁREA DO QUADRO — POTÊNCIA TOTAL: ${kVA}KVA</text>');

    // ── Conteúdo interno: coordenadas relativas à caixa ──────────────────
    final innerX = ax + 8;
    final innerY = ay + 28;
    final innerW = aw - 16;

    // Posição X do barramento
    final barrX = innerX + colFase + colBarr;
    // Topo do barramento (abaixo do rótulo "Vem do" + disjuntor geral)
    final barrTop = innerY + 50;
    // Base do barramento (acima da linha de terra)
    final nCirc = d.circuitos.length;
    final barrBot = barrTop + (nCirc.clamp(1, 30) * stepH * sc) + 20;

    // Vem do + alimentador
    _buildVemDo(buf, d, innerX, innerY, barrX, sc);

    // Barramento vertical
    _buildBarramento(buf, d, barrX, barrTop, barrBot, sc);

    // DPS
    if (d.temDPS) {
      _buildDPS(buf, d, barrX, barrTop - 10, sc);
    }

    // Neutro (linha paralela ao barramento)
    if (d.exibirNeutro) {
      final neutroX = barrX - 14;
      buf.writeln('<line x1="$neutroX" y1="$barrTop" '
          'x2="$neutroX" y2="$barrBot" '
          'stroke="#2196F3" stroke-width="1.5" stroke-dasharray="4,2"/>');
      buf.writeln('<text x="${neutroX - 4}" y="${(barrTop + barrBot) / 2}" '
          'text-anchor="end" font-size="7" fill="#2196F3" '
          'transform="rotate(-90,${neutroX - 4},${(barrTop + barrBot) / 2})">N</text>');
    }

    // Circuitos
    for (int i = 0; i < d.circuitos.length; i++) {
      final cy = barrTop + (i * stepH * sc) + 14;
      _buildCircuito(buf, d.circuitos[i], i, barrX, cy, innerW, sc);
    }

    // Terra
    if (d.exibirTerra) {
      _buildTerra(buf, d, innerX, barrBot + 8, barrX, sc);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VEM DO + DISJUNTOR GERAL
  // ─────────────────────────────────────────────────────────────────────────
  void _buildVemDo(StringBuffer buf, DiagramaUnifilar d,
      double x, double y, double barrX, double sc) {
    // Linha de alimentação (de cima para o barramento)
    final midX = barrX;
    buf.writeln('<line x1="$midX" y1="$y" x2="$midX" y2="${y + 44}" '
        'stroke="#111" stroke-width="1.8"/>');

    // Texto "Vem do"
    buf.writeln('<text x="${x + 4}" y="${y + 8}" '
        'font-size="8" fill="#333">'
        '${_escXml(d.vemDo)}</text>');

    // Fases do alimentador (ex: 3F+N+T - #10mm²)
    final fasesLabel = _fasesLabel(d.faseGeral);
    buf.writeln('<text x="${x + 4}" y="${y + 18}" '
        'font-size="7.5" font-weight="bold" fill="#555">'
        '$fasesLabel — #${_fmtBitola(d.caboGeral)}</text>');

    // Disjuntor Geral
    final djX = midX - disjtW / 2;
    final djY = y + 22;
    _drawDisjuntor(buf, djX, djY, d.faseGeral.polos, sc);

    // Rótulo "DISJ. GERAL"
    buf.writeln('<text x="${djX - 4}" y="${djY + 6}" '
        'text-anchor="end" font-size="7" fill="#111" font-weight="bold">DISJ. GERAL</text>');
    buf.writeln('<text x="${djX - 4}" y="${djY + 14}" '
        'text-anchor="end" font-size="7" fill="#333">'
        'Corrente (A): ${d.correnteGeral.toStringAsFixed(0)} A</text>');

    // DR geral (se houver)
    if (d.temDR) {
      final drY = djY + disjtH + 4;
      _drawBlocoDR(buf, midX - drW / 2, drY, sc);
      buf.writeln('<text x="${djX - 4}" y="${drY + 10}" '
          'text-anchor="end" font-size="7" fill="#009688">DR ${d.correnteDR.toStringAsFixed(0)}A</text>');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DISJUNTOR (N traços verticais = polos)
  // ─────────────────────────────────────────────────────────────────────────
  void _drawDisjuntor(StringBuffer buf, double x, double y, int polos, double sc) {
    // Linha principal (fio de cima)
    final cx = x + disjtW / 2;
    buf.writeln('<line x1="$cx" y1="$y" x2="$cx" y2="${y + disjtH * 0.3}" '
        'stroke="#111" stroke-width="1.5"/>');
    // Arco / interrupção (símbolo de chave)
    final arcY = y + disjtH * 0.3;
    buf.writeln('<path d="M $cx ${arcY} L ${cx - 6} ${arcY + disjtH * 0.4}" '
        'stroke="#111" stroke-width="1.5" fill="none"/>');
    // Linha de baixo
    buf.writeln('<line x1="$cx" y1="${arcY + disjtH * 0.5}" x2="$cx" y2="${y + disjtH}" '
        'stroke="#111" stroke-width="1.5"/>');

    // Traços verticais = polos
    final traco0X = cx - ((polos - 1) * 5.0) / 2;
    for (int i = 0; i < polos; i++) {
      final tx = traco0X + i * 5.0;
      final crossY = arcY + disjtH * 0.1;
      buf.writeln('<line x1="$tx" y1="${crossY}" x2="$tx" y2="${crossY + disjtH * 0.25}" '
          'stroke="#111" stroke-width="1.5"/>');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BLOCO DR
  // ─────────────────────────────────────────────────────────────────────────
  void _drawBlocoDR(StringBuffer buf, double x, double y, double sc) {
    buf.writeln('<rect x="$x" y="$y" width="$drW" height="$drH" '
        'fill="white" stroke="#009688" stroke-width="1.2" rx="2"/>');
    buf.writeln('<text x="${x + drW / 2}" y="${y + drH * 0.68}" '
        'text-anchor="middle" font-size="7.5" font-weight="bold" fill="#009688">DR</text>');
    // Fios de conexão (em série)
    final cx = x + drW / 2;
    buf.writeln('<line x1="$cx" y1="${y - 6}" x2="$cx" y2="$y" '
        'stroke="#111" stroke-width="1.2"/>');
    buf.writeln('<line x1="$cx" y1="${y + drH}" x2="$cx" y2="${y + drH + 6}" '
        'stroke="#111" stroke-width="1.2"/>');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BARRAMENTO
  // ─────────────────────────────────────────────────────────────────────────
  void _buildBarramento(StringBuffer buf, DiagramaUnifilar d,
      double x, double yTop, double yBot, double sc) {
    buf.writeln('<line x1="$x" y1="$yTop" x2="$x" y2="$yBot" '
        'stroke="#111" stroke-width="${barW}"/>');

    // Cota do barramento (texto rotacionado 90°, à esquerda)
    if (d.barramento.isNotEmpty) {
      final midY = (yTop + yBot) / 2;
      final cotaX = x - barW / 2 - 22;
      buf.writeln(
        '<text x="$cotaX" y="$midY" '
        'text-anchor="middle" font-size="7" fill="#555" '
        'transform="rotate(-90,$cotaX,$midY)">'
        '${_escXml(d.barramento)}</text>',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DPS
  // ─────────────────────────────────────────────────────────────────────────
  void _buildDPS(StringBuffer buf, DiagramaUnifilar d,
      double barrX, double y, double sc) {
    final dpX = barrX + 20;
    // Fio horizontal do barramento ao DPS
    buf.writeln('<line x1="$barrX" y1="$y" x2="$dpX" y2="$y" '
        'stroke="#111" stroke-width="1.2"/>');
    // Retângulo DPS
    buf.writeln('<rect x="$dpX" y="${y - 8}" width="22" height="16" '
        'fill="white" stroke="#E65100" stroke-width="1.2" rx="2"/>');
    // Símbolo para-raios (seta dentro do retângulo)
    buf.writeln('<polygon points="${dpX + 11},${y - 5} ${dpX + 7},${y + 2} '
        '${dpX + 11},${y + 2} ${dpX + 11},${y + 5} ${dpX + 15},${y - 2} '
        '${dpX + 11},${y - 2}" '
        'fill="#E65100" stroke="none"/>');
    // Linha vertical ao terra
    buf.writeln('<line x1="${dpX + 11}" y1="${y + 8}" x2="${dpX + 11}" y2="${y + 22}" '
        'stroke="#E65100" stroke-width="1.2" stroke-dasharray="3,2"/>');
    // Rótulo DPS
    buf.writeln('<text x="${dpX + 26}" y="${y - 2}" '
        'font-size="7" fill="#E65100" font-weight="bold">DPS</text>');
    buf.writeln('<text x="${dpX + 26}" y="${y + 6}" '
        'font-size="6.5" fill="#E65100">'
        'Cl. II ${d.dpskA.toStringAsFixed(0)}kA ${d.dpsV.toStringAsFixed(0)}V</text>');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TERRA
  // ─────────────────────────────────────────────────────────────────────────
  void _buildTerra(StringBuffer buf, DiagramaUnifilar d,
      double x, double y, double barrX, double sc) {
    // Linha horizontal de terra
    buf.writeln('<line x1="$x" y1="$y" x2="${barrX + 20}" y2="$y" '
        'stroke="#2E7D32" stroke-width="1.5"/>');
    // Símbolo de aterramento (3 traços decrescentes)
    final tx = x + 20;
    for (int i = 0; i < 3; i++) {
      final hw = 14.0 - i * 4.0;
      final ty = y + 6 + i * 5;
      buf.writeln('<line x1="${tx - hw}" y1="$ty" x2="${tx + hw}" y2="$ty" '
          'stroke="#2E7D32" stroke-width="${1.5 - i * 0.3}"/>');
    }
    // Rótulo
    if (d.quadroAterrado) {
      buf.writeln('<text x="${tx + 18}" y="${y + 3}" '
          'font-size="7" fill="#2E7D32" font-weight="bold">TERRA QD</text>');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CIRCUITO individual
  // Ordem: [Fase] → [Disj.] → [DR?] → [#mm²] → [(pot)(V)] → [→] → [CIRC. N - desc]
  // ─────────────────────────────────────────────────────────────────────────
  void _buildCircuito(StringBuffer buf, CircuitoUnifilar c, int idx,
      double barrX, double y, double innerW, double sc) {
    double cx = barrX;

    // Linha de derivação horizontal do barramento
    buf.writeln('<line x1="$cx" y1="$y" x2="${cx + wireLen + 60}" y2="$y" '
        'stroke="#111" stroke-width="1.2"/>');

    // Ponto de conexão ao barramento (pequeno círculo)
    buf.writeln('<circle cx="$cx" cy="$y" r="2.5" fill="#111"/>');

    // ── Fase (letra, cor por fase) ──────────────────────────────────────
    cx += 8;
    final faseColor = _faseColor(c.fase);
    buf.writeln('<text x="$cx" y="${y - 4}" '
        'font-size="8" font-weight="bold" fill="$faseColor">'
        '${_escXml(c.fase.label)}</text>');

    // ── Disjuntor (polos = fase.polos) ──────────────────────────────────
    cx = barrX + 20;
    _drawDisjuntor(buf, cx - disjtW / 2, y - disjtH / 2, c.fase.polos, sc);
    // Corrente + curva
    buf.writeln('<text x="${cx}" y="${y - disjtH / 2 - 3}" '
        'text-anchor="middle" font-size="6.5" fill="#111">'
        '${c.corrente.toStringAsFixed(0)}A (${c.curva.label})</text>');

    cx = barrX + 40;

    // ── DR (se houver) ───────────────────────────────────────────────────
    if (c.utilizaDR) {
      _drawBlocoDR(buf, cx, y - drH / 2, sc);
      cx += drW + 6;
    }

    // ── Bitola ───────────────────────────────────────────────────────────
    buf.writeln('<text x="$cx" y="${y - 3}" '
        'font-size="7.5" fill="#1A237E" font-weight="bold">'
        '#${_fmtBitola(c.bitola)}mm²</text>');
    cx += 32;

    // ── Potência (tensão) ─────────────────────────────────────────────────
    final potStr = _fmtPotencia(c.potencia, c.unidadePotencia);
    final tensStr = '${c.tensao.toStringAsFixed(0)}V';
    buf.writeln('<text x="$cx" y="${y - 3}" '
        'font-size="7.5" fill="#4A148C">'
        '($potStr) ($tensStr)</text>');
    cx += 70;

    // ── Seta ──────────────────────────────────────────────────────────────
    buf.writeln('<polygon points="$cx,${y - 4} ${cx + 6},${y} $cx,${y + 4}" '
        'fill="#555"/>');
    cx += 10;

    // ── Código + Descrição ────────────────────────────────────────────────
    final label = '${_escXml(c.codigo)} — ${_escXml(c.descricao)}';
    buf.writeln('<text x="$cx" y="${y + 3}" '
        'font-size="8" fill="#111" font-weight="bold">'
        '$label</text>');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RODAPÉ / SELO A4
  // ─────────────────────────────────────────────────────────────────────────
  void _buildSelo(StringBuffer buf, DiagramaUnifilar d,
      double x, double y, double w, double h) {
    // Linha divisória superior do selo
    buf.writeln('<line x1="$x" y1="$y" x2="${x + w}" y2="$y" '
        'stroke="#222" stroke-width="1"/>');

    // Divisão colunas (logo | info projeto | dados direita)
    final colLogo = w * 0.15;
    final colDados = w * 0.18;
    final colMid = w - colLogo - colDados;

    // Coluna logo (esquerda)
    buf.writeln('<rect x="$x" y="$y" width="$colLogo" height="$h" '
        'fill="#F5F5F5" stroke="none"/>');
    buf.writeln('<text x="${x + colLogo / 2}" y="${y + h / 2 + 4}" '
        'text-anchor="middle" font-size="8" fill="#999">LOGO</text>');
    buf.writeln('<line x1="${x + colLogo}" y1="$y" x2="${x + colLogo}" y2="${y + h}" '
        'stroke="#666" stroke-width="0.8"/>');

    // Coluna central (nome projeto + cliente)
    final midX = x + colLogo;
    // Nome do projeto (destaque)
    buf.writeln('<text x="${midX + colMid / 2}" y="${y + 16}" '
        'text-anchor="middle" font-size="11" font-weight="bold" fill="#111">'
        '${_escXml(d.nomeProjeto)}</text>');
    // Linha separadora
    buf.writeln('<line x1="$midX" y1="${y + 22}" x2="${midX + colMid}" y2="${y + 22}" '
        'stroke="#CCC" stroke-width="0.5"/>');
    // Bloco informações cliente
    buf.writeln('<text x="${midX + 6}" y="${y + 32}" '
        'font-size="7.5" font-weight="bold" fill="#555">INFORMAÇÕES DO CLIENTE</text>');
    buf.writeln('<text x="${midX + 6}" y="${y + 43}" '
        'font-size="7.5" fill="#333">${_escXml(d.clienteNome)}</text>');
    buf.writeln('<text x="${midX + 6}" y="${y + 53}" '
        'font-size="7" fill="#555">Doc.: ${_escXml(d.clienteDocumento)}</text>');
    buf.writeln('<text x="${midX + 6}" y="${y + 62}" '
        'font-size="7" fill="#555">${_escXml(d.clienteEndereco)}</text>');
    buf.writeln('<text x="${midX + 6}" y="${y + 71}" '
        'font-size="7" fill="#555">'
        'Tel.: ${_escXml(d.clienteTelefone)}  E-mail: ${_escXml(d.clienteEmail)}</text>');

    // Coluna direita (DATA / PÁGINA / Nº DOC / REVISÃO)
    final rightX = x + w - colDados;
    buf.writeln('<line x1="$rightX" y1="$y" x2="$rightX" y2="${y + h}" '
        'stroke="#666" stroke-width="0.8"/>');

    final cellH = h / 4;
    final labels = ['DATA', 'PÁGINA', 'Nº DOCUMENTO', 'REVISÃO'];
    final values = [
      d.data,
      '1 / 1',
      d.numeroDocumento,
      d.revisao.toString(),
    ];
    for (int i = 0; i < 4; i++) {
      final cy = y + i * cellH;
      if (i > 0) {
        buf.writeln('<line x1="$rightX" y1="$cy" x2="${x + w}" y2="$cy" '
            'stroke="#CCC" stroke-width="0.5"/>');
      }
      buf.writeln('<text x="${rightX + 4}" y="${cy + 9}" '
          'font-size="6.5" fill="#888">${labels[i]}</text>');
      buf.writeln('<text x="${rightX + colDados / 2}" y="${cy + cellH * 0.7}" '
          'text-anchor="middle" font-size="${i == 3 ? 14 : 9}" '
          'font-weight="bold" fill="#111">${_escXml(values[i])}</text>');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  String _escXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _fmtBitola(double b) {
    if (b == b.truncateToDouble()) return b.toInt().toString();
    return b.toString();
  }

  String _fmtPotencia(double v, UnidadePotencia u) {
    if (v >= 1000 && (u == UnidadePotencia.va || u == UnidadePotencia.w)) {
      return '${(v / 1000).toStringAsFixed(1)} k${u.label[0]}';
    }
    if (v == v.truncateToDouble()) return '${v.toInt()} ${u.label}';
    return '${v.toStringAsFixed(1)} ${u.label}';
  }

  String _faseColor(FaseUnifilar f) {
    switch (f) {
      case FaseUnifilar.r:   return '#EF5350';
      case FaseUnifilar.s:   return '#42A5F5';
      case FaseUnifilar.t:   return '#66BB6A';
      case FaseUnifilar.rs:  return '#FF7043';
      case FaseUnifilar.rt:  return '#AB47BC';
      case FaseUnifilar.st:  return '#26C6DA';
      case FaseUnifilar.rst: return '#111111';
    }
  }

  String _fasesLabel(FaseUnifilar f) {
    switch (f) {
      case FaseUnifilar.r:   return '1F';
      case FaseUnifilar.s:   return '1F';
      case FaseUnifilar.t:   return '1F';
      case FaseUnifilar.rs:  return '2F';
      case FaseUnifilar.rt:  return '2F';
      case FaseUnifilar.st:  return '2F';
      case FaseUnifilar.rst: return '3F+N+T';
    }
  }
}

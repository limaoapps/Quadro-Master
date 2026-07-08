// lib/widgets/unifilar_svg_builder.dart
// Gerador SVG vetorial — Diagrama Unifilar NBR 5444 / NBR 5410
// Session 10 — Reconstrução FIEL ao PDF de referência (medidas extraídas via PyMuPDF)
//
// MEDIDAS EXATAS DO PDF (595.32 × 841.92 pts):
//   Barramento: x=164.07, y=130.54..550.67, width=1.38
//   Caixa quadro: rect[88.26,111.0 .. 250.70,570.22], dashed, width=0.69
//   Espaçamento entre circuitos: 29.31 pts
//   Primeiro circuito: y=150.97 (fio de saída)
//   Fio entrada (barr->disj): x=165.61..191.54, width=0.46
//   Fio saída (disj->fim): x=211.71..368.27, width=0.46
//   Polo barramento (círculo preenchido): x_center=164.07, r≈1.545, y_center=fio_y
//   Polo disjuntor (círculo aberto): x=191.54..194.63, raio≈1.545, y=fio_y
//     polo 2: x=208.63..211.71, raio≈1.545
//   Arco disjuntor: x=193.93..209.41, y=142.82..148.27 (Bezier 2-segmentos)
//   Traços verticais: x=199.83, 201.76, 203.69; y=141.70..146.68 (largura=0.46)
//   Posições de texto:
//     Fase R/S/T: x=170.3, y=circ_y-3.8 (acima do fio)
//     Corrente:   x=189.3, y=circ_y-2.8 (entre disj e polo)
//     Bitola:     x=267.8, y=circ_y-8.0 (acima fio saída)
//     Potência:   x=331.8..336, y=circ_y+8.0 (abaixo fio saída)
//     Descrição:  x=373.0, y=circ_y+2.5 (após fio)
//   Aterramento: x=243.31, y=570.21..584.56 (3 traços decrescentes)
//   Rodapé (bloco de título):
//     Linha top:   y=681.34
//     Linha título/corpo: y=709.54 (separador horizontal)
//     Col 1 (logo): x=15.36..132.62
//     Col 2 (info): x=132.62..387.43
//       Sub: x=191.66 (rótulo|valor)
//     Col 3 (data): x=387.43..521.14
//       Sub: x=476.02 (data|página)
//     Col 4 (rev):  x=520.30..580.20
//     Linha inferior: y=789.36
//     Linha base:     y=790.20
//     Linha "Nº doc": y=749.52

import '../models/unifilar.dart';

class UnifilarSvgBuilder {
  // ─── Dimensões A4 (595.32 × 841.92 → arredondamos para 595 × 842)
  static const double pgW = 595.0;
  static const double pgH = 842.0;

  // ─── Moldura (bordas finas que delimitam a folha)
  // No PDF: retângulos finos de 0.84pt de largura
  static const double bL = 15.36;   // borda esquerda x
  static const double bR = 580.20;  // borda direita x
  static const double bT = 14.52;   // borda topo y
  static const double bB = 790.20;  // borda base y

  // ─── Barramento vertical principal
  static const double barrX  = 164.07;  // posição X do barramento
  static const double barrY0 = 130.54;  // topo do barramento
  // barrY1 = calculado dinamicamente (y do último circuito + margem)

  // ─── Caixa tracejada do quadro
  static const double caixaL  = 88.26;   // left
  static const double caixaT  = 111.0;   // top
  static const double caixaR  = 250.70;  // right
  // caixaB calculado dinamicamente

  // ─── Circuitos — posições fixas do PDF
  static const double y0Circ  = 150.97;  // Y do fio do 1º circuito
  static const double stepY   = 29.31;   // espaçamento entre circuitos

  // Fio entrada (barramento → disjuntor)
  static const double fioEntX0 = 165.61;  // começa logo após o polo do barramento
  static const double fioEntX1 = 191.54;  // termina no polo do disjuntor (esq)

  // Polo do disjuntor esquerdo (abertura da chave)
  static const double poloEsqX0 = 191.54;
  static const double poloEsqX1 = 194.63;
  static const double poloR = 1.545;  // raio dos polos

  // Polo do disjuntor direito
  static const double poloDirX0 = 208.63;
  static const double poloDirX1 = 211.71;

  // Fio saída (disjuntor → fim)
  static const double fioSaiX0 = 211.71;
  static const double fioSaiX1 = 368.27;

  // Arco do disjuntor (bezier 2-partes, medido do PDF)
  // Pontos exatos: M(193.93, cy-dy)  C(196.13,peak),(201.36,peak),(205.61,cy-dy2)
  //                C(207.26,cy-dy3),(208.59,cy-dy4),(209.41,cy)
  // Onde cy = y do fio no PDF = 151.19 (y=fio_y+0.22, centro do polo)
  // arc_top_y = 142.82 → delta = 151.19 - 142.82 = 8.37 acima do centro
  static const double arcX0  = 193.93;  // x início do arco
  static const double arcX3  = 209.41;  // x fim do arco
  static const double arcH   = 8.37;    // altura máxima do arco acima do centro do fio

  // Traços verticais do disjuntor (dentro do arco, ligando ao polo)
  // PDF: x=199.83, 201.76, 203.69; de y=141.70 a y=146.68
  // Offsets relativos ao centro do circuito (y_fio):
  static const double traco1X = 199.83;
  static const double traco2X = 201.76;
  static const double traco3X = 203.69;
  static const double tracoY0delta = 9.49;  // 151.19 - 141.70
  static const double tracoY1delta = 4.51;  // 151.19 - 146.68

  // Bitola (acima do fio de saída, entre disjuntor e fim)
  static const double bitolaX = 267.8;  // x fixo medido do PDF
  static const double bitolaYdelta = 8.0;  // acima do fio

  // Potência (abaixo do fio de saída)
  static const double potenciaXrst  = 331.8;  // x para correntes altas
  static const double potenciaXmono = 336.0;  // x para correntes baixas
  static const double potenciaYdelta = 8.0;   // abaixo do fio

  // Descrição do circuito (à direita do fio)
  static const double descX      = 373.0;
  static const double descYdelta = 2.5;  // abaixo do fio

  // Corrente do disjuntor (acima do fio, entre polo esq e polo dir)
  static const double correnteX     = 189.3;
  static const double correnteYdelta = 8.0;  // acima do fio

  // Fase (à esquerda, acima do fio)
  static const double faseX        = 170.3;
  static const double faseXmono    = 177.3;  // para monofásico
  static const double faseYdelta   = 3.8;    // acima do fio

  // Polo do barramento (círculo preenchido no barramento)
  // centro em (barrX, fio_y) — medido: x=162.52..165.61 → centro=164.07
  // y do polo = y_fio + 0.22 (fio_ent_y = fio_y + 0.22 no PDF)
  static const double poloBarrR = 1.545;

  // ─── DR — retângulo diferencial residual
  // No PDF circ 13: rect ligeiramente à direita do fio saída
  // x=225.92 (fioSaiX0+14.21), y=496.4 (circ y=502.72 → dy=-6.32 → cy-6.32)
  // size=14×12.6
  static const double drW = 14.0;
  static const double drH = 12.6;
  static const double drOffX = 14.0;  // offset desde fioSaiX0

  // ─── Aterramento (medido do PDF: x=243.31, y=570.21..584.56)
  // No PDF: linha vertical de x=243.31, y=570.21..581.73 (width=0.46)
  //         traço 1: x=235.92..250.70, y=581.73
  //         traço 2: x=239.12..247.50, y=583.14
  //         traço 3: x=241.21..245.40, y=584.56
  static const double aterX    = 243.31;
  // aterY0 = barrY1 calculado

  // ─── Rodapé / Bloco de Título
  static const double seloTopY   = 681.34;   // linha superior do bloco
  static const double seloTitY   = 709.54;   // linha separadora título/corpo
  static const double seloBaseY  = 789.36;   // linha inferior do corpo
  static const double seloFimY   = 790.20;   // borda inferior
  static const double seloNumDocY = 749.52;  // linha separadora N° doc

  // Colunas verticais do rodapé
  static const double seloX1    = 15.36;    // início (= bL)
  static const double seloX2    = 132.62;   // col logo | info cliente
  static const double seloX2sub = 191.66;   // sub-col rótulo|valor dentro da col2
  static const double seloX3    = 387.43;   // col info | data/página
  static const double seloX3sub = 476.02;   // sub-col data|página
  static const double seloX4    = 520.30;   // col data/página | revisão
  static const double seloX5    = 580.20;   // fim (= bR)

  // ─────────────────────────────────────────────────────────────────────────────
  /// Ponto de entrada: gera a string SVG completa do diagrama
  // ─────────────────────────────────────────────────────────────────────────────
  String build(DiagramaUnifilar d) {
    final bool paisagem = d.orientacao == OrientacaoFolha.paisagem;
    final double W = paisagem ? pgH : pgW;
    final double H = paisagem ? pgW : pgH;
    final double sc = d.escala.clamp(0.5, 1.5);

    final int n = d.circuitos.length;
    // Y do último fio
    final double yLast = n > 0
        ? y0Circ + (n - 1) * stepY * sc
        : y0Circ;
    // Bottom do barramento e da caixa
    final double barrY1 = yLast + 20.0;
    final double caixaB  = barrY1 + 30.0;

    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.write('<svg xmlns="http://www.w3.org/2000/svg" ');
    buf.write('width="${W.toStringAsFixed(0)}" ');
    buf.write('height="${H.toStringAsFixed(0)}" ');
    buf.write('viewBox="0 0 $W $H" ');
    buf.writeln('font-family="Arial,Helvetica,sans-serif">');

    // Fundo branco
    buf.writeln('<rect width="$W" height="$H" fill="white"/>');

    // 1. Moldura
    _buildBorda(buf, W, H);

    // 2. Topo: VEM DO + cabo geral + potência
    _buildTopo(buf, d, sc);

    // 3. Caixa tracejada do quadro
    _buildCaixaQuadro(buf, caixaB);

    // 4. Barramento vertical
    buf.writeln(
      '<line x1="$barrX" y1="$barrY0" x2="$barrX" y2="$barrY1" '
      'stroke="#000" stroke-width="1.38" stroke-linecap="square"/>',
    );

    // 5. Aterramento na base do barramento
    if (d.exibirTerra) {
      _buildAterramento(buf, barrY1 + 2.0);
    }

    // 6. Circuitos
    for (int i = 0; i < n; i++) {
      final cy = y0Circ + i * stepY * sc;
      _buildCircuito(buf, d.circuitos[i], i + 1, cy, sc, d);
    }

    // 7. Rodapé
    _buildSelo(buf, d, W, H);

    buf.writeln('</svg>');
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Moldura externa (4 linhas que delimitam a folha)
  // No PDF: 4 retângulos fill pretos de 0.84pt de largura
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildBorda(StringBuffer buf, double W, double H) {
    // Linhas finas ao redor da folha (simula as barras de 0.84pt do PDF)
    final s = 'stroke="#000" stroke-width="0.84" fill="none"';
    buf.writeln('<line x1="$bL" y1="$bT" x2="$bL" y2="$bB" $s/>');       // esq
    buf.writeln('<line x1="${W - (bR - pgW).abs()}" y1="$bT" x2="${W - (bR - pgW).abs()}" y2="$bB" $s/>'); // dir
    buf.writeln('<line x1="$bL" y1="$bT" x2="$bR" y2="$bT" $s/>');       // topo
    buf.writeln('<line x1="$bL" y1="$bB" x2="$bR" y2="$bB" $s/>');       // base
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Topo: "VEM DO...", cabo geral, potência total, 63A/#10
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildTopo(StringBuffer buf, DiagramaUnifilar d, double sc) {
    // Potência total — acima da caixa, lado esquerdo
    final kva = d.potenciaTotalkVA.toStringAsFixed(2);
    buf.writeln(
      '<text x="91" y="122" text-anchor="middle" '
      'font-size="8" font-weight="bold" fill="#000">'
      '(${_esc(kva)}KVA)</text>',
    );

    // Cabo geral — texto horizontal, acima e à direita do barramento
    buf.writeln(
      '<text x="${barrX + 4}" y="126" '
      'font-size="7" fill="#000">'
      'COBRE ${_esc(d.caboGeral.toStringAsFixed(0))} x 30mm</text>',
    );

    // Corrente geral e disjuntor geral — à esquerda do barramento
    final corrStr = d.correnteGeral.toStringAsFixed(0);
    buf.writeln(
      '<text x="${barrX - 5}" y="319" '
      'text-anchor="end" font-size="8" font-weight="bold" fill="#000">'
      '${_esc(corrStr)}A</text>',
    );
    buf.writeln(
      '<text x="${barrX - 5}" y="330" '
      'text-anchor="end" font-size="7" fill="#000">'
      '#${_fmtBitola(d.caboGeral)}</text>',
    );

    // VEM DO — texto vertical à esquerda (rotacionado -90°)
    // No PDF: x=50.1, y=395.0 (texto vertical "VEM DO Subestação Convention")
    final vemDo = _esc(d.vemDo);
    buf.writeln(
      '<text font-size="7" fill="#000" '
      'transform="rotate(-90 50 395)" '
      'x="50" y="395" text-anchor="middle">$vemDo</text>',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Caixa tracejada do quadro (strokeDashArray)
  // No PDF: rect[88.26, 111.0] .. [250.70, 570.22+], stroke-dash, width=0.69
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildCaixaQuadro(StringBuffer buf, double caixaB) {
    buf.writeln(
      '<rect x="$caixaL" y="$caixaT" '
      'width="${caixaR - caixaL}" height="${caixaB - caixaT}" '
      'fill="none" stroke="#000" stroke-width="0.69" stroke-dasharray="4 2"/>',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CIRCUITO individual — layout exato do PDF
  //
  // Para cada circuito (linha y = cy):
  //   a) Círculo preenchido no barramento (derivação)
  //   b) Fio horizontal: barrX → 191.54 (fio de entrada)
  //   c) Polo esquerdo do disjuntor (círculo aberto): cx=193.09, r=1.545
  //   d) Arco do disjuntor (curva bezier)
  //   e) Traços verticais dos polos (3 para trifásico)
  //   f) Polo direito do disjuntor (círculo aberto): cx=210.17, r=1.545
  //   g) Fio de saída: 211.71 → 368.27
  //   h) DR (se houver): retângulo sobre o fio
  //   i) Bitola (#mm²) acima do fio de saída
  //   j) Texto da fase (R/S/T) acima
  //   k) Corrente (25A C) acima do fio de entrada
  //   l) Potência abaixo do fio de saída
  //   m) Descrição à direita
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildCircuito(StringBuffer buf, CircuitoUnifilar c, int num,
      double cy, double sc, DiagramaUnifilar d) {
    // Centro real do fio (o PDF usa y+0.22 para o centro dos polos)
    final double fy = cy;  // Y do fio horizontal

    // a) Círculo preenchido no barramento (derivação)
    // No PDF: type=fs (filled), centro em (164.07, polo_y), r=1.545
    buf.writeln(
      '<circle cx="$barrX" cy="$fy" r="$poloBarrR" fill="#000" stroke="#000" stroke-width="0.46"/>',
    );

    // b) Fio de entrada: barrX → polo esq do disjuntor
    final double poloEsqCx = (poloEsqX0 + poloEsqX1) / 2;  // 193.085
    buf.writeln(
      '<line x1="${barrX + poloBarrR}" y1="$fy" x2="${poloEsqX0}" y2="$fy" '
      'stroke="#000" stroke-width="0.46"/>',
    );

    // c) Polo esquerdo do disjuntor (círculo aberto)
    buf.writeln(
      '<circle cx="$poloEsqCx" cy="$fy" r="$poloR" '
      'fill="white" stroke="#000" stroke-width="0.46"/>',
    );

    // d) Polo direito do disjuntor (círculo aberto)
    final double poloDirCx = (poloDirX0 + poloDirX1) / 2;  // 210.17
    buf.writeln(
      '<circle cx="$poloDirCx" cy="$fy" r="$poloR" '
      'fill="white" stroke="#000" stroke-width="0.46"/>',
    );

    // e) Arco do disjuntor (Bezier exato do PDF)
    // Ponto de início: (193.93, cy - 3.06) — topo do polo esq
    // Ponto de fim:   (209.41, cy - 0.91) — topo do polo dir (levemente assimétrico)
    // Pico: ~(201.36, cy - arcH)
    // Offsets exatos medidos do PDF (circ 1 y_fio=151.19):
    //   inicio: (193.93, 148.13) delta=3.06; pico: (201.36, 142.82) delta=8.37
    //   fim: (209.41, 148.27) delta=2.92
    final double arcX0v  = 193.93;  final double arcY0v  = fy - 3.06;
    final double arcCx1  = 196.13;  final double arcCy1  = fy - 6.87;
    final double arcCx2  = 201.36;  final double arcCy2  = fy - 8.37;
    final double arcX1v  = 205.61;  final double arcY1v  = fy - 6.39;
    final double arcCx3  = 207.26;  final double arcCy3  = fy - 5.63;
    final double arcCx4  = 208.59;  final double arcCy4  = fy - 4.41;
    final double arcX3v  = 209.41;  final double arcY3v  = fy - 2.92;

    buf.writeln(
      '<path d="M ${_f(arcX0v)} ${_f(arcY0v)} '
      'C ${_f(arcCx1)} ${_f(arcCy1)}, ${_f(arcCx2)} ${_f(arcCy2)}, ${_f(arcX1v)} ${_f(arcY1v)} '
      'C ${_f(arcCx3)} ${_f(arcCy3)}, ${_f(arcCx4)} ${_f(arcCy4)}, ${_f(arcX3v)} ${_f(arcY3v)}" '
      'stroke="#000" stroke-width="0.46" fill="none"/>',
    );

    // f) Traços verticais dos polos (PDF: x=199.83, 201.76, 203.69; len=4.98)
    // Esses traços ligam o arco ao fio de entrada
    // No PDF: de y=141.70 (cy-9.49) a y=146.68 (cy-4.51)
    final double tyTop = fy - tracoY0delta;
    final double tyBot = fy - tracoY1delta;
    final int numTracos = c.fase.polos == 3 ? 3 : (c.fase.polos == 2 ? 2 : 1);
    final List<double> tracosXs;
    if (numTracos == 3) {
      tracosXs = [traco1X, traco2X, traco3X];
    } else if (numTracos == 2) {
      tracosXs = [traco2X - 1.0, traco3X];
    } else {
      tracosXs = [traco2X];
    }
    for (final tx in tracosXs) {
      buf.writeln(
        '<line x1="${_f(tx)}" y1="${_f(tyTop)}" x2="${_f(tx)}" y2="${_f(tyBot)}" '
        'stroke="#000" stroke-width="0.46"/>',
      );
    }

    // g) Fio de saída: polo dir → fim
    buf.writeln(
      '<line x1="${fioSaiX0}" y1="$fy" x2="${fioSaiX1}" y2="$fy" '
      'stroke="#000" stroke-width="0.46"/>',
    );

    // h) DR (se houver)
    if (c.utilizaDR) {
      final double drX = fioSaiX0 + drOffX;
      final double drY = fy - drH / 2;
      buf.writeln(
        '<rect x="${_f(drX)}" y="${_f(drY)}" width="$drW" height="$drH" '
        'fill="white" stroke="#000" stroke-width="0.46"/>',
      );
      buf.writeln(
        '<text x="${_f(drX + drW / 2)}" y="${_f(fy + 2.5)}" '
        'text-anchor="middle" font-size="6" fill="#000">DR</text>',
      );
    }

    // i) Bitola (#mm²) acima do fio de saída
    // No PDF: x=267.8, y=circ_y - 8.0
    buf.writeln(
      '<text x="${_f(bitolaX)}" y="${_f(fy - bitolaYdelta)}" '
      'text-anchor="middle" font-size="7" fill="#000">'
      '#${_fmtBitola(c.bitola)}mm${_sup2()}</text>',
    );

    // j) Fase (acima, à esquerda)
    // No PDF: R/S/T → x=170.3, y=circ_y-3.8
    //         R solo → x=177.3 (um pouco mais para direita)
    final bool mono = c.fase.polos == 1;
    final double fX = mono ? faseXmono : faseX;
    final String fLabel = _escFase(c.fase);
    final String fColor = _faseColor(c.fase);
    buf.writeln(
      '<text x="${_f(fX)}" y="${_f(fy - faseYdelta)}" '
      'font-size="7" font-weight="bold" fill="$fColor">'
      '$fLabel</text>',
    );

    // k) Corrente do disjuntor (acima, entre os polos)
    // No PDF: x=189.3, y=circ_y - 8.0 (acima do fio de entrada)
    final corrStr = '${c.corrente.toStringAsFixed(0)}A (${_esc(c.curva.label)})';
    buf.writeln(
      '<text x="${_f(correnteX)}" y="${_f(fy - correnteYdelta)}" '
      'font-size="7" fill="#000">'
      '$corrStr</text>',
    );

    // l) Potência (abaixo do fio de saída)
    // No PDF: R/S/T → x=331.8, mono/bi → x=336.0; y=circ_y+8.0
    final double potX = c.fase.polos == 3 ? potenciaXrst : potenciaXmono;
    final String potStr = _fmtPotencia(c.potencia, c.unidadePotencia);
    buf.writeln(
      '<text x="${_f(potX)}" y="${_f(fy + potenciaYdelta)}" '
      'text-anchor="middle" font-size="7" fill="#000">'
      '($potStr)</text>',
    );

    // m) Descrição à direita (após o fim do fio)
    // No PDF: x=373.0, y=circ_y+2.5
    final desc = _esc(c.descricao.isEmpty ? '(sem descricao)' : c.descricao);
    buf.writeln(
      '<text x="${_f(descX)}" y="${_f(fy + descYdelta)}" '
      'font-size="7" fill="#000">$desc</text>',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Aterramento — fiel ao PDF
  // PDF: x=243.31 (entre barra e caixa direita)
  //   linha vertical: y=570.21..581.73 (width=0.46)
  //   traço 1 (largo):  x=235.92..250.70, y=581.73 (w=14.78)
  //   traço 2 (médio):  x=239.12..247.50, y=583.14 (w=8.38)
  //   traço 3 (curto):  x=241.21..245.40, y=584.56 (w=4.19)
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildAterramento(StringBuffer buf, double y0) {
    // Linha vertical
    buf.writeln(
      '<line x1="$aterX" y1="$y0" x2="$aterX" y2="${y0 + 11.5}" '
      'stroke="#000" stroke-width="0.46"/>',
    );
    // Traço 1 (largura 14.78)
    buf.writeln(
      '<line x1="${aterX - 7.39}" y1="${y0 + 11.5}" x2="${aterX + 7.39}" y2="${y0 + 11.5}" '
      'stroke="#000" stroke-width="0.46"/>',
    );
    // Traço 2 (largura 8.38)
    buf.writeln(
      '<line x1="${aterX - 4.19}" y1="${y0 + 12.9}" x2="${aterX + 4.19}" y2="${y0 + 12.9}" '
      'stroke="#000" stroke-width="0.46"/>',
    );
    // Traço 3 (largura 4.19)
    buf.writeln(
      '<line x1="${aterX - 2.1}" y1="${y0 + 14.3}" x2="${aterX + 2.1}" y2="${y0 + 14.3}" '
      'stroke="#000" stroke-width="0.46"/>',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RODAPÉ / BLOCO DE TÍTULO (selo técnico)
  // Layout fiel ao PDF com colunas medidas exatamente
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildSelo(StringBuffer buf, DiagramaUnifilar d, double W, double H) {
    // ── Linhas horizontais do bloco ──
    // Linha superior do bloco
    buf.writeln('<line x1="$seloX1" y1="$seloTopY" x2="$seloX5" y2="$seloTopY" stroke="#000" stroke-width="0.84"/>');
    // Linha separadora título/corpo
    buf.writeln('<line x1="$seloX2" y1="$seloTitY" x2="$seloX5" y2="$seloTitY" stroke="#000" stroke-width="0.84"/>');
    // Linha separadora Nº documento (só nas colunas 3 e 4)
    buf.writeln('<line x1="$seloX3" y1="$seloNumDocY" x2="$seloX4" y2="$seloNumDocY" stroke="#000" stroke-width="0.84"/>');
    // Linha inferior
    buf.writeln('<line x1="$seloX1" y1="$seloBaseY" x2="$seloX5" y2="$seloBaseY" stroke="#000" stroke-width="0.84"/>');

    // ── Linhas verticais do bloco ──
    // Col logo | info cliente
    buf.writeln('<line x1="$seloX2" y1="$seloTopY" x2="$seloX2" y2="$seloBaseY" stroke="#000" stroke-width="0.84"/>');
    // Sub-col rótulo|valor dentro da col2 (só do título/corpo para baixo)
    buf.writeln('<line x1="$seloX2sub" y1="$seloTitY" x2="$seloX2sub" y2="$seloBaseY" stroke="#000" stroke-width="0.84"/>');
    // Col info | data
    buf.writeln('<line x1="$seloX3" y1="$seloTitY" x2="$seloX3" y2="$seloBaseY" stroke="#000" stroke-width="0.84"/>');
    // Sub-col data | página
    buf.writeln('<line x1="$seloX3sub" y1="$seloTitY" x2="$seloX3sub" y2="$seloNumDocY" stroke="#000" stroke-width="0.84"/>');
    // Col data/página | revisão
    buf.writeln('<line x1="$seloX4" y1="$seloTitY" x2="$seloX4" y2="$seloBaseY" stroke="#000" stroke-width="0.84"/>');

    // ── TÍTULO do diagrama (faixa superior do bloco, centralizado entre col2 e col4) ──
    final double titMidX = (seloX2 + seloX4) / 2;
    final double titMidY = seloTopY + (seloTitY - seloTopY) / 2 + 4;
    buf.writeln(
      '<text x="${_f(titMidX)}" y="${_f(titMidY)}" '
      'text-anchor="middle" font-size="9" font-weight="bold" fill="#000">'
      '${_esc(d.nomeProjeto)}</text>',
    );

    // ── COL 1: LOGO ──
    // Fundo cinza claro
    buf.writeln(
      '<rect x="$seloX1" y="$seloTitY" '
      'width="${seloX2 - seloX1}" height="${seloBaseY - seloTitY}" '
      'fill="#F0F0F0"/>',
    );
    // Texto LOGO centralizado
    final double logoMidX = (seloX1 + seloX2) / 2;
    final double logoMidY = seloTitY + (seloBaseY - seloTitY) / 2 + 4;
    buf.writeln(
      '<text x="${_f(logoMidX)}" y="${_f(logoMidY)}" '
      'text-anchor="middle" font-size="9" fill="#888">LOGO</text>',
    );

    // ── COL 2: INFO DO CLIENTE (com sub-colunas) ──
    // Rótulos na sub-col esquerda, valores na sub-col direita
    // No PDF: y=709.54 (topo corpo), 6 linhas de info espaçadas ≈11.3pt
    double iy = seloTitY + 12;
    final double rotX = seloX2 + 3;
    final double valX = seloX2sub + 3;
    _seloLinha(buf, rotX, valX, iy, 'NOME:', _esc(d.clienteNome));
    iy += 11;
    _seloLinha(buf, rotX, valX, iy, 'No.DOC:', _esc(d.numeroDocumento));
    iy += 11;
    _seloLinha(buf, rotX, valX, iy, 'CNPJ/CPF:', _esc(d.clienteDocumento));
    iy += 11;
    _seloLinha(buf, rotX, valX, iy, 'ENDERECO:', _esc(d.clienteEndereco.length > 35
        ? '${d.clienteEndereco.substring(0, 35)}...' : d.clienteEndereco));
    iy += 11;
    _seloLinha(buf, rotX, valX, iy, 'FONE:', _esc(d.clienteTelefone));
    iy += 11;
    _seloLinha(buf, rotX, valX, iy, 'E-MAIL:', _esc(d.clienteEmail));

    // ── COL 3: DATA | PÁGINA ──
    final double dataMidX  = (seloX3 + seloX3sub) / 2;
    final double pagMidX   = (seloX3sub + seloX4) / 2;

    // Cabeçalho "DATA" e "PAGINA"
    buf.writeln('<text x="${_f(dataMidX)}" y="${_f(seloTitY + 9)}" '
        'text-anchor="middle" font-size="6" fill="#888">DATA</text>');
    buf.writeln('<text x="${_f(pagMidX)}" y="${_f(seloTitY + 9)}" '
        'text-anchor="middle" font-size="6" fill="#888">PAGINA</text>');

    // Valores
    buf.writeln('<text x="${_f(dataMidX)}" y="${_f(seloTitY + 22)}" '
        'text-anchor="middle" font-size="8" font-weight="bold" fill="#000">'
        '${_esc(d.data)}</text>');
    buf.writeln('<text x="${_f(pagMidX)}" y="${_f(seloTitY + 22)}" '
        'text-anchor="middle" font-size="10" font-weight="bold" fill="#000">1/1</text>');

    // Abaixo da linha seloNumDocY: N° documento
    final double ndocMidX = (seloX3 + seloX4) / 2;
    buf.writeln('<text x="${_f(ndocMidX)}" y="${_f(seloNumDocY + 9)}" '
        'text-anchor="middle" font-size="6" fill="#888">N DOCUMENTO</text>');
    buf.writeln('<text x="${_f(ndocMidX)}" y="${_f(seloNumDocY + 22)}" '
        'text-anchor="middle" font-size="8" font-weight="bold" fill="#000">'
        '${_esc(d.numeroDocumento)}</text>');

    // ── COL 4: REVISÃO ──
    final double revMidX = (seloX4 + seloX5) / 2;
    buf.writeln('<text x="${_f(revMidX)}" y="${_f(seloTitY + 9)}" '
        'text-anchor="middle" font-size="6" fill="#888">REV</text>');
    buf.writeln('<text x="${_f(revMidX)}" y="${_f(seloTitY + 35)}" '
        'text-anchor="middle" font-size="22" font-weight="bold" fill="#000">'
        '${d.revisao}</text>');
  }

  void _seloLinha(StringBuffer buf, double rotX, double valX, double y,
      String rotulo, String valor) {
    buf.writeln(
      '<text x="${_f(rotX)}" y="${_f(y)}" '
      'font-size="6.5" font-weight="bold" fill="#444">$rotulo</text>',
    );
    buf.writeln(
      '<text x="${_f(valX)}" y="${_f(y)}" '
      'font-size="6.5" fill="#000">$valor</text>',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────

  /// Formata double com 2 casas decimais (sem zeros desnecessários para o SVG)
  String _f(double v) => v.toStringAsFixed(2);

  /// ² em superscript SVG
  String _sup2() => '&#178;';

  /// Escapa o texto para XML (sem diacríticos — compatibilidade com pw.SvgImage)
  String _esc(String s) {
    if (s.isEmpty) return '';

    // 1. Entidades XML obrigatórias
    var r = s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    // 2. Pontuação especial
    r = r
        .replaceAll('\u2014', '-')   // em-dash —
        .replaceAll('\u2013', '-')   // en-dash –
        .replaceAll('\u2018', "'")   // ' esq
        .replaceAll('\u2019', "'")   // ' dir
        .replaceAll('\u201C', '"')   // " esq
        .replaceAll('\u201D', '"');  // " dir

    // 3. Diacríticos → ASCII (tabela completa PT/ES/FR/DE)
    const from = 'ÀÁÂÃÄÅàáâãäåÇçÈÉÊËèéêëÌÍÎÏìíîïÑñÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÝýÿ'
        'ĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĮįİıĴĵĶķĸ'
        'ĹĺĻļĽľĿŀŁłŃńŅņŇňŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧ'
        'ŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽž';
    const to   = 'AAAAAAaaaaaaCoEEEEeeeeIIIIiiiiNnOOOOOOooooooUUUUuuuuYyy'
        'AaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiJjKkk'
        'LlLlLlLlLlNnNnNnNnOoOoOoOEoeRrRrRrSsSsSsSsTtTtTt'
        'UuUuUuUuUuUuWwYyYZzZzZz';
    for (int i = 0; i < from.length && i < to.length; i++) {
      r = r.replaceAll(from[i], to[i]);
    }

    return r;
  }

  /// Escapa rótulo de fase (que pode ter '/')
  String _escFase(FaseUnifilar f) => _esc(f.label);

  String _fmtBitola(double b) {
    if (b == b.truncateToDouble()) return b.toInt().toString();
    return b.toStringAsFixed(1);
  }

  String _fmtPotencia(double v, UnidadePotencia u) {
    // Converte para VA antes de formatar
    final va = u.toWatts(v);
    if (va >= 1000) {
      return '${(va / 1000).toStringAsFixed(2)}KVA';
    }
    if (v == v.truncateToDouble()) return '${v.toInt()} ${u.label.toUpperCase()}';
    return '${v.toStringAsFixed(2)} ${u.label.toUpperCase()}';
  }

  String _faseColor(FaseUnifilar f) {
    switch (f) {
      case FaseUnifilar.r:   return '#000000';  // preto (fiel ao PDF)
      case FaseUnifilar.s:   return '#000000';
      case FaseUnifilar.t:   return '#000000';
      case FaseUnifilar.rs:  return '#000000';
      case FaseUnifilar.rt:  return '#000000';
      case FaseUnifilar.st:  return '#000000';
      case FaseUnifilar.rst: return '#000000';
    }
  }
}

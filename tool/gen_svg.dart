import 'dart:io';
import '../lib/models/unifilar.dart';
import '../lib/widgets/unifilar_svg_builder.dart';

void main() {
  final circuitos = <CircuitoUnifilar>[
    CircuitoUnifilar(id: '1', fase: FaseUnifilar.rst, corrente: 25, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 2.5, potencia: 6490, unidadePotencia: UnidadePotencia.va, tensao: 380, codigo: 'CIRC. 1', descricao: 'Fonte Central - Motobomba 7,5cv'),
    CircuitoUnifilar(id: '2', fase: FaseUnifilar.rst, corrente: 16, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 2.5, potencia: 2600, unidadePotencia: UnidadePotencia.va, tensao: 380, codigo: 'CIRC. 2', descricao: 'Fonte Central - Motobomba Jacuzzi 3cv'),
    CircuitoUnifilar(id: '3', fase: FaseUnifilar.rst, corrente: 25, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 2.5, potencia: 6490, unidadePotencia: UnidadePotencia.va, tensao: 380, codigo: 'CIRC. 3', descricao: 'Fonte Central - Motobomba 7,5cv RESERVA'),
    CircuitoUnifilar(id: '4', fase: FaseUnifilar.rst, corrente: 16, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 2.5, potencia: 2600, unidadePotencia: UnidadePotencia.va, tensao: 380, codigo: 'CIRC. 4', descricao: 'Fonte Central - Motobomba Jacuzzi 3cv RESERVA'),
    CircuitoUnifilar(id: '5', fase: FaseUnifilar.r, corrente: 10, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 1.5, potencia: 1670, unidadePotencia: UnidadePotencia.va, tensao: 220, codigo: 'CIRC. 5', descricao: 'Iluminacao Caminha SPA/VITALINO'),
    CircuitoUnifilar(id: '6', fase: FaseUnifilar.s, corrente: 10, curva: CurvaDisjuntor.c, utilizaDR: false, bitola: 1.5, potencia: 1670, unidadePotencia: UnidadePotencia.va, tensao: 220, codigo: 'CIRC. 6', descricao: 'Iluminacao Praca Dom Pedrto'),
    CircuitoUnifilar(id: '7', fase: FaseUnifilar.t, corrente: 20, curva: CurvaDisjuntor.c, utilizaDR: true, bitola: 2.5, potencia: 2590, unidadePotencia: UnidadePotencia.va, tensao: 220, codigo: 'CIRC. 7', descricao: 'Circuito de Tomada Casa de maquina'),
  ];

  final d = DiagramaUnifilar(
    nomeProjeto: 'DIAGRAMA UNIFILAR QUADRO "Retrofit Quadro Eletrico Fonte Guarita e Central"',
    numeroDocumento: '12112025',
    data: '12/11/2025',
    revisao: 1,
    vemDo: 'VEM DO Subestacao Convention',
    correnteGeral: 63,
    caboGeral: 10,
    faseGeral: FaseUnifilar.rst,
    temDR: false,
    correnteDR: 63,
    temDPS: true,
    dpskA: 45,
    dpsV: 380,
    barramento: 'COBRE 6 x 30mm',
    quadroAterrado: true,
    exibirTerra: true,
    exibirNeutro: true,
    unidadeCircuito: UnidadePotencia.va,
    unidadeQuadro: UnidadePotencia.kva,
    escala: 1.0,
    orientacao: OrientacaoFolha.retrato,
    estiloCanto: EstiloCanto.arredondado,
    centralizar: true,
    fatorDemanda: 1.0,
    clienteNome: 'ENOTEL HOTELS RESORTS AS',
    clienteDocumento: '03.787.288/0001-84',
    clienteEndereco: 'Rodovia PE-9, Porto de Galinhas, Ipojuca, PE, 55.590-000',
    clienteTelefone: '(81) 3552-5555',
    clienteEmail: '',
    circuitos: circuitos,
  );

  final svg = UnifilarSvgBuilder().build(d);
  File('/tmp/output.svg').writeAsStringSync(svg);
  print('done');
}

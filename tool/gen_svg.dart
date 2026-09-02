import 'dart:io';
import '../lib/models/unifilar.dart';
import '../lib/widgets/unifilar_svg_builder.dart';

void main() {
  // Cenário baseado na imagem de referência NBR do usuário:
  // 10A/3kA/CurvaB, 16A/3kA/CurvaB, 20A/6kA/CurvaC+DR25A, 16A/3kA/CurvaC+DR25A etc.
  final circuitos = <CircuitoUnifilar>[
    CircuitoUnifilar(id: '1', fase: FaseUnifilar.t, corrente: 10, curva: CurvaDisjuntor.b, capacidadeRuptura: 3, utilizaDR: false, bitola: 1.5, potencia: 251, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 1', descricao: 'Iluminacao Geral'),
    CircuitoUnifilar(id: '3', fase: FaseUnifilar.r, corrente: 16, curva: CurvaDisjuntor.b, capacidadeRuptura: 3, utilizaDR: false, bitola: 2.5, potencia: 2400, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 3', descricao: 'Tomadas Cozinha'),
    CircuitoUnifilar(id: '4', fase: FaseUnifilar.t, corrente: 16, curva: CurvaDisjuntor.b, capacidadeRuptura: 3, utilizaDR: false, bitola: 2.5, potencia: 2300, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 4', descricao: 'Tomadas Sala'),
    CircuitoUnifilar(id: '5', fase: FaseUnifilar.rst, corrente: 20, curva: CurvaDisjuntor.c, capacidadeRuptura: 6, utilizaDR: true, correnteDR: 25, bitola: 4, potencia: 6000, unidadePotencia: UnidadePotencia.w, tensao: 380, codigo: 'CIRC. 5', descricao: 'Chuveiro Eletrico'),
    CircuitoUnifilar(id: '7', fase: FaseUnifilar.t, corrente: 20, curva: CurvaDisjuntor.c, capacidadeRuptura: 3, utilizaDR: true, correnteDR: 25, bitola: 4, potencia: 1400, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 7', descricao: 'Torneira Eletrica'),
    CircuitoUnifilar(id: '8', fase: FaseUnifilar.t, corrente: 16, curva: CurvaDisjuntor.b, capacidadeRuptura: 3, utilizaDR: false, bitola: 2.5, potencia: 400, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 8', descricao: 'Iluminacao Quartos'),
    CircuitoUnifilar(id: '9', fase: FaseUnifilar.r, corrente: 16, curva: CurvaDisjuntor.c, capacidadeRuptura: 3, utilizaDR: true, correnteDR: 25, bitola: 2.5, potencia: 370, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 9', descricao: 'Tomadas Banheiro'),
    CircuitoUnifilar(id: '10', fase: FaseUnifilar.s, corrente: 16, curva: CurvaDisjuntor.c, capacidadeRuptura: 3, utilizaDR: false, bitola: 2.5, potencia: 1085, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 10', descricao: 'Tomadas Area Externa'),
    CircuitoUnifilar(id: '11', fase: FaseUnifilar.r, corrente: 16, curva: CurvaDisjuntor.c, capacidadeRuptura: 3, utilizaDR: false, bitola: 2.5, potencia: 1085, unidadePotencia: UnidadePotencia.w, tensao: 220, codigo: 'CIRC. 11', descricao: 'Tomadas Garagem'),
  ];

  final d = DiagramaUnifilar(
    nomeProjeto: 'DIAGRAMA UNIFILAR QUADRO "Retrofit Quadro Eletrico Fonte Guarita e Central"',
    numeroDocumento: '12112025',
    data: '12/11/2025',
    revisao: 1,
    vemDo: 'VEM DO Subestacao Convention',
    correnteGeral: 63,
    capacidadeRupturaGeral: 10,
    curvaGeral: CurvaDisjuntor.c,
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

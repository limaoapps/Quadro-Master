// Serviço central de integração com o Google Mobile Ads SDK (AdMob).
//
// IMPORTANTE — Suporte de plataforma:
// O pacote `google_mobile_ads` NÃO possui implementação nativa para Flutter
// Web (apenas Android/iOS). Por isso, toda chamada ao SDK real é protegida
// por `kIsWeb`: no Android o banner é carregado e exibido normalmente; na
// Web o widget de banner exibe um placeholder discreto (sem quebrar o app
// e sem tentar inicializar um SDK que não existe nesse ambiente).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// IDs de unidades de anúncio configurados para o app "Quadro Master".
class AdMobIds {
  AdMobIds._();

  /// App ID do AdMob (declarado também no AndroidManifest.xml).
  static const String appId = 'ca-app-pub-8464114280669008~8698658769';

  /// Banner "banner Qd" — exibido nas telas principais do app.
  static const String bannerQd = 'ca-app-pub-8464114280669008/4859752036';
}

/// Inicializa o Google Mobile Ads SDK.
///
/// Deve ser chamado uma única vez, no início do app (main.dart), apenas
/// quando a plataforma for Android (a Web não é suportada pelo SDK nativo).
class AdMobService {
  AdMobService._();

  static bool _initialized = false;

  /// Indica se o SDK de anúncios está disponível na plataforma atual.
  static bool get isSupported => !kIsWeb;

  static Future<void> initialize() async {
    if (!isSupported) {
      if (kDebugMode) {
        debugPrint('[AdMobService] Plataforma Web detectada — '
            'google_mobile_ads não é inicializado (sem suporte nativo).');
      }
      return;
    }
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[AdMobService] Mobile Ads SDK inicializado com sucesso.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdMobService] Falha ao inicializar Mobile Ads SDK: $e');
      }
    }
  }
}

/// Widget de banner AdMob reutilizável, com carregamento assíncrono,
/// tratamento de erros e liberação correta de recursos (dispose).
///
/// Uso: `const AdMobBanner(adUnitId: AdMobIds.bannerQd)`
class AdMobBanner extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const AdMobBanner({
    super.key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
  });

  @override
  State<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends State<AdMobBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (AdMobService.isSupported) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
            _failed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('[AdMobBanner] Falha ao carregar anúncio: $error');
          }
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoaded = false;
            _failed = true;
          });
        },
        onAdOpened: (ad) {
          if (kDebugMode) debugPrint('[AdMobBanner] Anúncio aberto.');
        },
        onAdClosed: (ad) {
          if (kDebugMode) debugPrint('[AdMobBanner] Anúncio fechado.');
        },
      ),
    );
    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web: sem suporte nativo ao SDK — não ocupa espaço na tela.
    if (!AdMobService.isSupported) {
      return const SizedBox.shrink();
    }

    // Falha ao carregar: não reserva espaço (evita "buraco" na tela).
    if (_failed || _bannerAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

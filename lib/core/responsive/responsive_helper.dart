import 'package:flutter/material.dart';

/// Clase auxiliar para manejar responsividad en la app
/// Proporciona métodos para calcular tamaños, paddings y breakpoints
/// adaptados al tamaño de la pantalla
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  // Getters para dimensiones de la pantalla
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  // Breakpoints responsivos (en logical pixels)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Determina el tipo de dispositivo
  DeviceType get deviceType {
    if (screenWidth < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Verifica si es mobile
  bool get isMobile => screenWidth < mobileBreakpoint;

  /// Verifica si es tablet
  bool get isTablet =>
      screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;

  /// Verifica si es desktop
  bool get isDesktop => screenWidth >= tabletBreakpoint;

  /// Calcula un tamaño responsivo basado en el ancho de la pantalla
  /// factor: valor base a multiplicar (ej: 16 para padding base)
  /// El resultado se ajusta según el ancho de pantalla
  double getResponsiveSize(double baseSize) {
    if (isMobile) {
      // Mobile: escala proporcional con cap para pantallas pequeñas
      final scale = (screenWidth / 400).clamp(0.75, 1.0);
      return baseSize * scale;
    } else if (isTablet) {
      // Tablet: mantiene proporción
      return baseSize * (screenWidth / 600);
    } else {
      // Desktop: mantiene con límite máximo
      return baseSize * (screenWidth / 800);
    }
  }

  /// Retorna padding responsivo (horizontal, vertical)
  EdgeInsets getResponsivePadding({
    double horizontal = 16,
    double vertical = 12,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveSize(horizontal),
      vertical: getResponsiveSize(vertical),
    );
  }

  /// Retorna padding responsivo solo para el contenedor principal
  EdgeInsets getMainPadding() {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(20);
    } else {
      return const EdgeInsets.all(24);
    }
  }

  /// Retorna tamaño de fuente responsivo
  double getResponsiveFontSize(double baseFontSize) {
    if (isMobile) {
      final scale = (screenWidth / 400).clamp(0.8, 1.0);
      return baseFontSize * scale;
    } else if (isTablet) {
      return baseFontSize;
    } else {
      return baseFontSize * 1.1;
    }
  }

  /// Retorna el tamaño de fuente para títulos principales
  double get headingLargeFontSize => getResponsiveFontSize(22);

  /// Retorna el tamaño de fuente para títulos
  double get headingMediumFontSize => getResponsiveFontSize(15);

  /// Retorna el tamaño de fuente para subtítulos
  double get headingSmallFontSize => getResponsiveFontSize(15);

  /// Retorna el tamaño de fuente para texto normal
  double get bodyMediumFontSize => getResponsiveFontSize(13);

  /// Retorna el tamaño de fuente para texto pequeño
  double get bodySmallFontSize => getResponsiveFontSize(11);

  /// Retorna el ancho máximo para contenedores principales
  double get maxContentWidth {
    if (isMobile) {
      return screenWidth;
    } else if (isTablet) {
      return screenWidth * 0.9;
    } else {
      return 1000;
    }
  }

  /// Retorna el número de columnas para un grid responsivo
  int getGridColumns({int mobileColumns = 1, int tabletColumns = 2, int desktopColumns = 3}) {
    if (isMobile) {
      return mobileColumns;
    } else if (isTablet) {
      return tabletColumns;
    } else {
      return desktopColumns;
    }
  }

  /// Retorna el espaciado entre elementos responsivo
  double getSpacing({
    double mobileSpacing = 8,
    double tabletSpacing = 12,
    double desktopSpacing = 16,
  }) {
    if (isMobile) {
      return mobileSpacing;
    } else if (isTablet) {
      return tabletSpacing;
    } else {
      return desktopSpacing;
    }
  }

  /// Retorna altura de un botón responsiva
  double get buttonHeight {
    if (isMobile) {
      return 48;
    } else if (isTablet) {
      return 52;
    } else {
      return 56;
    }
  }

  /// Retorna altura de un elemento responsiva
  double get elementHeight {
    if (isMobile) {
      return 56;
    } else if (isTablet) {
      return 64;
    } else {
      return 72;
    }
  }

  /// Retorna el ancho de icono responsivo
  double get iconSize {
    if (isMobile) {
      return 24;
    } else if (isTablet) {
      return 28;
    } else {
      return 32;
    }
  }

  /// Retorna el radio de esquinas responsivo
  double get borderRadius {
    if (isMobile) {
      return 12;
    } else if (isTablet) {
      return 14;
    } else {
      return 16;
    }
  }
}

/// Enum para tipos de dispositivo
enum DeviceType { mobile, tablet, desktop }

/// Extensión para acceder fácilmente a ResponsiveHelper desde BuildContext
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
}

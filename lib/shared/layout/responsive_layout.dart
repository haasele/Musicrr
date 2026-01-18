import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 840;
  static const double desktop = 1200;
}

/// Responsive layout utilities
class ResponsiveLayout {
  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.desktop;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.desktop;
  }

  /// Get responsive column count for grid layouts
  static int getColumnCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Get responsive padding
  static EdgeInsets getPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  /// Get responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800;
    return 1200;
  }
}

/// Adaptive navigation widget that switches between NavigationBar and NavigationRail
class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget child;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isTablet(context) || ResponsiveLayout.isDesktop(context)) {
      // Use NavigationRail for tablets and desktop
      return Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: destinations.map((dest) {
              return NavigationRailDestination(
                icon: dest.icon,
                selectedIcon: dest.selectedIcon,
                label: Text(dest.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      );
    } else {
      // Use NavigationBar for mobile
      return Column(
        children: [
          Expanded(child: child),
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations,
          ),
        ],
      );
    }
  }
}

/// Responsive container that adapts to screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? ResponsiveLayout.getPadding(context);
    final effectiveMaxWidth = maxWidth ?? ResponsiveLayout.getMaxContentWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Two-pane layout for tablets and desktop
class TwoPaneLayout extends StatelessWidget {
  final Widget primaryPane;
  final Widget? secondaryPane;
  final double primaryPaneWidth;
  final double? secondaryPaneWidth;

  const TwoPaneLayout({
    super.key,
    required this.primaryPane,
    this.secondaryPane,
    this.primaryPaneWidth = 300,
    this.secondaryPaneWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isTablet(context) && !ResponsiveLayout.isDesktop(context)) {
      // Single pane for mobile
      return primaryPane;
    }

    if (secondaryPane == null) {
      return primaryPane;
    }

    return Row(
      children: [
        SizedBox(
          width: primaryPaneWidth,
          child: primaryPane,
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: secondaryPane!,
        ),
      ],
    );
  }
}

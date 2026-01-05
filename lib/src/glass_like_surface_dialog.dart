import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'config.dart';
import 'glass_like_surface_style.dart';
import 'glass_like_surface_surface.dart';

Future<T?> showGlassLikeSurfaceDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color barrierColor = const Color(0x4D000000),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Duration transitionDuration = const Duration(milliseconds: 220),
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    pageBuilder: (context, _, __) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.05, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class GlassLikeSurfaceDialog extends StatelessWidget {
  const GlassLikeSurfaceDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.config,
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
    this.contentPadding = const EdgeInsets.fromLTRB(20, 18, 20, 12),
    this.actionsPadding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.actionsSpacing = 12,
    this.maxWidth = 340,
    this.minWidth = 270,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final GlassLikeSurfaceConfig? config;
  final BorderRadius borderRadius;
  final EdgeInsets contentPadding;
  final EdgeInsets actionsPadding;
  final double actionsSpacing;
  final double maxWidth;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = (textTheme.titleMedium ??
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))
        .copyWith(fontWeight: FontWeight.w600, height: 1.2);
    final contentStyle =
        (textTheme.bodySmall ?? const TextStyle(fontSize: 13)).copyWith(
      height: 1.25,
    );
    final dividerColor = Theme.of(context)
        .dividerColor
        .withValues(alpha: 0.4);
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final resolvedMaxWidth = math.min(maxWidth, mediaWidth - 40);
    final resolvedMinWidth = math.min(minWidth, resolvedMaxWidth);

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: resolvedMinWidth,
            maxWidth: resolvedMaxWidth,
          ),
          child: GlassLikeSurface(
            config: config,
            borderRadius: borderRadius,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: contentPadding,
                  child: GlassLikeSurfaceForeground(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          DefaultTextStyle(
                            style: titleStyle,
                            textAlign: TextAlign.left,
                            child: title!,
                          ),
                        if (title != null && content != null)
                          const SizedBox(height: 8),
                        if (content != null)
                          DefaultTextStyle(
                            style: contentStyle,
                            textAlign: TextAlign.left,
                            child: content!,
                          ),
                      ],
                    ),
                  ),
                ),
                if (actions.isNotEmpty)
                  Padding(
                    padding: actionsPadding,
                    child: _GlassLikeSurfaceDialogActions(
                      actions: actions,
                      spacing: actionsSpacing,
                      dividerColor: dividerColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassLikeSurfaceDialogAction extends StatelessWidget {
  const GlassLikeSurfaceDialogAction({
    super.key,
    required this.child,
    this.onPressed,
    this.isDestructive = false,
    this.isDefaultAction = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 44,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefaultAction;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w500);
    final fontWeight = isDefaultAction ? FontWeight.w600 : FontWeight.w500;
    final brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color systemBlue =
        isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final Color systemRed =
        isDark ? const Color(0xFFFF453A) : const Color(0xFFFF3B30);
    final Color neutralFill =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    final Color resolvedBackground = backgroundColor ??
        (isDefaultAction ? systemBlue : neutralFill);
    final Color resolvedForeground = foregroundColor ??
        (isDefaultAction
            ? Colors.white
            : isDestructive
                ? systemRed
                : systemBlue);

    return Material(
      color: resolvedBackground,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.pressed)
              ? resolvedForeground.withValues(alpha: 0.12)
              : null,
        ),
        child: SizedBox(
          height: height,
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(
                color: resolvedForeground,
                fontWeight: fontWeight,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: resolvedForeground),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassLikeSurfaceDialogActions extends StatelessWidget {
  const _GlassLikeSurfaceDialogActions({
    required this.actions,
    required this.spacing,
    required this.dividerColor,
  });

  final List<Widget> actions;
  final double spacing;
  final Color dividerColor;

  @override
  Widget build(BuildContext context) {
    final bool useRow = actions.length <= 2;

    if (useRow) {
      return Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            Expanded(child: actions[i]),
            if (i != actions.length - 1)
              SizedBox(width: spacing),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          actions[i],
          if (i != actions.length - 1)
            SizedBox(height: spacing),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'config.dart';
import 'glass_like_surface_surface.dart';

Future<T?> showGlassLikeSurfaceDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color barrierColor = const Color(0x66000000),
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: builder,
  );
}

class GlassLikeSurfaceDialog extends StatelessWidget {
  const GlassLikeSurfaceDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.config,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.contentPadding = const EdgeInsets.fromLTRB(20, 20, 20, 16),
    this.actionsPadding = const EdgeInsets.only(top: 8),
    this.maxWidth = 360,
    this.minWidth = 280,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;
  final GlassLikeSurfaceConfig? config;
  final BorderRadius borderRadius;
  final EdgeInsets contentPadding;
  final EdgeInsets actionsPadding;
  final double maxWidth;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 17);
    final contentStyle =
        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 15);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
        child: GlassLikeSurface(
          config: config,
          borderRadius: borderRadius,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: titleStyle,
                        textAlign: TextAlign.center,
                        child: title!,
                      ),
                    if (title != null && content != null)
                      const SizedBox(height: 8),
                    if (content != null)
                      DefaultTextStyle(
                        style: contentStyle,
                        textAlign: TextAlign.center,
                        child: content!,
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                Padding(
                  padding: actionsPadding,
                  child: const Divider(height: 1),
                ),
                _GlassLikeSurfaceDialogActions(actions: actions),
              ],
            ],
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
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefaultAction;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge ??
        const TextStyle(fontSize: 16);
    final Color color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final fontWeight = isDefaultAction ? FontWeight.w600 : FontWeight.w500;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: 44,
          child: Center(
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: color, fontWeight: fontWeight),
              child: IconTheme.merge(
                data: IconThemeData(color: color),
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
  });

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context)
        .dividerColor
        .withValues(alpha: 0.4);
    final bool useRow = actions.length <= 2;

    if (useRow) {
      return Row(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            Expanded(child: actions[i]),
            if (i != actions.length - 1)
              Container(width: 1, height: 44, color: dividerColor),
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
            Container(height: 1, color: dividerColor),
        ],
      ],
    );
  }
}

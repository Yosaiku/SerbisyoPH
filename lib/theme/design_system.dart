import 'package:flutter/material.dart';
import 'colors.dart';

export 'colors.dart';

class DS {
  DS._();

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;

  static const double btnHeightSm = 40;
  static const double btnHeightMd = 48;
  static const double btnHeightLg = 56;

  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;
  static const double avatarXl = 100;

  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.kBlack,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.kBlack,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.kBlack,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.kBlack,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.kBlack,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.kBlack,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.kBlack,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.kGreyText,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.kBlack,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.kBlack,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.kGreyText,
    letterSpacing: 0.8,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.kGreyText,
    letterSpacing: 0.8,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.kBlack,
    letterSpacing: 1.2,
    height: 1.4,
  );
}

class DSText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;

  const DSText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.align,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? DS.bodyMedium).copyWith(color: color),
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  const DSText.displayLarge(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.displayLarge;

  const DSText.headlineLarge(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.headlineLarge;

  const DSText.headlineMedium(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.headlineMedium;

  const DSText.titleLarge(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.titleLarge;

  const DSText.titleMedium(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.titleMedium;

  const DSText.bodyLarge(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.bodyLarge;

  const DSText.bodyMedium(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.bodyMedium;

  const DSText.bodySmall(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.bodySmall;

  const DSText.labelLarge(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.labelLarge;

  const DSText.labelMedium(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.labelMedium;

  const DSText.labelSmall(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.labelSmall;

  const DSText.caption(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.caption;

  const DSText.overline(this.text, {super.key, this.color, this.align, this.maxLines, this.overflow})
      : style = DS.overline;
}

class DSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const DSCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(DS.spaceLg),
      decoration: BoxDecoration(
        color: color ?? AppColors.kWhite,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        border: border ?? Border.all(color: AppColors.kBorder),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        child: card,
      );
    }
    return card;
  }
}

class DSChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;

  const DSChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: DS.iconSm, color: selected ? AppColors.kWhite : AppColors.kBlack),
            const SizedBox(width: DS.spaceXs),
          ],
          DSText.labelMedium(label, color: selected ? AppColors.kWhite : AppColors.kBlack),
        ],
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: selectedColor ?? AppColors.kBlack,
      backgroundColor: unselectedColor ?? AppColors.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DS.radiusFull),
        side: BorderSide(
          color: selected ? (selectedColor ?? AppColors.kBlack) : AppColors.kBorder,
        ),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: DS.spaceMd, vertical: DS.spaceXs),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: onTap != null ? (_) => onTap!() : null,
    );
  }
}

class DSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;
  final bool destructive;
  final IconData? icon;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const DSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outlined = false,
    this.destructive = false,
    this.icon,
    this.width,
    this.height = DS.btnHeightLg,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = destructive
        ? Colors.red
        : (outlined ? Colors.transparent : AppColors.kBlack);
    final fgColor = destructive || !outlined ? AppColors.kWhite : AppColors.kBlack;
    final borderColor = outlined ? (destructive ? Colors.red : AppColors.kBlack) : Colors.transparent;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(DS.radiusLg),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
        ),
        child: loading
            ? SizedBox(
                width: DS.iconMd,
                height: DS.iconMd,
                child: CircularProgressIndicator(
                  color: fgColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: DS.iconMd),
                    const SizedBox(width: DS.spaceSm),
                  ],
                  DSText.labelMedium(label),
                ],
              ),
      ),
    );
  }

  const DSButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.width,
    this.height = DS.btnHeightLg,
    this.borderRadius,
  }) : outlined = false,
       destructive = false;

  const DSButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.width,
    this.height = DS.btnHeightLg,
    this.borderRadius,
  }) : outlined = true,
       destructive = false;

  const DSButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.width,
    this.height = DS.btnHeightLg,
    this.borderRadius,
  }) : outlined = false,
       destructive = true;

  const DSButton.outlinedDestructive({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.width,
    this.height = DS.btnHeightLg,
    this.borderRadius,
  }) : outlined = true,
       destructive = true;
}

class DSInput extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final String? label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final String? Function(String?)? validator;

  const DSInput({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          DSText.labelMedium(label!),
          const SizedBox(height: DS.spaceSm),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.kWhite,
            borderRadius: BorderRadius.circular(DS.radiusMd),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            readOnly: readOnly,
            enabled: enabled,
            maxLines: maxLines,
            onTap: onTap,
            onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
            validator: validator,
            cursorColor: AppColors.kBlack,
            style: DS.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: DS.bodySmall,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.kBlack, size: DS.iconMd)
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DS.spaceLg,
                vertical: DS.spaceMd,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DSSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const DSSectionHeader({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DSText.overline(title),
        if (action != null) action!,
      ],
    );
  }
}

class DSStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const DSStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DS.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(DS.radiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: DS.iconLg),
          const SizedBox(height: DS.spaceSm),
          DSText.headlineLarge(value, color: color),
          const SizedBox(height: DS.spaceXs),
          DSText.caption(label),
        ],
      ),
    );
  }
}

class DSActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? bgColor;
  final Widget? trailing;

  const DSActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    this.bgColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DS.spaceLg),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.kWhite,
          borderRadius: BorderRadius.circular(DS.radiusLg),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DS.spaceSm),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.kBlack).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DS.radiusMd),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.kBlack, size: DS.iconMd),
            ),
            const SizedBox(width: DS.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText.titleMedium(title, color: titleColor),
                  if (subtitle != null) ...[
                    const SizedBox(height: DS.spaceXs),
                    DSText.bodySmall(subtitle!),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: AppColors.kGreyText, size: DS.iconMd),
          ],
        ),
      ),
    );
  }
}

class DSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool dark;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const DSAppBar({
    super.key,
    required this.title,
    this.dark = false,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: dark ? AppColors.kBlack : Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: dark ? AppColors.kWhite : AppColors.kBlack),
      actionsIconTheme: IconThemeData(color: dark ? AppColors.kWhite : AppColors.kBlack),
      title: DSText.headlineMedium(title, color: dark ? AppColors.kWhite : AppColors.kBlack),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class DSListTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const DSListTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DS.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(DS.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: BorderRadius.circular(DS.radiusLg),
          border: Border.all(color: AppColors.kBorder),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: DS.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText.titleMedium(title, color: titleColor),
                  if (subtitle != null) ...[
                    const SizedBox(height: DS.spaceXs),
                    DSText.bodySmall(subtitle!),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class DSDivider extends StatelessWidget {
  const DSDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.kBorder,
      thickness: 1,
      height: DS.spaceXl,
    );
  }
}

class DSBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? bgColor;

  const DSBadge({
    super.key,
    required this.label,
    required this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceSm, vertical: DS.spaceXs),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: DSText.labelSmall(label, color: color),
    );
  }
}

class DSStatusBadge extends StatelessWidget {
  final String status;

  const DSStatusBadge({super.key, required this.status});

  Color _getColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.kGreyText;
    }
  }

  String _getLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Searching...';
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceSm, vertical: DS.spaceXs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      child: DSText.labelSmall(_getLabel(status), color: color),
    );
  }
}

class DSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const DSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DS.space2xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: DS.iconXl * 2, color: AppColors.kBorder),
            const SizedBox(height: DS.spaceLg),
            DSText.headlineMedium(title),
            if (subtitle != null) ...[
              const SizedBox(height: DS.spaceSm),
              DSText.bodySmall(subtitle!, align: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: DS.spaceLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class DSModalBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? action;

  const DSModalBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DS.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: DS.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.kBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null || action != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DS.spaceLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null) DSText.overline(title!),
                  if (action != null) action!,
                ],
              ),
            ),
          const SizedBox(height: DS.spaceMd),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class DSDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const DSDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.radiusXl)),
      title: DSText.titleLarge(title),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.all(DS.spaceLg),
    );
  }
}

class DSAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final IconData? icon;
  final Color? bgColor;
  final Color? iconColor;

  const DSAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = DS.avatarMd,
    this.icon,
    this.bgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.kBlack,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: initials != null
            ? DSText.titleMedium(initials!, color: AppColors.kWhite)
            : Icon(icon ?? Icons.person, color: iconColor ?? AppColors.kWhite, size: size * 0.5),
      ),
    );
  }
}

class DSLocationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const DSLocationRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: DS.iconSm, color: iconColor ?? AppColors.kGreyText),
        const SizedBox(width: DS.spaceSm),
        DSText.labelSmall(label),
        const SizedBox(width: DS.spaceXs),
        Expanded(child: DSText.bodySmall(value)),
      ],
    );
  }
}

class DSNavDestination extends StatelessWidget {
  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;

  const DSNavDestination({
    super.key,
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      selectedIcon: Icon(selectedIcon, color: AppColors.kWhite, size: DS.iconMd),
      icon: Icon(unselectedIcon, color: AppColors.kBlack, size: DS.iconMd),
      label: label,
    );
  }
}
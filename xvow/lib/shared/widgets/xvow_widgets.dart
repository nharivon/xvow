import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
	const SectionHeader({
		super.key,
		required this.title,
		this.subtitle,
		this.trailing,
	});

	final String title;
	final String? subtitle;
	final Widget? trailing;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
							if (subtitle != null) ...[
								const SizedBox(height: 6),
								Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
							],
						],
					),
				),
				if (trailing != null) trailing!,
			],
		);
	}
}

class AppCard extends StatelessWidget {
	const AppCard({super.key, required this.child, this.padding, this.margin});

	final Widget child;
	final EdgeInsetsGeometry? padding;
	final EdgeInsetsGeometry? margin;

	@override
	Widget build(BuildContext context) {
		return Container(
			margin: margin,
			padding: padding ?? const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(28),
				border: Border.all(color: const Color(0xFFF1E7DB)),
				boxShadow: const [
					BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(0, 12)),
				],
			),
			child: child,
		);
	}
}

class EmptyStateView extends StatelessWidget {
	const EmptyStateView({super.key, required this.title, required this.message, this.action});

	final String title;
	final String message;
	final Widget? action;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return AppCard(
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						width: 56,
						height: 56,
						decoration: BoxDecoration(
							color: theme.colorScheme.primary.withValues(alpha: 0.1),
							shape: BoxShape.circle,
						),
						child: Icon(Icons.hourglass_empty_rounded, color: theme.colorScheme.primary),
					),
					const SizedBox(height: 16),
					Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
					const SizedBox(height: 8),
					Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B))),
					if (action != null) ...[
						const SizedBox(height: 16),
						action!,
					],
				],
			),
		);
	}
}

class StatChip extends StatelessWidget {
	const StatChip({super.key, required this.label, required this.value, this.icon});

	final String label;
	final String value;
	final IconData? icon;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return AppCard(
			padding: const EdgeInsets.all(16),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					if (icon != null) ...[
						Icon(icon, color: theme.colorScheme.primary),
						const SizedBox(height: 12),
					],
					Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
					const SizedBox(height: 4),
					Text(label, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B))),
				],
			),
		);
	}
}

class PrimaryButton extends StatelessWidget {
	const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false});

	final String label;
	final VoidCallback? onPressed;
	final bool loading;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: FilledButton(
				onPressed: loading ? null : onPressed,
				child: loading
					? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
					: Text(label),
			),
		);
	}
}

class SecondaryButton extends StatelessWidget {
	const SecondaryButton({super.key, required this.label, this.onPressed});

	final String label;
	final VoidCallback? onPressed;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: OutlinedButton(onPressed: onPressed, child: Text(label)),
		);
	}
}

class StatusBadge extends StatelessWidget {
	const StatusBadge({super.key, required this.label, required this.success});

	final String label;
	final bool success;

	@override
	Widget build(BuildContext context) {
		final color = success ? const Color(0xFF0F766E) : const Color(0xFFB45309);
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
			decoration: BoxDecoration(
				color: color.withValues(alpha: 0.12),
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
		);
	}
}
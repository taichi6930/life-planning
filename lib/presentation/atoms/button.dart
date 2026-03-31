import 'package:flutter/material.dart';

/// 基本的なボタン Atom
///
/// 様々なバリエーション（primary, secondary, disabled）に対応
class Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final ButtonSize size;

  const Button({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return _buildButton(context);
  }

  Widget _buildButton(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(context),
          foregroundColor: _getForegroundColor(context),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
        ),
        child: isLoading
            ? SizedBox(
                width: _getHeight(),
                height: _getHeight(),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return Theme.of(context).primaryColor;
      case ButtonVariant.secondary:
        return Colors.grey.shade200;
      case ButtonVariant.danger:
        return Colors.red;
    }
  }

  Color _getForegroundColor(BuildContext context) {
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return Colors.black;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 56;
    }
  }
}

enum ButtonVariant {
  primary,
  secondary,
  danger,
}

enum ButtonSize {
  small,
  medium,
  large,
}

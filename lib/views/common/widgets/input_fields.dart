import 'package:flutter/material.dart';
import 'package:parking_app/theme/app_colors.dart';
import 'package:parking_app/theme/text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged; // Added onChanged property
  final bool showTogglePasswordVisibility;
  final VoidCallback? onToggleVisibility; // Added onToggleVisibility callback
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged, // Added to constructor
    this.showTogglePasswordVisibility = false,
    this.onToggleVisibility, // Added to constructor
    this.decoration,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultDecoration = InputDecoration(
      labelText: widget.label,
      hintText: widget.hintText,
      hintStyle: TextStyles.inputHint,
      labelStyle: TextStyle(
        color: _isFocused ? AppColors.primary : AppColors.textSecondary,
        fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      suffixIcon:
          widget.showTogglePasswordVisibility
              ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color:
                      _isFocused ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () {
                  if (widget.onToggleVisibility != null) {
                    widget.onToggleVisibility!();
                  } else {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  }
                },
              )
              : null,
    );

    final finalDecoration =
        widget.decoration?.copyWith(
          labelStyle: TextStyle(
            color: _isFocused ? AppColors.primary : AppColors.textSecondary,
            fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
          ),
          suffixIcon:
              widget.showTogglePasswordVisibility
                  ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color:
                          _isFocused
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      if (widget.onToggleVisibility != null) {
                        widget.onToggleVisibility!();
                      } else {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      }
                    },
                  )
                  : widget.decoration?.suffixIcon,
        ) ??
        defaultDecoration;

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      focusNode: _focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged, // Pass onChanged to TextFormField
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      decoration: finalDecoration,
      style: TextStyles.inputText,
    );
  }
}

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFillColor,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyles.inputHint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      controller.clear();
                      if (onClear != null) {
                        onClear!();
                      }
                      onChanged('');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
        style: TextStyles.inputText,
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const CustomTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.validator,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          keyboardType: keyboardType,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyles.inputText,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyles.inputHint,
            helperStyle: TextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool showClearButton;

  const SearchField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText ?? '検索...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            showClearButton && controller?.text.isNotEmpty == true
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed:
                      onClear ??
                      () {
                        controller?.clear();
                        onChanged?.call('');
                      },
                )
                : null,
        filled: true,
        fillColor: AppColors.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
    );
  }
}

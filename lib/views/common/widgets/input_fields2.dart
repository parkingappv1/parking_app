import 'package:flutter/material.dart';
import 'package:parking_app/theme/text_styles.dart';

class AppTextField2 extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final bool showTogglePasswordVisibility;
  final VoidCallback? onToggleVisibility;
  final InputDecoration? decoration;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField2({
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
    this.onChanged,
    this.showTogglePasswordVisibility = false,
    this.onToggleVisibility,
    this.decoration,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final InputDecoration effectiveDecoration = decoration ??
        InputDecoration(
          hintText: hintText,
          hintStyle: TextStyles.inputHint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          suffixIcon: showTogglePasswordVisibility
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 4),
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        SizedBox(
          height: 50, // 保持统一高度
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            onChanged: onChanged,
            readOnly: readOnly,
            onTap: onTap,
            style: const TextStyle(fontSize: 16),
            decoration: effectiveDecoration,
          ),
        ),
      ],
    );
  }
}

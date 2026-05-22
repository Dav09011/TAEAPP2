import 'package:flutter/material.dart';

class PresetColorOption {
  const PresetColorOption({
    required this.label,
    required this.colorValue,
  });

  final String label;
  final int colorValue;

  Color get color => Color(colorValue);
}

const List<PresetColorOption> kPresetColorOptions = [
  PresetColorOption(label: 'Coral', colorValue: 0xFFFFD6CC),
  PresetColorOption(label: 'Arena', colorValue: 0xFFFFE9B8),
  PresetColorOption(label: 'Menta', colorValue: 0xFFD7F5DF),
  PresetColorOption(label: 'Cielo', colorValue: 0xFFD6EBFF),
  PresetColorOption(label: 'Lavanda', colorValue: 0xFFE7DEFF),
  PresetColorOption(label: 'Rosa', colorValue: 0xFFFFD9E8),
  PresetColorOption(label: 'Humo', colorValue: 0xFFE7ECEF),
  PresetColorOption(label: 'Grafito', colorValue: 0xFFCFD3D8),
];

const List<PresetColorOption> kTaeKwonDoBeltColorOptions = [
  PresetColorOption(label: 'Blanca', colorValue: 0xFFF7F7F2),
  PresetColorOption(label: 'Amarilla', colorValue: 0xFFF4D03F),
  PresetColorOption(label: 'Naranja', colorValue: 0xFFF39C12),
  PresetColorOption(label: 'Verde', colorValue: 0xFF2E8B57),
  PresetColorOption(label: 'Azul', colorValue: 0xFF2874A6),
  PresetColorOption(label: 'Morada', colorValue: 0xFF7D3C98),
  PresetColorOption(label: 'Roja', colorValue: 0xFFC0392B),
  PresetColorOption(label: 'Roja/Negra', colorValue: 0xFF7B241C),
  PresetColorOption(label: 'Negra', colorValue: 0xFF1C1C1C),
];

Color resolveCardColor(int? colorValue, {Color fallback = Colors.white}) {
  if (colorValue == null) {
    return fallback;
  }
  return Color(colorValue);
}

Color resolveOnColor(Color color) {
  return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
      ? Colors.white
      : Colors.black87;
}

Future<int?> showPresetColorPickerDialog({
  required BuildContext context,
  required String title,
  int? selectedColorValue,
  List<PresetColorOption> options = kPresetColorOptions,
}) {
  return showDialog<int>(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 340,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  options.map((option) {
                    final isSelected = option.colorValue == selectedColorValue;
                    return InkWell(
                      onTap: () {
                        Navigator.of(dialogContext).pop(option.colorValue);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 92,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: option.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isSelected ? Colors.black87 : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.palette_outlined,
                              color: resolveOnColor(option.color),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              option.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: resolveOnColor(option.color),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
  );
}

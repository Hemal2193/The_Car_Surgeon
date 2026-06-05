import 'package:flutter/material.dart';
import 'package:tcs/services/fuel_type_service.dart';
import 'package:tcs/widgets/custom_button.dart';

class AppFuelField extends StatefulWidget {
  final Function(String) onSelected;
  final String? initialValue;

  const AppFuelField({super.key, required this.onSelected, this.initialValue});

  @override
  State<AppFuelField> createState() => _AppFuelFieldState();
}

class _AppFuelFieldState extends State<AppFuelField> {
  final TextEditingController controller = TextEditingController();

  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;

  final List<String> defaults = const [
    'Petrol',
    'Diesel',
    'CNG',
    'EV',
    'Petrol + CNG',
    'Custom',
  ];

  List<String> filtered = [];

  @override
  void initState() {
    super.initState();

    controller.text = widget.initialValue ?? '';
    filtered = [...defaults, ...FuelTypeService.getAll()];
  }

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 300,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 55),
            child: Material(
              color: Colors.white,
              elevation: 8,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                ),
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];

                    return ListTile(
                      dense: true,
                      title: Text(item),
                      onTap: () {
                        if (item == 'Custom') {
                          _askCustomValue();
                          return;
                        }

                        controller.text = item;
                        widget.onSelected(item);

                        _removeOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _askCustomValue() {
    _removeOverlay();

    final textController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Fuel Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Petrol + CNG + EV',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black26),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    cButton(() => Navigator.pop(context), 'Cancel', false),

                    const SizedBox(width: 10),

                    cButton(
                      () {
                        final value = textController.text.trim();

                        if (value.isNotEmpty) {
                          FuelTypeService.add(value);

                          controller.text = value;
                          widget.onSelected(value);
                        }

                        Navigator.pop(context);
                      },
                      'Save',
                      true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _filter(String value) {
    final all = [...defaults, ...FuelTypeService.getAll()];

    setState(() {
      filtered = all
          .where((e) => e.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });

    _showOverlay();
  }

  @override
  void dispose() {
    _removeOverlay();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: controller,
        onChanged: _filter,
        onTap: () {
          setState(() {
            filtered = [...defaults, ...FuelTypeService.getAll()];
          });

          _showOverlay();
        },
        decoration: InputDecoration(
          hintText: 'Fuel Type',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }
}

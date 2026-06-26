import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tcs/widgets/app_selector_overlay.dart';

class AppSelector<T> extends StatefulWidget {
  final List<T> items;
  final Function(T) onSelected;
  final T? initialItem;
  final String? hintText;
  final String Function(T) displayText;
  final String Function(T) searchText;
  final Widget Function(T) itemBuilder;
  final bool showAbove;
  final FocusNode? focusNode;

  const AppSelector({
    super.key,
    required this.items,
    required this.onSelected,
    this.initialItem,
    this.hintText,
    required this.displayText,
    required this.searchText,
    required this.itemBuilder,
    this.showAbove = false,
    this.focusNode,
  });

  @override
  State<AppSelector<T>> createState() => _AppSelectorState<T>();
}

class _AppSelectorState<T> extends State<AppSelector<T>> {
  final TextEditingController controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _wrapperFocusNode = FocusNode();
  late final FocusNode _textFieldFocusNode;

  OverlayEntry? _overlayEntry;

  List<T> filtered = [];
  int highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode = widget.focusNode ?? FocusNode();

    final item = widget.initialItem;
    if (item != null) {
      controller.text = widget.displayText(item);
    }
  }

  void _selectItem(T item) {
    controller.text = widget.displayText(item);
    _removeOverlay();
    widget.onSelected(item);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_overlayEntry == null || filtered.isEmpty) {
      return KeyEventResult.ignored;
    }

    final visibleItems = filtered.take(6).toList();

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (highlightedIndex < visibleItems.length - 1) {
          highlightedIndex++;
        }
      });

      _showOverlay();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (highlightedIndex > 0) {
          highlightedIndex--;
        }
      });

      _showOverlay();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _selectItem(visibleItems[highlightedIndex]);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _showOverlay() {
    // Remove old overlay entry without unfocusing the text field
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.of(context);

    final visibleItems = filtered.take(6).toList();

    if (visibleItems.isEmpty) {
      return;
    }

    if (highlightedIndex >= visibleItems.length) {
      highlightedIndex = visibleItems.length - 1;
    }

    _overlayEntry = AppSelectorOverlay.create(
      context: context,
      link: _layerLink,
      onClose: _removeOverlay,
      showAbove: widget.showAbove,
      children: List.generate(visibleItems.length, (index) {
        final item = visibleItems[index];

        return Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            tileColor: highlightedIndex == index
                ? Colors.black12
                : null,
            title: widget.itemBuilder(item),
            onTap: () => _selectItem(item),
          ),
        );
      }),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _textFieldFocusNode.unfocus();
  }

  void _removeOverlayOnly() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filter(String value) {
    setState(() {
      filtered = widget.items
          .where(
            (item) => widget
                .searchText(item)
                .toLowerCase()
                .contains(value.toLowerCase()),
          )
          .toList();

      highlightedIndex = 0;
    });

    if (filtered.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlayOnly();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    controller.dispose();
    _wrapperFocusNode.dispose();
    if (widget.focusNode == null) {
      _textFieldFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _wrapperFocusNode,
      onKeyEvent: _handleKey,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: controller,
          focusNode: _textFieldFocusNode,
          onChanged: _filter,
          onTap: () {
            setState(() {
              filtered = widget.items;
              highlightedIndex = 0;
            });

            if (filtered.isNotEmpty) {
              _showOverlay();
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Select',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
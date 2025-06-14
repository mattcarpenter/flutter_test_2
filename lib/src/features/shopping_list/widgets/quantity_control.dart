import 'package:flutter/cupertino.dart';

class QuantityControl extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int? maxValue;

  const QuantityControl({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 1,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrease = value > minValue;
    final canIncrease = maxValue == null || value < maxValue!;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.systemGrey4,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minSize: 0,
            onPressed: canDecrease ? () => onChanged(value - 1) : null,
            child: Icon(
              CupertinoIcons.minus,
              size: 18,
              color: canDecrease 
                ? CupertinoColors.label
                : CupertinoColors.quaternaryLabel,
            ),
          ),
          
          // Quantity display
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
          
          // Increase button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minSize: 0,
            onPressed: canIncrease ? () => onChanged(value + 1) : null,
            child: Icon(
              CupertinoIcons.plus,
              size: 18,
              color: canIncrease 
                ? CupertinoColors.label
                : CupertinoColors.quaternaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
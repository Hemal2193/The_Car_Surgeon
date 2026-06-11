import 'package:flutter/material.dart';

class ErpMobileTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final List<String> subtitles;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ErpMobileTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitles = const [],
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        // surfaceTintColor: Colors.white,
        // elevation: 0,
        // margin: const EdgeInsets.only(bottom: 12),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   side: BorderSide(color: Colors.grey.shade200),
        // ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 12)],

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      for (final subtitle in subtitles)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

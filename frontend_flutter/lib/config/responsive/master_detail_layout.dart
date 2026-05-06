import 'package:cadife_smart_travel/config/responsive/responsive_breakpoints.dart';
import 'package:cadife_smart_travel/design_system/design_system.dart';
import 'package:flutter/material.dart';

class MasterDetailLayout extends StatelessWidget {
  final Widget Function(BuildContext) master;
  final Widget Function(BuildContext)? detail;
  final bool showDetail;
  final double masterWidthRatio;
  
  const MasterDetailLayout({
    required this.master,
    this.detail,
    this.showDetail = true,
    this.masterWidthRatio = 0.3,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    if (isMobile) {
      // Mobile: full-width master
      return master(context);
    } else {
      // Tablet/Desktop: side-by-side
      return Row(
        children: [
          // Master
          SizedBox(
            width: MediaQuery.sizeOf(context).width * masterWidthRatio,
            child: master(context),
          ),
          
          // Divider
          VerticalDivider(
            width: 1,
            color: context.colorScheme.outlineVariant,
          ),
          
          // Detail
          Expanded(
            child: showDetail && detail != null
              ? detail!(context)
              : Center(
                  child: Text(
                    'Selecione um item para visualizar detalhes',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
          ),
        ],
      );
    }
  }
}

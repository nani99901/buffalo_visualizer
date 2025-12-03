import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

/// Reusable PlutoGrid widget with standardized configuration
class ReusablePlutoGrid extends StatelessWidget {
  final List<PlutoColumn> columns;
  final List<PlutoRow> rows;
  final double height;
  final double rowHeight;
  final VoidCallback? onLoaded;
  final PlutoGridMode mode;
  final String gridId; // Unique identifier for each grid instance

  const ReusablePlutoGrid({
    Key? key,
    required this.columns,
    required this.rows,
    this.height = 600,
    this.rowHeight = 70,
    this.onLoaded,
    this.mode = PlutoGridMode.normal,
    required this.gridId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PlutoGrid(
        key: ValueKey(gridId), // Use gridId as key for proper state isolation
        configuration: PlutoGridConfiguration(
          style: PlutoGridStyleConfig(
            rowHeight: rowHeight,
            gridBorderRadius: BorderRadius.circular(8),
            gridBorderColor: Colors.grey[300]!,
            enableGridBorderShadow: true,
          ),
          columnSize: PlutoGridColumnSizeConfig(
            autoSizeMode: PlutoAutoSizeMode.scale,
          ),
        ),
        columns: columns,
        rows: rows,
        onLoaded: (event) {
          onLoaded?.call();
        },
        mode: mode,
      ),
    );
  }
}

/// Builder class for creating PlutoColumn with standardized configuration
class PlutoColumnBuilder {
  /// Create a text column with consistent styling
  static PlutoColumn textColumn({
    required String title,
    required String field,
    double width = 120,
    PlutoColumnTextAlign titleTextAlign = PlutoColumnTextAlign.center,
    PlutoColumnRenderer? renderer,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: PlutoColumnType.text(),
      width: width,
      titleTextAlign: titleTextAlign,
      titlePadding: const EdgeInsets.all(12),
      cellPadding: const EdgeInsets.all(12),
      enableEditingMode: false,
      enableSorting: false,
      enableColumnDrag: false,
      renderer: renderer,
    );
  }

  /// Create a center-aligned text cell renderer
  static PlutoColumnRenderer centerTextRenderer({
    required String Function(dynamic) getText,
    Color textColor = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 16,
    Color? backgroundColor,
  }) {
    return (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              getText(ctx.cell.value),
              style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      );
    };
  }

  /// Create a text cell renderer with optional label below
  static PlutoColumnRenderer labeledTextRenderer({
    required String Function(dynamic) getText,
    String Function(dynamic)? getLabel,
    Color textColor = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 16,
    Color? labelColor,
    double labelFontSize = 12,
    Color? backgroundColor,
  }) {
    return (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getText(ctx.cell.value),
              style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: fontSize,
              ),
            ),
            if (getLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                getLabel(ctx.cell.value),
                style: TextStyle(
                  color: labelColor ?? Colors.grey[600],
                  fontSize: labelFontSize,
                ),
              ),
            ],
          ],
        ),
      );
    };
  }

  /// Create a column with custom renderer
  static PlutoColumn customColumn({
    required String title,
    required String field,
    required PlutoColumnRenderer renderer,
    double width = 120,
    PlutoColumnTextAlign titleTextAlign = PlutoColumnTextAlign.center,
  }) {
    return PlutoColumn(
      title: title,
      field: field,
      type: PlutoColumnType.text(),
      width: width,
      titleTextAlign: titleTextAlign,
      titlePadding: const EdgeInsets.all(12),
      cellPadding: const EdgeInsets.all(12),
      enableEditingMode: false,
      enableSorting: false,
      enableColumnDrag: false,
      renderer: renderer,
    );
  }
}

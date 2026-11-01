import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';
import 'package:printing/printing.dart';

class TicketPrintScreen extends StatelessWidget {
  const TicketPrintScreen({super.key, required this.order});

  final CompletedOrder order;

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'POLLERÍA EL GIGANTE',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Center(child: pw.Text('TICKET DE VENTA')),
          pw.SizedBox(height: 12),
          pw.Text('Ticket: ${order.ticketNumber}'),
          pw.Text('Mesa: ${order.tableNumber}'),
          pw.Text('Fecha: ${_formatDate(order.completedAt)}'),
          pw.SizedBox(height: 10),
          _pdfDivider(),
          ...order.items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 28,
                    child: pw.Text(
                      '${item.quantity}×',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.product.name,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        if (item.product.description != null &&
                            item.product.description!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            item.product.description!,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    _money(item.subtotal),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _pdfDivider(),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Text(
                _money(order.total),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Center(child: pw.Text('¡Gracias por su visita!')),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _pdfDivider() => pw.Container(
    height: 0.7,
    margin: const pw.EdgeInsets.symmetric(vertical: 6),
    color: PdfColors.grey500,
  );

  Future<void> _printTicket(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        name: 'ticket-${order.ticketNumber}.pdf',
        onLayout: _buildPdf,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la opción de impresión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vista previa del ticket'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: isDark ? colorScheme.surface : Colors.white,
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'POLLERÍA EL GIGANTE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TICKET DE VENTA',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    Divider(height: 28, color: theme.dividerColor),
                    Text(
                      'Ticket: ${order.ticketNumber}',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    Text(
                      'Mesa: ${order.tableNumber}',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    Text(
                      'Fecha: ${_formatDate(order.completedAt)}',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    Divider(height: 28, color: theme.dividerColor),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${item.quantity}×',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (item.product.description != null &&
                                      item.product.description!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.product.description!,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _money(item.subtotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 28, color: theme.dividerColor),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          _money(order.total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '¡Gracias por su visita!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => _printTicket(context),
          icon: const Icon(Icons.print),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Imprimir ticket'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}

String _money(double amount) => 'S/ ${amount.toStringAsFixed(2)}';

String _formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $hour:$minute';
}

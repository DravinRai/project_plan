import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/task_model.dart';

class PdfGenerator {
  /// Generates a PDF document for the given list of tasks and triggers the native print dialog.
  static Future<void> printTaskList(List<TaskModel> tasks, DateTime date) async {
    final doc = pw.Document();
    
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(date);
    
    // Split tasks for better categorization in the PDF
    final importantTasks = tasks.where((t) => t.isImportant).toList();
    final regularTasks = tasks.where((t) => !t.isImportant).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(dateStr),
          pw.SizedBox(height: 20),
          
          if (importantTasks.isNotEmpty) ...[
            _buildSectionHeader('Important Activities'),
            ...importantTasks.map(_buildTaskRow),
            pw.SizedBox(height: 20),
          ],
          
          if (regularTasks.isNotEmpty) ...[
            _buildSectionHeader('Activities'),
            ...regularTasks.map(_buildTaskRow),
          ],
          
          if (tasks.isEmpty) ...[
            pw.Text('No tasks scheduled for this day.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
          ]
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Tasks_$dateStr.pdf',
    );
  }
  
  static pw.Widget _buildHeader(String dateStr) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('Project Plan', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.Text(dateStr, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
      ]
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800, letterSpacing: 1.5),
      ),
    );
  }

  static pw.Widget _buildTaskRow(TaskModel task) {
    final isDone = task.status == TaskStatus.completed;
    final timeStr = DateFormat('h:mm a').format(task.startTime);
    final durationStr = '${task.durationMinutes}m';
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            margin: const pw.EdgeInsets.only(top: 2, right: 10),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: isDone ? PdfColors.green : PdfColors.grey500),
              color: isDone ? PdfColors.green : null,
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  task.title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: isDone ? PdfColors.grey500 : PdfColors.black,
                    decoration: isDone ? pw.TextDecoration.lineThrough : null,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '$timeStr ($durationStr) ${task.category?.name.toUpperCase() ?? ''}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                if (task.notes != null && task.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    task.notes!,
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

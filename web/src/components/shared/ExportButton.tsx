import React from 'react';
import { useTranslation } from 'react-i18next';
import { Download } from 'lucide-react';
import * as XLSX from 'xlsx';
import jsPDF from 'jspdf';
import 'jspdf-autotable';

// Extend jsPDF type for autotable
declare module 'jspdf' {
  interface jsPDF {
    autoTable: (options: any) => jsPDF;
  }
}

interface ExportButtonProps {
  data: Record<string, any>[];
  columns: { header: string; key: string }[];
  filename: string;
}

export function ExportButton({ data, columns, filename }: ExportButtonProps) {
  const { t } = useTranslation();

  const exportExcel = () => {
    const worksheetData = data.map((row) => {
      const obj: Record<string, any> = {};
      columns.forEach((col) => {
        obj[col.header] = row[col.key];
      });
      return obj;
    });

    const ws = XLSX.utils.json_to_sheet(worksheetData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Report');
    XLSX.writeFile(wb, `${filename}.xlsx`);
  };

  const exportPdf = () => {
    const doc = new jsPDF();
    const headers = columns.map((c) => c.header);
    const rows = data.map((row) => columns.map((col) => String(row[col.key] ?? '')));

    doc.autoTable({
      head: [headers],
      body: rows,
      styles: { fontSize: 8 },
      headStyles: { fillColor: [37, 99, 235] },
    });

    doc.save(`${filename}.pdf`);
  };

  return (
    <div className="flex items-center gap-2">
      <button
        onClick={exportExcel}
        className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-green-700 bg-green-50 border border-green-200 rounded-md hover:bg-green-100"
      >
        <Download className="w-4 h-4" />
        {t('common.exportExcel')}
      </button>
      <button
        onClick={exportPdf}
        className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-red-700 bg-red-50 border border-red-200 rounded-md hover:bg-red-100"
      >
        <Download className="w-4 h-4" />
        {t('common.exportPdf')}
      </button>
    </div>
  );
}

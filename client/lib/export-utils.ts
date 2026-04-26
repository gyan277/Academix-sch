/**
 * Utility functions for exporting data to various formats
 */

import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

// Generate CSV from data
export function generateCSV(data: any[], filename: string) {
  if (data.length === 0) return;

  // Get headers from first object
  const headers = Object.keys(data[0]);
  
  // Create CSV content
  const csvContent = [
    headers.join(','),
    ...data.map(row => 
      headers.map(header => {
        const value = row[header];
        // Escape commas and quotes
        if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
          return `"${value.replace(/"/g, '""')}"`;
        }
        return value;
      }).join(',')
    )
  ].join('\n');

  // Create blob and download
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  downloadBlob(blob, `${filename}.csv`);
}

// Generate academic report PDF
export async function generateAcademicReportPDF(data: any[], schoolName: string, schoolLogo?: string, headmasterSignature?: string) {
  const doc = new jsPDF();
  
  let currentY = 20;

  // Add school logo if available
  if (schoolLogo) {
    try {
      console.log('Loading logo for academic report:', schoolLogo);
      const logoBase64 = await urlToBase64(schoolLogo);
      doc.addImage(logoBase64, 'PNG', 14, 10, 30, 30);
      currentY = 45;
    } catch (error) {
      console.error('Error adding logo to academic report:', error);
      currentY = 20;
    }
  }
  
  // Add header
  doc.setFontSize(20);
  doc.text(schoolName, 105, currentY, { align: 'center' });
  doc.setFontSize(16);
  doc.text('Academic Performance Report', 105, currentY + 10, { align: 'center' });
  
  // Add date
  doc.setFontSize(10);
  doc.text(`Generated on: ${new Date().toLocaleDateString()}`, 105, currentY + 20, { align: 'center' });
  
  // Add table
  autoTable(doc, {
    startY: currentY + 30,
    head: [['Class', 'Average Score', 'Top Student', 'Top Score']],
    body: data.map(item => [
      item.class,
      `${item.avgScore}%`,
      item.topStudent,
      item.topScore
    ]),
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add summary
  const finalY = (doc as any).lastAutoTable.finalY || 50;
  doc.setFontSize(12);
  doc.text('Summary', 14, finalY + 15);
  doc.setFontSize(10);
  doc.text(`Total Classes: ${data.length}`, 14, finalY + 25);
  doc.text(`School Average: ${(data.reduce((sum, item) => sum + item.avgScore, 0) / data.length).toFixed(1)}%`, 14, finalY + 32);
  
  // Add signature if available
  if (headmasterSignature) {
    try {
      console.log('Loading signature for academic report:', headmasterSignature);
      const signatureBase64 = await urlToBase64(headmasterSignature);
      doc.setFontSize(10);
      doc.text("Headmaster's Signature:", 14, finalY + 50);
      doc.addImage(signatureBase64, 'PNG', 14, finalY + 52, 40, 15);
    } catch (error) {
      console.error('Error adding signature to academic report:', error);
    }
  }
  
  // Add footer
  const pageCount = doc.getNumberOfPages();
  doc.setFontSize(8);
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(`Page ${i} of ${pageCount}`, 105, 285, { align: 'center' });
    doc.text(`© ${new Date().getFullYear()} School Management System`, 105, 290, { align: 'center' });
  }
  
  doc.save(`Academic_Report_${new Date().toISOString().split('T')[0]}.pdf`);
}

// Generate attendance report PDF
export async function generateAttendanceReportPDF(data: any[], schoolName: string, schoolLogo?: string, headmasterSignature?: string) {
  const doc = new jsPDF();
  
  let currentY = 20;

  // Add school logo if available
  if (schoolLogo) {
    try {
      console.log('Loading logo for attendance report:', schoolLogo);
      const logoBase64 = await urlToBase64(schoolLogo);
      doc.addImage(logoBase64, 'PNG', 14, 10, 30, 30);
      currentY = 45;
    } catch (error) {
      console.error('Error adding logo to attendance report:', error);
      currentY = 20;
    }
  }
  
  // Add header
  doc.setFontSize(20);
  doc.text(schoolName, 105, currentY, { align: 'center' });
  doc.setFontSize(16);
  doc.text('Attendance Report', 105, currentY + 10, { align: 'center' });
  
  // Add date
  doc.setFontSize(10);
  doc.text(`Generated on: ${new Date().toLocaleDateString()}`, 105, currentY + 20, { align: 'center' });
  
  // Add table
  autoTable(doc, {
    startY: currentY + 30,
    head: [['Class', 'Attendance Rate', 'Total Students', 'Absences']],
    body: data.map(item => [
      item.class,
      `${item.rate}%`,
      item.students,
      item.absent
    ]),
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add summary
  const finalY = (doc as any).lastAutoTable.finalY || 50;
  doc.setFontSize(12);
  doc.text('Summary', 14, finalY + 15);
  doc.setFontSize(10);
  doc.text(`School Average Attendance: ${(data.reduce((sum, item) => sum + item.rate, 0) / data.length).toFixed(1)}%`, 14, finalY + 25);
  doc.text(`Total Absences: ${data.reduce((sum, item) => sum + item.absent, 0)}`, 14, finalY + 32);
  
  // Add signature if available
  if (headmasterSignature) {
    try {
      console.log('Loading signature for attendance report:', headmasterSignature);
      const signatureBase64 = await urlToBase64(headmasterSignature);
      doc.setFontSize(10);
      doc.text("Headmaster's Signature:", 14, finalY + 50);
      doc.addImage(signatureBase64, 'PNG', 14, finalY + 52, 40, 15);
    } catch (error) {
      console.error('Error adding signature to attendance report:', error);
    }
  }
  
  // Add footer
  const pageCount = doc.getNumberOfPages();
  doc.setFontSize(8);
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(`Page ${i} of ${pageCount}`, 105, 285, { align: 'center' });
    doc.text(`© ${new Date().getFullYear()} School Management System`, 105, 290, { align: 'center' });
  }
  
  doc.save(`Attendance_Report_${new Date().toISOString().split('T')[0]}.pdf`);
}

// Generate enrollment report PDF
export async function generateEnrollmentReportPDF(data: any[], schoolName: string, schoolLogo?: string, headmasterSignature?: string) {
  const doc = new jsPDF();
  
  const totalEnrollment = data.reduce((sum, item) => sum + item.total, 0);
  const totalBoys = data.reduce((sum, item) => sum + item.boys, 0);
  const totalGirls = data.reduce((sum, item) => sum + item.girls, 0);
  
  let currentY = 20;

  // Add school logo if available
  if (schoolLogo) {
    try {
      console.log('Loading logo for enrollment report:', schoolLogo);
      const logoBase64 = await urlToBase64(schoolLogo);
      doc.addImage(logoBase64, 'PNG', 14, 10, 30, 30);
      currentY = 45;
    } catch (error) {
      console.error('Error adding logo to enrollment report:', error);
      currentY = 20;
    }
  }
  
  // Add header
  doc.setFontSize(20);
  doc.text(schoolName, 105, currentY, { align: 'center' });
  doc.setFontSize(16);
  doc.text('Enrollment Report', 105, currentY + 10, { align: 'center' });
  
  // Add date
  doc.setFontSize(10);
  doc.text(`Generated on: ${new Date().toLocaleDateString()}`, 105, currentY + 20, { align: 'center' });
  
  // Add overview
  doc.setFontSize(12);
  doc.text('Overview', 14, currentY + 35);
  autoTable(doc, {
    startY: currentY + 40,
    head: [['Metric', 'Value']],
    body: [
      ['Total Enrollment', totalEnrollment.toString()],
      ['Boys', `${totalBoys} (${((totalBoys / totalEnrollment) * 100).toFixed(1)}%)`],
      ['Girls', `${totalGirls} (${((totalGirls / totalEnrollment) * 100).toFixed(1)}%)`],
    ],
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add enrollment by class
  const finalY = (doc as any).lastAutoTable.finalY || 60;
  doc.setFontSize(12);
  doc.text('Enrollment by Class', 14, finalY + 15);
  
  autoTable(doc, {
    startY: finalY + 20,
    head: [['Class', 'Boys', 'Girls', 'Total']],
    body: data.map(item => [
      item.class,
      item.boys,
      item.girls,
      item.total
    ]),
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add signature if available
  const finalY2 = (doc as any).lastAutoTable.finalY || 60;
  if (headmasterSignature) {
    try {
      console.log('Loading signature for enrollment report:', headmasterSignature);
      const signatureBase64 = await urlToBase64(headmasterSignature);
      doc.setFontSize(10);
      doc.text("Headmaster's Signature:", 14, finalY2 + 15);
      doc.addImage(signatureBase64, 'PNG', 14, finalY2 + 17, 40, 15);
    } catch (error) {
      console.error('Error adding signature to enrollment report:', error);
    }
  }
  
  // Add footer
  const pageCount = doc.getNumberOfPages();
  doc.setFontSize(8);
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(`Page ${i} of ${pageCount}`, 105, 285, { align: 'center' });
    doc.text(`© ${new Date().getFullYear()} School Management System`, 105, 290, { align: 'center' });
  }
  
  doc.save(`Enrollment_Report_${new Date().toISOString().split('T')[0]}.pdf`);
}

// Helper function to convert image URL to base64
async function urlToBase64(url: string): Promise<string> {
  try {
    const response = await fetch(url);
    const blob = await response.blob();
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  } catch (error) {
    console.error('Error converting image to base64:', error);
    throw error;
  }
}

// Generate student report card
export async function generateStudentReportCard(student: any, schoolName: string, schoolLogo?: string, headmasterSignature?: string) {
  const doc = new jsPDF();
  
  let currentY = 20;

  // Add school logo if available
  if (schoolLogo) {
    try {
      console.log('Loading logo from URL:', schoolLogo);
      const logoBase64 = await urlToBase64(schoolLogo);
      doc.addImage(logoBase64, 'PNG', 14, 10, 30, 30);
      currentY = 45;
      console.log('Logo added successfully');
    } catch (error) {
      console.error('Error adding logo to PDF:', error);
      currentY = 20;
    }
  }
  
  // Add header
  doc.setFontSize(20);
  doc.text(schoolName, 105, currentY, { align: 'center' });
  doc.setFontSize(16);
  doc.text('Student Report Card', 105, currentY + 10, { align: 'center' });
  
  // Add student information
  doc.setFontSize(12);
  doc.text('Student Information', 14, currentY + 25);
  autoTable(doc, {
    startY: currentY + 30,
    head: [['Field', 'Value']],
    body: [
      ['Name', student.name],
      ['Student Number', student.id],
      ['Class', student.class],
      ['Term', student.term || 'Current Term'],
    ],
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add academic performance
  const finalY1 = (doc as any).lastAutoTable.finalY || 50;
  doc.setFontSize(12);
  doc.text('Academic Performance', 14, finalY1 + 15);
  
  autoTable(doc, {
    startY: finalY1 + 20,
    head: [['Subject', 'Class Score (50%)', 'Exam Score (50%)', 'Total (100%)', 'Grade']],
    body: student.subjects?.map((subject: any) => [
      subject.name,
      subject.classScore,
      subject.examScore,
      subject.total,
      subject.grade
    ]) || [['No subjects recorded', '', '', '', '']],
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add summary
  const finalY2 = (doc as any).lastAutoTable.finalY || 50;
  doc.setFontSize(12);
  doc.text('Summary', 14, finalY2 + 15);
  
  autoTable(doc, {
    startY: finalY2 + 20,
    head: [['Metric', 'Value']],
    body: [
      ['Total Score', student.totalScore || 'N/A'],
      ['Class Rank', student.classRank || 'N/A'],
      ['Attendance', `${student.attendance || 'N/A'}%`],
    ],
    theme: 'grid',
    headStyles: { fillColor: [66, 66, 66] },
  });
  
  // Add remarks
  const finalY3 = (doc as any).lastAutoTable.finalY || 50;
  doc.setFontSize(12);
  doc.text("Teacher's Remarks", 14, finalY3 + 15);
  doc.setFontSize(10);
  const remarks = student.remarks || 'No remarks provided.';
  const splitRemarks = doc.splitTextToSize(remarks, 180);
  doc.text(splitRemarks, 14, finalY3 + 22);
  
  // Add signature section
  const remarksHeight = splitRemarks.length * 5;
  const signatureY = finalY3 + 30 + remarksHeight;
  
  doc.setFontSize(10);
  doc.text("Headmaster's Signature:", 14, signatureY);
  
  // Add signature image if available
  if (headmasterSignature) {
    try {
      console.log('Loading signature from URL:', headmasterSignature);
      const signatureBase64 = await urlToBase64(headmasterSignature);
      doc.addImage(signatureBase64, 'PNG', 14, signatureY + 2, 40, 15);
      console.log('Signature added successfully');
    } catch (error) {
      console.error('Error adding signature to PDF:', error);
      doc.text("_______________________", 14, signatureY + 5);
    }
  } else {
    doc.text("_______________________", 14, signatureY + 5);
  }
  
  doc.text(`Date: ${new Date().toLocaleDateString()}`, 14, signatureY + 20);
  
  // Add footer
  const pageCount = doc.getNumberOfPages();
  doc.setFontSize(8);
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(`Page ${i} of ${pageCount}`, 105, 285, { align: 'center' });
    doc.text(`© ${new Date().getFullYear()} ${schoolName}`, 105, 290, { align: 'center' });
  }
  
  doc.save(`Report_Card_${student.name.replace(/\s+/g, '_')}_${new Date().toISOString().split('T')[0]}.pdf`);
}

// Download blob helper
function downloadBlob(blob: Blob, filename: string) {
  const url = window.URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  window.URL.revokeObjectURL(url);
}

// Export data as JSON
export function exportAsJSON(data: any, filename: string) {
  const jsonString = JSON.stringify(data, null, 2);
  const blob = new Blob([jsonString], { type: 'application/json' });
  downloadBlob(blob, `${filename}.json`);
}

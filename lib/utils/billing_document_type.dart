/// Utility to determine the billing document type from the invoice ID prefix.
/// Since we reuse the Invoice model, the document type is encoded in the ID:
///   "INV-xxxx" = Invoice
///   "QUO-xxxx" = Quotation
class BillingDocumentType {
  static const String invoicePrefix = 'INV-';
  static const String quotationPrefix = 'QUO-';

  static bool isInvoice(String documentId) =>
      documentId.startsWith(invoicePrefix);

  static bool isQuotation(String documentId) =>
      documentId.startsWith(quotationPrefix);

  static String getLabel(String documentId) {
    if (isQuotation(documentId)) return 'Quotation';
    return 'Invoice';
  }

  static String getShortLabel(String documentId) {
    if (isQuotation(documentId)) return 'QUO';
    return 'INV';
  }

  /// Title-case document type name for PDF headings etc.
  static String getDocumentTitle(String documentId) {
    if (isQuotation(documentId)) return 'QUOTATION';
    return 'TAX INVOICE';
  }

  /// Returns the singular lower-case form.
  static String typeOf(String documentId) {
    if (isQuotation(documentId)) return 'quotation';
    return 'invoice';
  }
}
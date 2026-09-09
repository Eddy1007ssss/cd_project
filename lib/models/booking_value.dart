/// Historical rows without a recorded price remain explicitly estimated.
class BookingValue {
  const BookingValue(this.unitPrice, this.estimated);
  final double unitPrice;
  final bool estimated;

  factory BookingValue.fromMap(Map<String, dynamic> row) {
    final recorded = row['unit_price_myr'] as num?;
    final slot = row['slot'] as Map?;
    final attraction = slot?['attraction'] as Map?;
    return BookingValue(
      recorded?.toDouble() ?? (attraction?['entrance_price_myr'] as num?)?.toDouble() ?? 0,
      recorded == null,
    );
  }
}

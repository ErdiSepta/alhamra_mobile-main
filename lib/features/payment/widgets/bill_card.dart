import 'package:flutter/material.dart';
import '../../../core/utils/app_styles.dart';
import '../../../core/models/bill.dart';

class BillCard extends StatelessWidget {
  const BillCard({
    super.key,
    required this.bill,
    required this.selected,
    required this.onSelectedChanged,
    required this.onTap,
  });

  final Bill bill;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPayable = bill.isPayable;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: selected
              ? Border.all(color: AppStyles.primaryColor, width: 1.2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isPayable)
              Checkbox(
                value: selected,
                onChanged: (v) => onSelectedChanged(v ?? false),
                shape: const CircleBorder(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                activeColor: AppStyles.primaryColor,
              ),
            if (isPayable) const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt, color: AppStyles.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bill.title,
                          style: AppStyles.bodyText(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _buildStatusChip(bill.status),
                    ],
                  ),
                  if (bill.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      bill.subtitle!,
                      style: AppStyles.bodyText(context).copyWith(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.event, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatDate(bill.dueDate),
                                style: AppStyles.bodyText(context).copyWith(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _rupiah(isPayable ? bill.outstanding : bill.amount),
                          style: AppStyles.saldoValue(context).copyWith(fontSize: 16),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BillStatus status) {
    late Color bg;
    late Color fg;
    late String label;
    switch (status) {
      case BillStatus.pending:
      case BillStatus.unpaid:
      case BillStatus.partial:
        bg = AppStyles.dangerColor.withOpacity(0.12);
        fg = AppStyles.dangerColor;
        label = 'Menunggu';
        break;
      case BillStatus.paid:
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        label = 'Terkonfirmasi';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _rupiah(int amount) {
    final s = amount.toString();
    final reg = RegExp(r'\\B(?=(\\d{3})+(?!\\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }
}


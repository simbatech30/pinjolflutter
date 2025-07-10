import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:intl/intl.dart'; // Untuk NumberFormat
import 'dart:math'; // Untuk pow

class LoanCalculatorWidget extends StatefulWidget {
  const LoanCalculatorWidget({super.key});

  @override
  State<LoanCalculatorWidget> createState() => _LoanCalculatorWidgetState();
}

class _LoanCalculatorWidgetState extends State<LoanCalculatorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _loanAmountController = TextEditingController();
  final _interestRateController = TextEditingController(); // Suku bunga tahunan
  final _loanTermController = TextEditingController();

  String _termUnit = 'Bulan'; // Default 'Bulan' atau 'Tahun'
  final List<String> _termUnits = ['Bulan', 'Tahun'];

  double _monthlyPayment = 0.0;
  double _totalPayment = 0.0;
  double _totalInterest = 0.0;
  bool _resultsVisible = false;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final numberFormatter = NumberFormat("#,###", "id_ID");

  void _calculateLoan() {
    // ... (Fungsi _calculateLoan tetap sama seperti versi "lebih menarik tapi simple dan elegan" sebelumnya) ...
    if (_formKey.currentState!.validate()) {
      double principal = double.tryParse(_loanAmountController.text.replaceAll('.', '')) ?? 0;
      double annualInterestRate = double.tryParse(_interestRateController.text.replaceAll(',', '.')) ?? 0;
      int term = int.tryParse(_loanTermController.text) ?? 0;

      if (principal <= 0 || annualInterestRate < 0 || term <= 0) {
        setState(() { _resultsVisible = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap isi jumlah, bunga, dan jangka waktu dengan benar (angka positif).')),
        );
        return;
      }

      double monthlyInterestRate = (annualInterestRate / 100) / 12;
      int numberOfMonths = _termUnit == 'Tahun' ? term * 12 : term;

      if (numberOfMonths == 0) {
        setState(() { _resultsVisible = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jangka waktu tidak boleh nol bulan.')),
        );
        return;
      }

      if (annualInterestRate == 0) {
        _monthlyPayment = principal / numberOfMonths;
      } else {
        _monthlyPayment = principal *
            (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfMonths)) /
            (pow(1 + monthlyInterestRate, numberOfMonths) - 1);
      }

      _totalPayment = _monthlyPayment * numberOfMonths;
      _totalInterest = _totalPayment - principal;

      if (_monthlyPayment.isNaN || _monthlyPayment.isInfinite) {
        setState(() { _resultsVisible = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hasil perhitungan tidak valid. Periksa kembali input Anda.')),
        );
        return;
      }

      setState(() { _resultsVisible = true; });
    }
  }

  String _formatInputNumber(String s) {
    // ... (Fungsi _formatInputNumber tetap sama) ...
    s = s.replaceAll('.', '');
    if (s.isEmpty) return '';
    final number = int.tryParse(s);
    if (number == null) return s;
    return numberFormatter.format(number);
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextTheme textTheme = theme.textTheme;
    ColorScheme colorScheme = theme.colorScheme;

    InputDecoration inputDecoration(String label, {String? prefix, String? suffix, IconData? icon, EdgeInsetsGeometry? contentPadding}) {
      return InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        prefixIcon: icon != null ? Icon(icon, color: colorScheme.primary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder( // Border saat tidak aktif
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest, // Sedikit berbeda dari surfaceVariant
        contentPadding: contentPadding, // Untuk DropdownButtonFormField yang dense
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Kalkulator Estimasi Pinjaman',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _loanAmountController,
                decoration: inputDecoration('Jumlah Pinjaman', prefix: 'Rp ', icon: Icons.account_balance_wallet_outlined),
                // ... (sisa TextFormField Jumlah Pinjaman tetap sama) ...
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (string) {
                  string = _formatInputNumber(string);
                  _loanAmountController.value = TextEditingValue(
                    text: string,
                    selection: TextSelection.collapsed(offset: string.length),
                  );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Harap masukkan jumlah pinjaman';
                  if ((double.tryParse(value.replaceAll('.', '')) ?? 0) <= 0) return 'Jumlah pinjaman harus > 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _interestRateController,
                decoration: inputDecoration('Suku Bunga Tahunan', suffix: '% / Tahun', icon: Icons.percent_outlined),
                // ... (sisa TextFormField Suku Bunga tetap sama) ...
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,])?\d{0,2}'))
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Harap masukkan suku bunga';
                  if ((double.tryParse(value.replaceAll(',', '.')) ?? 0) < 0) return 'Suku bunga tidak boleh negatif';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _loanTermController,
                      decoration: inputDecoration('Jangka Waktu', icon: Icons.calendar_today_outlined),
                      // ... (sisa TextFormField Jangka Waktu tetap sama) ...
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Harap masukkan jangka waktu';
                        if ((int.tryParse(value) ?? 0) <= 0) return 'Jangka waktu harus > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // --- PERUBAHAN DI SINI ---
                  Flexible( // Mengganti Expanded(flex:0, ...) dengan Flexible
                    child: DropdownButtonFormField<String>(
                      isDense: true, // Membuat dropdown lebih ringkas
                      decoration: inputDecoration(
                          'Satuan',
                          // icon: null, // Icon bisa dihilangkan jika dirasa terlalu ramai
                          // Atur contentPadding agar sejajar dengan TextFormField jika perlu
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.5)
                      ),
                      value: _termUnit,
                      items: _termUnits.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _termUnit = newValue!;
                        });
                      },
                    ),
                  ),
                  // -------------------------
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                // ... (ElevatedButton tetap sama) ...
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Hitung Estimasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _calculateLoan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 2.0,
                ),
              ),
              if (_resultsVisible) ...[
                // ... (Bagian Hasil Estimasi tetap sama) ...
                const SizedBox(height: 28),
                const Divider(thickness: 1),
                const SizedBox(height: 16),
                Text(
                    'Hasil Estimasi:',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary
                    )
                ),
                const SizedBox(height: 12),
                _buildResultRow('Angsuran Bulanan:', currencyFormatter.format(_monthlyPayment), context),
                _buildResultRow('Total Pembayaran:', currencyFormatter.format(_totalPayment), context),
                _buildResultRow('Total Bunga:', currencyFormatter.format(_totalInterest), context, isInterest: true),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, BuildContext context, {bool isInterest = false}) {
    // ... (Fungsi _buildResultRow tetap sama) ...
    ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isInterest ? theme.colorScheme.error : theme.colorScheme.onSurface,
              )
          ),
        ],
      ),
    );
  }
}
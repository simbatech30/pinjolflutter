import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk SystemUiOverlayStyle
import '../widgets/loan_calculator_widget.dart';

class LoanCalculatorScreen extends StatelessWidget {
  const LoanCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- APPBAR YANG DISESUAIKAN ---
      appBar: AppBar(
        title: const Text('Kalkulator Pinjaman'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 1.0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        iconTheme: IconThemeData( // Untuk warna tombol kembali (leading icon)
          color: Theme.of(context).colorScheme.primary, // Atau onSurface
        ),
      ),
      // --- AKHIR APPBAR ---
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          child: LoanCalculatorWidget(),
        ),
      ),
    );
  }
}
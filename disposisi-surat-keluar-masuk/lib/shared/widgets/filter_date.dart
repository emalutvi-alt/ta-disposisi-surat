// lib/shared/widgets/date_range_filter_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ta_mobile_disposisi_surat/core/constants/app_color.dart';

class DateRangeFilterResult {
  final DateTime? startDate;
  final DateTime? endDate;
  final String activeChip;
  final String dateFilterLabel;

  const DateRangeFilterResult({
    required this.startDate,
    required this.endDate,
    required this.activeChip,
    required this.dateFilterLabel,
  });
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 8) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class DateRangeFilterBottomSheet {
  static Future<DateRangeFilterResult?> show({
    required BuildContext context,
    DateTime? initialStartDate,
    DateTime? initialEndDate,
    String initialChip = 'Hari ini',
  }) async {
    return await showDialog<DateRangeFilterResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        final w = MediaQuery.of(context).size.width;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: w * 0.06),
          elevation: 0,
          child: _DateRangeFilterContent(
            initialStartDate: initialStartDate,
            initialEndDate: initialEndDate,
            initialChip: initialChip,
          ),
        );
      },
    );
  }
}

class _DateRangeFilterContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String initialChip;

  const _DateRangeFilterContent({
    this.initialStartDate,
    this.initialEndDate,
    required this.initialChip,
  });

  @override
  State<_DateRangeFilterContent> createState() =>
      _DateRangeFilterContentState();
}

class _DateRangeFilterContentState extends State<_DateRangeFilterContent> {
  late DateTime? tempStart;
  late DateTime? tempEnd;
  late String selectedChip;

  late TextEditingController _startController;
  late TextEditingController _endController;

  // Track error state per field
  bool _startError = false;
  bool _endError = false;

  static const List<String> _chips = [
    'Hari ini',
    'Bulan ini',
    'Pilih tanggal',
  ];

  // Batas tahun: 5 tahun ke belakang s/d sekarang
  final DateTime _firstDate = DateTime(DateTime.now().year - 5, 1, 1);
  final DateTime _lastDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    tempStart = widget.initialStartDate;
    tempEnd = widget.initialEndDate;
    selectedChip = widget.initialChip;

    _startController = TextEditingController(
      text: _dateToString(widget.initialStartDate),
    );
    _endController = TextEditingController(
      text: _dateToString(widget.initialEndDate),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  String _dateToString(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  DateTime? _parseDate(String val) {
    try {
      if (val.length != 10) return null;
      final parts = val.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      // Validasi range tahun dinamis (5 tahun ke belakang s/d sekarang)
      if (year < _firstDate.year || year > _lastDate.year) return null;
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  void _onChipTap(String label) {
    final now = DateTime.now();
    setState(() {
      selectedChip = label;
      _startError = false;
      _endError = false;
      if (label == 'Hari ini') {
        tempStart = now;
        tempEnd = now;
        _startController.text = _dateToString(now);
        _endController.text = _dateToString(now);
      } else if (label == 'Bulan ini') {
        tempStart = DateTime(now.year, now.month, 1);
        tempEnd = now;
        _startController.text = _dateToString(tempStart);
        _endController.text = _dateToString(now);
      } else {
        tempStart = null;
        tempEnd = null;
        _startController.clear();
        _endController.clear();
      }
    });
  }

  // Buka date picker → setelah pilih, isi controller & update state
  Future<void> _openDatePicker({required bool isStart}) async {
    final initial = isStart
        ? (tempStart ?? DateTime.now())
        : (tempEnd ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(_firstDate)
          ? _firstDate
          : initial.isAfter(_lastDate)
              ? _lastDate
              : initial,
      firstDate: _firstDate,
      lastDate: isStart ? _lastDate : _lastDate,
      locale: const Locale('id', 'ID'), // format Indonesia
      builder: (context, child) {
        // Warna date picker ikut AppColors
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.bluePrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        tempStart = picked;
        _startController.text = _dateToString(picked);
        _startError = false;
        // Reset endDate kalau start > end
        if (tempEnd != null && picked.isAfter(tempEnd!)) {
          tempEnd = null;
          _endController.clear();
        }
      } else {
        tempEnd = picked;
        _endController.text = _dateToString(picked);
        _endError = false;
      }
    });
  }

  void _onManualChanged(String val, {required bool isStart}) {
    if (val.length < 10) {
      // Belum lengkap → clear state, no error shown yet
      setState(() {
        if (isStart) {
          tempStart = null;
          _startError = false;
        } else {
          tempEnd = null;
          _endError = false;
        }
      });
      return;
    }

    // Lengkap 10 karakter → validasi
    final date = _parseDate(val);
    setState(() {
      if (isStart) {
        if (date == null) {
          _startError = true;
          tempStart = null;
        } else {
          _startError = false;
          tempStart = date;
          // Reset end kalau start > end
          if (tempEnd != null && date.isAfter(tempEnd!)) {
            tempEnd = null;
            _endController.clear();
            _endError = false;
          }
        }
      } else {
        if (date == null) {
          _endError = true;
          tempEnd = null;
        } else if (tempStart != null && date.isBefore(tempStart!)) {
          // End tidak boleh sebelum start
          _endError = true;
          tempEnd = null;
        } else {
          _endError = false;
          tempEnd = date;
        }
      }
    });
  }

  String _buildLabel() {
    if (selectedChip == 'Hari ini') return 'Hari ini';
    if (selectedChip == 'Bulan ini') return 'Bulan ini';
    if (tempStart != null && tempEnd != null) {
      return '${_dateToString(tempStart)} - ${_dateToString(tempEnd)}';
    }
    return 'Semua tanggal';
  }

  bool get _canApply {
    if (selectedChip != 'Pilih tanggal') return true;
    return tempStart != null && tempEnd != null && !_startError && !_endError;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.05, w * 0.05, w * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Filter Tanggal',
            style: TextStyle(
              fontSize: (w * 0.042).clamp(15.0, 18.0),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: w * 0.035),

          // Chips
          Row(
            children: _chips.map((label) {
              final isActive = selectedChip == label;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onChipTap(label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: label != _chips.last
                        ? EdgeInsets.only(right: w * 0.02)
                        : EdgeInsets.zero,
                    padding: EdgeInsets.symmetric(vertical: w * 0.025),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.bluePrimary : Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.05),
                      border: Border.all(
                        color: isActive
                            ? AppColors.bluePrimary
                            : const Color(0xFFD1D5DB),
                        width: 1.2,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.bluePrimary.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // Fix: dari 0.03 → 0.032 + clamp supaya tidak terlalu kecil
                        fontSize: (w * 0.032).clamp(11.0, 14.0),
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Field Dari & Sampai
          if (selectedChip == 'Pilih tanggal') ...[
            SizedBox(height: w * 0.045),
            _fieldTanggal(
              label: 'Dari',
              controller: _startController,
              isStart: true,
              hasError: _startError,
              errorText: 'Tanggal tidak valid',
              w: w,
            ),
            SizedBox(height: w * 0.03),
            _fieldTanggal(
              label: 'Sampai',
              controller: _endController,
              isStart: false,
              hasError: _endError,
              errorText: tempStart != null && _endError
                  ? 'Tidak boleh sebelum tanggal awal'
                  : 'Tanggal tidak valid',
              w: w,
            ),
          ],

          SizedBox(height: w * 0.05),

          // Tombol Terapkan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canApply
                  ? () {
                      Navigator.pop(
                        context,
                        DateRangeFilterResult(
                          startDate: tempStart,
                          endDate: tempEnd,
                          activeChip: selectedChip,
                          dateFilterLabel: _buildLabel(),
                        ),
                      );
                    }
                  : null, // disable kalau belum lengkap
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bluePrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                padding: EdgeInsets.symmetric(vertical: w * 0.035),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
              ),
              child: Text(
                'Terapkan Filter',
                style: TextStyle(
                  fontSize: (w * 0.037).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldTanggal({
    required String label,
    required TextEditingController controller,
    required bool isStart,
    required bool hasError,
    required String errorText,
    required double w,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: (w * 0.034).clamp(12.0, 15.0),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: w * 0.015),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _DateInputFormatter(),
          ],
          style: TextStyle(fontSize: (w * 0.037).clamp(13.0, 16.0)),
          decoration: InputDecoration(
            hintText: 'dd/mm/yyyy',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: (w * 0.037).clamp(13.0, 16.0),
            ),
            // Ikon kalender → tap → buka date picker
            suffixIcon: IconButton(
              icon: Icon(
                Icons.calendar_today_rounded,
                size: (w * 0.05).clamp(18.0, 22.0),
                color: AppColors.bluePrimary,
              ),
              onPressed: () => _openDatePicker(isStart: isStart),
            ),
            filled: true,
            fillColor:
                hasError ? Colors.red.shade50 : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.03),
              borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.03),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red.shade400
                    : const Color(0xFFE2E5EA),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(w * 0.03),
              borderSide: BorderSide(
                color:
                    hasError ? Colors.red.shade400 : AppColors.bluePrimary,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: w * 0.035,
              vertical: w * 0.03,
            ),
            // Error message di bawah field
            errorText: hasError ? errorText : null,
            errorStyle: TextStyle(
              fontSize: (w * 0.03).clamp(10.0, 12.0),
              color: Colors.red.shade600,
            ),
          ),
          onChanged: (val) => _onManualChanged(val, isStart: isStart),
        ),
      ],
    );
  }
}
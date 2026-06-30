import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aqar/core/theme/app_colors.dart';
import 'package:aqar/features/property/domain/entities/property_entity.dart';
import 'package:aqar/features/property/domain/entities/property_enums.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_bloc.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_event.dart';
import 'package:aqar/features/rent_request/presentation/bloc/rent_request_state.dart';

class CreateRentRequestSheet extends StatefulWidget {
  final PropertyEntity property;

  const CreateRentRequestSheet({
    super.key,
    required this.property,
  });

  @override
  State<CreateRentRequestSheet> createState() => _CreateRentRequestSheetState();
}

class _CreateRentRequestSheetState extends State<CreateRentRequestSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _isSubmitting = false;

  bool get _isMonthly => widget.property.pricingUnit == PricingUnit.month;

  double get _totalPrice {
    if (_checkIn == null || _checkOut == null) return 0;
    if (_isMonthly) return widget.property.priceValue;
    final days = _checkOut!.difference(_checkIn!).inDays;
    if (days <= 0) return 0;
    return widget.property.pricePerDay * days;
  }

  String? _dateError;
  String? _rangeError;

  void _validateDates() {
    setState(() {
      _dateError = null;
      _rangeError = null;
    });

    if (_checkIn == null || _checkOut == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_checkIn!.isBefore(today)) {
      setState(() => _dateError = 'Check-in cannot be in the past');
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) || _checkOut == _checkIn) {
      setState(() => _rangeError = 'Check-out must be after check-in');
      return;
    }

    if (!_isMonthly) {
      final days = _checkOut!.difference(_checkIn!).inDays;
      if (days > 90) {
        setState(() => _rangeError = 'Maximum 90 days for daily rental');
        return;
      }
    }
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(_checkIn!)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
      _validateDates();
    }
  }

  void _submit() {
    if (_isSubmitting) return;

    if (_checkIn == null || _checkOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select check-in and check-out dates')),
      );
      return;
    }

    _validateDates();
    if (_dateError != null || _rangeError != null) return;

    final rentingType = _isMonthly ? 'MONTH' : 'DAY';

    setState(() => _isSubmitting = true);

    context.read<RentRequestBloc>().add(CreateRentRequest(
      propertyId: widget.property.propertyId,
      checkInDate: _checkIn!.toIso8601String().substring(0, 10),
      checkOutDate: _checkOut!.toIso8601String().substring(0, 10),
      rentingType: rentingType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RentRequestBloc, RentRequestState>(
      listener: (context, state) {
        if (state is RentRequestActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }
        if (state is RentRequestError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Request to Rent',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                widget.property.propertyName,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 20),

              Text(
                'Check-in Date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              _dateButton(
                _checkIn != null ? _checkIn!.toString().substring(0, 10) : 'Select date',
                () => _pickDate(true),
              ),
              if (_dateError != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _dateError!,
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              SizedBox(height: 16),

              Text(
                'Check-out Date',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              _dateButton(
                _checkOut != null ? _checkOut!.toString().substring(0, 10) : 'Select date',
                () => _pickDate(false),
              ),
              if (_rangeError != null)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    _rangeError!,
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              SizedBox(height: 24),

              if (_totalPrice > 0)
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'EGP ${_totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: text.startsWith('Select') ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.calendar_today, size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

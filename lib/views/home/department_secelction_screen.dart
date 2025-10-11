//==============================================================================
// Department Selection Screen
//==============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/departments.dart';
import '../../models/department_model.dart' as app_models;
import '../../viewmodels/home_viewmodel.dart';

class DepartmentSelectionScreen extends StatefulWidget {
  const DepartmentSelectionScreen({super.key});

  @override
  State<DepartmentSelectionScreen> createState() => _DepartmentSelectionScreenState();
}

class _DepartmentSelectionScreenState extends State<DepartmentSelectionScreen> {
  app_models.Department? _selectedDepartment;
  bool _isSaving = false;

  void _saveDepartment() async {
    if (_selectedDepartment == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      await context.read<HomeViewModel>().updateUserDepartment(_selectedDepartment!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save department: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.school_outlined, size: 60, color: colors.secondary),
              const SizedBox(height: 24),
              Text('Select Your Department', style: textTheme.headlineSmall?.copyWith(color: colors.onBackground), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('This helps us personalize your content.', style: textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              DropdownButtonFormField<app_models.Department>(
                decoration: InputDecoration(
                  labelText: 'Choose your department',
                  labelStyle: TextStyle(color: colors.onSurfaceVariant),
                  filled: true,
                  fillColor: colors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.secondary, width: 2),
                  ),
                ),
                dropdownColor: colors.surface,
                value: _selectedDepartment,
                isExpanded: true,
                items: allDepartments.map((department) {
                  return DropdownMenuItem<app_models.Department>(value: department, child: Text(department.name, style: TextStyle(color: colors.onSurface)));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedDepartment = newValue);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (_selectedDepartment == null || _isSaving) ? null : _saveDepartment,
                child: _isSaving
                    ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : const Text('Save and Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../models/department_model.dart';
import '../../viewmodels/question_upload_viewmodel.dart';

/// A screen for users to upload exam questions by filling out a detailed form
/// and selecting either a PDF or a series of images.
class QuestionUploadScreen extends StatelessWidget {
  const QuestionUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide the UploadViewModel to this screen and its descendants.
    return ChangeNotifierProvider(
      create: (_) => UploadViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Exam Question'),
        ),
        // Use a Consumer to listen for state changes in the ViewModel.
        body: Consumer<UploadViewModel>(
          builder: (context, viewModel, _) {
            // Show a success message as a SnackBar after a successful upload.
            // This is done in a post-frame callback to avoid build-time errors.
            if (viewModel.uploadSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upload successful! Form has been reset.'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reset the flag to prevent the SnackBar from showing again on rebuilds.
                viewModel.resetUploadSuccess();
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader(context, 'Exam Details'),
                  const SizedBox(height: 24.0),
                  _buildDepartmentDropdown(context, viewModel),
                  const SizedBox(height: 16.0),
                  _buildCourseDropdown(context, viewModel),
                  const SizedBox(height: 16.0),
                  _buildExamTypeDropdown(context, viewModel),
                  const SizedBox(height: 16.0),
                  _buildYearAndSemesterRow(context, viewModel),
                  const SizedBox(height: 16.0),
                  _buildTeacherNameField(viewModel),
                  const SizedBox(height: 32.0),
                  _buildSectionHeader(context, 'Question File'),
                  const SizedBox(height: 24.0),
                  _buildFilePickerButtons(context, viewModel),
                  const SizedBox(height: 16.0),
                  // Animate the appearance of the file preview section.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: _buildFilePreview(context, viewModel),
                  ),
                  const SizedBox(height: 32.0),
                  _buildUploadButton(context, viewModel),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Builder Methods for UI Components ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDepartmentDropdown(BuildContext context, UploadViewModel viewModel) {
    return DropdownButtonFormField<Department>(
      value: viewModel.selectedDepartment,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Department',
        prefixIcon: Icon(Icons.school_outlined),
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select Department'),
      items: viewModel.departments.map((dept) {
        return DropdownMenuItem(value: dept, child: Text(dept.name, overflow: TextOverflow.ellipsis));
      }).toList(),
      onChanged: (dept) {
        if (dept != null) {
          viewModel.fetchCoursesForDepartment(dept);
        }
      },
    );
  }

  Widget _buildCourseDropdown(BuildContext context, UploadViewModel viewModel) {
    return DropdownButtonFormField<Course>(
      value: viewModel.selectedCourse,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Course',
        prefixIcon: const Icon(Icons.book_outlined),
        border: const OutlineInputBorder(),
        // Show a loading indicator while courses are being fetched.
        suffixIcon: viewModel.isCoursesLoading ? const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ) : null,
      ),
      hint: Text(viewModel.selectedDepartment == null ? 'Select a department first' : 'Select Course'),
      // Disable the dropdown if no department is selected or if courses are loading.
      onChanged: viewModel.selectedDepartment == null || viewModel.isCoursesLoading
          ? null
          : viewModel.selectCourse,
      items: viewModel.courses.map((course) {
        return DropdownMenuItem(value: course, child: Text('${course.code} - ${course.name}', overflow: TextOverflow.ellipsis));
      }).toList(),
    );
  }

  Widget _buildExamTypeDropdown(BuildContext context, UploadViewModel viewModel) {
    return DropdownButtonFormField<String>(
      value: viewModel.selectedExamType,
      decoration: const InputDecoration(
        labelText: 'Exam Type',
        prefixIcon: Icon(Icons.article_outlined),
        border: OutlineInputBorder(),
      ),
      items: viewModel.examTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      onChanged: viewModel.selectExamType,
    );
  }

  Widget _buildYearAndSemesterRow(BuildContext context, UploadViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: viewModel.selectedYear,
            decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
            items: viewModel.yearList.map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))).toList(),
            onChanged: viewModel.selectYear,
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: viewModel.selectedSemester,
            decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
            items: viewModel.semesterList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: viewModel.selectSemester,
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherNameField(UploadViewModel viewModel) {
    return TextFormField(
      controller: viewModel.teacherNameController,
      decoration: const InputDecoration(
        labelText: 'Teacher Name (Optional)',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildFilePickerButtons(BuildContext context, UploadViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: viewModel.pickPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Select PDF'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview(BuildContext context, UploadViewModel viewModel) {
    if (viewModel.selectedImages.isEmpty && viewModel.selectedPdf == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: viewModel.selectedPdf != null
          ? _buildPdfPreview(context, viewModel)
          : _buildImagePreviews(context, viewModel),
    );
  }

  Widget _buildImagePreviews(BuildContext context, UploadViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selected Images (${viewModel.selectedImages.length})'),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.selectedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    viewModel.selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPdfPreview(BuildContext context, UploadViewModel viewModel) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 36),
      title: Text(viewModel.selectedPdf!.path.split('/').last, overflow: TextOverflow.ellipsis),
      subtitle: const Text('PDF Selected'),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: viewModel.clearFiles,
        tooltip: 'Clear selection',
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, UploadViewModel viewModel) {
    if (viewModel.isUploading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (viewModel.lastUploadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              viewModel.lastUploadError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ElevatedButton.icon(
          onPressed: viewModel.uploadQuestion,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('UPLOAD QUESTION'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

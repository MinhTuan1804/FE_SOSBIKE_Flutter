import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

class AddNoteView extends StatefulWidget {
  const AddNoteView({
    super.key,
    required this.initialNote,
    required this.onSave,
    required this.onCancel,
  });

  final String initialNote;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  @override
  State<AddNoteView> createState() => _AddNoteViewState();
}

class _AddNoteViewState extends State<AddNoteView> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Darkened background
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        Column(
          children: [
            _buildFlowHeader(context, onBack: widget.onCancel),
            const Spacer(),
            // Main Bottom Sheet for Notes input
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Ghi chú cho Thợ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Note TextField
                  TextField(
                    controller: _noteController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Thêm chi tiết điểm đón (vd: gần tạp hóa A)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      counterText: '', // Hide default counter
                      contentPadding: const EdgeInsets.all(16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                    ),
                    onChanged: (text) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_noteController.text.length}/200 kí tự',
                      style: TextStyle(color: Colors.red[300], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => widget.onSave(_noteController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFlowHeader(BuildContext context, {required VoidCallback onBack}) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 8, bottom: 12, left: 16),
      color: AppColors.primary,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
            onPressed: onBack,
          ),
        ),
      ),
    );
  }
}

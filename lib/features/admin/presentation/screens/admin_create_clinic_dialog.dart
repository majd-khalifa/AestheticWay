import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/admin_clinic_editor.dart';

/// Super-admin provisioning wrapper; the editor owns and disposes all form state.
class AdminCreateClinicDialog extends StatelessWidget {
  const AdminCreateClinicDialog({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface(context),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * .94,
      child: const AdminCreateClinicDialog(),
    ),
  );
  @override
  Widget build(BuildContext context) => const AdminClinicEditor();
}

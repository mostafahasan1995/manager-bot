import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/features/reconciliation/data/break_view.dart';

/// What the admin chose in a [ResolveBreakSheet].
class ResolveBreakRequest {
  const ResolveBreakRequest({required this.status, required this.note});

  final BreakStatus status;

  /// Already trimmed and guaranteed non-empty.
  final String note;
}

/// Closing a break: pick the terminal status, then say why.
///
/// The three statuses are NOT interchangeable, so each carries its meaning on
/// screen rather than being an unexplained radio button.
///
/// The note is required HERE because the backend is not going to enforce it:
/// `ResolveBreakDto.note` has `@IsString` and `@MaxLength(2000)` but no
/// `@IsNotEmpty`, so an empty string is accepted server-side despite the doc
/// comment. This sheet is the only thing standing between an auditor and a
/// closed money difference with no explanation.
class ResolveBreakSheet extends StatefulWidget {
  const ResolveBreakSheet({required this.breakView, super.key});

  /// Returns null when dismissed without confirming.
  static Future<ResolveBreakRequest?> show(
    BuildContext context, {
    required BreakView breakView,
  }) {
    return showModalBottomSheet<ResolveBreakRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ResolveBreakSheet(breakView: breakView),
      ),
    );
  }

  /// The note limit the DTO enforces after trimming.
  static const int noteMaxLength = 2000;

  final BreakView breakView;

  @override
  State<ResolveBreakSheet> createState() => _ResolveBreakSheetState();
}

class _ResolveBreakSheetState extends State<ResolveBreakSheet> {
  final TextEditingController _noteController = TextEditingController();
  BreakStatus _status = BreakStatus.resolved;
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _noteController
      ..removeListener(_onNoteChanged)
      ..dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    final bool next = _noteController.text.trim().isNotEmpty;
    if (next != _canConfirm) {
      setState(() => _canConfirm = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final SemanticTone colors =
        AppSemanticColors.of(context).tone(_status.tone);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(s.closeBreakSheetTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            s.closeBreakSheetHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // The group value and the change callback live on the RadioGroup
          // ancestor; per-tile groupValue/onChanged were deprecated in 3.32.
          RadioGroup<BreakStatus>(
            groupValue: _status,
            onChanged: (BreakStatus? value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final BreakStatus status in BreakStatus.terminal)
                  RadioListTile<BreakStatus>(
                    value: status,
                    contentPadding: EdgeInsets.zero,
                    title: Text(status.label(s)),
                    subtitle: Text(
                      status.closingMeaning(s),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: ResolveBreakSheet.noteMaxLength,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: s.resolutionNoteLabel,
              hintText: s.resolutionNoteHint,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _canConfirm
                ? () => Navigator.of(context).pop(
                      ResolveBreakRequest(
                        status: _status,
                        note: _noteController.text.trim(),
                      ),
                    )
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.foreground,
              foregroundColor: theme.colorScheme.surface,
            ),
            child: Text(s.closeAsStatus(status: _status.label(s))),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }
}

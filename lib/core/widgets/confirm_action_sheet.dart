import 'package:flutter/material.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';

/// What the admin chose in a [ConfirmActionSheet].
class ConfirmActionResult {
  const ConfirmActionResult({required this.confirmed, this.note});

  /// Always true when returned from the sheet - a dismissal returns null
  /// instead. Kept explicit so `result?.confirmed ?? false` reads naturally.
  final bool confirmed;

  /// Trimmed note / rejection reason, or null when the sheet had no note field
  /// or the field was left empty.
  final String? note;
}

/// A modal confirmation for an irreversible money action.
///
/// Approving a deposit credits a player and moves agent float, so the console
/// never fires one on a single tap. The sheet can also collect the note the
/// backend wants alongside a rejection.
///
/// ```dart
/// final AppStrings s = context.s;
/// final result = await ConfirmActionSheet.show(
///   context,
///   title: s.confirmApproveAmountTitle(amount: deposit.claimed.format()),
///   message: s.confirmPlayerWillBeCredited(playerId: deposit.playerId),
///   confirmLabel: s.actionApprove,
///   tone: StatusTone.approve,
/// );
/// if (result?.confirmed ?? false) { ... }
/// ```
class ConfirmActionSheet extends StatefulWidget {
  const ConfirmActionSheet({
    required this.title,
    required this.confirmLabel,
    this.message,
    this.cancelLabel,
    this.tone = StatusTone.neutral,
    this.withNote = false,
    this.noteLabel,
    this.noteHint,
    this.noteRequired = false,
    this.noteMaxLength = 500,
    super.key,
  });

  /// Shows the sheet and resolves to null when dismissed without confirming.
  ///
  /// [cancelLabel] and [noteLabel] fall back to [AppStrings.cancel] and
  /// [AppStrings.note] in the admin's language.
  static Future<ConfirmActionResult?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    String? cancelLabel,
    StatusTone tone = StatusTone.neutral,
    bool withNote = false,
    String? noteLabel,
    String? noteHint,
    bool noteRequired = false,
    int noteMaxLength = 500,
  }) {
    return showModalBottomSheet<ConfirmActionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ConfirmActionSheet(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          tone: tone,
          withNote: withNote,
          noteLabel: noteLabel,
          noteHint: noteHint,
          noteRequired: noteRequired,
          noteMaxLength: noteMaxLength,
        ),
      ),
    );
  }

  final String title;
  final String? message;
  final String confirmLabel;

  /// Defaults to [AppStrings.cancel] when null.
  final String? cancelLabel;

  /// Colours the confirm button: `approve` green, `reject` red, and so on.
  final StatusTone tone;

  final bool withNote;

  /// Defaults to [AppStrings.note] when null.
  final String? noteLabel;

  final String? noteHint;

  /// When true the confirm button stays disabled until a note is typed.
  final bool noteRequired;

  final int noteMaxLength;

  @override
  State<ConfirmActionSheet> createState() => _ConfirmActionSheetState();
}

class _ConfirmActionSheetState extends State<ConfirmActionSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _canConfirm = !(widget.withNote && widget.noteRequired);
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
    if (!widget.withNote || !widget.noteRequired) {
      return;
    }
    final next = _noteController.text.trim().isNotEmpty;
    if (next != _canConfirm) {
      setState(() => _canConfirm = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppStrings s = context.s;
    final colors = AppSemanticColors.of(context).tone(widget.tone);
    final message = widget.message;
    final String noteLabel = widget.noteLabel ?? s.note;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(widget.title, style: theme.textTheme.titleLarge),
          if (message != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (widget.withNote) ...<Widget>[
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: widget.noteMaxLength,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: widget.noteRequired
                    ? s.noteRequiredSuffix(label: noteLabel)
                    : noteLabel,
                hintText: widget.noteHint,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canConfirm
                ? () {
                    final note = _noteController.text.trim();
                    Navigator.of(context).pop(
                      ConfirmActionResult(
                        confirmed: true,
                        note: note.isEmpty ? null : note,
                      ),
                    );
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.foreground,
              foregroundColor: theme.colorScheme.surface,
            ),
            child: Text(widget.confirmLabel),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.cancelLabel ?? s.cancel),
          ),
        ],
      ),
    );
  }
}

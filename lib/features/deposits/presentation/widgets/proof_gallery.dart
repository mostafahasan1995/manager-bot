import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/app_localizations_x.dart';
import 'package:manager_bot/core/i18n/app_strings.dart';
import 'package:manager_bot/core/theme/app_theme.dart';
import 'package:manager_bot/core/widgets/widgets.dart';
import 'package:manager_bot/features/deposits/application/deposit_proof_controller.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';
import 'package:manager_bot/features/deposits/presentation/widgets/deposit_formatting.dart';

/// Every proof on a deposit, as a horizontal strip of thumbnails.
///
/// The bytes CANNOT come from `Image.network`: the streaming route requires the
/// admin bearer token and there is no signed-URL variant of it, so each tile
/// fetches through the API client and renders `Image.memory`.
class ProofGallery extends StatelessWidget {
  const ProofGallery({
    required this.depositId,
    required this.proofs,
    super.key,
  });

  final String depositId;
  final List<DepositProofView> proofs;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (proofs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.image_not_supported_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.s.proofNone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: proofs.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) => ProofThumbnail(
          depositId: depositId,
          proof: proofs[index],
          index: index,
          total: proofs.length,
        ),
      ),
    );
  }
}

/// One proof tile: loading, image, or an explained failure.
class ProofThumbnail extends ConsumerWidget {
  const ProofThumbnail({
    required this.depositId,
    required this.proof,
    required this.index,
    required this.total,
    super.key,
  });

  final String depositId;
  final DepositProofView proof;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final ProofImageRequest request =
        ProofImageRequest(depositId: depositId, proof: proof);
    final AsyncValue<ProofImage> image = ref.watch(proofImageProvider(request));

    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: image.when(
                  skipLoadingOnRefresh: false,
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                  error: (Object error, StackTrace stackTrace) => _ProofProblem(
                    message: ErrorPresentation.of(error, s).message,
                    onRetry: () => ref.invalidate(proofImageProvider(request)),
                  ),
                  data: (ProofImage loaded) => switch (loaded) {
                    ProofImageBytes(:final bytes) => InkWell(
                        onTap: () => _openViewer(context, loaded),
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          // Bytes that decode to nothing are still a failure the
                          // reviewer must see rather than a blank grey box.
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) =>
                              _ProofProblem(message: s.proofDecodeFailed),
                        ),
                      ),
                    ProofImageUnavailable(:final message) => _ProofProblem(
                        message: message,
                        onRetry: () =>
                            ref.invalidate(proofImageProvider(request)),
                      ),
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            s.proofIndexOfTotal(index: index + 1, total: total),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            s.proofThumbnailCaption(
              source: proof.sourceLabel(s),
              size: proof.sizeLabel(s),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(BuildContext context, ProofImageBytes image) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (BuildContext context) =>
              _ProofViewer(proof: proof, image: image),
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of one receipt.
class _ProofViewer extends StatelessWidget {
  const _ProofViewer({required this.proof, required this.image});

  final DepositProofView proof;
  final ProofImageBytes image;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStrings s = context.s;
    final String localeTag = context.localeTag;
    final String? dimensions = proof.dimensionLabel(s);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.proofViewerTitle),
        actions: <Widget>[
          IconButton(
            tooltip: s.detailsTooltip,
            icon: const Icon(Icons.info_outline),
            onPressed: () => unawaited(
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext sheetContext) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.proofDetailsTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _DetailLine(s.proofDetailSource, proof.sourceLabel(s)),
                        _DetailLine(s.proofDetailStoredType, proof.mimeType),
                        _DetailLine(s.proofDetailServedAs, image.mimeType),
                        _DetailLine(s.proofDetailSize, proof.sizeLabel(s)),
                        if (dimensions != null)
                          _DetailLine(s.proofDetailDimensions, dimensions),
                        _DetailLine(
                          s.proofDetailUploaded,
                          DepositFormat.timestamp(
                            proof.createdAt,
                            s,
                            localeTag,
                          ),
                        ),
                        _DetailLine(s.proofDetailSha256, proof.shortHash),
                        _DetailLine(
                          s.proofDetailFetchedVia,
                          image.viaPresignedUrl
                              ? s.proofViaPresignedUrl
                              : s.proofViaApiStream,
                        ),
                        const SizedBox(height: 10),
                        // The upload stamp above is local time; the bot is UTC.
                        Text(
                          s.timesAreLocalNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          maxScale: 6,
          child: Image.memory(image.bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTheme.monoStyle(context)),
          ),
        ],
      ),
    );
  }
}

/// A proof that could not be shown, with the reason and a retry.
class _ProofProblem extends StatelessWidget {
  const _ProofProblem({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.broken_image_outlined,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: 4),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(context.s.retry),
            ),
          ],
        ],
      ),
    );
  }
}

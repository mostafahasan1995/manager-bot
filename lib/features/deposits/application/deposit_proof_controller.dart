import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manager_bot/core/i18n/locale_controller.dart';
import 'package:manager_bot/features/deposits/data/admin_deposit_view.dart';
import 'package:manager_bot/features/deposits/data/deposit_repository.dart';
import 'package:manager_bot/features/deposits/data/deposit_results.dart';

/// Identifies one proof image. Both ids are needed because the proof routes are
/// SCOPED BY DEPOSIT: a proofId belonging to another deposit answers 404, which
/// is deliberate anti-enumeration and not a bug to work around.
class ProofImageRequest {
  const ProofImageRequest({required this.depositId, required this.proof});

  final String depositId;
  final DepositProofView proof;

  @override
  bool operator ==(Object other) =>
      other is ProofImageRequest &&
      other.depositId == depositId &&
      other.proof.id == proof.id;

  @override
  int get hashCode => Object.hash(depositId, proof.id);

  @override
  String toString() => 'ProofImageRequest($depositId/${proof.id})';
}

/// Bytes for one proof, fetched WITH the admin bearer token.
///
/// A plain `Image.network` cannot load these: the streaming route needs the
/// same Authorization header as every other admin call and there is no
/// signed-URL or query-token variant of it. The repository handles the
/// presigned-URL-first, stream-second fallback and returns a
/// [ProofImageUnavailable] instead of throwing, so one broken receipt never
/// takes down the review screen.
///
/// Auto-disposed on purpose: presigned URLs live 5 minutes, the bytes are
/// personal data, and caching a receipt after the reviewer leaves the screen
/// buys nothing.
final AutoDisposeFutureProviderFamily<ProofImage, ProofImageRequest>
    proofImageProvider =
    FutureProvider.autoDispose.family<ProofImage, ProofImageRequest>(
  (ref, request) => ref.read(depositRepositoryProvider).loadProofImage(
        request.depositId,
        request.proof,
        // read, not watch: a language change must not throw away bytes that are
        // already on screen. Only the NEXT fetch speaks the new language.
        strings: ref.read(stringsProvider),
      ),
);

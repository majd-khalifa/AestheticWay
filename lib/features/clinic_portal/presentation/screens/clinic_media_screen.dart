import 'dart:io';
import 'package:dio/dio.dart';
import '../../services/showcase_video_change.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../../../core/auth/session_snapshot.dart';
import '../../../../core/data/paged_collection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/media_file_policy.dart';
import '../../../../core/widgets/portal_media_frame.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/luxury_image_picker_field.dart';
import '../../../../core/widgets/pagination_footer.dart';
import '../../../../core/widgets/silver_button.dart';
import '../../../clinics/models/clinic_model.dart';
import '../../data/clinic_media_repository.dart';
import '../../services/clinic_portal_service.dart';

/// Clinic-owned gallery assets and the actual profile showcase-video field.
/// No URL inputs, gallery-array PATCH, ad campaign mutation or fabricated poster field.
class ClinicMediaScreen extends StatefulWidget {
  const ClinicMediaScreen({super.key, this.repository});
  final ClinicMediaRepository? repository;
  @override
  State<ClinicMediaScreen> createState() => _ClinicMediaScreenState();
}

class _ClinicMediaScreenState extends State<ClinicMediaScreen>
    with WidgetsBindingObserver {
  final _service = ClinicPortalService();
  final _session = SessionSnapshot();
  late String _clinicId;
  late final ClinicMediaRepository _repository;
  late final PagedCollection<ClinicGalleryAsset> _gallery;
  final _pending = <String>[];
  final _galleryReceipts = <String, ClinicGalleryAsset>{};
  CancelToken? _galleryCancel;
  double? _galleryProgress;
  bool _galleryUncertain = false, _galleryRetryConfirmation = false;
  List<ClinicGalleryAsset> get _displayGallery => [
    ..._gallery.items,
    ..._galleryReceipts.values.where(
      (a) => !_gallery.items.any((r) => r.id == a.id),
    ),
  ];
  bool _busy = false, _confirming = false;
  int _completed = 0, _batchSize = 0;
  String? _error, _notice, _videoPath, _posterPath;
  bool _posterChanged = false;
  bool _profileLoading = false, _profileVerified = false;
  String? _profileError, _videoError, _videoNotice;
  String? _videoDiagnostic;
  ShowcaseVideoReceipt? _videoReceipt;
  CancelToken? _videoCancel;
  double? _videoProgress;
  bool _videoUncertain = false;
  VideoPlayerController? _player;
  bool get ar => LocaleService().isArabic;
  bool get _roleAllowed =>
      AuthState().isLoggedIn &&
      (AuthState().isClinicAdmin || AuthState().isClinicStaff);
  bool get _locked =>
      _busy ||
      _confirming ||
      _profileLoading ||
      !_profileVerified ||
      !_roleAllowed ||
      !_session.isCurrent;
  bool get _videoAllowed =>
      _profileVerified &&
      _service.activeClinic.subscriptionTierKnown &&
      _service.activeClinic.subscriptionTier == SubscriptionTier.vipPlatinum;
  int get _remaining => math
      .max(
        0,
        10 -
            math.max(_gallery.total ?? 0, _displayGallery.length) -
            _pending.length,
      )
      .toInt();
  @override
  void initState() {
    super.initState();
    _clinicId = _service.activeClinic.id;
    _repository = widget.repository ?? ClinicMediaRepository();
    _gallery = PagedCollection<ClinicGalleryAsset>(
      keyOf: (a) => a.id,
      loader: (page, _) async {
        final rows = await _repository.getGallery(_clinicId, page: page);
        if (mounted && _session.isCurrent) {
          _galleryReceipts.removeWhere((id, _) => rows.any((r) => r.id == id));
        }
        return rows;
      },
    );
    WidgetsBinding.instance.addObserver(this);
    AuthState().addListener(_sessionChanged);
    if (_roleAllowed) {
      if (_clinicId.isNotEmpty) _gallery.refresh();
      _loadOwnedProfile();
    }
  }

  void _sessionChanged() {
    if (!_session.isCurrent) {
      _videoCancel?.cancel();
      _galleryCancel?.cancel();
      _videoReceipt = null;
      _videoError = null;
      _videoDiagnostic = null;
      _videoNotice = null;
      _videoUncertain = false;
      _gallery.clear();
      _galleryReceipts.clear();
      _pending.clear();
      _player?.dispose();
      _player = null;
      _videoPath = null;
      _posterPath = null;
      _posterChanged = false;
      if (mounted) {
        setState(
          () => _error = ar
              ? 'تغيرت الجلسة. أغلق هذه الشاشة وأعد فتحها.'
              : 'Your session changed. Close and reopen this screen.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _player?.pause();
    } else if (!_busy && !_confirming && _session.isCurrent && _roleAllowed) {
      _loadOwnedProfile();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthState().removeListener(_sessionChanged);
    _videoCancel?.cancel();
    _galleryCancel?.cancel();
    _gallery.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<bool> _loadOwnedProfile({bool forVideo = false}) async {
    if (_profileLoading || !_session.isCurrent || !_roleAllowed) return false;
    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      await _service.refreshClinicProfile();
      _session.ensureCurrent();
      final id = _service.activeClinic.id;
      if (id.isEmpty || (_clinicId.isNotEmpty && id != _clinicId)) {
        throw const ApiException(
          message: 'Clinic identity changed. Close and reopen this screen.',
        );
      }
      final first = _clinicId.isEmpty;
      _clinicId = id;
      if (first) await _gallery.refresh();
      if (mounted) setState(() => _profileVerified = true);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileVerified = false;
          if (forVideo) {
            _videoError = ShowcaseVideoFailure(
              VideoSaveStage.entitlement,
              cause: e is ApiException ? e : null,
            ).message;
          } else {
            _profileError = ar
                ? 'تعذر التحقق من ملف العيادة الحالي. حدّث البيانات قبل إدارة الوسائط.'
                : 'Could not verify the current clinic profile. Refresh before managing media.';
          }
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  void _selected(List<String> paths) {
    if (_locked) return;
    setState(() {
      _pending.addAll(
        paths.where((p) => !_pending.contains(p)).take(_remaining),
      );
      _notice = null;
    });
  }

  String _failure(Object e) => !_session.isCurrent
      ? (ar
            ? 'تغيرت الجلسة. أغلق الشاشة وأعد فتحها.'
            : 'Your session changed. Close and reopen this screen.')
      : e is ApiException
      ? (e.isCancelled && e.message.isEmpty
            ? (ar ? 'أُلغي رفع الصورة.' : 'Image upload cancelled.')
            : e.message)
      : (ar
            ? 'تعذر إتمام العملية. تحقق من الملف والاتصال والصلاحيات وحاول مجدداً.'
            : 'Could not complete this operation. Check the file, connection and permissions, then try again.');

  Future<bool> _refreshProfile() async {
    try {
      await _service.refreshClinicProfile();
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = ar
              ? 'تم حفظ تغييرات الوسائط. أعد تحميل ملف العيادة للتحقق من العرض.'
              : 'Media changes were saved. Reload the clinic profile to verify its display.',
        );
      }
    }
    return false;
  }

  Future<void> _upload() async {
    if (_locked || _galleryUncertain || _pending.isEmpty) return;
    if (_galleryRetryConfirmation) {
      setState(() => _confirming = true);
      final retry = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            ar
                ? 'مراجعة الصور قبل إعادة الرفع'
                : 'Review photos before retrying',
          ),
          content: Text(
            ar
                ? 'قد يكون الخادم حفظ آخر صورة رغم انقطاع الرد. احذف أي ملف ظاهر في الصور المحفوظة من قائمة الرفع لتجنب التكرار.'
                : 'The server may have stored the last photo despite the lost response. Remove any file already visible in saved images from the upload queue to avoid duplicates.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                ar ? 'راجعت الصور، أعد الباقي' : 'Reviewed; retry remaining',
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _confirming = false);
      if (retry != true || !_session.isCurrent) return;
    }
    setState(() {
      _busy = true;
      _batchSize = 0;
      _error = null;
      _notice = null;
      _completed = 0;
      _batchSize = _pending.length;
      _galleryProgress = null;
    });
    _galleryCancel = CancelToken();
    try {
      for (final path in List<String>.of(_pending)) {
        _session.ensureCurrent();
        final asset = await _repository.uploadGallery(
          _clinicId,
          path,
          cancelToken: _galleryCancel,
          onSendProgress: (sent, total) {
            if (mounted && _session.isCurrent) {
              setState(
                () => _galleryProgress = total > 0 ? sent / total : null,
              );
            }
          },
        );
        _session.ensureCurrent();
        if (!mounted) return;
        _gallery.mutate((items) {
          items.removeWhere((a) => a.id == asset.id);
          items.add(asset);
        });
        setState(() {
          _galleryReceipts[asset.id] = asset;
          _pending.remove(path);
          _completed++;
          _galleryProgress = null;
        });
      }
      await _refreshProfile();
      await _reviewGallery();
    } catch (e) {
      if (mounted) {
        final localValidation =
            e is ApiException &&
            (e.errorCode?.startsWith('LOCAL_MEDIA_') ?? false);
        final uncertain =
            !localValidation &&
            (e is! ApiException ||
                e.isCancelled ||
                e.statusCode == null ||
                e.statusCode! >= 500);
        setState(() {
          _galleryUncertain = uncertain;
          _galleryRetryConfirmation = uncertain;
          _error =
              '${_failure(e)}${e is ApiException && e.statusCode != null ? ' (HTTP ${e.statusCode})' : ''} ${ar ? 'راجع الصور المحفوظة قبل إعادة محاولة الملفات المتبقية؛ لم تتم إعادة إرسال الصور المؤكدة.' : 'Review saved images before retrying remaining files; acknowledged uploads are not resent.'}';
        });
        if (_completed > 0) await _refreshProfile();
      }
    } finally {
      _galleryCancel = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewGallery() async {
    final hadUnverified = _galleryReceipts.isNotEmpty;
    await _gallery.refresh();
    if (!mounted ||
        !_session.isCurrent ||
        _gallery.error != null ||
        !_gallery.isLoaded) {
      return;
    }
    setState(() {
      _galleryReceipts.removeWhere(
        (id, _) => _gallery.items.any((r) => r.id == id),
      );
      _galleryUncertain = false;
      if (_galleryReceipts.isNotEmpty) {
        _notice = ar
            ? 'وصل تأكيد الرفع؛ ظهور بعض الصور في قراءة المعرض الجديدة غير مؤكد. حدّث الصور، ولا تعد رفع الصور المؤكدة.'
            : 'Upload acknowledged; some images are not yet confirmed in the fresh gallery. Refresh saved images; do not upload acknowledged files again.';
      } else if (_galleryRetryConfirmation) {
        _notice = ar
            ? 'تم تحديث الصور المحفوظة. راجعها قبل إعادة رفع الملفات المتبقية.'
            : 'Saved images refreshed. Review them before retrying remaining files.';
      } else if (hadUnverified) {
        _notice = ar
            ? 'تم التحقق من سجلات الصور المحفوظة.'
            : 'Saved gallery records verified.';
      }
    });
  }

  Future<void> _remove(ClinicGalleryAsset asset) async {
    if (_locked) return;
    setState(() => _confirming = true);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          ar ? 'حذف الصورة نهائياً؟' : 'Permanently delete this photo?',
        ),
        content: Text(
          ar
              ? 'ستُحذف هذه الصورة فقط من معرض العيادة والتخزين. لا يمكن التراجع عن الحذف.'
              : 'Only this photo will be removed from the clinic gallery and storage. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _confirming = false);
    if (ok != true || !_session.isCurrent) return;
    setState(() {
      _busy = true;
      _batchSize = 0;
      _error = null;
    });
    try {
      await _repository.deleteGallery(_clinicId, asset);
      _session.ensureCurrent();
      _gallery.mutate((items) => items.removeWhere((a) => a.id == asset.id));
      _galleryReceipts.remove(asset.id);
      await _gallery.refresh();
      await _refreshProfile();
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseVideo() async {
    if (_locked || _videoUncertain) return;
    if (!await _loadOwnedProfile(forVideo: true) ||
        !_videoAllowed ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _batchSize = 0;
      _videoError = null;
      _videoNotice = null;
      _videoDiagnostic = null;
    });
    VideoPlayerController? probe;
    try {
      final picked = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 15),
      );
      _session.ensureCurrent();
      if (picked == null) return;
      await MediaFilePolicy.inspect(picked.path, video: true);
      probe = VideoPlayerController.file(File(picked.path));
      await probe.initialize();
      if (probe.value.duration <= Duration.zero ||
          probe.value.duration >
              const Duration(seconds: 15, milliseconds: 500)) {
        throw ApiException(
          message: ar
              ? 'اختر فيديو لا تتجاوز مدته 15 ثانية.'
              : 'Select a video up to 15 seconds.',
        );
      }
      _session.ensureCurrent();
      await _player?.dispose();
      _player = null;
      if (mounted) setState(() => _videoPath = picked.path);
    } catch (e) {
      if (mounted) setState(() => _videoError = _failure(e));
    } finally {
      await probe?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveVideo({bool remove = false}) async {
    if (_locked || _videoUncertain || (!remove && _videoPath == null)) return;
    if (!await _loadOwnedProfile(forVideo: true) ||
        (!remove && !_videoAllowed) ||
        !mounted) {
      return;
    }
    if (remove) {
      setState(() => _confirming = true);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ar ? 'إزالة الفيديو المحفوظ؟' : 'Remove saved video?'),
          content: Text(
            ar
                ? 'سيُزال الفيديو من ملف العيادة. لن تتغير صورة الغلاف.'
                : 'The video will be removed from the clinic profile. The cover image is preserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ar ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ar ? 'إزالة' : 'Remove'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _confirming = false);
      if (confirmed != true || !_session.isCurrent) return;
    }
    setState(() {
      _busy = true;
      _batchSize = 0;
      _videoError = null;
      _videoNotice = null;
    });
    try {
      _session.ensureCurrent();
      _videoCancel = CancelToken();
      await _service.updateShowcaseVideo(
        remove ? null : _videoPath,
        cancelToken: _videoCancel,
        onSendProgress: (sent, total) {
          if (mounted && _session.isCurrent) {
            setState(() => _videoProgress = total > 0 ? sent / total : null);
          }
        },
      );
      _session.ensureCurrent();
      await _player?.dispose();
      _player = null;
      if (mounted) {
        setState(() {
          _videoPath = null;
          _videoUncertain = false;
          _videoReceipt = null;
          _videoNotice = ar
              ? 'تم التحقق من حفظ تغيير الفيديو.'
              : 'Saved video change verified.';
        });
      }
    } catch (e) {
      if (mounted && _session.isCurrent) {
        setState(() {
          _videoError = _failure(e);
          _videoDiagnostic = e is ShowcaseVideoFailure
              ? e.diagnostic?.safeText(e.stage.name)
              : null;
          _videoReceipt = e is ShowcaseVideoFailure ? e.receipt : null;
          _videoUncertain =
              e is ShowcaseVideoFailure &&
              (e.stage != VideoSaveStage.upload ||
                  e.statusCode == null ||
                  e.statusCode! >= 500);
        });
      }
    } finally {
      _videoCancel = null;
      _videoProgress = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkSavedVideo() async {
    if (_busy || !_session.isCurrent) return;
    setState(() {
      _busy = true;
      _videoError = null;
    });
    try {
      final receipt = _videoReceipt;
      if (receipt != null) {
        await _service.verifyShowcaseVideo(receipt);
        _session.ensureCurrent();
        await _player?.dispose();
        _player = null;
        if (mounted) {
          setState(() {
            _videoPath = null;
            _videoNotice = ar
                ? 'تم التحقق من حفظ تغيير الفيديو.'
                : 'Saved video change verified.';
          });
        }
      } else {
        await _service.refreshClinicProfile();
        _session.ensureCurrent();
        if (mounted) {
          setState(
            () => _videoNotice = ar
                ? 'تم تحديث الملف. راجع الفيديو المحفوظ قبل إعادة الرفع؛ نتيجة المحاولة السابقة غير مؤكدة.'
                : 'Profile refreshed. Inspect the saved video before uploading again; the previous attempt remains unconfirmed.',
          );
        }
      }
      if (mounted) {
        setState(() {
          _videoUncertain = false;
          _videoReceipt = null;
        });
      }
    } catch (e) {
      if (mounted && _session.isCurrent) {
        setState(() => _videoError = _failure(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play() async {
    if (_locked) return;
    if (_player != null) {
      if (_player!.value.isPlaying) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
      if (mounted) setState(() {});
      return;
    }
    final url = _service.activeClinic.videoUrl;
    if (_videoPath == null && (url == null || url.isEmpty)) return;
    setState(() {
      _busy = true;
      _batchSize = 0;
      _videoError = null;
    });
    final player = _videoPath != null
        ? VideoPlayerController.file(File(_videoPath!))
        : VideoPlayerController.networkUrl(Uri.parse(url!));
    try {
      await player.initialize();
      _session.ensureCurrent();
      if (!mounted) {
        await player.dispose();
        return;
      }
      _player = player;
      await player.play();
    } catch (e) {
      await player.dispose();
      if (mounted) setState(() => _videoError = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discardVideo() async {
    if (_locked) return;
    final player = _player;
    setState(() {
      _player = null;
      _videoPath = null;
    });
    await player?.dispose();
  }

  Future<void> _savePoster() async {
    if (_locked || _videoUncertain || !_posterChanged) return;
    setState(() {
      _busy = true;
      _batchSize = 0;
      _error = null;
    });
    try {
      _session.ensureCurrent();
      await _service.updateClinicCover(_posterPath);
      _session.ensureCurrent();
      if (mounted) {
        setState(() {
          _posterChanged = false;
          _posterPath = null;
          _notice = ar ? 'تم تحديث صورة الغلاف.' : 'Clinic cover updated.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      bottomNavigationBar:
          _pending.isEmpty || !_session.isCurrent || !_roleAllowed
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ar
                          ? '${_pending.length} صورة محددة. اضغط الرفع للحفظ.'
                          : '${_pending.length} ${_pending.length == 1 ? 'photo' : 'photos'} selected. Upload to save.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    SilverButton(
                      label: ar
                          ? 'رفع الصور المحددة'
                          : 'Upload selected photos',
                      isLoading: _busy,
                      onPressed: _locked || _galleryUncertain ? null : _upload,
                    ),
                    if (_galleryUncertain)
                      TextButton(
                        onPressed: _locked ? null : _reviewGallery,
                        child: Text(
                          ar ? 'مراجعة الصور المحفوظة' : 'Review saved images',
                        ),
                      ),
                  ],
                ),
              ),
            ),
      appBar: AppBar(
        title: Text(ar ? 'وسائط العيادة' : 'Clinic Media'),
        actions: [
          IconButton(
            onPressed: _busy || _profileLoading ? null : _loadOwnedProfile,
            tooltip: ar
                ? 'تحديث ملف العيادة والصلاحيات'
                : 'Refresh clinic profile and permissions',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: AppColors.bg(context),
      body: !_session.isCurrent || !_roleAllowed
          ? Center(
              child: Text(
                ar
                    ? 'تغيرت الجلسة. أغلق الشاشة وأعد فتحها.'
                    : 'Your session changed. Close and reopen this screen.',
              ),
            )
          : ListenableBuilder(
              listenable: Listenable.merge([_gallery, _service]),
              builder: (context, _) {
                final clinic = _service.activeClinic;
                final vip = _videoAllowed;
                final unknownTier = !clinic.subscriptionTierKnown;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_profileLoading) const LinearProgressIndicator(),
                    if (_profileError != null) ...[
                      Text(
                        _profileError!,
                        style: TextStyle(color: AppColors.dangerText(context)),
                      ),
                      TextButton.icon(
                        onPressed: _profileLoading ? null : _loadOwnedProfile,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          ar
                              ? 'إعادة التحقق من الملف'
                              : 'Retry profile verification',
                        ),
                      ),
                    ],
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_notice != null)
                      Semantics(liveRegion: true, child: Text(_notice!)),
                    if (_busy) ...[
                      LinearProgressIndicator(
                        value: _batchSize > 0 ? _galleryProgress : null,
                      ),
                      if (_galleryCancel != null)
                        TextButton(
                          onPressed: () => _galleryCancel?.cancel(),
                          child: Text(
                            ar ? 'إلغاء رفع الصور' : 'Cancel image upload',
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _batchSize > 0
                            ? (ar
                                  ? 'تم رفع $_completed من $_batchSize'
                                  : 'Uploaded $_completed of $_batchSize')
                            : (ar
                                  ? 'جارٍ معالجة الوسائط…'
                                  : 'Processing media…'),
                      ),
                    ],
                    Text(
                      ar ? 'معرض صور العيادة' : 'Clinic photo gallery',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ar
                          ? 'تُحفظ الصور المرفوعة وتظهر مباشرةً. الحذف نهائي لصورة واحدة. تعرض الواجهة العامة أول 10 صور حسب ترتيب الخادم؛ إعادة الترتيب غير متاحة.'
                          : 'Uploads are saved and published immediately. Deletion permanently removes one photo. The public gallery shows the first 10 images in server order; reordering is unavailable.',
                    ),
                    const SizedBox(height: 12),
                    for (final asset in _displayGallery)
                      Card(
                        child: Column(
                          children: [
                            PortalMediaFrame(
                              imageUrl: asset.url,
                              expandable: true,
                              label: ar
                                  ? 'صورة من معرض العيادة'
                                  : 'Clinic gallery photo',
                            ),
                            TextButton.icon(
                              onPressed: _locked ? null : () => _remove(asset),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(
                                ar ? 'حذف هذه الصورة' : 'Delete this photo',
                              ),
                            ),
                            if (_galleryReceipts.containsKey(asset.id))
                              Text(
                                ar
                                    ? 'بانتظار تأكيد القراءة المحفوظة'
                                    : 'Awaiting saved-gallery verification',
                              ),
                          ],
                        ),
                      ),
                    PaginationFooter(
                      loading: _gallery.isLoading || _gallery.isLoadingMore,
                      hasMore: _gallery.hasMore,
                      error: _gallery.error,
                      onLoadMore: _gallery.loadMore,
                    ),
                    TextButton.icon(
                      onPressed: _locked ? null : _reviewGallery,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        ar ? 'تحديث الصور المحفوظة' : 'Refresh saved images',
                      ),
                    ),
                    for (final path in _pending)
                      Card(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 120,
                              child: PortalMediaFrame(
                                imageUrl: path,
                                height: 120,
                              ),
                            ),
                            TextButton(
                              onPressed: _locked
                                  ? null
                                  : () => setState(() {
                                      _pending.remove(path);
                                      if (_pending.isEmpty) {
                                        _galleryUncertain = false;
                                        _galleryRetryConfirmation = false;
                                      }
                                    }),
                              child: Text(
                                ar
                                    ? 'إزالة من قائمة الرفع'
                                    : 'Remove from upload queue',
                              ),
                            ),
                          ],
                        ),
                      ),
                    LuxuryImagePickerField(
                      label: ar
                          ? 'إضافة صور من الكاميرا أو المعرض'
                          : 'Add photos from Camera or Gallery',
                      height: 100,
                      enabled: !_locked && _gallery.isLoaded && _remaining > 0,
                      maxImages: math.max(1, _remaining),
                      onImageSelected: (path) {
                        if (path != null) _selected([path]);
                      },
                      onImagesSelected: _selected,
                      helperText: ar
                          ? 'JPG / PNG / WebP، حتى 5 MB للصورة، دون 25 MP.'
                          : 'JPG / PNG / WebP, up to 5 MB per image, at most 25 MP.',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      ar ? 'فيديو عرض العيادة' : 'Clinic showcase video',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (_videoError != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _videoError!,
                          key: const ValueKey('video-operation-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_videoNotice != null)
                      Semantics(liveRegion: true, child: Text(_videoNotice!)),
                    if (_videoError != null && _videoDiagnostic != null)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text(
                          ar ? 'تفاصيل آمنة للدعم' : 'Safe support details',
                        ),
                        children: [
                          SelectableText(
                            _videoDiagnostic!,
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    if (_videoCancel != null) ...[
                      LinearProgressIndicator(value: _videoProgress),
                      Text(
                        ar
                            ? 'جارٍ رفع الفيديو والتحقق من حفظه…'
                            : 'Uploading video and verifying persistence…',
                      ),
                      TextButton(
                        onPressed: () => _videoCancel?.cancel(),
                        child: Text(
                          ar
                              ? 'إيقاف الرفع والتحقق من النتيجة'
                              : 'Stop upload and check outcome',
                        ),
                      ),
                    ],
                    if (_videoUncertain)
                      TextButton.icon(
                        onPressed: _busy ? null : _checkSavedVideo,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          ar
                              ? 'التحقق من الفيديو المحفوظ'
                              : 'Check saved video',
                        ),
                      ),
                    if (_profileLoading)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          ar
                              ? 'جارٍ التحقق من صلاحية الفيديو…'
                              : 'Checking video permission…',
                        ),
                      ),
                    Text(
                      vip
                          ? (ar
                                ? 'MP4 / MOV / WebM، حتى 25 MB و15 ثانية. صورة الغلاف منفصلة عن ملف الفيديو.'
                                : 'MP4 / MOV / WebM, up to 25 MB and 15 seconds. The cover image is separate from the video file.')
                          : (ar
                                ? 'رفع الفيديو متاح للعيادات ذات أهلية الفيديو فقط.'
                                : 'Video upload requires the clinic’s video entitlement.'),
                    ),
                    if (!_profileLoading &&
                        !vip &&
                        !clinic.hasVideoAd &&
                        _videoPath == null) ...[
                      Text(
                        unknownTier
                            ? (ar
                                  ? 'لم يُعِد الخادم صلاحية الفيديو لهذه العيادة. حدّث الملف للتحقق؛ لا يمكن افتراض الأهلية من الشارة.'
                                  : 'The server did not establish this clinic’s video entitlement. Refresh to verify; a badge cannot grant permission.')
                            : (ar
                                  ? 'رفع فيديو العرض غير مفعّل في صلاحيات ملف عيادتك الحالي. حدّث الملف أو راجع إدارة المنصة إذا كانت الصلاحية متوقعة.'
                                  : 'Showcase video upload is not enabled by your current clinic profile. Refresh the profile or contact the platform administrator if you expect access.'),
                      ),
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.video_library_outlined),
                        label: Text(
                          ar
                              ? 'اختيار فيديو من المعرض'
                              : 'Select gallery video',
                        ),
                      ),
                    ],
                    if (unknownTier || _profileError != null)
                      TextButton.icon(
                        onPressed: _profileLoading ? null : _loadOwnedProfile,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          ar
                              ? 'التحقق من صلاحية الفيديو'
                              : 'Verify video entitlement',
                        ),
                      ),
                    if (vip || clinic.hasVideoAd || _videoPath != null) ...[
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: _player?.value.isInitialized == true
                            ? _player!.value.aspectRatio
                            : 16 / 9,
                        child: _player?.value.isInitialized == true
                            ? VideoPlayer(_player!)
                            : PortalMediaFrame(imageUrl: clinic.coverImageUrl),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _locked ? null : _play,
                            icon: Icon(
                              _player?.value.isPlaying == true
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _player?.value.isPlaying == true
                                  ? (ar
                                        ? 'إيقاف الفيديو مؤقتاً'
                                        : 'Pause video')
                                  : (ar ? 'معاينة الفيديو' : 'Preview video'),
                            ),
                          ),
                          if (vip)
                            TextButton.icon(
                              onPressed: _locked || _videoUncertain
                                  ? null
                                  : _chooseVideo,
                              icon: const Icon(Icons.video_library_outlined),
                              label: Text(
                                ar
                                    ? 'اختيار فيديو من المعرض'
                                    : 'Select gallery video',
                              ),
                            ),
                          if (_videoPath != null)
                            TextButton(
                              onPressed: _locked ? null : _discardVideo,
                              child: Text(
                                ar
                                    ? 'إلغاء اختيار الفيديو'
                                    : 'Discard selected video',
                              ),
                            ),
                          if (clinic.hasVideoAd)
                            TextButton(
                              onPressed: _locked || _videoUncertain
                                  ? null
                                  : () => _saveVideo(remove: true),
                              child: Text(
                                ar
                                    ? 'إزالة الفيديو المحفوظ'
                                    : 'Remove saved video',
                              ),
                            ),
                        ],
                      ),
                      if (_videoPath != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            ar
                                ? 'معاينة محلية فقط؛ لم يتم تأكيد حفظ الفيديو على الخادم.'
                                : 'Local preview only; saving on the server has not been confirmed.',
                            key: const ValueKey(
                              'video-local-preview-not-saved',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (_videoPath != null)
                        SilverButton(
                          label: ar
                              ? 'رفع وحفظ الفيديو'
                              : 'Upload and save video',
                          isLoading: _busy,
                          onPressed: _locked || !vip || _videoUncertain
                              ? null
                              : () => _saveVideo(),
                        ),
                      Text(
                        ar
                            ? 'تستخدم صورة غلاف العيادة كصورة عرض احتياطية. تحديثها يغير غلاف العيادة أيضاً؛ لا توجد صورة ملصق مستقلة لفيديو الملف.'
                            : 'The clinic cover is the fallback poster. Updating it also changes the clinic cover; this profile video has no independent poster field.',
                      ),
                      LuxuryImagePickerField(
                        label: ar
                            ? 'غلاف العيادة / صورة عرض الفيديو'
                            : 'Clinic cover / video poster',
                        initialUrl: clinic.coverImageUrl,
                        enabled: !_locked && !_videoUncertain,
                        height: 120,
                        onImageSelected: (path) => setState(() {
                          _posterPath = path;
                          _posterChanged = true;
                        }),
                      ),
                      if (_posterChanged)
                        SilverButton(
                          label: ar ? 'حفظ صورة الغلاف' : 'Save clinic cover',
                          isLoading: _busy,
                          onPressed: _locked || _videoUncertain
                              ? null
                              : _savePoster,
                        ),
                    ],
                  ],
                );
              },
            ),
    ),
  );
}

import 'dart:io';
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
import '../../../../core/widgets/luxury_image.dart';
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
  late final String _clinicId;
  late final ClinicMediaRepository _repository;
  late final PagedCollection<ClinicGalleryAsset> _gallery;
  final _pending = <String>[];
  bool _busy = false, _confirming = false;
  int _completed = 0, _batchSize = 0;
  String? _error, _notice, _videoPath, _posterPath;
  bool _posterChanged = false;
  VideoPlayerController? _player;
  bool get ar => LocaleService().isArabic;
  bool get _locked => _busy || _confirming || !_session.isCurrent;
  int get _remaining => math
      .max(
        0,
        10 -
            math.max(_gallery.total ?? 0, _gallery.items.length) -
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
      loader: (page, _) => _repository.getGallery(_clinicId, page: page),
    );
    WidgetsBinding.instance.addObserver(this);
    AuthState().addListener(_sessionChanged);
    _gallery.refresh();
  }

  void _sessionChanged() {
    if (!_session.isCurrent) {
      _gallery.clear();
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
    if (state != AppLifecycleState.resumed) _player?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthState().removeListener(_sessionChanged);
    _gallery.dispose();
    _player?.dispose();
    super.dispose();
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
      : e is ApiException && e.statusCode != null
      ? e.message
      : (ar
            ? 'تعذر إتمام العملية. تحقق من الملف والاتصال والصلاحيات وحاول مجدداً.'
            : 'Could not complete this operation. Check the file, connection and permissions, then try again.');

  Future<void> _refreshProfile() async {
    try {
      await _service.refreshClinicProfile();
    } catch (_) {
      if (mounted) {
        setState(
          () => _notice = ar
              ? 'تم حفظ تغييرات الوسائط. أعد تحميل ملف العيادة للتحقق من العرض.'
              : 'Media changes were saved. Reload the clinic profile to verify its display.',
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_locked || _pending.isEmpty) return;
    setState(() {
      _busy = true;
      _batchSize = 0;
      _error = null;
      _notice = null;
      _completed = 0;
      _batchSize = _pending.length;
    });
    try {
      for (final path in List<String>.of(_pending)) {
        _session.ensureCurrent();
        final asset = await _repository.uploadGallery(_clinicId, path);
        _session.ensureCurrent();
        if (!mounted) return;
        _gallery.mutate((items) {
          items.removeWhere((a) => a.id == asset.id);
          items.add(asset);
        });
        setState(() {
          _pending.remove(path);
          _completed++;
        });
      }
      await _refreshProfile();
      await _gallery.refresh();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              '${_failure(e)} ${ar ? 'راجع الصور المحفوظة قبل إعادة محاولة الملفات المتبقية؛ لم تتم إعادة إرسال الصور المؤكدة.' : 'Review saved images before retrying remaining files; acknowledged uploads are not resent.'}',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      await _gallery.refresh();
      await _refreshProfile();
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseVideo() async {
    if (_locked) return;
    setState(() {
      _busy = true;
      _batchSize = 0;
      _error = null;
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
        throw const ApiException(message: 'Select a video up to 15 seconds.');
      }
      _session.ensureCurrent();
      await _player?.dispose();
      _player = null;
      if (mounted) setState(() => _videoPath = picked.path);
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
    } finally {
      await probe?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveVideo({bool remove = false}) async {
    if (_locked || (!remove && _videoPath == null)) return;
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
      _error = null;
    });
    try {
      _session.ensureCurrent();
      await _service.updateShowcaseVideo(remove ? null : _videoPath);
      _session.ensureCurrent();
      await _player?.dispose();
      _player = null;
      if (mounted) {
        setState(() {
          _videoPath = null;
          _notice = ar ? 'تم حفظ فيديو العيادة.' : 'Clinic video saved.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _failure(e));
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
      _error = null;
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
      if (mounted) setState(() => _error = _failure(e));
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
    if (_locked || !_posterChanged) return;
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
      appBar: AppBar(title: Text(ar ? 'وسائط العيادة' : 'Clinic Media')),
      body: !_session.isCurrent
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
                final vip =
                    clinic.subscriptionTier == SubscriptionTier.vipPlatinum;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
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
                      const LinearProgressIndicator(),
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
                    for (final asset in _gallery.items)
                      Card(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: LuxuryImage(
                                imageUrl: asset.url,
                                fit: BoxFit.cover,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _locked ? null : () => _remove(asset),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(
                                ar ? 'حذف هذه الصورة' : 'Delete this photo',
                              ),
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
                      onPressed: _locked ? null : () => _gallery.refresh(),
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
                              child: LuxuryImage(imageUrl: path),
                            ),
                            TextButton(
                              onPressed: _locked
                                  ? null
                                  : () => setState(() => _pending.remove(path)),
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
                    if (_pending.isNotEmpty)
                      SilverButton(
                        label: ar
                            ? 'رفع الصور المحددة'
                            : 'Upload selected photos',
                        isLoading: _busy,
                        onPressed: _locked ? null : _upload,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      ar ? 'فيديو عرض العيادة' : 'Clinic showcase video',
                      style: Theme.of(context).textTheme.titleLarge,
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
                    if (vip || clinic.hasVideoAd || _videoPath != null) ...[
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: _player?.value.isInitialized == true
                            ? _player!.value.aspectRatio
                            : 16 / 9,
                        child: _player?.value.isInitialized == true
                            ? VideoPlayer(_player!)
                            : LuxuryImage(
                                imageUrl: clinic.coverImageUrl,
                                fit: BoxFit.cover,
                              ),
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
                              ar ? 'معاينة الفيديو' : 'Preview video',
                            ),
                          ),
                          if (vip)
                            TextButton.icon(
                              onPressed: _locked ? null : _chooseVideo,
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
                              onPressed: _locked
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
                        SilverButton(
                          label: ar
                              ? 'رفع وحفظ الفيديو'
                              : 'Upload and save video',
                          isLoading: _busy,
                          onPressed: _locked ? null : () => _saveVideo(),
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
                        enabled: !_locked,
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
                          onPressed: _locked ? null : _savePoster,
                        ),
                    ],
                  ],
                );
              },
            ),
    ),
  );
}

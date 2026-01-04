import 'package:flutter/material.dart';
import 'package:strengthwise/models/coach_profile/coach_profile_model.dart';
import 'package:strengthwise/models/coach_profile/coach_specialty.dart';
import 'package:strengthwise/services/interfaces/i_coach_profile_service.dart';
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/views/pages/profile/coach_profile_form_page.dart';

/// 教練公開檔案內容組件（共用）
///
/// 可用於：
/// - 教練公開檔案頁面（個人版）
/// - 學員中心教練詳情
/// - 教練中心我的檔案 Tab
class CoachProfileContent extends StatefulWidget {
  /// 教練 ID
  final String coachId;

  /// 教練 Email（聯絡資訊用）
  final String? email;

  /// 教練頭像 URL
  final String? photoUrl;

  /// 是否可編輯（顯示編輯按鈕）
  final bool isEditable;

  /// 是否顯示聯絡資訊
  final bool showContactInfo;

  /// 危險區域 Widget（學員解除綁定用）
  final Widget? dangerZoneWidget;

  /// 當沒有檔案時的空狀態提示
  final String emptyStateTitle;
  final String emptyStateSubtitle;

  const CoachProfileContent({
    super.key,
    required this.coachId,
    this.email,
    this.photoUrl,
    this.isEditable = false,
    this.showContactInfo = true,
    this.dangerZoneWidget,
    this.emptyStateTitle = '尚未建立教練檔案',
    this.emptyStateSubtitle = '建立您的專業檔案，讓學員認識您',
  });

  @override
  State<CoachProfileContent> createState() => _CoachProfileContentState();
}

class _CoachProfileContentState extends State<CoachProfileContent> {
  CoachProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(CoachProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coachId != widget.coachId) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileService = serviceLocator<ICoachProfileService>();
      final profile = await profileService.getProfile(widget.coachId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[COACH_PROFILE_CONTENT] 載入失敗: $e');
      if (mounted) {
        setState(() {
          _errorMessage = '載入教練檔案失敗';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CoachProfileFormPage()),
    ).then((_) => _loadProfile()); // 編輯完成後重新載入
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorState(
        message: _errorMessage!,
        onRetry: _loadProfile,
      );
    }

    if (_profile == null) {
      return _EmptyState(
        title: widget.emptyStateTitle,
        subtitle: widget.emptyStateSubtitle,
        showCreateButton: widget.isEditable,
        onCreateProfile: _navigateToEdit,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 頭像與基本資訊
          _ProfileHeaderCard(
            profile: _profile!,
            photoUrl: widget.photoUrl,
          ),
          const SizedBox(height: 24),

          // 聯絡資訊
          if (widget.showContactInfo && widget.email != null) ...[
            _SectionContainer(
              title: '聯絡資訊',
              icon: Icons.contact_mail,
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: widget.email!,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 關於我
          if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
            _SectionContainer(
              title: '關於我',
              icon: Icons.person_outline,
              children: [
                Text(
                  _profile!.bio!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 專長領域
          if (_profile!.specialties.isNotEmpty) ...[
            _SectionContainer(
              title: '專長領域',
              icon: Icons.fitness_center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _profile!.specialties
                      .map((tag) => _SpecialtyChip(tag: tag))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 專業證照
          if (_profile!.certifications.isNotEmpty) ...[
            _SectionContainer(
              title: '專業證照',
              icon: Icons.workspace_premium,
              children: _profile!.certifications
                  .map((cert) => _CertificationTile(certification: cert))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 基本資訊
          _SectionContainer(
            title: '基本資訊',
            icon: Icons.info_outline,
            children: [
              _InfoRow(
                icon: Icons.work_history_outlined,
                label: '從業年資',
                value: _profile!.yearsExperience > 0
                    ? '${_profile!.yearsExperience} 年'
                    : '未設定',
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.language,
                label: '教學語言',
                value: _profile!.languages.isNotEmpty
                    ? _profile!.languages.map(_getLanguageLabel).join('、')
                    : '未設定',
              ),
            ],
          ),

          // 危險區域（學員用）
          if (widget.dangerZoneWidget != null) ...[
            const SizedBox(height: 24),
            widget.dangerZoneWidget!,
          ],

          // 編輯按鈕
          if (widget.isEditable) ...[
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('編輯教練檔案'),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getLanguageLabel(String code) {
    const labels = {
      'zh-TW': '繁體中文',
      'zh-CN': '簡體中文',
      'en': 'English',
      'ja': '日本語',
      'ko': '한국어',
    };
    return labels[code] ?? code;
  }
}

// ============================================================
// 共用子組件
// ============================================================

/// 頭像卡片（漸層背景）
class _ProfileHeaderCard extends StatelessWidget {
  final CoachProfileModel profile;
  final String? photoUrl;

  const _ProfileHeaderCard({
    required this.profile,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayName = profile.displayName ?? '未命名';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 頭像
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primary,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
                    displayName.isNotEmpty
                        ? displayName.substring(0, 1).toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          // 姓名與標題
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (profile.headline != null &&
                    profile.headline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.headline!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                // 認證徽章
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '認證教練',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 區塊容器（帶標題區）
class _SectionContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionContainer({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題區
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 內容區
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// 專長標籤
class _SpecialtyChip extends StatelessWidget {
  final String tag;

  const _SpecialtyChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        CoachSpecialty.getLabel(tag),
        style: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// 證照列表項
class _CertificationTile extends StatelessWidget {
  final dynamic certification;

  const _CertificationTile({required this.certification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.verified_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certification.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${certification.organization}${certification.year != null ? ' · ${certification.year}' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 資訊行
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 空狀態
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showCreateButton;
  final VoidCallback onCreateProfile;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.showCreateButton,
    required this.onCreateProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (showCreateButton) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateProfile,
                icon: const Icon(Icons.add),
                label: const Text('建立教練檔案'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 錯誤狀態
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      ),
    );
  }
}


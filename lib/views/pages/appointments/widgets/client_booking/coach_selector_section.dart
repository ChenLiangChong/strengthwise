import 'package:flutter/material.dart';
import '../../../../../models/coaching_relationship_model.dart';
import '../../../../../models/user/user_model.dart';
import '../../../../../services/service_locator.dart';
import '../../../../../services/interfaces/i_user_service.dart';

/// 教練選擇區域組件
class CoachSelectorSection extends StatefulWidget {
  final List<CoachingRelationshipModel> coaches;
  final String? selectedCoachId;
  final Function(UserModel) onCoachSelected;

  const CoachSelectorSection({
    super.key,
    required this.coaches,
    required this.selectedCoachId,
    required this.onCoachSelected,
  });

  @override
  State<CoachSelectorSection> createState() => _CoachSelectorSectionState();
}

class _CoachSelectorSectionState extends State<CoachSelectorSection> {
  late final IUserService _userService;
  final Map<String, UserModel> _coachProfiles = {}; // 快取教練資料
  bool _isLoadingProfiles = true;

  @override
  void initState() {
    super.initState();
    _userService = serviceLocator<IUserService>();
    _loadCoachProfiles();
  }

  Future<void> _loadCoachProfiles() async {
    setState(() => _isLoadingProfiles = true);

    try {
      for (final relationship in widget.coaches) {
        final coachProfile = await _userService.getUserProfile(relationship.coachId);
        if (coachProfile != null) {
          _coachProfiles[relationship.coachId] = coachProfile;
        }
      }
    } catch (e) {
      // 錯誤處理：顯示 coachId 作為後備
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfiles = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coaches.isEmpty) {
      return _buildNoCoachesState();
    }

    if (_isLoadingProfiles) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Theme.of(context).colorScheme.surface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選擇教練',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.coaches.map((relationship) {
                final coach = _coachProfiles[relationship.coachId];
                final coachName = coach?.displayName ?? '教練 ${relationship.coachId.substring(0, 6)}';
                
                return _buildCoachChip(
                  context,
                  relationship.coachId,
                  coachName,
                  coach,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachChip(
    BuildContext context,
    String coachId,
    String coachName,
    UserModel? coach,
  ) {
    final isSelected = coachId == widget.selectedCoachId;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(coachName),
        selected: isSelected,
        onSelected: (selected) {
          if (selected && coach != null) {
            widget.onCoachSelected(coach);
          } else if (selected) {
            // 後備方案：創建簡化的 UserModel
            final fallbackCoach = UserModel(
              uid: coachId,
              email: '',
              displayName: coachName,
              isCoach: true,
            );
            widget.onCoachSelected(fallbackCoach);
          }
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildNoCoachesState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              '尚未綁定教練',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '請先與教練建立綁定關係',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


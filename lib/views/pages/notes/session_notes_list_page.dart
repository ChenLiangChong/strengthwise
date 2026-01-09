// ✅ 已響應式改造 (Phase 0)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strengthwise/controllers/session_note_controller.dart';
import 'package:strengthwise/controllers/interfaces/i_auth_controller.dart';
import 'package:strengthwise/models/session_note/session_note_model.dart';
import 'package:strengthwise/models/user_model.dart';
import 'package:strengthwise/models/client_with_relationship.dart'; // ⭐ 新增
import 'package:strengthwise/models/coach_with_relationship.dart'; // ⭐ 新增
import 'package:strengthwise/services/service_locator.dart';
import 'package:strengthwise/services/interfaces/i_coaching_relationship_service.dart';
import 'package:strengthwise/services/interfaces/i_user_service.dart';
import 'package:strengthwise/utils/responsive/responsive.dart';
import 'package:strengthwise/views/pages/notes/widgets/session_note_card.dart';
import 'package:strengthwise/views/pages/notes/widgets/empty_notes_state.dart';
import 'package:strengthwise/views/pages/notes/widgets/notes_search_empty_state.dart';
import 'package:strengthwise/views/pages/notes/widgets/notes_filter_empty_state.dart';
import 'package:strengthwise/views/pages/notes/widgets/notes_filter_chip.dart';
import 'package:strengthwise/views/pages/notes/widgets/client_selector_dialog.dart';
import 'package:strengthwise/views/pages/notes/session_note_editor_page.dart';
import 'package:strengthwise/views/pages/notes/session_note_detail_page.dart';

/// 課程筆記列表頁面
///
/// 功能：
/// - 教練模式：顯示教練的所有課程筆記（可新增）
/// - 學員模式：顯示學員的共享筆記（只讀）
/// - 支援篩選（全部/私人/共享）
/// - 下拉刷新
/// - 點擊進入詳情頁面
class SessionNotesListPage extends StatefulWidget {
  /// 是否為學員模式（true = 學員查看筆記，false = 教練管理筆記）
  final bool isClientMode;

  /// Phase 4C: 可選的學員 ID（教練查看特定學員的筆記）
  final String? clientId;

  /// Phase 4C: 可選的教練 ID（學員查看特定教練的筆記）
  final String? coachId;

  /// Phase 4C: 是否為學員查看模式（只顯示已分享的筆記）
  final bool? isClientView;

  /// UX 重構：是否顯示學員篩選功能（教練管理中心使用）
  final bool showClientFilter;

  /// ⭐ 新增：學員資訊（教練詳情頁使用，避免重複查詢）
  final UserModel? client;

  /// ⭐ 新增：教練資訊（學員詳情頁使用，避免重複查詢）
  final UserModel? coach;

  const SessionNotesListPage({
    Key? key,
    this.isClientMode = false,
    this.clientId,
    this.coachId,
    this.isClientView,
    this.showClientFilter = false,
    this.client, // ⭐ 新增
    this.coach, // ⭐ 新增
  }) : super(key: key);

  @override
  State<SessionNotesListPage> createState() => _SessionNotesListPageState();
}

class _SessionNotesListPageState extends State<SessionNotesListPage> {
  late final SessionNoteController _controller;
  late final IAuthController _authController;
  late final ICoachingRelationshipService _relationshipService;
  late final IUserService _userService;
  String _currentFilter = 'all'; // 'all', 'private', 'shared'

  // UX 重構：學員篩選與搜尋
  ClientWithRelationship? _selectedClient; // ⭐ 選中的學員（含關係狀態）
  CoachWithRelationship? _selectedCoach; // ⭐ 選中的教練（含關係狀態）
  String? _selectedClientId; // ⭐ 保留向後相容
  String? _selectedCoachId; // ⭐ 保留向後相容
  List<ClientWithRelationship> _clientsWithRelationship =
      []; // ⭐ 教練的學員列表（含關係狀態）
  List<CoachWithRelationship> _coachesWithRelationship = []; // ⭐ 學員的教練列表（含關係狀態）
  List<UserModel> _clientsList = []; // ⭐ 保留舊的（用於其他地方）
  List<UserModel> _coachsList = []; // 學員的教練列表 ⭐ 新增
  bool _isLoadingClients = false;
  bool _isLoadingCoaches = false; // ⭐ 新增
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = serviceLocator<SessionNoteController>();
    _authController = serviceLocator<IAuthController>();
    _relationshipService = serviceLocator<ICoachingRelationshipService>();
    _userService = serviceLocator<IUserService>();
    _searchController.addListener(_onSearchChanged);

    // 調試：顯示當前用戶資訊
    final currentUser = _authController.user;
    print(
        '[SessionNotesListPage] 📱 當前用戶: ${currentUser?.email} (${currentUser?.uid})');
    print('[SessionNotesListPage] 📱 是否教練: ${currentUser?.isCoach}');
    print(
        '[SessionNotesListPage] 📱 showClientFilter: ${widget.showClientFilter}');

    // ⭐ 總是載入學員列表（用於顯示學員名稱）
    print('[SessionNotesListPage] 🔄 準備載入學員列表...');
    _loadClientsList();

    // ⭐ 學員模式：載入教練列表（用於篩選和顯示教練名稱）
    if (widget.isClientMode) {
      print('[SessionNotesListPage] 🔄 學員模式：準備載入教練列表...');
      _loadCoachesList();
    }

    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  /// 載入教練的學員列表
  Future<void> _loadClientsList() async {
    final currentUser = _authController.user;
    if (currentUser == null) {
      print('[SessionNotesListPage] ❌ 無法獲取當前用戶');
      return;
    }

    print('[SessionNotesListPage] 🔄 開始載入學員列表，當前用戶: ${currentUser.email}');

    setState(() {
      _isLoadingClients = true;
    });

    try {
      List<UserModel> clients = [];

      // ⭐ 如果是學員查看模式（學員查看教練的共享筆記）
      if (widget.isClientView == true) {
        // 學員查看自己，查詢完整的用戶資料（包含 displayName）
        if (widget.clientId != null) {
          final clientProfile =
              await _userService.getUserProfile(widget.clientId!);
          if (clientProfile != null) {
            clients = [clientProfile];
            print(
                '[SessionNotesListPage] ✅ 學員模式：載入完整用戶資料 (${clientProfile.displayName ?? clientProfile.email})');
          }
        }
      } else {
        // ⭐ 查詢完整的用戶資料，檢查是否為教練
        final userProfile = await _userService.getUserProfile(currentUser.uid);
        final isCoach = userProfile?.isCoach ?? false;

        print(
            '[SessionNotesListPage] 📋 完整用戶資料：${userProfile?.displayName ?? userProfile?.email}');
        print('[SessionNotesListPage] 📋 isCoach (從資料庫): $isCoach');

        if (isCoach) {
          // 教練模式：使用 CoachingRelationshipService 載入學員列表（含關係狀態）⭐ 修改
          // ⭐ 載入所有學員（包括已解除關係的），以便查看歷史筆記
          final clientsWithRel =
              await _relationshipService.getCoachClientsWithRelationship(
            currentUser.uid,
            status: null, // null = 載入所有狀態（active + archived）
          );

          // 轉換為舊格式（向後相容）
          clients = clientsWithRel
              .where((c) => c.user != null)
              .map((c) => c.user!)
              .toList();

          print(
              '[SessionNotesListPage] ✅ 教練模式：成功載入 ${clientsWithRel.length} 個學員（含歷史）');

          // 保存完整資料（用於篩選器）
          if (mounted) {
            setState(() {
              _clientsWithRelationship = clientsWithRel;
              _clientsList = clients;
              _isLoadingClients = false;
            });
            return; // ⭐ 提前返回
          }
        } else {
          print('[SessionNotesListPage] ⚠️  非教練用戶，不載入學員列表');
        }
      }

      for (var client in clients) {
        print('  - ${client.displayName ?? client.email} (${client.uid})');
      }

      if (mounted) {
        setState(() {
          _clientsList = clients;
          _isLoadingClients = false;
        });
      }
    } catch (e, stackTrace) {
      print('[SessionNotesListPage] ❌ 載入學員列表失敗: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _clientsList = []; // 確保設為空列表
          _isLoadingClients = false;
        });

        // 顯示錯誤提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入學員列表失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 載入學員的教練列表（學員模式）⭐ 使用 CoachWithRelationship
  Future<void> _loadCoachesList() async {
    final currentUser = _authController.user;
    if (currentUser == null) {
      print('[SessionNotesListPage] ❌ 無法獲取當前用戶');
      return;
    }

    print('[SessionNotesListPage] 🔄 開始載入教練列表，當前學員: ${currentUser.email}');

    setState(() {
      _isLoadingCoaches = true;
    });

    try {
      // ⭐ 使用新的 Service 方法：載入所有教練（含關係狀態）
      final coachesWithRel =
          await _relationshipService.getClientCoachesWithRelationship(
        currentUser.uid,
        status: null, // null = 載入所有狀態（active + archived）
      );

      // 轉換為舊格式（向後相容）
      final coaches = coachesWithRel
          .where((c) => c.user != null)
          .map((c) => c.user!)
          .toList();

      print(
          '[SessionNotesListPage] ✅ 學員模式：成功載入 ${coachesWithRel.length} 個教練（含歷史）');

      if (mounted) {
        setState(() {
          _coachesWithRelationship = coachesWithRel; // ⭐ 保存完整資料
          _coachsList = coaches;
          _isLoadingCoaches = false;
        });
        print('[SessionNotesListPage] ✅ 最終教練列表：${coaches.length} 個教練');
      }
    } catch (e, stackTrace) {
      print('[SessionNotesListPage] ❌ 載入教練列表失敗: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _coachsList = [];
          _isLoadingCoaches = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入教練列表失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 載入筆記列表
  Future<void> _loadNotes() async {
    final currentUser = _authController.user;
    if (currentUser == null) return;

    if (widget.isClientMode) {
      // 學員模式：載入學員的共享筆記
      // ⭐ 支援教練篩選
      String? filterCoachId;
      String? filterCoachName;

      if (_selectedCoach != null) {
        // ⭐ 使用選中的教練
        filterCoachId = _selectedCoach!.relationship.coachId; // 可能為 null
        if (filterCoachId == null) {
          // ⭐ 已刪除的教練：使用 coach_name 查詢
          filterCoachName = _selectedCoach!.displayName;
        }
      }

      print(
          '[SessionNotesListPage] 🔍 學員模式載入筆記：coachId=$filterCoachId, coachName=$filterCoachName');

      await _controller.loadClientNotes(
        clientId: currentUser.uid,
        coachId: filterCoachId, // ⭐ 可能為 null（已刪除的教練）
        coachName: filterCoachName, // ⭐ 用於查詢已刪除教練的筆記
      );
    } else if (widget.isClientView == true && widget.coachId != null) {
      // Phase 4C: 學員查看特定教練的共享筆記
      await _controller.loadCoachNotes(
        coachId: widget.coachId!,
        clientId: widget.clientId ?? currentUser.uid,
      );
    } else {
      // 教練模式：載入教練的所有筆記
      // UX 重構：優先使用 _selectedClient，其次使用 widget.clientId
      String? filterClientId;
      String? filterClientName;

      if (_selectedClient != null) {
        // ⭐ 使用選中的學員
        filterClientId = _selectedClient!.relationship.clientId; // 可能為 null
        if (filterClientId == null) {
          // ⭐ 已刪除的學員：使用 client_name 查詢
          filterClientName = _selectedClient!.displayName;
        }
      } else if (widget.clientId != null) {
        // 使用傳入的 clientId
        filterClientId = widget.clientId;
      }

      print(
          '[SessionNotesListPage] 🔍 載入筆記：clientId=$filterClientId, clientName=$filterClientName');

      await _controller.loadCoachNotes(
        coachId: currentUser.uid,
        clientId: filterClientId, // ⭐ 可能為 null（已刪除的學員）
        clientName: filterClientName, // ⭐ 用於查詢已刪除學員的筆記
      );
    }
  }

  /// 根據篩選條件過濾筆記
  List<SessionNoteModel> _getFilteredNotes(List<SessionNoteModel> notes) {
    var filtered = notes;

    // 0. ⭐ 學員模式的教練篩選已在資料庫層完成（loadClientNotes），不需要前端篩選

    // 1. 可見性篩選
    switch (_currentFilter) {
      case 'private':
        filtered = filtered.where((note) => note.isPrivate).toList();
        break;
      case 'shared':
        filtered = filtered.where((note) => note.isShared).toList();
        break;
      default:
        break;
    }

    // 2. 搜尋過濾（SOAP 筆記內容 + 標籤 + 學員名稱）
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        // 搜尋 SOAP 內容
        final subjective = note.soap?.subjective?.toLowerCase() ?? '';
        final objective = note.soap?.objective?.toLowerCase() ?? '';
        final assessment = note.soap?.assessment?.toLowerCase() ?? '';
        final plan = note.soap?.plan?.toLowerCase() ?? '';

        // 搜尋標籤
        final tags = note.quickTags.join(' ').toLowerCase();

        // ⭐ 搜尋學員名稱（從學員列表查找）
        String clientName = '';
        if (_clientsList.isNotEmpty) {
          final client = _clientsList.firstWhere(
            (c) => c.uid == note.clientId,
            orElse: () => UserModel(uid: '', email: ''),
          );
          clientName = (client.displayName ?? client.email).toLowerCase();
        }

        return subjective.contains(_searchQuery) ||
            objective.contains(_searchQuery) ||
            assessment.contains(_searchQuery) ||
            plan.contains(_searchQuery) ||
            tags.contains(_searchQuery) ||
            clientName.contains(_searchQuery); // ⭐ 新增：搜尋學員名稱
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        // ⭐ 移除標題（外層 TabBar 已有標籤），只保留 actions
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: null,
          toolbarHeight: 48, // 縮小高度
          elevation: 0,
          actions: [
            // 新增筆記按鈕（僅教練模式）
            if (!widget.isClientMode)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () async {
                  // ⭐ v3.1.1: 如果已傳入 clientId，直接使用（學員詳情頁）
                  String? clientId = widget.clientId;
                  
                  // 如果沒有傳入 clientId，才顯示選擇對話框
                  if (clientId == null) {
                    clientId = await showDialog<String>(
                      context: context,
                      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
                      builder: (context) => const ClientSelectorDialog(),
                    );
                  }

                  if (clientId != null && mounted) {
                    // 導航到新增筆記頁面
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessionNoteEditorPage(
                          clientId: clientId,
                        ),
                      ),
                    );

                    // 如果有修改，重新載入列表
                    if (result == true) {
                      _loadNotes();
                    }
                  }
                },
                tooltip: '新增筆記',
              ),
          ],
        ),
        body: Consumer<SessionNoteController>(
          builder: (context, controller, child) {
            // 載入中狀態
            if (controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 錯誤狀態
            if (controller.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadNotes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新載入'),
                    ),
                  ],
                ),
              );
            }

            // 過濾筆記
            final filteredNotes = _getFilteredNotes(controller.notes);

            // 筆記列表（始終顯示搜尋欄和篩選器）
            return RefreshIndicator(
              onRefresh: _loadNotes,
              child: Column(
                children: [
                  // UX 重構：搜尋欄（教練管理中心）
                  if (widget.showClientFilter) _buildSearchBar(),

                  // UX 重構：學員篩選（教練管理中心）
                  if (widget.showClientFilter) _buildClientFilterBar(),

                  // UX 重構：搜尋欄（學員模式）⭐ 新增
                  if (widget.isClientMode) _buildSearchBar(),

                  // UX 重構：教練篩選（學員模式）⭐ 新增
                  if (widget.isClientMode) _buildCoachFilterBar(),

                  // 篩選器（可見性：全部/私人/共享）
                  _buildFilterBar(),

                  // 空狀態或筆記列表
                  Expanded(
                    child: filteredNotes.isEmpty
                        ? _buildEmptyState() // ⭐ 自訂空狀態（顯示搜尋提示）
                        : ListView.builder(
                            padding: context.pagePadding, // ⭐ 響應式邊距
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];

                              // ⭐ 使用名稱快照（優先）或從列表查找
                              String? clientName;
                              String? coachName;

                              // 教練模式：顯示學員名稱
                              if (!widget.isClientMode) {
                                // 優先使用名稱快照
                                clientName = note.clientName;

                                // 否則從列表查找或使用傳入的學員資訊
                                if (clientName == null) {
                                  if (widget.client != null) {
                                    clientName = widget.client!.displayName ??
                                        widget.client!.email;
                                  } else if (_clientsList.isNotEmpty) {
                                    final client = _clientsList.firstWhere(
                                      (c) => c.uid == note.clientId,
                                      orElse: () =>
                                          UserModel(uid: '', email: ''),
                                    );
                                    if (client.uid.isNotEmpty) {
                                      clientName =
                                          client.displayName ?? client.email;
                                    }
                                  }
                                }
                              }

                              // 學員模式：顯示教練名稱
                              if (widget.isClientMode) {
                                // 優先使用名稱快照
                                coachName = note.coachName;

                                // 否則從列表查找或使用傳入的教練資訊
                                if (coachName == null) {
                                  if (widget.coach != null) {
                                    coachName = widget.coach!.displayName ??
                                        widget.coach!.email;
                                  } else if (_coachsList.isNotEmpty) {
                                    final coachId = note.coachId;
                                    if (coachId != null && coachId.isNotEmpty) {
                                      final coach = _coachsList.firstWhere(
                                        (c) => c.uid == coachId,
                                        orElse: () =>
                                            UserModel(uid: '', email: ''),
                                      );
                                      if (coach.uid.isNotEmpty) {
                                        coachName =
                                            coach.displayName ?? coach.email;
                                      }
                                    }
                                  }
                                }
                              }

                              return SessionNoteCard(
                                note: note,
                                clientName: clientName, // 教練模式顯示學員名稱
                                coachName: coachName, // ⭐ 學員模式顯示教練名稱
                                onTap: () => _navigateToNoteDetail(note),
                                onDelete: () => _deleteNote(note),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 篩選器列
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md, // ⭐ 響應式邊距
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          NotesFilterChip(
            label: '全部',
            isSelected: _currentFilter == 'all',
            onSelected: () => setState(() => _currentFilter = 'all'),
          ),
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          NotesFilterChip(
            label: '私人',
            isSelected: _currentFilter == 'private',
            onSelected: () => setState(() => _currentFilter = 'private'),
          ),
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          NotesFilterChip(
            label: '共享',
            isSelected: _currentFilter == 'shared',
            onSelected: () => setState(() => _currentFilter = 'shared'),
          ),
        ],
      ),
    );
  }

  /// UX 重構：搜尋欄
  Widget _buildSearchBar() {
    return Padding(
      padding: context.pagePadding, // ⭐ 響應式邊距
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜尋筆記內容或標籤...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withAlpha(200),
        ),
      ),
    );
  }

  /// UX 重構：學員篩選下拉選單
  Widget _buildClientFilterBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md, // ⭐ 響應式邊距
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 20.scaled(context)), // ⭐ 響應式圖標
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          Text('學員：', style: context.responsive.bodyMedium),
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          Expanded(
            child: _isLoadingClients
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButton<String?>(
                    value: _selectedClientId,
                    isExpanded: true,
                    hint: const Text('全部學員'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部學員'),
                      ),
                      // ⭐ 使用帶關係狀態的學員列表
                      ..._clientsWithRelationship.map((clientWithRel) {
                        // ⭐ 使用 relationship.id 作為唯一標識（避免 NULL 衝突）
                        final uniqueId = clientWithRel.relationship.id;

                        // 圖標
                        String icon = '';
                        Color? textColor;
                        if (clientWithRel.isDeleted) {
                          icon = '👻 ';
                          textColor = Colors.grey.shade400;
                        } else if (clientWithRel.isArchived) {
                          icon = '🔗 ';
                          textColor = Colors.grey.shade600;
                        }

                        return DropdownMenuItem<String?>(
                          value: uniqueId, // ⭐ 使用 relationship.id
                          child: Text(
                            '$icon${clientWithRel.displayName}${clientWithRel.isArchived ? ' (已解除)' : clientWithRel.isDeleted ? ' (已刪除)' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClientId = value;
                        // ⭐ 根據 relationship.id 找到對應的 ClientWithRelationship
                        _selectedClient = value == null
                            ? null
                            : _clientsWithRelationship.firstWhere(
                                (c) => c.relationship.id == value,
                              );
                      });
                      _loadNotes();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// UX 重構：教練篩選下拉選單（學員模式）⭐ 簡化
  Widget _buildCoachFilterBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md, // ⭐ 響應式邊距
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 20.scaled(context)), // ⭐ 響應式圖標
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          Text('教練：', style: context.responsive.bodyMedium),
          SizedBox(width: context.spacing.sm), // ⭐ 響應式間距
          Expanded(
            child: _isLoadingCoaches
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : DropdownButton<String?>(
                    value: _selectedCoachId,
                    isExpanded: true,
                    hint: const Text('全部教練'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('全部教練'),
                      ),
                      // ⭐ 使用帶關係狀態的教練列表
                      ..._coachesWithRelationship.map((coachWithRel) {
                        // ⭐ 使用 relationship.id 作為唯一標識
                        final uniqueId = coachWithRel.relationship.id;

                        // 圖標
                        String icon = '';
                        Color? textColor;
                        if (coachWithRel.isDeleted) {
                          icon = '👻 ';
                          textColor = Colors.grey.shade400;
                        } else if (coachWithRel.isArchived) {
                          icon = '🔗 ';
                          textColor = Colors.grey.shade600;
                        }

                        return DropdownMenuItem<String?>(
                          value: uniqueId, // ⭐ 使用 relationship.id
                          child: Text(
                            '$icon${coachWithRel.displayName}${coachWithRel.isArchived ? ' (已解除)' : coachWithRel.isDeleted ? ' (已刪除)' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: textColor),
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCoachId = value;
                        // ⭐ 根據 relationship.id 找到對應的 CoachWithRelationship
                        _selectedCoach = value == null
                            ? null
                            : _coachesWithRelationship.firstWhere(
                                (c) => c.relationship.id == value,
                              );
                      });
                      _loadNotes(); // ⭐ 重新載入筆記
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 導航到筆記詳情頁面
  Future<void> _navigateToNoteDetail(SessionNoteModel note) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SessionNoteDetailPage(noteId: note.id),
      ),
    );

    // 如果有修改，重新載入列表
    if (result == true) {
      _loadNotes();
    }
  }

  /// 自訂空狀態（顯示不同提示）
  Widget _buildEmptyState() {
    // 1. 如果有搜尋關鍵字，顯示「找不到結果」
    if (_searchQuery.isNotEmpty) {
      return NotesSearchEmptyState(
        searchQuery: _searchQuery,
        onClearSearch: () {
          _searchController.clear();
        },
      );
    }

    // 2. 如果選擇了特定學員或篩選器，顯示對應空狀態
    if (_selectedClientId != null || _currentFilter != 'all') {
      final clientName = _selectedClientId != null
          ? _clientsList
                  .firstWhere(
                    (c) => c.uid == _selectedClientId,
                    orElse: () => UserModel(uid: '', email: ''),
                  )
                  .displayName ??
              '該學員'
          : null;

      return NotesFilterEmptyState(
        clientName: clientName,
        filter: _currentFilter,
      );
    }

    // 3. 完全沒有筆記（使用原本的空狀態組件）
    return EmptyNotesState(
      filter: _currentFilter,
      onCreateNote: () async {
        final clientId = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const ClientSelectorDialog(),
        );

        if (clientId != null && mounted) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => SessionNoteEditorPage(
                clientId: clientId,
              ),
            ),
          );

          if (result == true) {
            _loadNotes();
          }
        }
      },
    );
  }

  /// 刪除筆記
  Future<void> _deleteNote(SessionNoteModel note) async {
    // ⭐ 檢查是否為學員模式
    final isClient = widget.isClientMode;
    final isSharedNote = note.isShared;
    final currentUser = _authController.user;

    // ⭐ 共享筆記的刪除邏輯（檢查關係狀態）
    if (isSharedNote) {
      if (currentUser == null || note.coachId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('無法執行此操作')),
          );
        }
        return;
      }

      try {
        // 學員模式：檢查是否還有 active 綁定關係
        if (isClient) {
          final relationship =
              await _relationshipService.getRelationshipByUsers(
            note.coachId!,
            currentUser.uid,
          );

          // 如果關係仍為 active，不允許刪除
          if (relationship != null && relationship.status == 'active') {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('無法移除筆記'),
                  content: const Text('此筆記由教練分享給您，在教練關係有效期間無法移除。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            }
            return;
          }
        }
      } catch (e) {
        print('[SessionNotesListPage] ❌ 檢查綁定關係失敗: $e');
        // 如果查詢失敗，繼續執行（讓 RLS 決定）
      }
    }

    // ⭐ 顯示確認對話框
    String dialogTitle = '刪除筆記';
    String dialogContent = '確定要刪除此筆記嗎？此操作無法復原。';
    String confirmButtonText = '刪除';
    String successMessage = '筆記已刪除';

    // 學員移除共享筆記
    if (isClient && isSharedNote) {
      dialogTitle = '移除筆記';
      dialogContent = '此筆記將從您的檢視中移除，但教練仍可查看。\n\n確定要移除嗎？';
      confirmButtonText = '移除';
      successMessage = '筆記已從您的檢視中移除';
    }
    // 教練移除共享筆記（關係已結束）⭐ 新增
    else if (!isClient && isSharedNote) {
      dialogTitle = '移除筆記';
      dialogContent = '此筆記將從您的檢視中移除，但學員仍可查看。\n\n確定要移除嗎？';
      confirmButtonText = '移除';
      successMessage = '筆記已從您的檢視中移除';
    }

    // 顯示確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 🐛 修復：禁止點擊旁邊關閉
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(confirmButtonText),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // ⭐ 學員模式：隱藏筆記（UPDATE hidden_by_client = true）
        if (isClient && isSharedNote) {
          await _controller.hideNote(noteId: note.id, isCoach: false);
        }
        // ⭐ 教練模式 + 共享筆記：隱藏筆記（UPDATE hidden_by_coach = true）
        else if (!isClient && isSharedNote) {
          await _controller.hideNote(noteId: note.id, isCoach: true);
        }
        // ⭐ 私人筆記：真正刪除
        else {
          await _controller.deleteNote(note.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(successMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('操作失敗: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

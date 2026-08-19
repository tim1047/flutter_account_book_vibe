import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/constants/event_type.dart';
import 'package:account_book_vibe/data/models/event_model.dart';
import 'package:account_book_vibe/data/models/member_model.dart';
import 'package:account_book_vibe/data/services/event_service.dart';
import 'package:account_book_vibe/data/services/member_service.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 멤버 드롭다운 항목. 멤버 목록은 화면이 뜬 뒤에 도착하는데, 그 사이에
/// 수정 대상의 `memberId` 가 항목에 없으면 `DropdownButton` 이 assert 로 죽는다.
/// 목록이 늦거나 실패해도 지금 값은 항상 끼워 넣는다.
@visibleForTesting
List<({String id, String name})> memberOptions(
  List<MemberListResponse> members,
  String selectedId,
  String selectedName,
) {
  final options = <({String id, String name})>[
    (id: '', name: '지정 안 함'),
    for (final member in members) (id: member.memberId, name: member.memberNm),
  ];
  if (selectedId.isNotEmpty &&
      !options.any((option) => option.id == selectedId)) {
    options.add((
      id: selectedId,
      name: selectedName.isEmpty ? selectedId : selectedName,
    ));
  }
  return options;
}

/// 일정 등록·수정. 수정은 전량 치환(`PUT`)이라 항상 전 필드를 보낸다.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.extra});

  final Object? extra;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _contentsCtrl;

  String _typeCd = EventType.schedule;
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime _endDate = DateUtils.dateOnly(DateTime.now());
  bool _isAllDay = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _memberId = '';
  String _memberNm = '';

  List<MemberListResponse> _members = <MemberListResponse>[];

  EventListResponse? get _editItem => widget.extra as EventListResponse?;
  bool get _isEditMode => _editItem != null;

  @override
  void initState() {
    super.initState();
    final item = _editItem;
    if (item != null) {
      _typeCd = item.eventTypeCd;
      _startDate = item.startDate;
      _endDate = item.endDate;
      _isAllDay = item.isAllDay;
      if (!item.isAllDay) {
        _startTime = _parseTime(item.strtTm);
        _endTime = _parseTime(item.endTm);
      }
      _memberId = item.memberId;
      _memberNm = item.memberNm;
    }
    _nameCtrl = TextEditingController(text: item?.eventNm ?? '');
    _contentsCtrl = TextEditingController(text: item?.contents ?? '');
    _loadMembers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contentsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await MemberService.instance.getMembers();
      if (mounted) setState(() => _members = members);
    } on Exception catch (_) {
      // 멤버 목록은 선택 항목이라 실패해도 화면은 그대로 쓸 수 있다.
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static TimeOfDay _parseTime(String hhmm) => TimeOfDay(
        hour: int.parse(hhmm.substring(0, 2)),
        minute: int.parse(hhmm.substring(3, 5)),
      );

  /// 서버는 `"HH:MM"` 5자리만 받는다. `"9:00"`은 422다.
  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  static String _displayDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.'
      '${dt.day.toString().padLeft(2, '0')}';

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // 시작일을 종료일 뒤로 밀면 종료일도 같이 민다.
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  /// 서버 검증(422)과 같은 규칙을 미리 본다. 날짜가 다르면 시각 역전은
  /// 밤샘 일정이라 정상이다.
  String? _validate() {
    if (_nameCtrl.text.trim().isEmpty) return '일정명을 입력해주세요.';
    if (_endDate.isBefore(_startDate)) return '종료일은 시작일 이후여야 합니다.';
    if (!_isAllDay &&
        DateUtils.isSameDay(_startDate, _endDate) &&
        _toMinutes(_endTime) <= _toMinutes(_startTime)) {
      return '같은 날이면 종료시각은 시작시각 이후여야 합니다.';
    }
    return null;
  }

  static int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      await AppAlertDialog.show(context, message: error);
      return;
    }

    final request = EventRequest(
      eventTypeCd: _typeCd,
      eventNm: _nameCtrl.text.trim(),
      contents: _contentsCtrl.text.trim(),
      strtDt: formatApiDate(_startDate),
      endDt: formatApiDate(_endDate),
      strtTm: _isAllDay ? '' : _formatTime(_startTime),
      endTm: _isAllDay ? '' : _formatTime(_endTime),
      memberId: _memberId,
    );

    if (!mounted) return;
    AppLoadingDialog.show(context);
    try {
      if (_isEditMode) {
        await EventService.instance.updateEvent(_editItem!.eventId, request);
      } else {
        await EventService.instance.createEvent(request);
      }
      if (mounted) {
        AppLoadingDialog.hide(context);
        context.pop(_isEditMode ? '수정' : '등록');
      }
    } on Exception catch (e) {
      if (mounted) {
        AppLoadingDialog.hide(context);
        await AppAlertDialog.show(context, message: e.toString());
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await AppAlertDialog.confirm(
      context,
      title: '삭제 확인',
      message: '정말 삭제하시겠습니까?',
      confirmText: '삭제',
    );
    if (!confirmed || !mounted) return;
    AppLoadingDialog.show(context);
    try {
      await EventService.instance.deleteEvent(_editItem!.eventId);
      if (mounted) {
        AppLoadingDialog.hide(context);
        context.pop('삭제');
      }
    } on Exception catch (e) {
      if (mounted) {
        AppLoadingDialog.hide(context);
        await AppAlertDialog.show(context, message: e.toString());
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.colorBgMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditMode ? '일정 수정' : '일정 추가',
          style: AppTextStyles.textHeadlineMd,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.colorTextSecondary,
          size: 24,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: _buildForm(),
                ),
              ),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _FormRow(
          emoji: '🏷️',
          label: '유형',
          child: _Dropdown<String>(
            value: _typeCd,
            items: <DropdownMenuItem<String>>[
              for (final code in EventType.all)
                DropdownMenuItem<String>(
                  value: code,
                  child: Text(EventType.nameOf(code)),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _typeCd = value);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '📌',
          label: '일정명',
          child: TextField(
            controller: _nameCtrl,
            maxLength: 100,
            decoration: const InputDecoration(
              hintText: '일정명',
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '📅',
          label: '시작일',
          child: _PickerField(
            text: _displayDate(_startDate),
            onTap: () => _pickDate(isStart: true),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '🏁',
          label: '종료일',
          child: _PickerField(
            text: _displayDate(_endDate),
            onTap: () => _pickDate(isStart: false),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '🌗',
          label: '종일',
          child: Align(
            alignment: Alignment.centerLeft,
            child: Switch(
              value: _isAllDay,
              activeThumbColor: AppColors.colorAccentTeal,
              onChanged: (value) => setState(() => _isAllDay = value),
            ),
          ),
        ),
        if (!_isAllDay) ...[
          const Divider(height: 1, color: AppColors.colorDivider),
          _FormRow(
            emoji: '⏰',
            label: '시작시각',
            child: _PickerField(
              text: _formatTime(_startTime),
              onTap: () => _pickTime(isStart: true),
            ),
          ),
          const Divider(height: 1, color: AppColors.colorDivider),
          _FormRow(
            emoji: '⏱️',
            label: '종료시각',
            child: _PickerField(
              text: _formatTime(_endTime),
              onTap: () => _pickTime(isStart: false),
            ),
          ),
        ],
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '👤',
          label: '멤버',
          child: _Dropdown<String>(
            value: _memberId,
            items: <DropdownMenuItem<String>>[
              for (final option in memberOptions(_members, _memberId, _memberNm))
                DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(option.name),
                ),
            ],
            onChanged: (value) => setState(() => _memberId = value ?? ''),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),
        _FormRow(
          emoji: '📝',
          label: '내용',
          child: TextField(
            controller: _contentsCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '선택사항',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (_isEditMode) ...[
              Expanded(
                child: DestructiveButton(
                  label: '삭제',
                  icon: Icons.delete_outline,
                  onPressed: _delete,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: GradientButton(
                label: _isEditMode ? '수정' : '등록',
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.colorDivider)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppTextStyles.textBodyLg)),
            const Icon(
              Icons.expand_more,
              color: AppColors.colorTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.colorBgCard,
        items: items,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.emoji,
    required this.label,
    required this.child,
  });

  final String emoji;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: AppTextStyles.textBodyMd.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

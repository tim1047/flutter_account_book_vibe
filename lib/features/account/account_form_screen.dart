import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/core/utils/thousands_formatter.dart';
import 'package:account_book_vibe/data/models/account_model.dart';
import 'package:account_book_vibe/data/services/account_service.dart';
import 'package:account_book_vibe/features/account/account_form_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, this.extra});

  final Object? extra;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  late final AccountFormViewModel _vm;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _remarkCtrl;
  late final TextEditingController _pointPriceCtrl;

  DateTime _selectedDate = DateTime.now();
  String _impulseYn = 'N';

  AccountListResponse? get _editItem => widget.extra as AccountListResponse?;
  bool get _isEditMode => _editItem != null;

  @override
  void initState() {
    super.initState();
    _vm = AccountFormViewModel();

    final item = _editItem;
    if (item != null) {
      _selectedDate = DateTime.parse(item.accountDt);
      _impulseYn = item.impulseYn;
    }

    _priceCtrl = TextEditingController(
      text: item != null ? FormatUtil.formatPrice(item.price) : '',
    );
    _remarkCtrl = TextEditingController(text: item?.remark ?? '');
    _pointPriceCtrl = TextEditingController(
      text: item != null && item.pointPrice > 0
          ? FormatUtil.formatPrice(item.pointPrice)
          : '',
    );

    _vm.init(
      divisionId: item?.divisionId,
      memberId: item?.memberId,
      categoryId: item?.categoryId,
      categorySeq: item?.categorySeq,
      paymentId: item?.paymentId,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    _priceCtrl.dispose();
    _remarkCtrl.dispose();
    _pointPriceCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  int _parsePrice(String text) =>
      int.tryParse(text.replaceAll(',', '')) ?? 0;

  String _toApiDate(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2010),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_vm.selectedDivisionId == null) {
      await AppAlertDialog.show(context, message: '구분을 선택해주세요.');
      return;
    }
    if (_vm.selectedMemberId == null) {
      await AppAlertDialog.show(context, message: '주체를 선택해주세요.');
      return;
    }
    if (_vm.selectedPaymentId == null) {
      await AppAlertDialog.show(context, message: '결제수단을 선택해주세요.');
      return;
    }
    if (_vm.selectedCategoryId == null) {
      await AppAlertDialog.show(context, message: '대분류를 선택해주세요.');
      return;
    }
    final price = _parsePrice(_priceCtrl.text);
    if (price <= 0) {
      await AppAlertDialog.show(context, message: '가격을 입력해주세요.');
      return;
    }

    final request = AccountRequest(
      accountDt: _toApiDate(_selectedDate),
      divisionId: _vm.selectedDivisionId!,
      memberId: _vm.selectedMemberId!,
      paymentId: _vm.selectedPaymentId!,
      categoryId: _vm.selectedCategoryId!,
      categorySeq: _vm.selectedCategorySeq ?? '',
      price: price,
      remark: _remarkCtrl.text.isNotEmpty ? _remarkCtrl.text : null,
      impulseYn: _impulseYn,
      pointPrice: _parsePrice(_pointPriceCtrl.text),
    );

    if (!mounted) return;
    AppLoadingDialog.show(context);
    try {
      if (_isEditMode) {
        await AccountService.instance
            .updateAccount(_editItem!.accountId, request);
      } else {
        await AccountService.instance.createAccount(request);
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
      await AccountService.instance.deleteAccount(_editItem!.accountId);
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
          _isEditMode ? '거래 수정' : '거래 추가',
          style: AppTextStyles.textHeadlineMd.copyWith(
            color: AppColors.colorTextPrimary,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppColors.colorTextSecondary,
          size: 24,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              if (_vm.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.colorAccentTeal,
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _buildForm(),
                    ),
                  ),
                  _buildButtons(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        // 날짜
        _FormRow(
          emoji: '📅',
          label: '날짜',
          child: GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.colorDivider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _displayDate(_selectedDate),
                      style: AppTextStyles.textBodyLg,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    color: AppColors.colorTextSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 구분
        _FormRow(
          emoji: '🏷️',
          label: '구분',
          child: _buildDropdown<String>(
            value: _vm.selectedDivisionId,
            hint: '선택',
            items: _vm.divisions
                .map((d) => DropdownMenuItem(
                      value: d.divisionId,
                      child: Text(d.divisionNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onDivisionChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 주체
        _FormRow(
          emoji: '👤',
          label: '주체',
          child: _buildDropdown<String>(
            value: _vm.selectedMemberId,
            hint: '선택',
            items: _vm.members
                .map((m) => DropdownMenuItem(
                      value: m.memberId,
                      child: Text(m.memberNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onMemberChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 결제수단
        _FormRow(
          emoji: '💳',
          label: '결제수단',
          child: _buildDropdown<String>(
            value: _vm.selectedPaymentId,
            hint: _vm.selectedMemberId == null ? '주체를 먼저 선택하세요' : '선택',
            enabled: _vm.selectedMemberId != null,
            items: _vm.payments
                .map((p) => DropdownMenuItem(
                      value: p.paymentId,
                      child: Text(p.paymentNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onPaymentChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 대분류
        _FormRow(
          emoji: '📂',
          label: '대분류',
          child: _buildDropdown<String>(
            value: _vm.selectedCategoryId,
            hint: _vm.selectedDivisionId == null
                ? '구분을 먼저 선택하세요'
                : _vm.isCategoriesLoading
                    ? '로딩 중...'
                    : '선택',
            enabled: _vm.selectedDivisionId != null &&
                !_vm.isCategoriesLoading,
            items: _vm.categories
                .map((c) => DropdownMenuItem(
                      value: c.categoryId,
                      child: Text(c.categoryNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onCategoryChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 소분류
        _FormRow(
          emoji: '📁',
          label: '소분류',
          child: _buildDropdown<String>(
            value: _vm.selectedCategorySeq,
            hint: _vm.selectedCategoryId == null
                ? '대분류를 먼저 선택하세요'
                : _vm.isCategorySeqsLoading
                    ? '로딩 중...'
                    : '선택',
            enabled: _vm.selectedCategoryId != null &&
                !_vm.isCategorySeqsLoading,
            items: _vm.categorySeqs
                .map((s) => DropdownMenuItem(
                      value: s.categorySeq,
                      child: Text(s.categorySeqNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onCategorySeqChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 가격
        _FormRow(
          emoji: '💰',
          label: '가격',
          child: TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: '원',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 비고
        _FormRow(
          emoji: '📝',
          label: '비고',
          child: TextField(
            controller: _remarkCtrl,
            decoration: const InputDecoration(
              hintText: '선택사항',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 충동지출
        _FormRow(
          emoji: '⚠️',
          label: '충동지출',
          child: _buildDropdown<String>(
            value: _impulseYn,
            items: const [
              DropdownMenuItem(value: 'N', child: Text('N')),
              DropdownMenuItem(value: 'Y', child: Text('Y')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _impulseYn = v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 포인트 처리 금액
        _FormRow(
          emoji: '⭐',
          label: '포인트',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pointPriceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  final price = _parsePrice(_priceCtrl.text);
                  if (price > 0) {
                    _pointPriceCtrl.text = FormatUtil.formatPrice(price);
                  }
                },
                child: const Text('전액'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    String? hint,
    bool enabled = true,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: AppColors.colorBgCard,
        hint: Text(
          hint ?? '선택',
          style: const TextStyle(color: AppColors.colorTextDisabled),
        ),
        items: enabled ? items : [],
        onChanged: enabled ? onChanged : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        disabledHint: Text(
          hint ?? '선택',
          style: const TextStyle(color: AppColors.colorTextDisabled),
        ),
      ),
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

// ── Form Row ──────────────────────────────────────────────────────────────────

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

import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/utils/format_util.dart';
import 'package:account_book_vibe/core/utils/thousands_formatter.dart';
import 'package:account_book_vibe/data/models/my_asset_model.dart';
import 'package:account_book_vibe/data/services/my_asset_service.dart';
import 'package:account_book_vibe/features/asset/my_asset_form_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MyAssetFormScreen extends StatefulWidget {
  const MyAssetFormScreen({super.key, this.extra});

  final Object? extra;

  @override
  State<MyAssetFormScreen> createState() => _MyAssetFormScreenState();
}

class _MyAssetFormScreenState extends State<MyAssetFormScreen> {
  late final MyAssetFormViewModel _vm;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tickerCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;

  MyAssetItemResponse? get _editItem => widget.extra as MyAssetItemResponse?;
  bool get _isEditMode => _editItem != null;

  @override
  void initState() {
    super.initState();
    _vm = MyAssetFormViewModel();

    final item = _editItem;
    _nameCtrl = TextEditingController(text: item?.myAssetNm ?? '');
    _tickerCtrl = TextEditingController(text: item?.ticker ?? '');
    _priceCtrl = TextEditingController(
      text: item != null ? FormatUtil.formatPrice(item.price) : '',
    );
    _qtyCtrl = TextEditingController(
      text: item != null ? _formatQty(item.qty) : '',
    );

    _vm.init(
      assetId: item?.assetId,
      priceDivCd: item?.priceDivCd,
      exchangeRateYn: item?.exchangeRateYn,
      cashableYn: item?.cashableYn,
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    _nameCtrl.dispose();
    _tickerCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toString();
  }

  int _parsePrice(String text) =>
      int.tryParse(text.replaceAll(',', '')) ?? 0;

  double _parseQty(String text) => double.tryParse(text) ?? 0;

  Future<void> _submit() async {
    if (_vm.selectedAssetId == null) {
      await AppAlertDialog.show(context, message: '자산 분류를 선택해주세요.');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      await AppAlertDialog.show(context, message: '자산 이름을 입력해주세요.');
      return;
    }
    final qty = _parseQty(_qtyCtrl.text);
    if (qty <= 0) {
      await AppAlertDialog.show(context, message: '개수를 입력해주세요.');
      return;
    }
    final price = _parsePrice(_priceCtrl.text);
    if (!_vm.isAuto && price == 0) {
      await AppAlertDialog.show(context, message: '가격을 입력해주세요.');
      return;
    }

    final request = MyAssetRequest(
      myAssetNm: _nameCtrl.text.trim(),
      assetId: _vm.selectedAssetId!,
      ticker: _tickerCtrl.text.trim(),
      priceDivCd: _vm.priceDivCd,
      price: _vm.isAuto ? 0 : price,
      qty: qty,
      exchangeRateYn: _vm.exchangeRateYn,
      cashableYn: _vm.cashableYn,
    );

    if (!mounted) return;
    AppLoadingDialog.show(context);
    try {
      if (_isEditMode) {
        await MyAssetService.instance
            .updateMyAsset(_editItem!.myAssetId, request);
      } else {
        await MyAssetService.instance.createMyAsset(request);
      }
      if (mounted) {
        AppLoadingDialog.hide(context);
        context.pop(_isEditMode ? '수정 완료!!!' : '등록 완료!!!');
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
      await MyAssetService.instance.deleteMyAsset(_editItem!.myAssetId);
      if (mounted) {
        AppLoadingDialog.hide(context);
        context.pop('삭제 완료!!!');
      }
    } on Exception catch (e) {
      if (mounted) {
        AppLoadingDialog.hide(context);
        await AppAlertDialog.show(context, message: e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '자산 수정' : '자산 추가'),
        backgroundColor: AppColors.colorBgMain,
        foregroundColor: AppColors.colorTextPrimary,
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
        // 자산 분류
        _FormRow(
          emoji: '🏦',
          label: '자산 분류',
          child: _buildDropdown<String>(
            value: _vm.selectedAssetId,
            hint: '선택',
            items: _vm.assets
                .map((a) => DropdownMenuItem(
                      value: a.assetId,
                      child: Text(a.assetNm),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _vm.onAssetChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 자산 이름
        _FormRow(
          emoji: '🏷️',
          label: '자산 이름',
          child: TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: '이름 입력',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 티커
        _FormRow(
          emoji: '📌',
          label: '티커',
          child: TextField(
            controller: _tickerCtrl,
            decoration: const InputDecoration(
              hintText: '선택사항',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 가격 세팅 방식
        _FormRow(
          emoji: '⚙️',
          label: '가격 방식',
          child: _buildDropdown<String>(
            value: _vm.priceDivCd,
            items: const [
              DropdownMenuItem(value: 'MANUAL', child: Text('MANUAL')),
              DropdownMenuItem(value: 'AUTO', child: Text('AUTO')),
            ],
            onChanged: (v) {
              if (v != null) _vm.onPriceDivCdChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 가격
        _FormRow(
          emoji: '💰',
          label: '가격',
          child: _vm.isAuto
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  color: AppColors.colorBgSub,
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AUTO 조회',
                          style: TextStyle(color: AppColors.colorTextDisabled),
                        ),
                      ),
                    ],
                  ),
                )
              : TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
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

        // 개수
        _FormRow(
          emoji: '🔢',
          label: '개수',
          child: TextField(
            controller: _qtyCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: const InputDecoration(
              hintText: '0',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 환율 적용
        _FormRow(
          emoji: '💱',
          label: '환율 적용',
          child: _buildDropdown<String>(
            value: _vm.exchangeRateYn,
            items: const [
              DropdownMenuItem(value: 'N', child: Text('N')),
              DropdownMenuItem(value: 'Y', child: Text('Y')),
            ],
            onChanged: (v) {
              if (v != null) _vm.onExchangeRateYnChanged(v);
            },
          ),
        ),
        const Divider(height: 1, color: AppColors.colorDivider),

        // 현금성 여부
        _FormRow(
          emoji: '💵',
          label: '현금성',
          child: _buildDropdown<String>(
            value: _vm.cashableYn,
            items: const [
              DropdownMenuItem(value: 'N', child: Text('N')),
              DropdownMenuItem(value: 'Y', child: Text('Y')),
            ],
            onChanged: (v) {
              if (v != null) _vm.onCashableYnChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    String? hint,
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
        items: items,
        onChanged: onChanged,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
          SizedBox(
            width: 20,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.colorTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}


import 'package:account_book_vibe/core/constants/app_colors.dart';
import 'package:account_book_vibe/core/constants/app_text_styles.dart';
import 'package:account_book_vibe/features/ai_report/ai_profile_viewmodel.dart';
import 'package:account_book_vibe/shared/widgets/app_dialogs.dart';
import 'package:account_book_vibe/shared/widgets/app_toast.dart';
import 'package:account_book_vibe/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';

/// 미답변 질문을 읽고, 사용자 확정 구역을 통째로 고치는 화면.
///
/// 질문에 답하는 별도 엔드포인트는 없다. 답은 확정 구역에 직접 적는 것이고,
/// 질문 텍스트가 자동으로 옮겨오지 않는다.
class AiProfileScreen extends StatefulWidget {
  const AiProfileScreen({super.key});

  @override
  State<AiProfileScreen> createState() => _AiProfileScreenState();
}

class _AiProfileScreenState extends State<AiProfileScreen> {
  final _vm = AiProfileViewModel();
  final _controller = TextEditingController();

  /// 서버에서 마지막으로 받은 원문. 이것과 다르면 미저장 변경이 있는 것이다.
  String _saved = '';

  @override
  void initState() {
    super.initState();
    _vm.addListener(_syncController);
    _vm.load();
  }

  @override
  void dispose() {
    _vm.removeListener(_syncController);
    _vm.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncController() {
    final loaded = _vm.profile?.userConfirmed;
    if (loaded == null || loaded == _saved) return;
    _saved = loaded;
    _controller.text = loaded;
  }

  bool get _isDirty => _controller.text != _saved;

  Future<void> _save() async {
    final failure = await _vm.save(_controller.text);
    if (!mounted) return;
    if (failure != null) {
      // 입력 내용은 그대로 둔다. 다시 누르면 재시도된다.
      AppToast.show(context, failure, type: ToastType.error);
      return;
    }
    AppToast.show(context, '저장했어', type: ToastType.success);
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return AppAlertDialog.confirm(
      context,
      message: '저장하지 않은 변경이 있어. 그냥 나갈까?',
      confirmText: '나가기',
      cancelText: '계속 쓰기',
    );
  }

  /// `PopScope.onPopInvokedWithResult`용. State의 `context`/`mounted`를 쓰도록
  /// `build`가 아닌 별도 메서드로 뺐다 — `build`의 지역 `context` 매개변수
  /// 안에서는 analyzer가 async-gap 뒤 `mounted` 가드를 인식하지 못한다.
  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) return;
    if (await _confirmDiscard() && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopInvoked(didPop),
      child: Scaffold(
        backgroundColor: AppColors.colorBgMain,
        appBar: AppBar(
          backgroundColor: AppColors.colorBgMain,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.colorTextPrimary),
          title: Text(
            '내 프로필',
            style: AppTextStyles.textHeadlineSm.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          actions: [
            ListenableBuilder(
              listenable: Listenable.merge([_vm, _controller]),
              builder: (context, _) {
                final canSave = _isDirty && !_vm.isSaving;
                return TextButton(
                  onPressed: canSave ? _save : null,
                  child: Text(
                    _vm.isSaving ? '저장 중…' : '저장',
                    style: AppTextStyles.textLabelMd.copyWith(
                      color: canSave
                          ? AppColors.colorAccentTeal
                          : AppColors.colorTextDisabled,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.isLoading) {
              return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.colorAccentTeal),
              );
            }

            final profile = _vm.profile;
            if (_vm.errorMessage != null || profile == null) {
              return ErrorView(
                message: _vm.errorMessage ?? '프로필을 불러오지 못했습니다.',
                onRetry: _vm.load,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (profile.pendingQuestions.trim().isNotEmpty) ...[
                  const _SectionLabel(
                    label: 'AI가 물어본 것',
                    color: AppColors.colorAccentTeal,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.colorHoverTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      profile.pendingQuestions,
                      style: AppTextStyles.textBodyMd.copyWith(
                        color: AppColors.colorTextPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                const _SectionLabel(label: '내가 확정한 내용'),
                const SizedBox(height: 4),
                Text(
                  '여기에 적은 내용이 다음 리포트에 반영돼. 질문에 대한 답도 여기 적으면 돼.',
                  style: AppTextStyles.textBodyXs.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 10,
                  style: AppTextStyles.textBodyMd.copyWith(
                    color: AppColors.colorTextPrimary,
                    height: 1.6,
                  ),
                  decoration: InputDecoration(
                    hintText: '- 목표: 전세보증금 1.5억 · 2028년\n- 월 지출 상한 300만',
                    hintStyle: AppTextStyles.textBodyMd.copyWith(
                      color: AppColors.colorTextDisabled,
                    ),
                    filled: true,
                    fillColor: AppColors.colorBgSub,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.colorDivider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.colorDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.colorAccentTeal),
                    ),
                  ),
                ),
                if (profile.observations.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      iconColor: AppColors.colorTextSecondary,
                      collapsedIconColor: AppColors.colorTextSecondary,
                      title: Text(
                        'AI가 관찰한 내용',
                        style: AppTextStyles.textLabelMd.copyWith(
                          color: AppColors.colorTextSecondary,
                        ),
                      ),
                      children: [
                        SelectableText(
                          profile.observations,
                          style: AppTextStyles.textBodySm.copyWith(
                            color: AppColors.colorTextSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.textTitleSm.copyWith(
        color: color ?? AppColors.colorTextPrimary,
      ),
    );
  }
}

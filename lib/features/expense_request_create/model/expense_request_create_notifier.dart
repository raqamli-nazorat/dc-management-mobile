import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/api/dio_client.dart';
import '../../../entities/expense_request/api/expense_request_repository.dart';
import '../../../entities/expense_request/model/expense_request.dart';

// State
sealed class ExpenseRequestCreateState {
  const ExpenseRequestCreateState();
}

class ExpenseRequestCreateIdle extends ExpenseRequestCreateState {
  const ExpenseRequestCreateIdle();
}

class ExpenseRequestCreateLoading extends ExpenseRequestCreateState {
  const ExpenseRequestCreateLoading();
}

class ExpenseRequestCreateSuccess extends ExpenseRequestCreateState {
  final ExpenseRequest request;
  const ExpenseRequestCreateSuccess(this.request);
}

class ExpenseRequestCreateError extends ExpenseRequestCreateState {
  final String message;
  const ExpenseRequestCreateError(this.message);
}

// Providers
final _dioProvider = Provider((ref) => DioClient.create());

final _expenseRepoProvider = Provider(
  (ref) => ExpenseRequestRepository(ref.read(_dioProvider)),
);

final expenseRequestCreateProvider =
    StateNotifierProvider.autoDispose<ExpenseRequestCreateNotifier, ExpenseRequestCreateState>(
  (ref) => ExpenseRequestCreateNotifier(ref.read(_expenseRepoProvider)),
);

class ExpenseRequestCreateNotifier
    extends StateNotifier<ExpenseRequestCreateState> {
  final ExpenseRequestRepository _repo;

  ExpenseRequestCreateNotifier(this._repo)
      : super(const ExpenseRequestCreateIdle());

  Future<void> submit(ExpenseRequestCreatePayload payload) async {
    state = const ExpenseRequestCreateLoading();
    try {
      final result = await _repo.create(payload);
      state = ExpenseRequestCreateSuccess(result);
    } catch (_) {
      state = const ExpenseRequestCreateError(
        "So'rov yuborishda xatolik yuz berdi",
      );
    }
  }

  void reset() => state = const ExpenseRequestCreateIdle();
}

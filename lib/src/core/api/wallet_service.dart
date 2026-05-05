import '../models/api_models.dart';
import 'api_client.dart';
import 'api_config.dart';

class WalletService {
  WalletService._();

  // Bank Accounts
  static Future<({List<BankAccountData> accounts, int count})>
      filterBankAccounts({
    int skip = 0,
    int limit = 50,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterBankAccounts,
      <String, dynamic>{'Skip': skip, 'Limit': limit},
    );

    if (!response.success || response.data == null) {
      return (accounts: <BankAccountData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<BankAccountData> accounts = dataList
        .map((dynamic item) =>
            BankAccountData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (accounts: accounts, count: response.count ?? accounts.length);
  }

  static Future<ApiResponse> createBankAccount(
      Map<String, dynamic> accountData) async {
    return ApiClient.instance.post(ApiConfig.createBankAccount, accountData);
  }

  static Future<ApiResponse> editBankAccount(
      Map<String, dynamic> accountData) async {
    return ApiClient.instance.post(ApiConfig.editBankAccount, accountData);
  }

  static Future<ApiResponse> toggleBankAccount(String accountId,
      {required bool active}) async {
    return ApiClient.instance.post(
      active ? ApiConfig.activeBankAccount : ApiConfig.inactiveBankAccount,
      <String, dynamic>{'BankAccountID': accountId},
    );
  }

  static Future<({bool valid, String? bankName, String? branchName})> validateIfsc(
      String ifscCode) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.validateIfsc,
      <String, dynamic>{'IFSC_Code': ifscCode},
    );

    if (response.success && response.data != null) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return (
        valid: true,
        bankName: data['Bank_Name'] as String?,
        branchName: data['Branch_Name'] as String?,
      );
    }
    return (valid: false, bankName: null, branchName: null);
  }

  static Future<({bool valid, String? customerName})> validateUpi(
    String upiId,
  ) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.validateUpi,
      <String, dynamic>{'UPI_ID': upiId},
    );
    if (response.success && response.data is Map<String, dynamic>) {
      final Map<String, dynamic> data =
          response.data as Map<String, dynamic>;
      return (
        valid: data['Whether_Valid'] as bool? ?? true,
        customerName: data['Customer_Name'] as String?,
      );
    }

    return (valid: false, customerName: null);
  }

  // Transactions
  static Future<({List<WalletTransactionData> transactions, int count})>
      filterWalletTransactions({
    int skip = 0,
    int limit = 10,
    int? transactionType,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterWalletTransactions,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Transaction_Type_Filter': transactionType != null,
        if (transactionType != null) 'Transaction_Type': transactionType,
      },
    );

    if (!response.success || response.data == null) {
      return (transactions: <WalletTransactionData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<WalletTransactionData> transactions = dataList
        .map((dynamic item) =>
            WalletTransactionData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (
      transactions: transactions,
      count: response.count ?? transactions.length,
    );
  }

  // Withdrawals
  static Future<({List<WithdrawalData> withdrawals, int count})>
      filterWithdrawals({
    int skip = 0,
    int limit = 10,
    int? statusFilter,
  }) async {
    final ApiResponse response = await ApiClient.instance.post(
      ApiConfig.filterWalletWithdrawals,
      <String, dynamic>{
        'Skip': skip,
        'Limit': limit,
        'Whether_Withdrawal_Status_Filter': statusFilter != null,
        if (statusFilter != null) 'Withdrawal_Status': statusFilter,
      },
    );

    if (!response.success || response.data == null) {
      return (withdrawals: <WithdrawalData>[], count: 0);
    }

    final List<dynamic> dataList = response.data as List<dynamic>;
    final List<WithdrawalData> withdrawals = dataList
        .map((dynamic item) =>
            WithdrawalData.fromJson(item as Map<String, dynamic>))
        .toList();

    return (
      withdrawals: withdrawals,
      count: response.count ?? withdrawals.length,
    );
  }

  static Future<ApiResponse> withdrawAmount(
      String bankAccountId, double amount) async {
    return ApiClient.instance.post(
      ApiConfig.withdrawWalletAmount,
      <String, dynamic>{
        'BankAccountID': bankAccountId,
        'Amount': amount,
      },
    );
  }
}

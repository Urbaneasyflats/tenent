import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/vendor_service.dart';
import '../../core/api/wallet_service.dart';
import '../../core/models/api_models.dart';
import '../../core/models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_tab_bar.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/tone_badge.dart';

class BankWalletPage extends StatefulWidget {
  const BankWalletPage({super.key});

  @override
  State<BankWalletPage> createState() => _BankWalletPageState();
}

class _BankWalletPageState extends State<BankWalletPage> {
  static const int _pageSize = 10;

  int _currentTab = 0;

  // Wallet summary
  WalletSummaryData? _walletSummary;

  // Accounts tab
  bool _isLoadingAccounts = true;
  String? _accountsError;
  List<BankAccountData> _accounts = <BankAccountData>[];
  int _accountsSkip = 0;

  // Transactions tab
  bool _isLoadingTransactions = true;
  String? _transactionsError;
  List<WalletTransactionData> _transactions = <WalletTransactionData>[];
  int _transactionsTotal = 0;
  int _transactionsSkip = 0;
  int? _transactionTypeFilter;

  // Withdrawals tab
  bool _isLoadingWithdrawals = true;
  String? _withdrawalsError;
  List<WithdrawalData> _withdrawals = <WithdrawalData>[];
  int _withdrawalsTotal = 0;
  int _withdrawalsSkip = 0;
  int? _withdrawalStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait<void>(<Future<void>>[
      _loadWalletSummary(),
      _loadAccounts(reset: true),
      _loadTransactions(reset: true),
      _loadWithdrawals(reset: true),
    ]);
  }

  Future<void> _loadWalletSummary() async {
    try {
      final VendorData? vendor = await VendorService.fetchVendorInfo();
      if (!mounted) return;
      setState(() {
        _walletSummary = vendor?.walletInfo;
      });
    } catch (_) {}
  }

  Future<void> _loadAccounts({bool reset = false}) async {
    if (reset) {
      setState(() {
        _accountsSkip = 0;
        _isLoadingAccounts = true;
        _accountsError = null;
      });
    } else {
      setState(() {
        _isLoadingAccounts = true;
      });
    }

    try {
      final result = await WalletService.filterBankAccounts(
        skip: reset ? 0 : _accountsSkip,
        limit: 100, // load all accounts at once (typically few)
      );
      if (!mounted) return;
      setState(() {
        _accounts = result.accounts;
        _isLoadingAccounts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _accountsError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingAccounts = false;
      });
    }
  }

  Future<void> _loadTransactions({bool reset = false}) async {
    final int skip = reset ? 0 : _transactionsSkip;
    if (reset) {
      setState(() {
        _transactionsSkip = 0;
        _isLoadingTransactions = true;
        _transactionsError = null;
      });
    } else {
      setState(() {
        _isLoadingTransactions = true;
      });
    }

    try {
      final result = await WalletService.filterWalletTransactions(
        skip: skip,
        limit: _pageSize,
        transactionType: _transactionTypeFilter,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _transactions = result.transactions;
        } else {
          _transactions = <WalletTransactionData>[
            ..._transactions,
            ...result.transactions,
          ];
        }
        _transactionsTotal = result.count;
        _transactionsSkip = skip + result.transactions.length;
        _isLoadingTransactions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _transactionsError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _loadWithdrawals({bool reset = false}) async {
    final int skip = reset ? 0 : _withdrawalsSkip;
    if (reset) {
      setState(() {
        _withdrawalsSkip = 0;
        _isLoadingWithdrawals = true;
        _withdrawalsError = null;
      });
    } else {
      setState(() {
        _isLoadingWithdrawals = true;
      });
    }

    try {
      final result = await WalletService.filterWithdrawals(
        skip: skip,
        limit: _pageSize,
        statusFilter: _withdrawalStatusFilter,
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _withdrawals = result.withdrawals;
        } else {
          _withdrawals = <WithdrawalData>[
            ..._withdrawals,
            ...result.withdrawals,
          ];
        }
        _withdrawalsTotal = result.count;
        _withdrawalsSkip = skip + result.withdrawals.length;
        _isLoadingWithdrawals = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _withdrawalsError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingWithdrawals = false;
      });
    }
  }

  Future<void> _toggleAccount(BankAccountData account) async {
    try {
      final ApiResponse response = await WalletService.toggleBankAccount(
        account.accountId,
        active: !account.isActive,
      );
      _showMessage(response.message ?? 'Account status updated.');
      await _loadAccounts(reset: true);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openAccountSheet({BankAccountData? account}) async {
    final TextEditingController holderController = TextEditingController(
      text: account?.holderName ?? '',
    );
    final TextEditingController numberController = TextEditingController(
      text: account?.accountNumber ?? '',
    );
    final TextEditingController ifscController = TextEditingController(
      text: account?.ifscCode ?? '',
    );
    final TextEditingController bankNameController = TextEditingController(
      text: account?.bankName ?? '',
    );
    final TextEditingController branchNameController = TextEditingController(
      text: account?.branchName ?? '',
    );
    final TextEditingController upiController = TextEditingController(
      text: account?.upiId ?? '',
    );

    int accountType = account?.accountType ?? 1;
    bool isDefault = account?.isDefault ?? false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        bool isSubmitting = false;
        bool isValidating = false;
        String? validationMessage;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> validateCurrent() async {
              setModalState(() {
                isValidating = true;
                validationMessage = null;
              });

              try {
                if (accountType == 1) {
                  final result = await WalletService.validateIfsc(
                      ifscController.text.trim());
                  if (result.valid) {
                    bankNameController.text = result.bankName ?? '';
                    branchNameController.text = result.branchName ?? '';
                    validationMessage = result.bankName == null
                        ? 'IFSC validated.'
                        : 'IFSC validated for ${result.bankName}.';
                  } else {
                    validationMessage = 'Invalid IFSC code.';
                  }
                } else {
                  final result = await WalletService.validateUpi(
                      upiController.text.trim());
                  validationMessage = result.valid
                      ? result.customerName == null
                          ? 'UPI validated.'
                          : 'UPI validated for ${result.customerName}.'
                      : 'Invalid UPI ID.';
                }
              } catch (error) {
                validationMessage =
                    error.toString().replaceFirst('Exception: ', '');
              } finally {
                setModalState(() {
                  isValidating = false;
                });
              }
            }

            Future<void> submit() async {
              if (accountType == 1 &&
                  (holderController.text.trim().isEmpty ||
                      numberController.text.trim().isEmpty ||
                      ifscController.text.trim().isEmpty)) {
                _showMessage(
                    'Holder name, account number, and IFSC are required.');
                return;
              }
              if (accountType == 2 && upiController.text.trim().isEmpty) {
                _showMessage('UPI ID is required.');
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              final Map<String, dynamic> payload = <String, dynamic>{
                if (account != null) 'BankAccountID': account.accountId,
                'Account_Type': accountType,
                'Whether_Default': isDefault,
                if (accountType == 1)
                  'Account_Holder_Name': holderController.text.trim(),
                if (accountType == 1)
                  'Account_Number': numberController.text.trim(),
                if (accountType == 1)
                  'IFSC_Code': ifscController.text.trim(),
                if (accountType == 1)
                  'Bank_Name': bankNameController.text.trim(),
                if (accountType == 1)
                  'Branch_Name': branchNameController.text.trim(),
                if (accountType == 2) 'UPI_ID': upiController.text.trim(),
              };

              try {
                if (account == null) {
                  await WalletService.createBankAccount(payload);
                } else {
                  await WalletService.editBankAccount(payload);
                }
                if (!mounted) return;
                Navigator.of(context).pop();
                _showMessage(account == null
                    ? 'Account added successfully.'
                    : 'Account updated successfully.');
                await _loadAccounts(reset: true);
                await _loadWalletSummary();
              } catch (error) {
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                setModalState(() {
                  isSubmitting = false;
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      account == null ? 'Add Account' : 'Edit Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: accountType,
                      decoration:
                          const InputDecoration(labelText: 'Account type'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(
                            value: 1, child: Text('Bank account')),
                        DropdownMenuItem(value: 2, child: Text('UPI')),
                      ],
                      onChanged: (int? value) {
                        setModalState(() {
                          accountType = value ?? 1;
                          validationMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (accountType == 1) ...<Widget>[
                      TextField(
                        controller: holderController,
                        decoration: const InputDecoration(
                            labelText: 'Account holder name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: numberController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Account number'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ifscController,
                        textCapitalization: TextCapitalization.characters,
                        decoration:
                            const InputDecoration(labelText: 'IFSC code'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: bankNameController,
                        decoration:
                            const InputDecoration(labelText: 'Bank name'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: branchNameController,
                        decoration:
                            const InputDecoration(labelText: 'Branch name'),
                      ),
                    ] else ...<Widget>[
                      TextField(
                        controller: upiController,
                        decoration:
                            const InputDecoration(labelText: 'UPI ID'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Set as default payout account'),
                      value: isDefault,
                      onChanged: (bool value) {
                        setModalState(() {
                          isDefault = value;
                        });
                      },
                    ),
                    if (validationMessage != null) ...<Widget>[
                      const SizedBox(height: 8),
                      CustomCard(
                        padding: CustomCardPadding.sm,
                        color: AppTheme.surfaceMuted,
                        child: Text(validationMessage!),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: CustomButton(
                            label: 'Validate',
                            variant: CustomButtonVariant.outline,
                            isLoading: isValidating,
                            onPressed: isValidating ? null : validateCurrent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            label: account == null ? 'Save' : 'Update',
                            isLoading: isSubmitting,
                            onPressed: isSubmitting ? null : submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    holderController.dispose();
    numberController.dispose();
    ifscController.dispose();
    bankNameController.dispose();
    branchNameController.dispose();
    upiController.dispose();
  }

  Future<void> _openWithdrawSheet() async {
    final List<BankAccountData> activeAccounts =
        _accounts.where((BankAccountData item) => item.isActive).toList();
    if (activeAccounts.isEmpty) {
      _showMessage('Add an active bank account before withdrawing.');
      return;
    }

    String selectedAccountId = activeAccounts.first.accountId;
    final TextEditingController amountController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> submit() async {
              final double? amount =
                  double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                _showMessage('Enter a valid amount.');
                return;
              }

              setModalState(() {
                isSubmitting = true;
              });

              try {
                final ApiResponse response = await WalletService.withdrawAmount(
                  selectedAccountId,
                  amount,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                _showMessage(
                    response.message ?? 'Withdrawal request created.');
                await Future.wait<void>(<Future<void>>[
                  _loadWalletSummary(),
                  _loadWithdrawals(reset: true),
                ]);
              } catch (error) {
                if (!mounted) return;
                _showMessage(error.toString().replaceFirst('Exception: ', ''));
                setModalState(() {
                  isSubmitting = false;
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Withdraw wallet amount',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      decoration:
                          const InputDecoration(labelText: 'Bank account'),
                      items: activeAccounts
                          .map((BankAccountData acc) {
                            final String label = acc.accountType == 2
                                ? (acc.upiId ?? 'UPI')
                                : '${acc.bankName ?? 'Bank'} ${acc.accountNumber ?? ''}';
                            return DropdownMenuItem<String>(
                              value: acc.accountId,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (String? value) {
                        setModalState(() {
                          selectedAccountId = value ?? selectedAccountId;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'Rs ',
                      ),
                    ),
                    if (_walletSummary != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        'Available balance: Rs ${_walletSummary!.availableAmount.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Request Withdrawal',
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : submit,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Bank Details & Wallet'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: AppTheme.pagePadding,
          children: <Widget>[
            const PageHeader(
              title: 'Bank Details & Wallet',
              description:
                  'Accounts, validation, ledger activity, and withdrawal requests.',
            ),
            const SizedBox(height: 16),
            // Wallet balance summary
            if (_walletSummary != null) ...<Widget>[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _WalletTile(
                      label: 'Available',
                      amount: _walletSummary!.availableAmount,
                      tone: UiTone.success,
                    ),
                    const SizedBox(width: 12),
                    _WalletTile(
                      label: 'Total Credited',
                      amount: _walletSummary!.creditedAmount,
                      tone: UiTone.brand,
                    ),
                    const SizedBox(width: 12),
                    _WalletTile(
                      label: 'Total Debited',
                      amount: _walletSummary!.debitedAmount,
                      tone: UiTone.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            CustomTabBar(
              style: CustomTabBarStyle.pill,
              currentIndex: _currentTab,
              onChanged: (int value) {
                setState(() {
                  _currentTab = value;
                });
              },
              tabs: const <CustomTabItem>[
                CustomTabItem(label: 'Accounts'),
                CustomTabItem(label: 'Transactions'),
                CustomTabItem(label: 'Withdrawals'),
              ],
            ),
            const SizedBox(height: 16),
            ..._buildActiveTab(theme),
          ],
        ),
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              onPressed: _openAccountSheet,
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Add Account'),
            )
          : _currentTab == 2
              ? FloatingActionButton.extended(
                  onPressed: _openWithdrawSheet,
                  icon: const Icon(Icons.call_made_rounded),
                  label: const Text('Withdraw'),
                )
              : null,
    );
  }

  List<Widget> _buildActiveTab(ThemeData theme) {
    switch (_currentTab) {
      case 0:
        return _buildAccountsTab(theme);
      case 1:
        return _buildTransactionsTab(theme);
      default:
        return _buildWithdrawalsTab(theme);
    }
  }

  List<Widget> _buildAccountsTab(ThemeData theme) {
    if (_isLoadingAccounts) {
      return <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_accountsError != null) {
      return <Widget>[
        _ErrorCard(message: _accountsError!, onRetry: () => _loadAccounts(reset: true)),
      ];
    }
    if (_accounts.isEmpty) {
      return <Widget>[
        const CustomCard(child: Text('No bank or UPI accounts found yet.')),
      ];
    }

    return _accounts.map((BankAccountData account) {
      final bool isUpi = account.accountType == 2;
      final String subtitle = isUpi
          ? (account.holderName.isNotEmpty
              ? account.holderName
              : 'UPI payout account')
          : '${account.holderName}${account.accountNumber != null ? ' | ${account.accountNumber}' : ''}';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CustomCard(
          padding: CustomCardPadding.sm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isUpi
                              ? (account.upiId ?? 'UPI Account')
                              : (account.bankName ?? 'Bank Account'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ToneBadge(
                        label: isUpi ? 'UPI' : 'Bank',
                        tone: UiTone.brand,
                      ),
                      ToneBadge(
                        label: account.isActive ? 'Active' : 'Inactive',
                        tone: account.isActive
                            ? UiTone.success
                            : UiTone.neutral,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (account.isDefault)
                    const ToneBadge(label: 'Default', tone: UiTone.warning),
                  if (account.isVerified == true)
                    const ToneBadge(label: 'Verified', tone: UiTone.success),
                  if (account.ifscCode?.isNotEmpty == true)
                    ToneBadge(label: account.ifscCode!, tone: UiTone.neutral),
                  if (account.branchName?.isNotEmpty == true)
                    ToneBadge(
                        label: account.branchName!, tone: UiTone.neutral),
                ],
              ),
              if (account.createdAt != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Added ${formatCompactDate(account.createdAt!)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: CustomButton(
                      label: 'Edit',
                      variant: CustomButtonVariant.outline,
                      onPressed: () => _openAccountSheet(account: account),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      label: account.isActive ? 'Deactivate' : 'Activate',
                      variant: account.isActive
                          ? CustomButtonVariant.danger
                          : CustomButtonVariant.primary,
                      onPressed: () => _toggleAccount(account),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildTransactionsTab(ThemeData theme) {
    final bool hasMore = _transactionsSkip < _transactionsTotal;
    return <Widget>[
      // Type filter
      DropdownButtonFormField<int?>(
        value: _transactionTypeFilter,
        decoration: const InputDecoration(labelText: 'Transaction type'),
        items: const <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(value: null, child: Text('All types')),
          DropdownMenuItem<int?>(value: 1, child: Text('Bill Credit')),
          DropdownMenuItem<int?>(value: 2, child: Text('Withdrawal')),
          DropdownMenuItem<int?>(value: 3, child: Text('Withdrawal Refund')),
        ],
        onChanged: (int? value) {
          setState(() {
            _transactionTypeFilter = value;
          });
          _loadTransactions(reset: true);
        },
      ),
      const SizedBox(height: 16),
      if (_isLoadingTransactions && _transactions.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_transactionsError != null && _transactions.isEmpty)
        _ErrorCard(
            message: _transactionsError!,
            onRetry: () => _loadTransactions(reset: true))
      else if (_transactions.isEmpty)
        const CustomCard(child: Text('No wallet transactions found.'))
      else ...<Widget>[
        ..._transactions.map((WalletTransactionData tx) {
          final TransactionType type =
              tx.type == 1 ? TransactionType.credit : TransactionType.debit;
          final String typeLabel = switch (tx.type) {
            1 => 'Bill Credit',
            2 => 'Withdrawal',
            3 => 'Refund',
            _ => type.label,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              padding: CustomCardPadding.sm,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.toneSoft(type.tone),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      type == TransactionType.credit
                          ? Icons.call_received_rounded
                          : Icons.call_made_rounded,
                      color: AppTheme.toneColor(type.tone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                tx.description?.isNotEmpty == true
                                    ? tx.description!
                                    : typeLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            ToneBadge(label: typeLabel, tone: type.tone),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rs ${tx.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Balance: Rs ${tx.previousBalance.toStringAsFixed(0)} → Rs ${tx.newBalance.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${formatCompactDate(tx.date)} at ${formatClock(tx.date)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_isLoadingTransactions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _loadTransactions(),
                child: Text(
                    'Load More (${_transactionsTotal - _transactionsSkip} remaining)'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'All $_transactionsTotal transactions loaded',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ),
          ),
      ],
    ];
  }

  List<Widget> _buildWithdrawalsTab(ThemeData theme) {
    final bool hasMore = _withdrawalsSkip < _withdrawalsTotal;
    return <Widget>[
      // Status filter
      DropdownButtonFormField<int?>(
        value: _withdrawalStatusFilter,
        decoration: const InputDecoration(labelText: 'Status'),
        items: const <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(value: null, child: Text('All statuses')),
          DropdownMenuItem<int?>(value: 1, child: Text('Pending')),
          DropdownMenuItem<int?>(value: 2, child: Text('Success')),
          DropdownMenuItem<int?>(value: 3, child: Text('Failed')),
        ],
        onChanged: (int? value) {
          setState(() {
            _withdrawalStatusFilter = value;
          });
          _loadWithdrawals(reset: true);
        },
      ),
      const SizedBox(height: 16),
      if (_isLoadingWithdrawals && _withdrawals.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_withdrawalsError != null && _withdrawals.isEmpty)
        _ErrorCard(
            message: _withdrawalsError!,
            onRetry: () => _loadWithdrawals(reset: true))
      else if (_withdrawals.isEmpty)
        const CustomCard(child: Text('No withdrawal records found.'))
      else ...<Widget>[
        ..._withdrawals.map((WithdrawalData wd) {
          final WithdrawalStatus status = switch (wd.status) {
            2 => WithdrawalStatus.completed,
            3 => WithdrawalStatus.failed,
            4 => WithdrawalStatus.failed,
            _ => WithdrawalStatus.pending,
          };

          // Account label
          final String accountLabel = wd.bankAccountType == 2
              ? (wd.upiId ?? 'UPI')
              : <String>[
                  if (wd.bankAccountName?.isNotEmpty == true)
                    wd.bankAccountName!,
                  if (wd.bankName?.isNotEmpty == true) wd.bankName!,
                  if (wd.bankAccountNumber?.isNotEmpty == true)
                    '****${wd.bankAccountNumber!.length > 4 ? wd.bankAccountNumber!.substring(wd.bankAccountNumber!.length - 4) : wd.bankAccountNumber!}',
                ].join(' | ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CustomCard(
              padding: CustomCardPadding.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Rs ${wd.amount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ToneBadge(label: status.label, tone: status.tone),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (accountLabel.isNotEmpty)
                    Text(
                      accountLabel,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  if (wd.payoutMode?.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Mode: ${wd.payoutMode!}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                  if (wd.previousBalance != null &&
                      wd.newBalance != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Balance: Rs ${wd.previousBalance!.toStringAsFixed(0)} → Rs ${wd.newBalance!.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                  if (wd.utr?.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'UTR: ${wd.utr!}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                  if (status == WithdrawalStatus.failed &&
                      wd.failureReason?.isNotEmpty == true) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${wd.failureReason!}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${formatCompactDate(wd.date)} at ${formatClock(wd.date)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_isLoadingWithdrawals)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _loadWithdrawals(),
                child: Text(
                    'Load More (${_withdrawalsTotal - _withdrawalsSkip} remaining)'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'All $_withdrawalsTotal withdrawals loaded',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ),
          ),
      ],
    ];
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.label,
    required this.amount,
    required this.tone,
  });

  final String label;
  final double amount;
  final UiTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: CustomCard(
        padding: CustomCardPadding.sm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ToneBadge(label: label, tone: tone, size: ToneBadgeSize.small),
            const SizedBox(height: 14),
            Text(
              'Rs ${amount.toStringAsFixed(0)}',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Unable to load data',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Retry',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

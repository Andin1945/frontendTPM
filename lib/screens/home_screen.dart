import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';
import 'transfer_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = TransactionService();

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final searchController = TextEditingController();

  List<dynamic> transactions = [];

  int userId = 1;
  String username = "User";
  String type = "expense";

  bool loading = false;
  bool hideBalance = false;

  @override
  void initState() {
    super.initState();
    initUser();
  }

  Future<void> initUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getInt("user_id") ?? 1;
      username = prefs.getString("username") ?? "User";
      hideBalance = prefs.getBool("hide_balance") ?? false;
    });

    loadData();
  }

  Future<void> saveHideBalance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hide_balance", value);
  }

  String formatRupiah(num value) {
    final text = value.toStringAsFixed(0);
    return text.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String money(double value) {
    if (hideBalance) return "Rp •••••••";
    return "Rp${formatRupiah(value)}";
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final data = await service.getTransactions(userId);

    if (!mounted) return;

    setState(() {
      transactions = data;
      loading = false;
    });
  }

  double get income => transactions
      .where((e) => e["type"] == "income")
      .fold(0.0, (sum, e) => sum + ((e["amount"] as num).toDouble()));

  double get expense => transactions
      .where((e) => e["type"] == "expense")
      .fold(0.0, (sum, e) => sum + ((e["amount"] as num).toDouble()));

  double get balance => income - expense;

  Future<void> addTransaction() async {
    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0) {
      showMessage("Nama transaksi dan jumlah wajib diisi");
      return;
    }

    final success = await service.addTransaction(
      userId: userId,
      title: title,
      amount: amount,
      type: type,
    );

    if (success) {
      titleController.clear();
      amountController.clear();
      FocusScope.of(context).unfocus();
      showMessage("Transaksi berhasil ditambahkan");
      loadData();
    } else {
      showMessage("Gagal menambah transaksi");
    }
  }

  Future<void> deleteTransaction(int id) async {
    final success = await service.deleteTransaction(id);

    if (success) {
      showMessage("Transaksi dihapus");
      loadData();
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void openAI() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatScreen()),
    );
  }

  void openTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransferScreen()),
    );

    if (result == true) loadData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((trx) {
      final title = trx["title"].toString().toLowerCase();
      return title.contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xffeef4ff),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 90,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xff5146b8),
              title: const Text("SmartPay AI"),
              actions: [
                IconButton(
                  onPressed: openAI,
                  icon: const Icon(Icons.smart_toy),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _balanceCard(),
                    const SizedBox(height: 18),
                    _quickActions(),
                    const SizedBox(height: 18),
                    _aiBanner(),
                    const SizedBox(height: 18),
                    _transactionForm(),
                    const SizedBox(height: 18),
                    _searchBox(),
                    const SizedBox(height: 14),
                    _sectionTitle("Riwayat Transaksi"),
                  ],
                ),
              ),
            ),

            if (loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            if (!loading && filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: _emptyState(),
                ),
              ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trx = filtered[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _transactionItem(trx),
                  );
                },
                childCount: filtered.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff5146b8),
            Color(0xff7b8cff),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff5146b8).withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Halo, $username",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => hideBalance = !hideBalance);
                  saveHideBalance(hideBalance);
                },
                icon: Icon(
                  hideBalance ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            "Total Saldo",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            money(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  "Pemasukan",
                  income,
                  Icons.south_west,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  "Pengeluaran",
                  expense,
                  Icons.north_east,
                  Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    double value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "$label\n${money(value)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        _action(Icons.send_rounded, "Transfer", openTransfer),
        _action(Icons.add_card_rounded, "Top Up", () {
          showMessage("Fitur Top Up segera hadir");
        }),
        _action(Icons.qr_code_rounded, "QR Pay", () {
          showMessage("Fitur QR Pay segera hadir");
        }),
        _action(Icons.smart_toy_rounded, "AI", openAI),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xffe9f2ff),
                child: Icon(icon, color: const Color(0xff5146b8)),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiBanner() {
    final insight = expense > income
        ? "Pengeluaran kamu lebih besar dari pemasukan. Coba tanya AI untuk tips mengatur uang."
        : "Keuangan kamu cukup stabil. Tanya AI untuk tips keamanan e-wallet.";

    return InkWell(
      onTap: openAI,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xffffefba),
              Color(0xffffffff),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xff5146b8),
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SmartPay AI Assistant",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    insight,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _transactionForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _sectionTitle("Tambah Transaksi"),
          const SizedBox(height: 14),
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: "Nama transaksi",
              prefixIcon: const Icon(Icons.shopping_bag),
              filled: true,
              fillColor: const Color(0xfff6f8ff),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: "Jumlah",
              prefixIcon: const Icon(Icons.payments),
              filled: true,
              fillColor: const Color(0xfff6f8ff),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _typeButton(
                  label: "Keluar",
                  value: "expense",
                  icon: Icons.north_east,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _typeButton(
                  label: "Masuk",
                  value: "income",
                  icon: Icons.south_west,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: addTransaction,
              icon: const Icon(Icons.add),
              label: const Text("Tambah Transaksi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff5146b8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final selected = type == value;

    return InkWell(
      onTap: () => setState(() => type = value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff5146b8) : const Color(0xfff6f8ff),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "Cari transaksi...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _transactionItem(dynamic trx) {
    final isIncome = trx["type"] == "income";
    final amount = (trx["amount"] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          trx["title"].toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          trx["date"]?.toString() ?? "-",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hideBalance
                  ? "${isIncome ? '+' : '-'} Rp••••"
                  : "${isIncome ? '+' : '-'} Rp${formatRupiah(amount)}",
              style: TextStyle(
                color: isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => deleteTransaction(trx["id"]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: const [
          Icon(Icons.receipt_long, size: 48, color: Color(0xff5146b8)),
          SizedBox(height: 10),
          Text(
            "Belum ada transaksi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            "Tambahkan pemasukan atau pengeluaran pertama kamu.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
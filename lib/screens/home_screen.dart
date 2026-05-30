import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/transaction_service.dart';
import 'transfer_screen.dart';
import 'ai_chat_screen.dart';
import 'gyro_game_screen.dart';
import 'qris_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final service = TransactionService();

  final searchController = TextEditingController();
  final noteTitleController = TextEditingController();
  final noteAmountController = TextEditingController();
  final noteDescController = TextEditingController();

  final PageController bannerController = PageController();

  List<dynamic> transactions = [];
  List<Map<String, dynamic>> notes = [];

  int userId = 1;
  String username = "User";

  bool loading = false;
  bool hideBalance = false;

  Timer? bannerTimer;
  int bannerIndex = 0;

  final bgDark = const Color(0xff0F1020);
  final cardDark = const Color(0xff1A1B2E);
  final fieldDark = const Color(0xff25263A);
  final primary = const Color(0xff7C5CFF);
  final secondary = const Color(0xff00D1FF);

  final List<Map<String, dynamic>> banners = [
    {
      "title": "Smart Saving",
      "subtitle": "Mulai atur target tabungan dan rencana keuangan harian.",
      "image":
          "https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1000&q=80",
      "icon": Icons.savings,
    },
    {
      "title": "Anti Scam Alert",
      "subtitle": "Jangan bagikan OTP, PIN, dan kode akses ke siapa pun.",
      "image":
          "https://images.unsplash.com/photo-1563013544-824ae1b704d3?auto=format&fit=crop&w=1000&q=80",
      "icon": Icons.security,
    },
    {
      "title": "Budgeting Mingguan",
      "subtitle": "Pantau pengeluaran agar saldo tetap aman.",
      "image":
          "https://images.unsplash.com/photo-1554224154-26032ffc0d07?auto=format&fit=crop&w=1000&q=80",
      "icon": Icons.pie_chart,
    },
  ];

  @override
  void initState() {
    super.initState();
    initUser();
    startBannerAutoSlide();
  }

  Future<void> initUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userId = prefs.getInt("user_id") ?? 1;
      username = prefs.getString("username") ?? "User";
      hideBalance = prefs.getBool("hide_balance") ?? false;
    });

    await loadNotes();
    await loadData();
  }

  void startBannerAutoSlide() {
    bannerTimer?.cancel();

    bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!bannerController.hasClients) return;

      bannerIndex = (bannerIndex + 1) % banners.length;

      bannerController.animateToPage(
        bannerIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> saveHideBalance(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("hide_balance", value);
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList("finance_notes_$userId") ?? [];

    setState(() {
      notes = raw
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = notes.reversed.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList("finance_notes_$userId", raw);
  }

  Future<void> addNote() async {
    final title = noteTitleController.text.trim();
    final amount = noteAmountController.text.trim();
    final desc = noteDescController.text.trim();

    if (title.isEmpty) {
      showMessage("Judul catatan wajib diisi");
      return;
    }

    final note = {
      "id": DateTime.now().millisecondsSinceEpoch,
      "title": title,
      "amount": amount,
      "desc": desc,
      "date": DateTime.now().toString().substring(0, 16),
    };

    setState(() => notes.insert(0, note));
    await saveNotes();

    noteTitleController.clear();
    noteAmountController.clear();
    noteDescController.clear();

    if (!mounted) return;
    Navigator.pop(context);
    showMessage("Catatan berhasil ditambahkan");
  }

  Future<void> deleteNote(int id) async {
    setState(() => notes.removeWhere((e) => e["id"] == id));
    await saveNotes();
    showMessage("Catatan dihapus");
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

  Future<void> deleteTransaction(int id) async {
    final success = await service.deleteTransaction(id);

    if (success) {
      showMessage("Transaksi dihapus");
      loadData();
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardDark,
      ),
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

  void openQRIS() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRISScreen()),
    );

    if (result == true) loadData();
  }

  void showAddNoteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note, size: 54, color: secondary),
                  const SizedBox(height: 12),
                  const Text(
                    "Catatan Keuangan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _noteInput(noteTitleController, "Judul catatan", Icons.title),
                  const SizedBox(height: 12),
                  _noteInput(
                    noteAmountController,
                    "Nominal opsional",
                    Icons.payments,
                    number: true,
                  ),
                  const SizedBox(height: 12),
                  _noteInput(
                    noteDescController,
                    "Keterangan",
                    Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: addNote,
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan Catatan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _noteInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool number = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: secondary),
        filled: true,
        fillColor: fieldDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void showTransactionDetail(dynamic trx) {
    final isIncome = trx["type"] == "income";
    final amount = (trx["amount"] as num).toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: isIncome
                      ? Colors.greenAccent.withOpacity(0.15)
                      : Colors.redAccent.withOpacity(0.15),
                  child: Icon(
                    isIncome ? Icons.south_west : Icons.north_east,
                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  trx["title"].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${isIncome ? '+' : '-'} Rp${formatRupiah(amount)}",
                  style: TextStyle(
                    color: isIncome ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                _detailRow("Jenis", isIncome ? "Pemasukan" : "Pengeluaran"),
                _detailRow("Tanggal", trx["date"]?.toString() ?? "-"),
                _detailRow("ID Transaksi", trx["id"].toString()),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      deleteTransaction(trx["id"]);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text("Hapus Transaksi"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((trx) {
      final title = trx["title"].toString().toLowerCase();
      return title.contains(searchController.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: bgDark,
      body: RefreshIndicator(
        onRefresh: loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 90,
              pinned: true,
              backgroundColor: bgDark,
              elevation: 0,
              title: const Text(
                "SmartPay AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: showAddNoteSheet,
                  icon: Icon(Icons.edit_note, color: secondary),
                ),
                IconButton(
                  onPressed: openAI,
                  icon: Icon(Icons.smart_toy, color: secondary),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _balanceCard(),
                    const SizedBox(height: 18),
                    _quickActions(),
                    const SizedBox(height: 18),
                    _eventSlider(),
                    const SizedBox(height: 18),
                    _aiBanner(),
                    const SizedBox(height: 18),
                    _notesSection(),
                    const SizedBox(height: 18),
                    _searchBox(),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _sectionTitle("Riwayat Transaksi"),
                    ),
                  ],
                ),
              ),
            ),
            if (loading)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: primary),
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
            if (!loading && filtered.isNotEmpty)
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
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            const Color(0xff14162E),
            secondary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.18),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Halo, $username",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
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
          const SizedBox(height: 24),
          const Text("Total Saldo", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 24),
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
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label\n${money(value)}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.35,
                fontSize: 12,
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
        _action(Icons.smart_toy_rounded, "AI", openAI),
        _action(Icons.sports_esports_rounded, "Game", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GyroGameScreen()),
          );
        }),
        _action(Icons.qr_code_rounded, "QRIS", openQRIS),
      ],
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: primary.withOpacity(0.18),
                child: Icon(icon, color: secondary, size: 21),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => bannerIndex = i),
            itemBuilder: (_, i) {
              final banner = banners[i];

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner["image"],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primary, secondary],
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.black.withOpacity(0.10),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white24,
                              child: Icon(
                                banner["icon"],
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 66,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      banner["title"],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      banner["subtitle"],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        height: 1.2,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: bannerIndex == i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: bannerIndex == i ? secondary : Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aiBanner() {
    final insight = expense > income
        ? "Pengeluaran lebih besar dari pemasukan. Tanya AI untuk strategi hemat."
        : "Keuangan kamu stabil. Tanya AI untuk tips keamanan dan budgeting.";

    return InkWell(
      onTap: openAI,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.95), secondary.withOpacity(0.55)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white24,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                insight,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _notesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _sectionTitle("Catatan Keuangan"),
              const Spacer(),
              IconButton(
                onPressed: showAddNoteSheet,
                icon: Icon(Icons.add_circle, color: secondary),
              ),
            ],
          ),
          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Belum ada catatan. Catatan ini tidak memengaruhi saldo.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          else
            ...notes.take(3).map((note) => _noteItem(note)),
        ],
      ),
    );
  }

  Widget _noteItem(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.sticky_note_2, color: secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${note["title"]}\n${note["amount"] == "" ? note["date"] : "Rp${note["amount"]} • ${note["date"]}"}",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          IconButton(
            onPressed: () => deleteNote(note["id"]),
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Cari transaksi...",
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(Icons.search, color: secondary),
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _transactionItem(dynamic trx) {
    final isIncome = trx["type"] == "income";
    final amount = (trx["amount"] as num).toDouble();

    return InkWell(
      onTap: () => showTransactionDetail(trx),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isIncome
                  ? Colors.greenAccent.withOpacity(0.15)
                  : Colors.redAccent.withOpacity(0.15),
              child: Icon(
                isIncome ? Icons.south_west : Icons.north_east,
                color: isIncome ? Colors.greenAccent : Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 44,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trx["title"].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trx["date"]?.toString() ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 105),
              child: Text(
                hideBalance
                    ? "${isIncome ? '+' : '-'} Rp••••"
                    : "${isIncome ? '+' : '-'} Rp${formatRupiah(amount)}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isIncome ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
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
        color: cardDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 50, color: secondary),
          const SizedBox(height: 10),
          const Text(
            "Belum ada transaksi",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 5),
          const Text(
            "Transfer, QRIS, atau tambah pemasukan agar riwayat muncul.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    bannerTimer?.cancel();
    bannerController.dispose();
    searchController.dispose();
    noteTitleController.dispose();
    noteAmountController.dispose();
    noteDescController.dispose();
    super.dispose();
  }
}
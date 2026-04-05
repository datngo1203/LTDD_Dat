import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'CREATE_JOIN_GROUP/create_group_sheet.dart';
import 'CREATE_JOIN_GROUP/group_repository.dart';
import 'Manage_Group/group_details_page.dart';
import 'SETTING/screensettings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GroupRepository _repository = GroupRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GroupDetails> _groups = [];
  bool _loadingGroups = true;

  final Map<String, double> _balances = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _subs = {};

  double _totalReceive = 0.0;
  double _totalPay = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndSubscribe();
  }

  Future<void> _loadGroupsAndSubscribe() async {
    print('[HomePage] _loadGroupsAndSubscribe START');
    setState(() {
      _loadingGroups = true;
    });

    try {
      final groups = await _repository.getCurrentUserGroups();
      if (!mounted) return;
      print('[HomePage] fetched ${groups.length} groups');

      for (final s in _subs.values) {
        s.cancel();
      }
      _subs.clear();
      _balances.clear();

      setState(() {
        _groups = groups;
        _loadingGroups = false;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      for (final g in groups) {
        final docRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(g.groupId)
            .collection('members')
            .doc(currentUser.uid);

        print('[HomePage] subscribing to member doc for group ${g.groupId}');

        final sub = docRef.snapshots().listen((snap) {
          if (!mounted) return;
          double bal = 0.0;
          if (snap.exists) {
            final data = snap.data() ?? {};
            final raw = data['balance'];
            if (raw is num) {
              bal = raw.toDouble();
            } else {
              bal = double.tryParse(raw?.toString() ?? '') ?? 0.0;
            }
          }
          setState(() {
            _balances[g.groupId] = bal;
            _recomputeTotals();
          });
        });

        _subs[g.groupId] = sub;
      }
      print('[HomePage] subscriptions created: ${_subs.length}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _groups = [];
        _loadingGroups = false;
      });
    }
  }

  void _recomputeTotals() {
    double recv = 0.0;
    double pay = 0.0;
    for (final bal in _balances.values) {
      if (bal >= 0) recv += bal;
      else pay += -bal;
    }
    _totalReceive = recv;
    _totalPay = pay;
    print('[HomePage] totals updated receive=$_totalReceive pay=$_totalPay');
  }

  @override
  void dispose() {
    print('[HomePage] dispose: canceling ${_subs.length} subscriptions');
    for (final s in _subs.values) s.cancel();
    _subs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.home_outlined,
                  color: Colors.blue,
                  size: 30,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 60),
              IconButton(
                icon: const Icon(
                  Icons.manage_accounts_outlined,
                  color: Colors.grey,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add_rounded, size: 30),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) => const CreateGroupSheet(),
          ).then((_) => _loadGroupsAndSubscribe());
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          _buildHeader(currentUser),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildBalanceCard(true, _totalReceive, _loadingGroups)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildBalanceCard(false, _totalPay, _loadingGroups)),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nhóm của tôi",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) {
                  if (_loadingGroups) return const Center(child: CircularProgressIndicator());
                  if (_groups.isEmpty) return const Center(child: Text("Bạn chưa có nhóm nào"));

                  return ListView.separated(
                    itemCount: _groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return _buildGroupCard(context, group);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? currentUser) {
    final displayName = (currentUser?.displayName ?? '').trim();
    final email = (currentUser?.email ?? '').trim();
    final title = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : 'Bạn');

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 70),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[400]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Chào bạn,",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isReceive, double amount, bool loading) {
    final color = isReceive ? Colors.green : Colors.red;
    final icon = isReceive ? Icons.trending_down : Icons.trending_up;
    final title = isReceive ? "Bạn nhận được" : "Bạn cần trả";

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              "${amount.toStringAsFixed(0)}đ",
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _computeTotals(List<GroupDetails> groups) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || groups.isEmpty)
      return {'receive': 0.0, 'pay': 0.0};

    final db = FirebaseFirestore.instance;
    final futures = groups
        .map(
          (g) => db
              .collection('groups')
              .doc(g.groupId)
              .collection('members')
              .doc(currentUser.uid)
              .get(),
        )
        .toList();
    final docs = await Future.wait(futures);

    double totalReceive = 0.0;
    double totalPay = 0.0;

    for (final doc in docs) {
      if (!doc.exists) continue;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      double bal = 0.0;
      final raw = data['balance'];
      if (raw is num)
        bal = raw.toDouble();
      else
        bal = double.tryParse(raw?.toString() ?? '') ?? 0.0;

      if (bal >= 0) {
        totalReceive += bal;
      } else {
        totalPay += -bal;
      }
    }

    return {'receive': totalReceive, 'pay': totalPay};
  }

  Widget _buildGroupCard(BuildContext context, GroupDetails group) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsPage(groupId: group.groupId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 25, child: Icon(Icons.group)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.groupName, style: const TextStyle(fontSize: 18)),
                  Text("${group.memberCount} thành viên"),
                  Text(_buildGroupSubtitle(group)),
                ],
              ),
            ),
            Column(
              children: const [
                Text(
                  "0đ",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Số dư"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildGroupSubtitle(GroupDetails group) {
    if (group.groupType.isNotEmpty) {
      return group.groupType;
    }
    if (group.groupCode.isNotEmpty) {
      return "Mã nhóm: ${group.groupCode}";
    }
    return "Nhóm đã tạo";
  }
}

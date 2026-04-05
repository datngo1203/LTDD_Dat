import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'CREATE_JOIN_GROUP/create_group_sheet.dart';
import 'CREATE_JOIN_GROUP/group_repository.dart';
import 'ChiTietNhom.dart';
import 'SETTING/app_language.dart';
import 'SETTING/screensettings.dart';

class TrangChu extends StatelessWidget {
  const TrangChu({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguage>();
    final currentUser = FirebaseAuth.instance.currentUser;
    final repository = GroupRepository();

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
                icon: const Icon(Icons.home_filled, color: Colors.blue, size: 30),
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
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) => const CreateGroupSheet(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: FutureBuilder<List<GroupDetails>>(
        future: repository.getCurrentUserGroups(),
        builder: (context, groupsSnapshot) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(lang, currentUser),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildBalanceCard(
                            lang.t('Bạn nhận được'),
                            lang.formatMoney(0),
                            Icons.trending_down,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildBalanceCard(
                            lang.t('Bạn cần trả'),
                            lang.formatMoney(0),
                            Icons.trending_up,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nhóm của tôi',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildGroupList(context, lang, groupsSnapshot),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLanguage lang, User? currentUser) {
    final displayName = (currentUser?.displayName ?? '').trim();
    final email = (currentUser?.email ?? '').trim();
    final titleName = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : 'Bạn');

    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[800]!, Colors.blue[400]!],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào bạn,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
              Text(
                titleName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(
    BuildContext context,
    AppLanguage lang,
    AsyncSnapshot<List<GroupDetails>> groupsSnapshot,
  ) {
    if (groupsSnapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (groupsSnapshot.hasError) {
      return _buildInfoCard('Không thể tải danh sách nhóm.');
    }

    final groups = groupsSnapshot.data ?? [];
    if (groups.isEmpty) {
      return _buildInfoCard('Bạn chưa tham gia nhóm nào.');
    }

    return Column(
      children: groups
          .map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGroupItem(context, lang, group),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.black54),
      ),
    );
  }

  Widget _buildBalanceCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupItem(
    BuildContext context,
    AppLanguage lang,
    GroupDetails group,
  ) {
    final subtitleParts = <String>[
      '${group.memberCount} thành viên',
      if (group.groupType.isNotEmpty) group.groupType,
      if (group.groupCode.isNotEmpty) 'Mã: ${group.groupCode}',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChiTietNhom()),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.group, color: Colors.blue, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleParts.join(' • '),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    Text(
                      _formatCreatedAt(group.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lang.formatMoney(0),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Số dư',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Vừa tạo';
    }

    final createdAt = timestamp.toDate();
    return 'Tạo ngày ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
}

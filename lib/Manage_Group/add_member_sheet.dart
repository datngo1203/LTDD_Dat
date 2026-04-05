import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddMemberSheet extends StatefulWidget {
  final String groupId;
  final Function(String) onMemberAdded;

  const AddMemberSheet({
    super.key,
    required this.groupId,
    required this.onMemberAdded,
  });

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _emailController.text.trim().isNotEmpty;
    });
  }

  Future<void> _addMemberByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Người dùng không tồn tại')),
          );
        }
        return;
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();
      final displayName = (userData['displayName'] ?? userData['name'] ?? userData['email'] ?? '').toString().trim();

      final memberRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(userId);

      final existing = await memberRef.get();
      if (existing.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Người này đã là thành viên')), 
          );
        }
        return;
      }

      await memberRef.set({
        'userId': userId,
        'email': email,
        'displayName': displayName.isEmpty ? email : displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'balance': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm thành viên')), 
        );
        widget.onMemberAdded(userId);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra')), 
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thêm bạn',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 15),

          RichText(
            text: const TextSpan(
              text: 'Email',
              style: TextStyle(
                color: Color(0xFF006D4E),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _emailController,
              onChanged: (v) => _validateForm(),
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Nhập email bạn bè',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isButtonEnabled && !_isLoading ? _addMemberByEmail : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
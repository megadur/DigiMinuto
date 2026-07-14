import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:core_engine/core_engine.dart';
import '../services/app_services.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _groupNameController = TextEditingController();
  List<GroupMembership> _myGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final groups = await AppServices.instance.groupRepository.getAllGroups();
    setState(() {
      _myGroups = groups;
      _isLoading = false;
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) return;

    final myPubKey = AppServices.instance.currentIdentity.publicKey;
    final privKey = AppServices.instance.currentIdentity.privateKey;
    final String actualGroupId = Uuid().v4();

    // Als Gründer laden wir uns sozusagen selbst ein
    var membership = GroupMembership(
      groupId: actualGroupId,
      groupName: groupName,
      memberPubKey: myPubKey,
      inviterPubKey: myPubKey,
      timestamp: DateTime.now(),
      signature: '', // Gründer-Signatur kann leer sein oder sich selbst signieren
    );

    // Signieren (optional für den Gründer, aber konsistent)
    if (privKey != null) {
      final keyPair = await AppServices.instance.cryptoService.loadKeyPairFromHex(privKey, myPubKey);
      final signature = await AppServices.instance.cryptoService.signData(
        membership.messageToSign,
        keyPair,
      );
      membership = GroupMembership(
        groupId: membership.groupId,
        groupName: membership.groupName,
        memberPubKey: membership.memberPubKey,
        inviterPubKey: membership.inviterPubKey,
        timestamp: membership.timestamp,
        signature: signature,
      );
    }

    await AppServices.instance.groupRepository.saveGroup(membership);
    _groupNameController.clear();
    await _loadGroups();
    
    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gruppe "$groupName" gegründet!')),
      );
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Gruppe gründen'),
        content: TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Name der Gruppe (z.B. Ökodorf XY)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: _createGroup,
            child: const Text('Gründen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Gruppen'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myGroups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Du bist noch in keiner Gruppe.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bitte jemanden um eine Einladung (per QR-Code) oder gründe selbst eine neue Gruppe.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _myGroups.length,
                  itemBuilder: (context, index) {
                    final group = _myGroups[index];
                    final isFounder = group.inviterPubKey == group.memberPubKey;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          isFounder ? Icons.star : Icons.group,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isFounder 
                          ? 'Gründer'
                          : 'Eingeladen von: ${group.inviterPubKey.substring(0, 8)}...',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await AppServices.instance.groupRepository.deleteGroup(group.groupId);
                          _loadGroups();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add),
        label: const Text('Gruppe gründen'),
      ),
    );
  }
}

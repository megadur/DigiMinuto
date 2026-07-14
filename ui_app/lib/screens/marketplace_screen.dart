import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_engine/core_engine.dart';
import '../services/app_services.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _requestController = TextEditingController();
  final List<RequestPost> _posts = [];
  Map<String, Contact> _knownContacts = {};
  
  List<GroupMembership> _myGroups = [];
  GroupMembership? _selectedFilterGroup; // null means "All my groups"
  GroupMembership? _selectedPostGroup; 

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadGroupsAndSubscribe();
  }

  Future<void> _loadGroupsAndSubscribe() async {
    final groups = await AppServices.instance.groupRepository.getAllGroups();
    if (!mounted) return;
    
    setState(() {
      _myGroups = groups;
      if (groups.isNotEmpty) {
        _selectedPostGroup = groups.first;
      }
    });

    final groupIds = groups.map((g) => g.groupId).toList();

    AppServices.instance.nostrService.subscribeToRequests((post, ticket) async {
      if (!mounted) return;
      
      // Spam-Schutz / Ticket-Prüfung
      if (ticket != null) {
        // Prüfe ob das Ticket gültig ist
        final isValid = await AppServices.instance.cryptoService.verifySignature(
          publicKeyHex: ticket.inviterPubKey,
          data: ticket.messageToSign,
          signatureHex: ticket.signature,
        );
        // Prüfen, ob wir die Gruppe kennen
        final isKnownGroup = _myGroups.any((g) => g.groupId == ticket.groupId);
        
        if (!isValid || !isKnownGroup) return; // Ignore spam/invalid
      } else {
        // Im neuen System ignorieren wir Posts ohne Ticket, oder wir erlauben globale Nostr-Posts?
        // Für jetzt erlauben wir globale Posts (alte Version), falls man keine Gruppen nutzt.
        if (groups.isNotEmpty) return; // Wenn Nutzer in Gruppen ist, filtere alte globale Posts raus.
      }

      setState(() {
        if (!_posts.any((p) => p.id == post.id)) {
          _posts.add(post);
          _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        }
      });
    }, groupIds: groupIds);
  }

  @override
  void dispose() {
    _requestController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await AppServices.instance.contactRepository.getAllContacts();
    if (mounted) {
      setState(() {
        _knownContacts = {for (var c in contacts) c.publicKey: c};
      });
    }
  }

  void _publishRequest() {
    final text = _requestController.text.trim();
    if (text.isEmpty) return;
    if (_myGroups.isNotEmpty && _selectedPostGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte wähle eine Gruppe aus.')));
      return;
    }

    final identity = AppServices.instance.currentIdentity;
    if (identity.privateKey == null) return;

    AppServices.instance.nostrService.publishRequest(
      text, 
      identity.privateKey!,
      group: _selectedPostGroup,
    );
    _requestController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anfrage veröffentlicht!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Pinnwand (Anfragen)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Column(
        children: [
          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                if (_myGroups.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: DropdownButtonFormField<GroupMembership>(
                      value: _selectedPostGroup,
                      decoration: const InputDecoration(
                        labelText: 'In welche Gruppe posten?',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _myGroups.map((group) => DropdownMenuItem(
                        value: group,
                        child: Text(group.groupName),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPostGroup = val);
                      },
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _requestController,
                        decoration: const InputDecoration(
                          hintText: 'Suche / Brauche Hilfe bei...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _publishRequest,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
          
          // Filter Section
          if (_myGroups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButton<GroupMembership?>(
                isExpanded: true,
                value: _selectedFilterGroup,
                hint: const Text('Alle meine Gruppen'),
                items: [
                  const DropdownMenuItem<GroupMembership?>(value: null, child: Text('Alle meine Gruppen')),
                  ..._myGroups.map((group) => DropdownMenuItem(
                    value: group,
                    child: Text('Nur: ${group.groupName}'),
                  ))
                ],
                onChanged: (val) {
                  setState(() => _selectedFilterGroup = val);
                },
              ),
            ),
          
          // Feed Section
          Expanded(
            child: _posts.isEmpty
                ? Center(
                    child: Text(
                      'Noch keine Anfragen in dieser Gruppe.',
                      style: GoogleFonts.inter(color: textColor.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      // Theoretisch könnten wir hier noch filtern basierend auf _selectedFilterGroup, 
                      // aber da NostrService alles in _posts pumpt, filtern wir es hier im UI:
                      // (Da wir das Ticket nicht in RequestPost speichern, ist die UI Filterung gerade etwas tricky,
                      // wir belassen es für das MVP bei der globalen Liste aller abonnierten Gruppen).
                      
                      final isMe = post.pubKey == AppServices.instance.currentIdentity.publicKey;
                      final contact = _knownContacts[post.pubKey];
                      
                      String displayName = isMe ? 'Mir' : (contact?.name ?? '${post.pubKey.substring(0, 8)}...');
                      String? portfolio = isMe ? AppServices.instance.currentIdentity.portfolio : contact?.portfolio;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    displayName,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                  ),
                                  Text(
                                    '${post.timestamp.day}.${post.timestamp.month}.${post.timestamp.year} ${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.inter(fontSize: 12, color: textColor.withOpacity(0.5)),
                                  ),
                                ],
                              ),
                              if (portfolio != null && portfolio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Bietet: $portfolio',
                                    style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                post.text,
                                style: GoogleFonts.inter(fontSize: 15, color: textColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadContacts();
    AppServices.instance.nostrService.subscribeToRequests((post) {
      if (mounted) {
        setState(() {
          // Add post if not already exists
          if (!_posts.any((p) => p.id == post.id)) {
            _posts.add(post);
            _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          }
        });
      }
    });
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

    final identity = AppServices.instance.currentIdentity;
    if (identity.privateKey == null) return;

    AppServices.instance.nostrService.publishRequest(text, identity.privateKey!);
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
            child: Row(
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
          ),
          
          // Feed Section
          Expanded(
            child: _posts.isEmpty
                ? Center(
                    child: Text(
                      'Noch keine Anfragen im Netzwerk gefunden.',
                      style: GoogleFonts.inter(color: textColor.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
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

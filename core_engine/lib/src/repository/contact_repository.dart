import '../models/contact.dart';

abstract class ContactRepository {
  Future<void> saveContact(Contact contact);
  Future<Contact?> getContactByPublicKey(String publicKey);
  Future<List<Contact>> getAllContacts();
  Future<void> deleteContact(String publicKey);
}

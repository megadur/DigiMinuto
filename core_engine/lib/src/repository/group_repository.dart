import '../models/group_membership.dart';

abstract class GroupRepository {
  Future<void> saveGroup(GroupMembership group);
  Future<List<GroupMembership>> getAllGroups();
  Future<void> deleteGroup(String groupId);
}

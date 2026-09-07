import '../models/category.dart';

/// Returns [parentId] and all descendant category IDs (DFS). Use for filtering
/// and budget spent so selecting a parent includes all children and nested children.
Set<String> getDescendantCategoryIds(List<Category> categories, String parentId) {
  final result = <String>{parentId};
  final byParent = <String?, List<Category>>{};
  for (final c in categories) {
    byParent.putIfAbsent(c.parentId, () => []).add(c);
  }
  void collect(String id) {
    final children = byParent[id]; // direct children of id
    if (children == null) return;
    for (final c in children) {
      result.add(c.id);
      collect(c.id);
    }
  }
  collect(parentId);
  return result;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'newsfeed_providers.dart';
import 'article_follow_provider.dart';

class NewsfeedAuthorsScreen extends ConsumerStatefulWidget {
  const NewsfeedAuthorsScreen({super.key});

  @override
  ConsumerState<NewsfeedAuthorsScreen> createState() => _NewsfeedAuthorsScreenState();
}

class _NewsfeedAuthorsScreenState extends ConsumerState<NewsfeedAuthorsScreen> {
  final Set<String> _selected = {};
  bool _selectMode = false;

  @override
  Widget build(BuildContext context) {
    final authors = ref.watch(newsfeedAuthorsProvider);
    final followed = ref.watch(articleFollowProvider);
    final allSelected = _selected.length == authors.length && authors.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authors'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selected.clear();
              });
            },
            child: Text(_selectMode ? 'Cancel' : 'Select', style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${_selected.length} selected'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selected.clear();
                        } else {
                          _selected.addAll(authors);
                        }
                      });
                    },
                    child: Text(allSelected ? 'Clear all' : 'Select all'),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            for (final a in _selected) {
                              if (!followed.contains(a)) {
                                ref.read(articleFollowProvider.notifier).toggle(a);
                              }
                            }
                            setState(() => _selected.clear());
                          },
                    child: const Text('Follow'),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            for (final a in _selected) {
                              if (followed.contains(a)) {
                                ref.read(articleFollowProvider.notifier).toggle(a);
                              }
                            }
                            setState(() => _selected.clear());
                          },
                    child: const Text('Unfollow'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: authors.length,
              itemBuilder: (context, index) {
                final author = authors[index];
                final isFollowed = followed.contains(author);
                if (_selectMode) {
                  return CheckboxListTile(
                    value: _selected.contains(author),
                    onChanged: (_) {
                      setState(() {
                        if (_selected.contains(author)) {
                          _selected.remove(author);
                        } else {
                          _selected.add(author);
                        }
                      });
                    },
                    title: Text(author),
                    secondary: Icon(isFollowed ? Icons.person : Icons.person_outline),
                  );
                }
                return ListTile(
                  title: Text(author),
                  trailing: TextButton(
                    onPressed: () => ref.read(articleFollowProvider.notifier).toggle(author),
                    child: Text(isFollowed ? 'Following' : 'Follow'),
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

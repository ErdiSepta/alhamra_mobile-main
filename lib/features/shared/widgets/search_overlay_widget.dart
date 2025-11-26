import 'package:flutter/material.dart';
import '../../../core/utils/app_styles.dart';

class SearchOverlayWidget extends StatefulWidget {
  final bool isVisible;
  final String title;
  final List<String> items;
  final String selectedItem;
  final Function(String) onItemSelected;
  final VoidCallback onClose;
  final String searchHint;
  final String? avatarUrl;

  const SearchOverlayWidget({
    super.key,
    required this.isVisible,
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    required this.onClose,
    this.searchHint = 'Cari...',
    this.avatarUrl,
  });

  @override
  State<SearchOverlayWidget> createState() => _SearchOverlayWidgetState();
}

class _SearchOverlayWidgetState extends State<SearchOverlayWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppStyles.sectionTitle(context),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: _filterItems,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: _filteredItems.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text('Tidak ada ${widget.title.toLowerCase()}'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[300],
                                backgroundImage: widget.avatarUrl != null 
                                    ? NetworkImage(widget.avatarUrl!) 
                                    : null,
                                child: widget.avatarUrl == null 
                                    ? const Icon(Icons.person, color: Colors.grey) 
                                    : null,
                              ),
                              title: Text(item),
                              trailing: item == widget.selectedItem
                                  ? const Icon(Icons.check, color: AppStyles.primaryColor)
                                  : null,
                              onTap: () {
                                widget.onItemSelected(item);
                                widget.onClose();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

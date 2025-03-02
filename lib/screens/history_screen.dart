import 'package:flutter/material.dart';
import '../utils/database_helper.dart';
import '../models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<HistoryEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _dbHelper.getHistory();

      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    try {
      await _dbHelper.clearHistory();

      if (mounted) {
        setState(() {
          _history.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('History cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browsing History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearHistory,
            tooltip: "Clear",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "No browsing history found",
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      child: const Text("Refresh"),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final entry = _history[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade200,
                        child:
                            entry.favicon.isNotEmpty
                                ? Image.network(
                                  entry.favicon,
                                  width: 24,
                                  height: 24,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.public),
                                )
                                : const Icon(Icons.public),
                      ),
                      title: Text(
                        entry.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text("Visited on: ${entry.timestamp}"),
                    ),
                  );
                },
              ),
    );
  }
}

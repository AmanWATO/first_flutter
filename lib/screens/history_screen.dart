import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/database_helper.dart';
import '../models/history_model.dart';
import '../services/accessibility_service.dart'; // Add this file from the previous artifact

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
  bool _loadingMore = false;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  bool _isAccessibilityServiceEnabled = false;
  bool _checkingAccessibility = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccessibilityService();

    // Set up scroll listener for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_loadingMore &&
          _hasMoreData) {
        _loadMoreHistory();
      }
    });
  }

  Future<void> _checkAccessibilityService() async {
    setState(() {
      _checkingAccessibility = true;
    });

    // Check if the accessibility service is enabled
    bool isEnabled = await AccessibilityService.isEnabled();

    if (mounted) {
      setState(() {
        _isAccessibilityServiceEnabled = isEnabled;
        _checkingAccessibility = false;
      });

      if (isEnabled) {
        _loadHistory();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check accessibility service again when app is resumed
      _checkAccessibilityService();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _page = 1;
    });

    try {
      // Modified to support pagination
      final history = await _dbHelper.getHistoryPaginated(_page, _pageSize);

      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
          _hasMoreData = history.length == _pageSize;
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

  Future<void> _loadMoreHistory() async {
    if (!mounted || _loadingMore || !_hasMoreData) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      _page++;
      final moreHistory = await _dbHelper.getHistoryPaginated(_page, _pageSize);

      if (mounted) {
        setState(() {
          if (moreHistory.isNotEmpty) {
            _history.addAll(moreHistory);
          }
          _hasMoreData = moreHistory.length == _pageSize;
          _loadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more history: $e');
      if (mounted) {
        setState(() {
          _loadingMore = false;
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
          _page = 1;
          _hasMoreData = false;
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

  void _copyToClipboard(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('URL copied to clipboard')));
  }

  void _openAccessibilitySettings() {
    AccessibilityService.openSettings();
  }

  Widget _buildAccessibilityServiceGuide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.accessibility_new, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              "Enable Accessibility Service",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "To track your browsing history, this app needs Accessibility Service permission.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "How to enable:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "1. Tap the button below to open Settings",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "2. Find and select \"StealthGuard\"",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "3. Toggle \"Use Service\" to ON",
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "4. Confirm if prompted",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAccessibilitySettings,
              icon: const Icon(Icons.settings),
              label: const Text("Open Accessibility Settings"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _checkAccessibilityService,
              icon: const Icon(Icons.refresh),
              label: const Text("I've enabled the service"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browsing History"),
        actions: [
          if (_isAccessibilityServiceEnabled) ...[
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
        ],
      ),
      body:
          _checkingAccessibility
              ? const Center(child: CircularProgressIndicator())
              : !_isAccessibilityServiceEnabled
              ? _buildAccessibilityServiceGuide()
              : _isLoading
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
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _history.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _history.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final entry = _history[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: 0.4,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.blueGrey,
                              width: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(8),
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: "Copy URL",
                                  onPressed: () => _copyToClipboard(entry.url),
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

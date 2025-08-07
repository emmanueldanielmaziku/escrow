import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DeleteAccountWebView extends StatefulWidget {
  const DeleteAccountWebView({super.key});

  @override
  State<DeleteAccountWebView> createState() => _DeleteAccountWebViewState();
}

class _DeleteAccountWebViewState extends State<DeleteAccountWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://escrowlabz.vercel.app/delete-account'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

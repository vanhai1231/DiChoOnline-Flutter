import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaypalPaymentScreen extends StatelessWidget {
  final String paymentUrl;

  const PaypalPaymentScreen({super.key, required this.paymentUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PayPal Payment"),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onPageStarted: (url) {
              if (url.contains("success")) {
                Navigator.pop(context, true);
              } else if (url.contains("cancel")) {
                Navigator.pop(context, false);
              }
            },
          ))
          ..loadRequest(Uri.parse(paymentUrl)),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MoMoPaymentScreen extends StatelessWidget {
  final String paymentUrl;

  const MoMoPaymentScreen({Key? key, required this.paymentUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán MoMo"),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(NavigationDelegate(
            onPageStarted: (url) {
              if (url.contains("success")) {
                Navigator.pop(context, true);  // Trả về true khi thanh toán thành công
              } else if (url.contains("cancel")) {
                Navigator.pop(context, false);  // Trả về false khi thanh toán bị hủy
              }
            },
          ))
          ..loadRequest(Uri.parse(paymentUrl)),  // Tải URL thanh toán MoMo
      ),
    );
  }
}

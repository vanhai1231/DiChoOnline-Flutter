import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DriveClient implements http.BaseClient {
  final _client = http.Client();
  final Map<String, String> authHeaders;
  DriveClient(this.authHeaders);

  @override
  void close() {}

  @override
  Future<http.Response> delete(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.get(url, headers: headers);
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.head(url, headers: headers);
  }

  @override
  Future<http.Response> patch(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.patch(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> post(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.put(url, headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.read(url, headers: headers);
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    headers ??= {};
    headers.addAll(authHeaders);
    return _client.readBytes(url, headers: headers);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(authHeaders);
    return _client.send(request);
  }
}
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:path_provider/path_provider.dart';

import 'AuthGoogleDirve.dart';

import 'DriveClient.dart';


class DriveService {
  final _authService = AuthGoogleDrive();
  static final _instance = DriveService._();

  DriveService._();

  factory DriveService() {
    return _instance;
  }







  /// upload file in the google drive
  /// returns id of the uploaded file on success, else null
  // Future<String?> uploadFile(String fileName, String filePath) async {
  //   final file = File(filePath);
  //
  //   // 1. sign in with Google to get auth headers
  //   final headers = await _authService.googleSignIn();
  //   if (headers == null) return null;
  //
  //   // 2. create auth http client & pass it to drive API
  //   final client = DriveClient(headers);
  //   final drive = ga.DriveApi(client);
  //
  //   // 3. check if the file already exists in the google drive
  //   final fileId = await _getFileID(drive, fileName);
  //
  //   // 4. if the file does not exists in the google drive, create a new one
  //   // else update the existing file
  //   if (fileId == null) {
  //     final res = await drive.files.create(
  //       ga.File()..name = fileName
  //         ..parents = ['1tZL7exf9LKtrK0jCEEoVHmJ3GFbcmHs8'],
  //       uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
  //     );
  //     return res.id;
  //   } else {
  //     final res = await drive.files.update(
  //       ga.File()..name = fileName
  //         ..parents = ['1tZL7exf9LKtrK0jCEEoVHmJ3GFbcmHs8'],
  //       fileId,
  //       uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
  //     );
  //     return res.id;
  //   }
  // }
  Future<String?> uploadFile(String fileName, String filePath) async {
    final file = File(filePath);

    // 1. sign in with Google to get auth headers
    final headers = await _authService.googleSignIn();
    if (headers == null) return null;

    // 2. create auth http client & pass it to drive API
    final client = DriveClient(headers);
    final drive = ga.DriveApi(client);

    // 3. always create a new file in Google Drive
    final res = await drive.files.create(
      ga.File()
        ..name = fileName
        ..parents = ['1tZL7exf9LKtrK0jCEEoVHmJ3GFbcmHs8'], // Thay đổi ID thư mục nếu cần
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );

    return res.id;
  }

  /// download the file from the google drive
  /// @params [fileId] google drive id for the uploaded file
  /// @params [filePath] file path to copy the downloaded file
  /// returns download file path on success, else null
  Future<String?> downloadFile(String fileId, String filePath) async {
    // 1. sign in with Google to get auth headers
    final headers = await _authService.googleSignIn();
    if (headers == null) return null;

    // 2. create auth http client & pass it to drive API
    final client = DriveClient(headers);
    final drive = ga.DriveApi(client);

    // 3. download file from the google drive
    final res = await drive.files.get(
      fileId,
      downloadOptions: ga.DownloadOptions.fullMedia,
    ) as ga.Media;

    // 4. convert downloaded file stream to bytes
    final bytesArray = await res.stream.toList();
    List<int> bytes = [];
    for (var arr in bytesArray) {
      bytes.addAll(arr);
    }

    // 5. write file bytes to disk
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }


  /// returns file id for existing file,
  /// returns null if file does not exists
  Future<String?> _getFileID(ga.DriveApi drive, String fileName) async {
    final list = await drive.files.list(q: "name: '$fileName'", pageSize: 1);
    if (list.files?.isEmpty ?? true) return null;
    return list.files?.first.id;
  }
}
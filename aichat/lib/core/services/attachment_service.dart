import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import '../models/message.dart';

final attachmentServiceProvider = Provider((ref) => AttachmentService());

class AttachmentService {
  Future<String> get _attachmentDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentDir = Directory('${appDir.path}/attachments');
    if (!await attachmentDir.exists()) {
      await attachmentDir.create(recursive: true);
    }
    return attachmentDir.path;
  }

  Future<Attachment> saveFile(File file) async {
    final fileName = file.path.split('/').last;
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    final size = await file.length();

    final saveDir = await _attachmentDir;
    final savedFile = await file.copy('$saveDir/$fileName');

    return Attachment(
      name: fileName,
      path: savedFile.path,
      mimeType: mimeType,
      size: size,
    );
  }

  Future<void> deleteAttachment(Attachment attachment) async {
    final file = File(attachment.path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> getAttachmentFile(Attachment attachment) async {
    return File(attachment.path);
  }
}

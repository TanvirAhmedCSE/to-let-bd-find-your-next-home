import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class CloudinaryUploadResult {
  final String url;
  final String publicId;
  CloudinaryUploadResult({required this.url, required this.publicId});
}

class CloudinaryService {
  Future<CloudinaryUploadResult> uploadImage(File file) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return CloudinaryUploadResult(
      url: data['secure_url'],
      publicId: data['public_id'],
    );
  }

  Future<void> deleteImage(String publicId) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    final paramsToSign =
        'public_id=$publicId&timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    final signature = sha1.convert(utf8.encode(paramsToSign)).toString();

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/destroy',
    );

    final response = await http.post(
      url,
      body: {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
        'api_key': CloudinaryConfig.apiKey,
        'signature': signature,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Cloudinary delete failed: ${response.body}');
    }
  }

  Future<void> deleteImages(List<String> publicIds) async {
    for (final id in publicIds) {
      try {
        await deleteImage(id);
      } catch (_) {
        // Best-effort: continue deleting remaining images even if one fails.
      }
    }
  }
}

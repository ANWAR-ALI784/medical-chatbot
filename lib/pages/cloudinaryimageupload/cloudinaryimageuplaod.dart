import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryUploader {
  static const String cloudName = "dnb00s9z9";
  static const String uploadPreset = "upload_image";

  static Future<String?> uploadFile(File imageFile) async {
    try {
      final uploadUrl =
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final result = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var data = jsonDecode(result.body.toString());
        return data['secure_url']; // ✅ only return URL
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // static Future<String?>imageUpload(File imageFile)async{
  //   final url="https://api.cloudinary.com/v1_1/$cloudName/image/upload";
  //   final request= http.MultipartRequest("POST", Uri.parse(url));
  //    request.fields['uploadPreset']=uploadPreset;
  //    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
  //    final response=await request.send();
  //    if(response.statusCode==200){
  //      final responseData=await response.stream.toString();
  //      final responseString= String.fromCharCode(responseData as int);
  //      final jsonMap=jsonDecode(responseString);
  //      setState(){
  //      final url=jsonMap['url'];
  //      imageFile=url;
  //      }
  //    }
  //
  //
  //
  // }

}

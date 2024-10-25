import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:papp_scout/common/scout.dart';

class HttpUploadService {
  Future<String> uploadScout(Scout scout) async {
    Uri uri = Uri.parse('http://54.149.184.248:8000/api/scouts/');
    http.MultipartRequest request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('img', scout.image));
    request.fields['name'] = scout.name;
    request.fields['latitude'] = scout.latitude.toString();
    request.fields['longitude'] = scout.longitude.toString();

    http.StreamedResponse response = await request.send();
    var responseBytes = await response.stream.toBytes();
    var responseString = utf8.decode(responseBytes);
    print('\n\n');
    print('RESPONSE WITH HTTP');
    print(responseString);
    print('\n\n');
    return responseString;
  }
}

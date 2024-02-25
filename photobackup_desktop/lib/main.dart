import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/widgets.dart';


void main() async {
  // bind the socket server to an address and port
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);

  // listen for clent connections to the server
  server.listen((client) {
    handleConnection(client);
  });
}

void handleConnection(Socket client) {
  print('Connection from'
      ' ${client.remoteAddress.address}:${client.remotePort}');

  // listen for events from the client
  client.listen(

    // handle data from the client
    (Uint8List data) async {
        final message = String.fromCharCodes(data);
        if (message.length > 150) {
            print("Client message: " + message.substring(50, 139) + "   " + message.substring(message.length-20, message.length) + " " + message.length.toString());
        } else {
            print("Client message: " + message + " " + message.length.toString());
        }

        final Map<String, dynamic> jsonData = jsonDecode(message);

        await ProcessDataClient(jsonData, client);
        
    },

    // handle errors
    onError: (error) {
      print(error);
      client.close();
    },

    // handle the client closing the connection
    onDone: () {
      print('Client left');
      // client.close();
    },
  );
}



String all_data = "";

ProcessDataClient(Map<String, dynamic> jsonData, Socket client) async {


    all_data += jsonData["Data"];
    print(all_data.length);


    var resp = {"Info": {"Tag": "Recived"}};
    String json_resp = jsonEncode(resp);
    client.write(json_resp);



    if (jsonData["End"]) {

        switch (jsonData["Info"]["Tag"]) {
            case "make backup: info":
            case "Make backup: base64 media":
                // Image.memory(base64Decode(all_data));
                Uint8List imageInUnit8List = base64Decode(all_data);
                // final tempDir = await getTemporaryDirectory();
                File file = await File('/Users/filipporaciti/Desktop/images/' + jsonData["Info"]["Image name"]);
                file.writeAsBytesSync(imageInUnit8List);
                // var _image = MemoryImage(imageInUnit8List);
                // print(_image);

        }




        all_data = "";
    }

}

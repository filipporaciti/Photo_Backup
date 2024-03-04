import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/widgets.dart';


void main() async {
  // bind the socket server to an address and port
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9084);

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

        Map<String, dynamic> jsonData = {};
        String m_data = "";
        if (message.substring(0, 6) == "{\"Info") {
            jsonData = jsonDecode(message);
        } else {
            m_data = message;
        }

        await ProcessDataClient(jsonData, m_data, client);
        
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
var resp = {"Info": {"Tag": "Recived"}};
String json_resp_recived = jsonEncode(resp);

ProcessDataClient(Map<String, dynamic> jsonData, String data, Socket client) async {

    if (jsonData.isNotEmpty) {

        if (jsonData["Info"]["Tag"] == "Make backup: base64 media") {
            if (jsonData["End"]){
                Image.memory(base64Decode(all_data));
                Uint8List imageInUnit8List = base64Decode(all_data);

                String imgname = jsonData["Info"]["Image name"];
                String imgfiletype = "." + imgname.split(".").last;
                imgname = imgname.split(".").sublist(0, imgname.split(".").length-1).join("");
                String imgdate = jsonData["Info"]["Image date"].replaceAll(":", "-").replaceAll(" ", "_").split(".")[0];

                File file = await File('/Users/filipporaciti/Desktop/images/' + imgdate + "_" + imgname + "_" + jsonData["Info"]["Image length"].toString() + imgfiletype);
                file.writeAsBytesSync(imageInUnit8List);
            }
        } else if (jsonData["Info"]["Tag"] == "Discover" && jsonData["End"]) {
            client.write(jsonEncode({"Info": {"Tag": "Discover response", "Computer name": Platform.localHostname.replaceAll(".local", "")}}));
        }

        if (jsonData["End"]) {
            print("all_data reset");
            all_data = "";
        }

        client.write(json_resp_recived);

    }

    if (data != "") {
        all_data += data;
        if (all_data.substring(all_data.length-2, all_data.length) == "{}") {
            client.write(json_resp_recived);
            all_data = all_data.substring(0, all_data.length-2);
            
        }
    }

}

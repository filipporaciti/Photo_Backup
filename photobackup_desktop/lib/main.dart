import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';


final String _device_name = Platform.localHostname.replaceAll(".local", "");
String _root_dest_directory = "/Users/filipporaciti/Desktop/images/";
List<Backup_info> _backup_list = [];
String _last_media = "";
int _total_num_media = 0;
int _current_num_media = 0;
String _current_backup_name = "";
double _progressbar_value = 0.0;

String all_data = "";
String json_resp_recived = jsonEncode({"Info": {"Tag": "Recived"}});

class Backup_info {
    String backup_name;
    int media_num;
    int photo_num;
    int video_num;
    int size;
    String path;
    Backup_info(this.backup_name, this.media_num, this.photo_num, this.video_num, this.size, this.path);
}


void main() async {

    if (_root_dest_directory == "") {
        _root_dest_directory = getHomeDirectory();
    }

    runApp(MaterialApp(
        home: HomeBackup()
        )
    );
}

class HomeBackup extends StatefulWidget {
  @override
  _HomeBackupState createState() => _HomeBackupState();
}

class _HomeBackupState extends State<HomeBackup> {

    String _dest_device_selected = "";


    @override
    void initState() {
        super.initState();      
        _initAsync();
    }

    Future<void> _initAsync() async {
        final server = await ServerSocket.bind(InternetAddress.anyIPv4, 9084);

        // listen for clent connections to the server
        server.listen((client) {
            handleConnection(client);
        });

        refreshBackupList();
    }

    @override
    Widget build(BuildContext context) {

        return Scaffold(
            appBar: AppBar(
              title: const Text("Photo backup"),
              ),
            body: Container(
                margin: EdgeInsets.only(
                    left: 10.0, 
                    top: 10.0, 
                    right: 10.0, 
                    bottom: 8.0, 
                    ),
                child: Column(
                    children:[
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Device name: $_device_name")
                            ),
                        Row(
                            children: [
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text("Destination directory: $_root_dest_directory")
                                    ),
                                Spacer(),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        child:
                                        Text("Change path"),
                                        onPressed: () async {

                                            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

                                            if (selectedDirectory != null) {
                                              // User canceled the picker
                                                print(selectedDirectory);
                                                setState((){
                                                    _root_dest_directory = selectedDirectory ?? _root_dest_directory;

                                                });
                                            }

                                        }
                                        ),
                                    ),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        child:
                                        Text("Open"),
                                        onPressed: () {
                                            final Uri _url = Uri.parse('file:$_root_dest_directory');
                                            launchUrl(_url);
                                        }
                                        ),
                                    ),
                                
                                ]
                            ),
                        Divider(),

                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Old backups:")
                            ),
                        Expanded(
                            child: 
                            GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8.0,
                                    crossAxisSpacing: 8.0,
                                    ),
                                padding: EdgeInsets.all(4.0),
                                itemCount: _backup_list.length, 
                                itemBuilder: (context, index) {
                                    return Container(
                                        padding: EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                            border: Border.all(width:2),
                                            borderRadius: BorderRadius.circular(12),
                                            color: Color.fromARGB(20, 0, 0, 0),
                                        ),
                                        child: Column(
                                            children: [
                                                Text(_backup_list[index].backup_name),
                                                Divider(),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("All media number: " + _backup_list[index].media_num.toString())
                                                    ),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("Photo: " + _backup_list[index].photo_num.toString())
                                                    ),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("Video: " + _backup_list[index].video_num.toString())
                                                    ),
                                                Spacer(),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("Size: " + (_backup_list[index].size/1000000000).toStringAsFixed(2) + " GB")
                                                    ),
                                                Divider(),
                                                TextButton(
                                                    child: Text("Open folder"),
                                                    onPressed: () {
                                                        final Uri _url = Uri.parse('file:' + _backup_list[index].path);
                                                        launchUrl(_url);
                                                    }
                                                    )
                                                ]
                                        ),
                                      );
                                },
                                )

                            ),

                        Divider(),


                        Text("Backup name: $_current_backup_name"),
                        LinearProgressIndicator(
                            value: _progressbar_value
                        ),
                        Row(
                            children: [
                                Text("$_last_media"),
                                Spacer(),
                                Text("$_current_num_media/$_total_num_media"),
                                ]),
                        ]
)
)
);
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
      all_data = "";
  },
  onDone: () {
      print('Client left');
      all_data = "";
  },
  );
}

Future<void> ProcessDataClient(Map<String, dynamic> jsonData, String data, Socket client) async {

    if (jsonData.isNotEmpty) {

        if (jsonData["Info"]["Tag"] == "Make backup: base64 media") {
            if (jsonData["End"]){
                Image.memory(base64Decode(all_data));
                Uint8List imageInUnit8List = base64Decode(all_data);

                String imgname = jsonData["Info"]["Image name"];
                String imgfiletype = "." + imgname.split(".").last;
                imgname = imgname.split(".").sublist(0, imgname.split(".").length-1).join("");
                String imgdate = jsonData["Info"]["Image date"].replaceAll(":", "-").replaceAll(" ", "_").split(".")[0];
                final String finalImgName = imgdate + "_" + imgname + "_" + jsonData["Info"]["Image length"].toString() + imgfiletype;

                final String finalPath = _root_dest_directory + _current_backup_name + "/";

                var path_dir = await Directory(finalPath);
                await path_dir.create();

                File file = await File(finalPath + finalImgName);
                file.writeAsBytesSync(imageInUnit8List);

            } else {
                // reset all_data to prepare for a new media
                all_data = "";
                // Update _last_media string
                String imgname = jsonData["Info"]["Image name"];
                String imgfiletype = "." + imgname.split(".").last;
                imgname = imgname.split(".").sublist(0, imgname.split(".").length-1).join("");
                String imgdate = jsonData["Info"]["Image date"].replaceAll(":", "-").replaceAll(" ", "_").split(".")[0];
                final String finalImgName = imgdate + "_" + imgname + "_" + jsonData["Info"]["Image length"].toString() + imgfiletype;

                setState(() {
                    _last_media = finalImgName;
                    _current_num_media = jsonData["Info"]["Media index"] ?? 0;
                    _progressbar_value = _current_num_media/_total_num_media;
                });
                refreshBackupList();

                bool ris = await checkMediaExist();
                if (ris) {
                    client.write(jsonEncode({"Info": {"Tag": "Media exist"}}));
                    await Future.delayed(Duration(milliseconds: 50));
                }
            }


        } else if (jsonData["Info"]["Tag"] == "Discover" && jsonData["End"]) {
            client.write(jsonEncode({"Info": {"Tag": "Discover response", "Computer name": _device_name}}));


        } else if (jsonData["Info"]["Tag"] == "Make backup: info" && jsonData["End"]) {
            setState((){
                _total_num_media = jsonDecode(all_data)["Media number"] ?? 0;
                _current_backup_name = jsonDecode(all_data)["Backup name"] ?? "";
            });
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

Future<bool> checkMediaExist() async {
    for (var backup in _backup_list) {
        if (backup.backup_name == _current_backup_name) {
            var all_media = await Directory(backup.path).list().toList();
            for (var media in all_media) {
                if (media.path.split("/").last == _last_media) {
                    return true;
                }
            }

            return false;
        }
    }
    return false;
}
    
    void refreshBackupList() async {
        _backup_list = await getOldBackups(_root_dest_directory);
        setState(() {
            _backup_list = _backup_list;
        });
    }
}



String getHomeDirectory() {
    String out = "";

    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
        out = envVars['HOME'] ?? "";
    } else if (Platform.isLinux) {
        out = envVars['HOME'] ?? "";
    } else if (Platform.isWindows) {
        out = envVars['UserProfile'] ?? "";
    }
    out += "/images/";
    return out;
}


Future<List<Backup_info>> getOldBackups(String path) async {
    List<Backup_info> out = [];
    var myDir = await Directory(path).list().toList();
    for (var dir in myDir) {
        if (dir.runtimeType.toString() == "_Directory") {
            var bkp_dir = await Directory(dir.path).list().toList();

            String bkp_name = dir.path.split("/").last;
            int video_num = 0;
            int photo_num = 0;
            int size = 0;


            for (var media in bkp_dir) {
                if (lookupMimeType(media.path) != null && lookupMimeType(media.path)!.contains("video")) {
                    video_num += 1;
                } else {
                    photo_num += 1;
                }
                size += await File(media.path).length();
            }
            
            out.add(Backup_info(bkp_name, bkp_dir.length, photo_num, video_num, size, dir.path));

        }
    }
    return out;
}





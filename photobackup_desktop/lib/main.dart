import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

import 'package:socket_io/socket_io.dart';

import 'package:shared_preferences/shared_preferences.dart';

final String _device_name = Platform.localHostname.replaceAll(".local", "");
String _root_dest_directory = "";
List<Backup_info> _backup_list = [];
String _last_media = "";
int _total_num_media = 0;
int _current_num_media = 0;
String _current_backup_name = "";
double _progressbar_value = 0.0;

String all_data = "";
String json_resp_recieved = jsonEncode({"Info": {"Tag": "Recieved"}});

class Backup_info {
    String backup_name;
    int media_num;
    int photo_num;
    int video_num;
    int size;
    String path;
    Backup_info(this.backup_name, this.media_num, this.photo_num, this.video_num, this.size, this.path);
}


void main() {

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

        final SharedPreferences prefs = await SharedPreferences.getInstance();

        final String? saved_root_dest_directory = prefs.getString('root dest directory');
        _root_dest_directory = saved_root_dest_directory ?? getHomeDirectory();


        var io = new Server();
        io.listen(9084);
        
        handleConnection(io);

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
                            child: Text(
                                "Device name: $_device_name",
                                overflow: TextOverflow.visible,
                                )
                            ),
                        Row(
                            children: [
                                Container(
                                    width: 600,
                                    child: 
                                Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        "Destination directory: $_root_dest_directory",
                                        overflow: TextOverflow.visible,
                                    )
                                    )),
                                Spacer(),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        child:
                                        Text("Change path"),
                                        onPressed: () async {

                                            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

                                            if (selectedDirectory != null) {

                                                final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                await prefs.setString('root dest directory', selectedDirectory);


                                                setState((){
                                                    _root_dest_directory = selectedDirectory!;

                                                });
                                            }

                                            refreshBackupList();

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
                                                Text(
                                                    _backup_list[index].backup_name,
                                                    overflow: TextOverflow.visible,
                                                    ),
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


                        Text(
                            "Backup name: $_current_backup_name",
                            overflow: TextOverflow.visible,
                            ),
                        LinearProgressIndicator(
                            value: _progressbar_value
                        ),
                        Row(
                            children: [
                                Text(
                                    "$_last_media",
                                    overflow: TextOverflow.visible,
                                    ),
                                Spacer(),
                                Text(
                                    "$_current_num_media/$_total_num_media",
                                    overflow: TextOverflow.visible,
                                    ),
                                ]),
                        ]
)
)
);
}

void handleConnection(Server io) {

    io.on('connection', (client) {
        print('Connection');

        client.on('Discover', (data) async {
            await ProcessDataClient('Discover', data, client);
        });

        client.on('Make backup: info media', (data) async {
            await ProcessDataClient('Make backup: info media', data, client);
        });

        client.on('Make backup: base64 media', (data) async {
            await ProcessDataClient('Make backup: base64 media', data, client);
        });

        client.on('Backup early end', (data) async {
            await ProcessDataClient('Backup early end', {}, client);

        });


    });
}

Future<void> ProcessDataClient(String tag, Map<String, dynamic> json_data, Socket client) async {

    // Map<String, dynamic> json_data = jsonDecode(data);
    // controllare se jsondecode è giusto, controllando le chiavi per esempio 

    if (tag == 'Make backup: base64 media') {
        Uint8List byte_image = base64Decode(json_data['Image data']);

        final String finalPath = _root_dest_directory + _current_backup_name;

        // se elimino la cartella e faccio ripartire il backup, crushia (se riavvio l'app non lo fa)
        var path_dir = await Directory(finalPath);
        await path_dir.create();

        File file = await File(finalPath + "/" + _last_media);
        file.writeAsBytesSync(byte_image);
        print('create file ' + _last_media);

    }
    if (tag == 'Discover') {
        String myAddress = await getPrivateAddress();
        client.emit('Discover response', {'Computer name': _device_name, 'Remote address': myAddress});
        // client.disconnect();
    }
    if (tag == 'Make backup: info media') {

        setState((){
            _total_num_media = json_data["Media number"];
            _current_backup_name = json_data["Backup name"];
        });

        String imgname = json_data["Image name"];
        String imgfiletype = "." + imgname.split(".").last;
        imgname = imgname.split(".").sublist(0, imgname.split(".").length-1).join("");
        String imgdate = json_data["Image date"].replaceAll(":", "-").replaceAll(" ", "_").split(".")[0];
        final String finalImgName = imgdate + "_" + imgname + "_" + json_data["Image length"].toString() + imgfiletype;

        setState(() {
            _last_media = finalImgName;
            _current_num_media = json_data["Media index"];
            _progressbar_value = _current_num_media/_total_num_media;
        });

        if (_current_num_media%101 == 0 || _current_num_media == _total_num_media || _current_num_media == 1) {
            refreshBackupList();
        }

        bool ris = await checkMediaExist();
        if (ris) {
            client.emit('Media exist', true); 
        } else {
            client.emit('Media exist', false); 
        }

    }
    if (tag == 'Backup early end') {
        refreshBackupList();
    }
    

    print("send recivied");
    client.emit('Recieved', '');
}


Map<String, bool> media_exist = {};
Future<bool> checkMediaExist() async {
    
    if (_current_num_media == 1) {
        media_exist = {};
    }
    if (media_exist.isEmpty) {
        for (var backup in _backup_list) {
            if (backup.backup_name == _current_backup_name) {
                var all_media = await Directory(backup.path).list().toList();
                for (var media in all_media) {
                    media_exist[media.path.split("/").last] = true;
                }
            }
        }
    } 

    if (media_exist.containsKey(_last_media)) {
        return true;
    } else {
        media_exist[_last_media] = true;
        return false;
    }
    
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
                    size += await File(media.path).length();
                } else if (lookupMimeType(media.path) != null && lookupMimeType(media.path)!.contains("image")) {
                    photo_num += 1;
                    size += await File(media.path).length();
                }
            }
            
            out.add(Backup_info(bkp_name, (video_num+photo_num), photo_num, video_num, size, dir.path));

        }
    }
    return out;
}

Future<String> getPrivateAddress() async {
    for (var x in await NetworkInterface.list()) {
        if (x.name == "en0") {
            for (var y in x.addresses) {
                if (y.type.name == "IPv4") {
                    return y.address;
                }
            }
        }
    }
    return "";
}




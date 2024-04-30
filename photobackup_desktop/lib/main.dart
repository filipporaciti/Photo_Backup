import 'dart:io';
import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:socket_io/socket_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'functions.dart';

final String _device_name = Platform.localHostname.replaceAll('.local', '');
String _root_dest_directory = '';
List<Backup_info> _backup_list = [];
String _last_media = '';
int _total_num_media = 0;
int _current_num_media = 0;
String _current_backup_name = '';
double _progressbar_value = 0.0;


void main() {
    // run first page
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
    @override
    void initState() {
        super.initState();      
        _initAsync();
    }

    Future<void> _initAsync() async {

        // I use SharedPreferences to save settings preference. In this case 
        // I have only one preference (root dest directory) that store backup directory.
        // If is null, I'll set the home directory as default. 
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? saved_root_dest_directory = prefs.getString('root dest directory');
        _root_dest_directory = saved_root_dest_directory ?? getHomeDirectory();

        // start servet
        var io = new Server();
        io.listen(9084);
        handleConnection(io);

        // refresh backup list. It's necessary to view all backups in backup directory
        refreshBackupList();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Photo backup'),
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
                        // device name text
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                'Device name: $_device_name',
                                overflow: TextOverflow.visible,
                            )
                        ),
                        // row with destination directory text, button to change
                        // destination directory path and a button to open that
                        // folder
                        Row(
                            children: [
                                Container(
                                    width: 600,
                                    child: 
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                            'Destination directory: $_root_dest_directory',
                                            overflow: TextOverflow.visible,
                                        )
                                    )
                                ),
                                Spacer(),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        child:
                                        Text('Change path'),
                                        onPressed: () async {
                                            // FilePicket to select destination directort
                                            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

                                            if (selectedDirectory != null) {
                                                // save setting persistently
                                                final SharedPreferences prefs = await SharedPreferences.getInstance();
                                                await prefs.setString('root dest directory', selectedDirectory + '/');

                                                // update state
                                                setState((){
                                                    _root_dest_directory = selectedDirectory! + '/';

                                                });
                                            }

                                            // update backup list
                                            refreshBackupList();

                                        }
                                    ),
                                ),
                                Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                        child:
                                        Text('Open'),
                                        onPressed: () {
                                            // open destination backups directory
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
                            child: Text('Old backups:')
                        ),
                        // stored backup grid
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
                                                // backup name text
                                                Text(
                                                    _backup_list[index].backup_name,
                                                    overflow: TextOverflow.visible,
                                                ),
                                                Divider(),

                                                // backup informations
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text('All media number: ' + _backup_list[index].media_num.toString())
                                                ),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text('Photo: ' + _backup_list[index].photo_num.toString())
                                                ),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text('Video: ' + _backup_list[index].video_num.toString())
                                                ),
                                                Spacer(),
                                                Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text('Size: ' + (_backup_list[index].size/1000000000).toStringAsFixed(2) + ' GB')
                                                ),
                                                Divider(),
                                                // button to open backup folder
                                                TextButton(
                                                    child: Text('Open folder'),
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
                        // currrent backup name
                        Text(
                            'Backup name: $_current_backup_name',
                            overflow: TextOverflow.visible,
                        ),
                        // progress bar
                        LinearProgressIndicator(
                            value: _progressbar_value
                        ),
                        Row(
                            children: [
                                // last media stored text
                                Text(
                                    '$_last_media',
                                    overflow: TextOverflow.visible,
                                ),
                                Spacer(),
                                // number of processed backup and total number of media
                                Text(
                                    '$_current_num_media/$_total_num_media',
                                    overflow: TextOverflow.visible,
                                ),
                            ]
                        ),
                    ]
                )
            )
        );
    }

/*
Manage server connections
Input: Server io (server object)
Output:
*/
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

/*
Handler to process data from client. 
Input: String tag (to understand request type), Map<String, dynamic> json_data (data), Socket client (object to send a response)
Output:
*/
Future<void> ProcessDataClient(String tag, Map<String, dynamic> json_data, Socket client) async {

    if (tag == 'Make backup: base64 media') {
        Uint8List byte_image = base64Decode(json_data['Image data']);

        final String finalPath = _root_dest_directory + _current_backup_name;

        // Create destination directory; if exist, nothing happened
        var path_dir = await Directory(finalPath);
        await path_dir.create();

        // Save image
        File file = await File(finalPath + '/' + _last_media);
        file.writeAsBytesSync(byte_image);
        // print('create file ' + finalPath + '/' + _last_media);

    }
    if (tag == 'Discover') {
        String private_ip = await getPrivateAddress();
        if (private_ip != '') {  
            client.emit('Discover response', {'Computer name': _device_name, 'Remote address': private_ip});
        }
    }
    if (tag == 'Make backup: info media') {

        // get all informations
        String imgname = json_data['Image name'];
        String imgfiletype = '.' + imgname.split('.').last;
        imgname = imgname.split('.').sublist(0, imgname.split('.').length-1).join('');
        String imgdate = json_data['Image date'].replaceAll(':', '-').replaceAll(' ', '_').split('.')[0];
        final String finalImgName = imgdate + '_' + imgname + '_' + json_data['Image length'].toString() + imgfiletype;

        // update state
        setState(() {
            _total_num_media = json_data['Media number'];
            _current_backup_name = json_data['Backup name'];

            _last_media = finalImgName;
            _current_num_media = json_data['Media index'];
            _progressbar_value = _current_num_media/_total_num_media;
        });

        // refresh backup list every some times or at the end
        if (_current_num_media%51 == 0 || _current_num_media == _total_num_media || _current_num_media == 1) {
            refreshBackupList();
        }

        // if media exist, i don't want to get image
        bool ris = await checkMediaExist();
        if (ris) {
            client.emit('Media exist', true); 
        } else {
            client.emit('Media exist', false); 
        }

    }
    if (tag == 'Backup early end') {
        // refresh backup list if backup early end
        refreshBackupList();
    }
    // to unlock waitUntilDone function
    client.emit('Recieved', '');
}

// list to store informations about media
Map<String, bool> media_exist = {};
/*
return true if media exist, false otherwise. It use an hashmap to speed up the process
Input:
Output: bool (true is exist)
*/
Future<bool> checkMediaExist() async {

    if (_current_num_media == 1) {
        // reset hashmap if backup start
        media_exist = {};
    }
    // if empty, it fill the hashmap with informations
    if (media_exist.isEmpty) {
        for (var backup in _backup_list) {
            if (backup.backup_name == _current_backup_name) {
                var all_media = await Directory(backup.path).list().toList();
                for (var media in all_media) {
                    // I have to do ".replaceAll('\\', '/')" because Windows like "\" ;)
                    media_exist[media.path.replaceAll('\\', '/').split('/').last] = true;
                }
            }
        }
    } 
    // return true if _last_media exist
    if (media_exist.containsKey(_last_media)) {
        return true;
    } else {
        // the media will be saved to directory, so i creare a new record. 
        // It return false because I need media data
        media_exist[_last_media] = true;
        return false;
    }    
}

/*
Refresh backup list
Input:
Output:
*/
void refreshBackupList() async {
    _backup_list = await getOldBackups(_root_dest_directory);
    setState(() {
        _backup_list = _backup_list;
    });
}
}

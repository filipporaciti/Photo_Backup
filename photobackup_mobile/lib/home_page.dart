import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'make_page.dart';
import 'socket_client.dart';


// Struct to store informations about online server devices. It store server's hostname and a bool variable (check) which indicate selected target server. 
class Destination_device {
    String hostname;
    bool check;
    Destination_device(this.hostname, this.check);
}

// A map of online servers. Key = server ip address, value = Destination_device's struct. 
Map<String, Destination_device> online_devices = {};


class HomeBackup extends StatefulWidget {
  @override
  _HomeBackupState createState() => _HomeBackupState();
}

class _HomeBackupState extends State<HomeBackup> {

    String _dest_device_selected = '';      // server target ip address
    String _backup_name = '';               // backup name
    bool _check_destination_device = false; // check if one of online devices checkbox is selected
    bool _discover_devices = true;          // if true, send discover devices request, else no

    @override
    void initState() {
        super.initState(); 
        _initAsync();
    }

    Future<void> _initAsync() async {
        askPermission();

        String private_ip = await getPrivateAddress();
        while (_discover_devices) {
            getServerDevices(private_ip);
            await Future.delayed(Duration(milliseconds: 10000));
        }
    }

    /*
    Ask photo library and network permission. 
    Input:
    Output:
    */
    Future<void> askPermission() async{
        var _albums = await PhotoManager.getAssetPathList();
        SocketClient client = SocketClient();
        await client.connect('1.1.1.1', 53);
    }


    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Photo backup'),
            ),
            body: Container(
                margin: 
                EdgeInsets.only(
                    left: 10.0, 
                    top: 0.0, 
                    right: 10.0, 
                    bottom: 25.0, 
                ),
                child: Column(
                    children:[
                        Expanded(
                            child: SingleChildScrollView(
                                child: Column(
                                    children: [

                                        // backup name text and textfield
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Backup name:')
                                        ),
                                        TextField(
                                            decoration: InputDecoration(
                                                border: OutlineInputBorder(),
                                                hintText: 'Enter a name',
                                            ),
                                            onChanged: (text) {  
                                                // update _backup_name
                                                _backup_name = text;
                                            }, 
                                        ),  

                                        Divider(),

                                        // target server text and list of checkbox
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('Select destination (only one):')
                                        ),
                                        ListView.builder(
                                            scrollDirection: Axis.vertical,
                                            shrinkWrap: true,
                                            itemCount: online_devices.length,
                                            itemBuilder: (context, index) {
                                                String key = online_devices.keys.elementAt(index);
                                                return Column(
                                                    children: [
                                                        CheckboxListTile(
                                                            title: Text(online_devices[key]?.hostname ?? '??????????'),
                                                            value: online_devices[key]?.check,
                                                            onChanged: (val) {
                                                                // set _check_destination_device to the value of the last changed
                                                                _check_destination_device = val!;
                                                                setState(() {
                                                                    // I can't make a backup to more than one servers, so I'll set 
                                                                    // all servers to false and only selected server to true.
                                                                    for (var x in online_devices.keys) {
                                                                        online_devices[x]?.check = false;
                                                                    }
                                                                    online_devices[key]?.check = val!;
                                                                    // update selected target server
                                                                    _dest_device_selected = key;
                                                                },
                                                                );
                                                            },
                                                        ),
                                                        Divider(),
                                                    ]
                                                );
                                            },
                                        ),

                                        // button to insert server manually
                                        Center(
                                            child: TextButton(
                                                style: TextButton.styleFrom(
                                                    foregroundColor: Colors.white,
                                                    side: 
                                                    BorderSide(
                                                        color: Colors.black,
                                                        width: 1,
                                                        ),
                                                    minimumSize: Size(100, 20),
                                                    textStyle:
                                                    TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                    ),
                                                    backgroundColor:
                                                    Colors.blue,
                                                    ),

                                                onPressed: () async {
                                                    // variable to save writed ip address
                                                    String manual_ip_address = '';

                                                    // spawn alert box
                                                    showCupertinoDialog<void>(
                                                        context: context,
                                                        barrierDismissible: false,
                                                        builder: (BuildContext context) => CupertinoAlertDialog(
                                                            title: Text('Insert server IP address'),
                                                            content: 
                                                                Card(
                                                                    color: Colors.transparent,
                                                                    elevation: 0.0,
                                                                    child: Column(
                                                                        children: <Widget>[
                                                                            TextField(
                                                                                decoration: InputDecoration(
                                                                                    border: OutlineInputBorder(),
                                                                                    labelText: 'IP address',
                                                                                    filled: true,
                                                                                ),
                                                                                onChanged: (text) {
                                                                                    // update manual ip address
                                                                                    manual_ip_address = text;
                                                                                }, 
                                                                            ), 
                                                                        ],
                                                                    ),
                                                                ),

                                                            actions: <CupertinoDialogAction>[
                                                                CupertinoDialogAction(
                                                                    onPressed: () {
                                                                        // send discover request to writed ip address
                                                                        sendDiscoverRequest(manual_ip_address);
                                                                        // close alert box
                                                                        Navigator.of(context).pop();
                                                                    },
                                                                    child: const Text('Ok'),
                                                                ),
                                                                CupertinoDialogAction(
                                                                    // just close alert box
                                                                    onPressed: () => Navigator.of(context).pop(),
                                                                    child: const Text('Cancel'),
                                                                ),
                                                            ],
                                                        ),
                                                    );
                                                    
                                                },
                                                child: Text('Insert a device manually'),
                                                ),
                                            ),

                                        Divider(),

                                        // link of project github page
                                        RichText(
                                            text: TextSpan(
                                                children: <TextSpan>[
                                                    const TextSpan(
                                                        text: 'This project is open source on ',
                                                        style: TextStyle(color: Colors.black87),
                                                    ),
                                                    TextSpan(
                                                        text: 'github',
                                                        style: const TextStyle(
                                                            color: Colors.blue,
                                                            decoration: TextDecoration.underline,
                                                        ),
                                                        recognizer: TapGestureRecognizer()
                                                        ..onTap = () => _launchURL('https://github.com/filipporaciti/Photo_Backup'),
                                                    ),
                                                    const TextSpan(
                                                        text: '.',
                                                        style: TextStyle(color: Colors.black87),
                                                    ),

                                                ],
                                            ),
                                        )

                                    ]
                                )
                            )
                        ),
                        // start backup button
                        Center(
                            child: TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: 
                                    BorderSide(
                                        color: Colors.black,
                                        width: 2,
                                    ),
                                    minimumSize: Size(100, 50),
                                    textStyle:
                                    TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                    ),
                                    backgroundColor:
                                    Colors.red,
                                ),

                                onPressed: () async {
                                    // check if one target address is selected and there is backup name
                                    if (_check_destination_device && _backup_name != '') {
                                        _discover_devices = false;
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => MakeBackup(_dest_device_selected, _backup_name)));
                                    } else {
                                        showAlertDialog(
                                            context, 
                                            'Error', 
                                            'Destination device or backup name not set'
                                        );
                                    }
                                },
                                child: Text('Start backup'),
                            ),
                        ),
                    ]
                )
            )

        );
}

/*
Open default browser to given url
Input: String site (url)
Output: 
*/
Future<void> _launchURL(String site) async {
    final Uri url = Uri.parse(site);
    if (!await launchUrl(url)) {
        throw Exception('Could not launch $site');
    }

}

/*
Spawn alert box
Input: BuildContext context, String title (alert box title), String message (alert box message)
Output:
*/
void showAlertDialog(BuildContext context, String title, String message) {
    showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <CupertinoDialogAction>[
                CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                ),
            ],
        ),
    );
}

/*
Send discover request to all devices from private_ip's network. It works only with 192.168.1.XX network!!!
Input: String private_ip
Output: bool (true if no error)
*/
Future<bool> getServerDevices(String private_ip) async {
    if (private_ip != '') {
        // print('Start discover devices');
        private_ip = private_ip.split('.').sublist(0, 3).join('.');
        for (var i = 1; i < 255; i++) {
            String ip = private_ip + '.' + i.toString();
            sendDiscoverRequest(ip);
        }
        // print('End discover devices');
        return true;
    }
    return false;
}

/*
Send a discover request to given ip address and, after 1 second, it will update the state
Input: String ip (target ip address)
Output:
*/
Future<void> sendDiscoverRequest(String ip) async {

    SocketClient client = SocketClient();

    // connect and send request
    await client.connect(ip, 9084);
    await client.write('Discover', {});
    client.close();
    
    // wait 1 second and update the state
    await Future.delayed(Duration(milliseconds: 1000));
    setState((){});
    // print(ip);
}

/*
Return network private ip address
Input:
Output: String (private ip address)
*/
Future<String> getPrivateAddress() async {
    for (var x in await NetworkInterface.list()) {
        if (x.name == 'en0') {
            for (var y in x.addresses) {
                if (y.type.name == 'IPv4') {
                    return y.address;
                }
            }
        }
    }
    return '';
}
}



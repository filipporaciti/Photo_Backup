import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'make_page.dart';
import 'socket_client.dart';

class Destination_device {
    String hostname;
    bool check;
    Destination_device(this.hostname, this.check);
}


Map<String, Destination_device> online_devices = {};


class HomeBackup extends StatefulWidget {
  @override
  _HomeBackupState createState() => _HomeBackupState();
}

class _HomeBackupState extends State<HomeBackup> {

    String _dest_device_selected = "";
    String _backup_name = "";
    bool check_destination_device = false;

    @override
    void initState() {
        super.initState(); 
        _initAsync();
    }

    Future<void> _initAsync() async {
        getServerDevices();

    }

   @override
   Widget build(BuildContext context) {
    
    return Scaffold(
        appBar: AppBar(
          title: const Text("Photo backup"),
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

                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Backup name:")
                                        ),
                                    TextField(
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'Enter a name',
                                        ),
                                        onChanged: (text) {  
                                            _backup_name = text;  
                                        }, 
                                      ),

                                    Divider(),

                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Select destination (only one):")
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
                                                      title: Text(online_devices[key]?.hostname ?? ""),
                                                      value: online_devices[key]?.check,
                                                      onChanged: (val) {
                                                        check_destination_device = val!;
                                                        setState(
                                                          () {
                                                            for (var x in online_devices.keys) {
                                                                online_devices[x]?.check = false;
                                                            }
                                                            online_devices[key]?.check = val!;
                                                            _dest_device_selected = key;
                                                        },
                                                        );
                                                    },
                                                    ),
                                                    Divider()]);
                                        },
                                        ),


                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Settings:")
                                        ),
                                    Text("..."),
                                    Text("..."),
                                    Text("..."),

                                    
                                    SizedBox(
                                        height:30
                                        ),

                                    Divider(),

                                    // project github page
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
                                                ..onTap = () => _launchURL("https://github.com/filipporaciti/Photo_Backup"),
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
                                final permission = await _promptPermissionSetting();
                                if (permission && check_destination_device && _backup_name != "") {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MakeBackup(_dest_device_selected, _backup_name)));
                                } else if (!permission) {
                                    // permission alert
                                    showAlertDialog(
                                        context, 
                                        "Permission error", 
                                        "You have to enable photos access from settings"
                                        );
                                } else {
                                    //
                                    showAlertDialog(
                                        context, 
                                        "Error", 
                                        "Destination device or backup name not set"
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
Future<void> _launchURL(String site) async {
   final Uri url = Uri.parse(site);
   if (!await launchUrl(url)) {
    throw Exception('Could not launch $site');
}
}

void showAlertDialog(BuildContext context, String title, String message) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () { 
        Navigator.of(context).pop();
    },
    );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      okButton,
      ],
    );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
  },
  );
}

Future<bool> _promptPermissionSetting() async {
    if (Platform.isIOS) {
        if (await Permission.photos.request().isGranted || await Permission.storage.request().isGranted) {
            return true;
        }
    }
    if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted ||
            await Permission.photos.request().isGranted &&
            await Permission.videos.request().isGranted) {
            return true;
    }
}
return false;
}

Future<void> getServerDevices() async {

    print("Start discover devices");

    

    for (var i = 1; i < 255; i++) {

            String ip = "192.168.1." + i.toString();
            sendDiscoverRequest(ip);

    }
    // wait every request time
    await Future.delayed(Duration(milliseconds: 1500));
    setState((){});

    print("End discover devices");

}

Future<void> sendDiscoverRequest(String ip) async {

    print(ip);

    SocketClient client = SocketClient();

    try{

    await client.connect(ip, 9084, timeout:1000);

    await client.write({"Tag": "Discover"}, "Hello");
    print("Write $ip");

    client.close();
    } on Exception catch(_) {

    }
   
}


}



import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Album>? _albums;
  Album? _all_album;
  bool _loading = false;

  @override
  void initState() {
	super.initState();
	_loading = true;
	initAsync();
  }

  Future<void> initAsync() async {

  
	if (await _promptPermissionSetting()) {
	  List<Album> albums = await PhotoGallery.listAlbums(); // id album with all media: "__ALL__"

	  if (albums.length >= 1) {
		_all_album = albums[0];
		for (var i = 0; i < albums.length; i++) {
		  if (albums[i].id == "__ALL__") {
			_all_album = albums[i];
			print("all album find");
		  }
		}
	  } else {
		print("[Error] no album");
	  }
	  

	  setState(() {
		_albums = albums;
		_loading = false;
	  });
	}
	setState(() {
	  _loading = false;
	});
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

  @override
  Widget build(BuildContext context) {
	return MaterialApp(
	  home: Scaffold(
		appBar: AppBar(
		  title: const Text("Photo backup"),
		),
		body: 
		  Column(
			children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        side: BorderSide(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        MakeBackupFromAlbum(_all_album);
                      },
                      child: Text('Make backup'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        side: BorderSide(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        waitDone();
                      },
                      child: Text('wait done'),
                    ),
            ]

		  ),
	  ),
	);
  }

  

  	void MakeBackupFromAlbum(Album? album) async {

	 	if (album != null) {
	 		

	 	 	MediaPage mediaPage = await album.listMedia(
	 	 		take: 10
	 	 		);

	 	 	SocketClient client = SocketClient();
			await client.connect("192.168.1.56", 4567);

	 	 	var media_info = {"Media number": mediaPage.items.length};
	 	 	final String json_media_info = jsonEncode(media_info);

			await client.write({"Tag": "Make backup: info"}, json_media_info);

			for (var i = 0; i < mediaPage.items.length; i++) {
			// for (var i = 0; i < 1; i++) {
				File imagefile = await mediaPage.items[i].getFile();

				Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
				String base64string = base64.encode(imagebytes); //convert bytes to base64 string

				var tag = {"Tag": "Make backup: base64 media", "Image name": mediaPage.items[i].filename};

				await client.write(tag, base64string);

      			// await Future.delayed(Duration(milliseconds: 5000));



			}

	 		client.close();
	 	}
   }


}

var completer;
Future _waitUntilDone() async {
  completer = Completer();
  return completer.future;
}
void waitDone() {
	if (completer != null) {
    	completer.complete();
    }
}


class SocketClient {

	Socket? socket;
	
	connect(String address, int port) async {

		this.socket = await Socket.connect(address, port);
		this.socket?.listen(
			// handle data from the client
			(Uint8List data) async {
				final message = String.fromCharCodes(data);
				print(message);

				if (message == '{"Info":{"Tag":"Recived"}}') {
					waitDone();
				}
			},
			// handle errors
			onError: (error) {
				print(error);
				this.close();
			},
			// handle the client closing the connection
			onDone: () {
				print("Server left");
				this.close();
			},
		);
	}
	write(Map<String, dynamic> json_tag, String json_data) async {
		var len = 1000;
 		for (var i = 0; i < json_data.length; i += len) {
 			var data_piece = {"Info": json_tag, "Number": (i/len).toInt(), "Total": ((json_data.length/len) + 1).toInt(), "End": i >= (json_data.length-len), "Data": json_data.substring(i, [i+len, json_data.length].reduce(min))};
 			// var data_piece = {"Info": json_tag, "Number": (i/50000).toInt(), "Total": ((json_data.length/50000) + 1).toInt(), "End": i >= (json_data.length-50000), "Data": "ciao"};
 			String json_piece = jsonEncode(data_piece);
 			this.socket?.write(json_piece);
 			print(json_piece.substring(0, 10) + "   " + json_piece.substring(json_piece.length-20, json_piece.length) + " " + json_piece.length.toString());
			await _waitUntilDone();
			await Future.delayed(Duration(milliseconds: 10));
 		}
 	 	
		
		
		print("Socket write " + json_data);
	}
	close() {
		this.socket?.close();
		print("Socket close");
	}
}

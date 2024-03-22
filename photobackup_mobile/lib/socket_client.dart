import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import 'make_page.dart';
import 'home_page.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;



class SocketClient {



	IO.Socket? _socket;
	
	bool abort = false;

	Future<void> connect(String address, int port) async {


		 this._socket = IO.io('http://${address}:${port.toString()}', <String, dynamic>{
	        'transports': ['websocket'],
	        'autoConnect': false
	    });

		this._socket!.connect();

	    this._socket!.on('connect', (_) => print('connect'));
	    this._socket!.on('disconnect', (_) {
	    	print('disconnect');
	    	waitDone();
	    });

	    this._socket!.on('Discover response', (json_data) {
	    	if (json_data.keys.contains('Remote address')) {
	    		online_devices[json_data['Remote address']] = Destination_device(json_data['Computer name'], false);
	    	}
	    });
	    this._socket!.on('Media exist', (data) {
	    	this.abort = data;
	    });	
	    this._socket!.on('Recieved', (data) {
	    	print('recived');
	    	waitDone();
	    });


	}

	Future<void> write(String tag, Map<String, dynamic> json_data, {timeout = 500}) async {
		var timer;
		if (timeout != null) {
			timer = Timer(Duration(milliseconds: timeout), () {
				this.close();
				// print('timeout');
	        	return;
	    	});
		}
		
		
		this._socket!.emit(tag, json_data);
		print('write sent');
		await waitUntilDone();

		if (timeout != null) {
			timer.cancel();
		}	

	}

	Future<(bool, String)> writeImage(String tag, Map<String, dynamic> data, AssetEntity image) async {

		if (end) {
			return (false, 'Backup was terminated early');
		}
		if (setpauseresumebutton == 'RESUME') {
			await waitUntilDone_playpause();
		}

		await this.write('Make backup: info media', data, timeout: null);
		if (this.abort) {
			this.abort = false;
			return (true, 'Media already exist');
		}

		try{

			File? imagefile = await image.originFile;
			if (imagefile != null) {

				Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
				data['Image data'] = base64Encode(imagebytes);

				await this.write(tag, data, timeout: null);

			} else {
				print('File not found');
				return (false, 'Files not found');
			}
		} on OutOfMemoryError catch (_) {
			return (false, 'Media too large');
		}

		return (true, '');

	}

	void close() {
		this._socket?.close();
	}

}

var completer;
Future waitUntilDone() async {
	completer = Completer();
	return completer.future;
}
void waitDone() {
	if (completer != null) {
		completer.complete();
		completer = null;
	}
}
var completerplaypause;
Future waitUntilDone_playpause() async {
	completerplaypause = Completer();
	return completerplaypause.future;
}
void waitDone_playpause() {
	if (completerplaypause != null) {
		completerplaypause.complete();
		completerplaypause = null;
	}
}


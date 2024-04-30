import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'make_page.dart';
import 'home_page.dart';


// You can connect, send and recive message from server
class SocketClient {

	IO.Socket? _socket; // socket object
	bool abort = false; // to check if an image already exist (true) or not. if true, you will not send image data

	Future<void> connect(String address, int port) async {

		// set connection
		this._socket = IO.io('http://${address}:${port.toString()}', <String, dynamic>{
			'transports': ['websocket'],
			'autoConnect': false
		});
		// connect to server
		this._socket!.connect();

		// this._socket!.on('connect', (_) => print('connect'));
		this._socket!.on('disconnect', (_) {
			// print('disconnect');
			// to unlock blocked function
			waitDone();
		});

		// recive 'discover response'. After sending 'discover request', online servers 
		// will send 'discover response' with remote address and computer name
		this._socket!.on('Discover response', (json_data) {
			// print(json_data);
			if (json_data.keys.contains('Remote address')) {
				if (!online_devices.containsKey(json_data['Remote address'])) {
					online_devices[json_data['Remote address']] = Destination_device(json_data['Computer name'], false);
				}
			}
		});
		// recive 'media exist'. before sending image data, i will send
		// a packet to check if that media already exist
		this._socket!.on('Media exist', (data) {
			this.abort = data;
		});	
		// recive 'recived'. Once reciver, i will unlock blocked function
		this._socket!.on('Recieved', (data) {
			waitDone();
		});

	}

	/*
	Send json data to connected server. there is a timeout and, once 
	sending a message, I will wait until response or the server disconnects
	Input: String tag (data tag), Map<String, dynamic> json_data, timeout (default 700)
	Output:
	*/
	Future<void> write(String tag, Map<String, dynamic> json_data, {timeout = 700}) async {
		// to create timeout
		var timer;
		if (timeout != null) {
			timer = Timer(Duration(milliseconds: timeout), () {
				this.close();
				return;
			});
		}

		// send data
		this._socket!.emit(tag, json_data);
		// wait until response
		await waitUntilDone();

		// cancel timeout if the function end before the timeout
		if (timeout != null) {
			timer.cancel();
		}	
	}

	/*
	Write image data and json data to connected server. It use 'write' function.
	Input: String tag (data tag), Map<String, dynamic> data (json data), AssetEntity image
	Output: bool, String
	*/
	Future<(bool, String)> writeImage(String tag, Map<String, dynamic> data, AssetEntity image) async {

		// if i push end button, end become true and I have to terminate backup, so...
		if (end) {
			return (false, 'Backup was terminated early');
		}
		// for play/pause
		if (set_pause_resume_button == 'RESUME') {
			await waitUntilDone_playpause();
		}

		// send packet to check if media already exist
		await this.write('Make backup: info media', data, timeout: null);
		if (this.abort) {
			this.abort = false;
			return (true, 'Media already exist');
		}

		try{
			// take image data
			File? imagefile = await image.originFile;
			if (imagefile != null) {
				Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
				// encode to base64
				data['Image data'] = base64Encode(imagebytes);

				// send image using 'write' function
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

// functions to wait until something. It's used for packet transmissions
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

// functions to wait until something. It's used to manage play/pause condition
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


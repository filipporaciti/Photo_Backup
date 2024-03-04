import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

import 'make_page.dart';
import 'home_page.dart';


class SocketClient {

	Socket? _socket;
	int _imagepiecesize = 12000000; // deve essere un multiplo di tre per la codifica in base64, altrimenti ci saranno gli "=" che creano casino.
	
	Future<void> connect(String address, int port, {int? timeout}) async {
		if (timeout != null) {
			this._socket = await Socket.connect(address, port, timeout: Duration(milliseconds:timeout));

		} else {
			this._socket = await Socket.connect(address, port);

		}
		this._socket?.listen(
			// handle data from the client
			(Uint8List data) async {
				final message = String.fromCharCodes(data);

				if (message == '{"Info":{"Tag":"Recived"}}') {
					waitDone();
				} else if (message.startsWith('{"Info":{"Tag":"Discover response","Computer name"')) {
					Map<String, dynamic> jsonData = jsonDecode(message);
					if (this._socket?.remoteAddress.address != null) {
						online_devices[this._socket?.remoteAddress.address ?? ""] = Destination_device(jsonData["Info"]["Computer name"], false);

					}

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

	Future<void> write(Map<String, dynamic> json_tag, String json_data) async {

		var data_piece = {"Info": json_tag, "End": false};
		this._socket?.write(jsonEncode(data_piece));

		await waitUntilDone();

		this._socket?.write(json_data + "{}");

		await waitUntilDone();
		// await Future.delayed(Duration(milliseconds: 10));

		data_piece = {"Info": json_tag, "End": true};
		this._socket?.write(jsonEncode(data_piece));

		await waitUntilDone();

	}

	Future<(bool, String)> writeImage(Map<String, dynamic> json_tag, AssetEntity image) async {

		File? imagefile = await image.originFile;
		if (imagefile != null) {

			var size = await imagefile.length();

			try {
				Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes

				print("Size: " + size.toString());

				// Socket writing
				var data_piece = {"Info": json_tag, "End": false};
				this._socket?.write(jsonEncode(data_piece));
				await waitUntilDone();

				for (var i = 0; i < imagebytes.length; i+=_imagepiecesize) {

					if (end) {
						return (false, "Backup was terminated early");
					}
					if (setpauseresumebutton == "RESUME") {
						await waitUntilDone();

					}

					String base64string = base64.encode(imagebytes.sublist(i, [i+_imagepiecesize, imagebytes.length].reduce(min))); //convert bytes to base64 string
					this._socket?.write(base64string + "{}");
					await waitUntilDone();
					// await Future.delayed(Duration(milliseconds: 10));
					// print("Piece: " + i.toString() + " " + [i+_imagepiecesize, imagebytes.length].reduce(min).toString());
				}

				data_piece = {"Info": json_tag, "End": true};
				this._socket?.write(jsonEncode(data_piece));
				await waitUntilDone();
				// End socket writing

			} on OutOfMemoryError catch (_) {
				return (false, "Media too large");
			}

		} else {
			print("File not found");
			return (false, "Files not found");
		}
		return (true, "");
	}

	close() {
		this._socket?.close();
		print("Socket close");
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
	}
}


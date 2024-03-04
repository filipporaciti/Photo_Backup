import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'socket_client.dart';
import 'resume_page.dart';

import 'package:flutter/material.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';

bool end = false;

Map<String, Color> _pauseresumebutton = {"PAUSE":Colors.yellow, "RESUME": Colors.green};
String setpauseresumebutton = "PAUSE";


class MakeBackup extends StatefulWidget {

	MakeBackup(this._ipaddress);

	final String _ipaddress;


	@override
	_MakeBackupState createState() => _MakeBackupState(_ipaddress);
}

class _MakeBackupState extends State<MakeBackup> {

	List<AssetPathEntity>? _albums;
	int _mediacount = 0;

	int _step = 100;

	double _numberindicatorvalue = 0.0;
	int _numbercountervalue = 0;
	int _successvalue = 0;
	int _faliedvalue = 0;
	String _lastsuccessmedia = "";
	String _lastfaliedmedia = "";

	_MakeBackupState(this._dest_ipaddress);

	final String _dest_ipaddress;
	

	@override
	void initState() {
		super.initState();		
		_initAsync();
	}

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			home: Scaffold(
				appBar: AppBar(
					title: const Text("Make backup"),
					),
				body: 	
				Container(
					margin: 
					EdgeInsets.only(
						left: 10.0, 
						top: 0.0, 
						right: 10.0, 
						bottom: 25.0, 
						),
					child: 
					Column(
						children: [

							LinearProgressIndicator(
								value: _numberindicatorvalue
								),
							Text('${_numbercountervalue}/${_mediacount}'),

		            		// Success
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Recived: ${_successvalue}/${_numbercountervalue}')
								),
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Last: ${_lastsuccessmedia}'),
								),

						    // Divide falied from success
                            Divider(),


						    // Falied
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Falied: ${_faliedvalue}/${_numbercountervalue}')
								),
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Last: ${_lastfaliedmedia}'),
								),


							Spacer(),


							Row(
								children: [
									Spacer(),
									TextButton(
										style: TextButton.styleFrom(
											side: 
											BorderSide(
												color: Colors.black,
												width: 2,
												),
											minimumSize: Size(130, 50),
											textStyle:
											TextStyle(
												fontSize: 18,
												fontWeight: FontWeight.bold,
												),
											backgroundColor:
											_pauseresumebutton[setpauseresumebutton],
											),
										onPressed: () {
											if (setpauseresumebutton == "PAUSE") {
												setState(() {setpauseresumebutton = "RESUME";});
											} else {
												waitDone();
												setState(() {setpauseresumebutton = "PAUSE";});		
											}

										},
										child: Text(setpauseresumebutton),
										),
									Spacer(),

									TextButton(
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

										onPressed: () {
											end = true;
										},
										child: Text('END'),
										),
									Spacer(),

									]
								),

							]

						),
					),
				),
			);
	}

	Future<void> _initAsync() async {

		_albums = await PhotoManager.getAssetPathList();
		var newmediacount = await PhotoManager.getAssetCount();

		setState(() {
			_mediacount = newmediacount;
			});

		MakeBackupFromAlbum();
	}



Future<void> MakeBackupFromAlbum() async {


	if (_albums == null) {
		await _initAsync();
	} else {
		SocketClient client = SocketClient();
		await client.connect(_dest_ipaddress, 9084);

		var media_info = {"Media number": _mediacount};
		final String json_media_info = jsonEncode(media_info);
		await client.write({"Tag": "Make backup: info"}, json_media_info);

		Map<AssetEntity, String> faliedBackup = {};


		for (var i_album = 0; i_album < _mediacount; i_album += _step){

			if (end) {
				break;
			}

			final images = await _albums![0].getAssetListPaged(page: (i_album/_step).toInt(), size: _step);

			for (var i = 0; i < images.length; i++) {

				if (end) {
					break;
				}

				print("Saving item " + (i_album+i).toString() + "/" + (_mediacount).toString());

				final Medium mediumimage = await PhotoGallery.getMedium(
					mediumId: images[i].id,
					);

				File? imagefile = await images[i].originFile;
				if (imagefile != null) {
					var imgsize = await imagefile.length();

					var tag = {"Tag": "Make backup: base64 media", "Image name": mediumimage.filename, "Image length": imgsize, "Image date": images[i].createDateTime.toString()};
					var (success, info) = await client.writeImage(tag, images[i]);

					if (success) {
						_successvalue += 1;
						_lastsuccessmedia = mediumimage.filename ?? "";
					} else {
						faliedBackup[images[i]] = info;
						_faliedvalue += 1;
						_lastfaliedmedia = (mediumimage.filename ?? "") + " ($info)";
					}

					setState(() {
						_numberindicatorvalue = (i_album+i) / _mediacount;
						_numbercountervalue = i_album+i+1;
					});
				}					

			}
		}
		

		client.close();
	}

	print("End backup");
	Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResumeBackup()));


}

}

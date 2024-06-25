import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_gallery/photo_gallery.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_friendly_name/device_friendly_name.dart';

import 'resume_page.dart';
import 'socket_client.dart';


bool end = false; // if true, backup will be end
Map<String, Color> _pauseresumebutton = {'PAUSE':Colors.yellow, 'RESUME': Colors.green}; // to set button color based on button state
String set_pause_resume_button = 'PAUSE'; // actual button state
Map<String, String> falied_backup = {}; // map of falied backups


class MakeBackup extends StatefulWidget {

	// get from previus page informations about which ip address and backup name it have to use
	MakeBackup(this._ip_address, this._backup_name);
	final String _ip_address;
	final String _backup_name;

	@override
	_MakeBackupState createState() => _MakeBackupState(_ip_address, _backup_name);
}

class _MakeBackupState extends State<MakeBackup> {

	List<AssetPathEntity>? _albums;
	int _mediacount = 0;

	int _step = 100;

	double _numberindicatorvalue = 0.0;
	int _numbercountervalue = 0;
	int _successvalue = 0;
	int _faliedvalue = 0;
	String _lastsuccessmedia = '';
	String _lastfaliedmedia = '';
	String _actualmedia = '';

	// get from MakeBackup's class informations about which ip address and backup name it have to use
	_MakeBackupState(this._dest_ip_address, this._backup_name);
	final String _dest_ip_address;
	final String _backup_name;
	
	/*
	Init state function
	Input:
	Output:
	*/
	@override
	void initState() {
		super.initState();	
		_initAsync();
	}

	/*
	Async init state function
	Input:
	Output:
	*/
	Future<void> _initAsync() async {
		// variables reset 
		end = false;
		falied_backup = {};
		set_pause_resume_button = 'PAUSE';

		// get and set albums list
		_albums = await PhotoManager.getAssetPathList();

		// get and set media count and update the state
		_mediacount = await PhotoManager.getAssetCount();
		setState(() {
			_mediacount;
		});

		// start backup
		MakeBackupFromAlbum();
	}

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			home: Scaffold(
				appBar: AppBar(
					title: const Text('Make backup'),
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

							// progress bar
							Text('${_actualmedia}'),
							LinearProgressIndicator(
								value: _numberindicatorvalue
							),
							Text('${_numbercountervalue}/${_mediacount}'),

		            		// success
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Recieved: ${_successvalue}/${_numbercountervalue}')
							),
							Align(
								alignment: Alignment.centerLeft,
								child: Text('Last: ${_lastsuccessmedia}'),
							),

							Divider(),

						    // falied
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
									// pause/resume button
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
											_pauseresumebutton[set_pause_resume_button],
											),
										onPressed: () {
											if (set_pause_resume_button == 'PAUSE') {
												// update pause/resume button state
												setState(() {set_pause_resume_button = 'RESUME';});
												// after that, in SocketClient class in writeImage function will be triggered waitUntilDone function
											} else {
												// finish waitUntilDone
												waitDone_playpause();
												// update pause/resume button state
												setState(() {set_pause_resume_button = 'PAUSE';});		
											}
										},
										child: Text(set_pause_resume_button),
									),

									Spacer(),

									// end button
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
											// set end to true so other function can stop backup
											end = true;
											waitDone_playpause();
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


	/*
	Take photos from the first album (it contains all photos); after it will send its to server.
	Input:
	Output:
	*/
	Future<void> MakeBackupFromAlbum() async {

		// try to get albums again
		if (_albums == null) {
			await _initAsync();
		}

		if (_albums != null) {
			SocketClient client = SocketClient();
			await client.connect(_dest_ip_address, 9084);

			for (var i_album = 0; i_album < _mediacount; i_album += _step){

				// take images
				final images = await _albums![0].getAssetListPaged(page: (i_album/_step).toInt(), size: _step);

				for (var i = 0; i < images.length; i++) {

					// terminate backup
					if (end) {
						await client.write('Backup early end', {}, timeout: null);
						break;
					}

					// update state
					setState(() {
						_numberindicatorvalue = (i_album+i+1) / _mediacount;
						_numbercountervalue = i_album+i+1;
					});

					// print('Saving item ' + (i_album+i).toString() + '/' + (_mediacount).toString());

					// to get image informations
					final Medium mediumimage = await PhotoGallery.getMedium(mediumId: images[i].id);
					File? imagefile = await images[i].originFile;

					if (imagefile != null && mediumimage != null) {
						var imgsize = await imagefile.length();

						// I have to replace some characters to avoid issues 
						// when i have to save medium on desktop
						_actualmedia = mediumimage.filename ?? '';
						_actualmedia = _actualmedia.replaceAll(':', '-');
						_actualmedia = _actualmedia.replaceAll('*', '-');
						_actualmedia = _actualmedia.replaceAll('?', '-');
						_actualmedia = _actualmedia.replaceAll('"', '-');
						_actualmedia = _actualmedia.replaceAll('<', '-');
						_actualmedia = _actualmedia.replaceAll('>', '-');
						_actualmedia = _actualmedia.replaceAll('|', '-');
						_actualmedia = _actualmedia.replaceAll('/', '-');
						_actualmedia = _actualmedia.replaceAll('\\', '-');

						// update state to view actual media
						setState(() {});

						// image informations
						var data = {
							'Image name': _actualmedia, 
							'Image length': imgsize, 
							'Image date': images[i].createDateTime.toString(), 
							'Media index': (i+i_album+1),
							'Media number': _mediacount,
							'Backup name': _backup_name
						};

						// send image to server
						var (success, info) = await client.writeImage('Make backup: base64 media', data, images[i]);

						// success and falied
						if (success) {
							_successvalue += 1;
							_lastsuccessmedia = _actualmedia;
						} else {
							falied_backup[_actualmedia] = info;
							_faliedvalue += 1;
							_lastfaliedmedia = (_actualmedia) + ' ($info)';
						}

						// update state to view last success or falied media
						setState(() {});
					}					

				}
			}
			await client.write('Backup done', {}, timeout: null);
			client.close();
		}
		// Once completed, it will spawn resume page
		Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResumeBackup(_numbercountervalue, _successvalue, _faliedvalue, falied_backup)));

	}
}


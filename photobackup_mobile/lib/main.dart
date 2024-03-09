import 'home_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


void main() {
	WidgetsFlutterBinding.ensureInitialized(); 
	SystemChrome.setPreferredOrientations( 
		[DeviceOrientation.portraitUp]
	); 

	runApp(MaterialApp(
		home: HomeBackup()
		)
	);
}

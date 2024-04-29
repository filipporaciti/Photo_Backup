import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart';


void main() {

    // lock device orientation to portrait up
	WidgetsFlutterBinding.ensureInitialized(); 
	SystemChrome.setPreferredOrientations( 
	   [DeviceOrientation.portraitUp]
    ); 

    // run first page
    runApp(MaterialApp(home: HomeBackup()));
}

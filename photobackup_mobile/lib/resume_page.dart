import 'package:flutter/material.dart';

class ResumeBackup extends StatefulWidget {
  @override
  _ResumeBackupState createState() => _ResumeBackupState();
}

class _ResumeBackupState extends State<ResumeBackup> {

    List<String> _falied = [];

    @override
    Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Resume"),
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
                                        child: Text("Total images: ")
                                        ),
                                    Divider(),
                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Recived: ")
                                        ),
                                    Divider(),


                                    Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("Falied: ")
                                        ),
                                    ListView.builder(
                                        scrollDirection: Axis.vertical,
                                        shrinkWrap: true,
                                        itemCount: _falied.length,
                                        itemBuilder: (context, index) {
                                            return Column(
                                                children: [
                                                    Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Text(_falied[index])
                                                        ),
                                                    Divider(),
                                                    ]);
                                        },
                                        ),

                                    
                                    ]
                                )
                            )
                        ),
                    
                    ]
                )
            )

        );
}


}



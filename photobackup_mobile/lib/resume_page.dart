import 'package:flutter/material.dart';

import 'package:photo_manager/photo_manager.dart';


class ResumeBackup extends StatefulWidget {
  ResumeBackup(this.total_num, this.success_num, this.falied_num, this.faliedBackup);
  final int total_num;
  final int success_num;
  final int falied_num;
  final Map<String, String> faliedBackup;

  @override
  _ResumeBackupState createState() => _ResumeBackupState(this.total_num, this.success_num, this.falied_num, this.faliedBackup);
}

class _ResumeBackupState extends State<ResumeBackup> {

    _ResumeBackupState(this.total_num, this.success_num, this.falied_num, this.faliedBackup);
    

    final int total_num;
    final int success_num;
    final int falied_num;
    final Map<String, String> faliedBackup;


    @override
    void initState() {
        super.initState();  
        _initAsync();
    }

    Future<void> _initAsync() async {

    }

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
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Total images: $total_num")
                            ),
                        Divider(),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Recieved: $success_num")
                            ),
                        Divider(),


                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Falied: $falied_num")
                            ),
                        Expanded(
                            child:
                        ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: faliedBackup.keys.length,
                            itemBuilder: (context, index) {
                                var key = faliedBackup.keys.toList()[index];
                                return Column(
                                    children: [
                                        Row(
                                            children: [

                                             Container(
                                                width: 250,
                                                child: Text(
                                                    key!,
                                                    overflow: TextOverflow.visible
                                                    )),
                                             Spacer(),
                                             Container(
                                                width: 120,
                                                child: 
                                                Align(
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                        faliedBackup[key]!,
                                                        overflow: TextOverflow.visible
                                                        )
                                                    ),),

                                             ]
                                            ),
                                        Divider(),
                                        ]);
                            },
                            ),
                        ),
                        SizedBox(
                            height:10
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
                                    Navigator.pop(context);

                                },
                                child: Text('End'),
                                ),
                            ),


                        ]
                    )
                )
            );

}


}



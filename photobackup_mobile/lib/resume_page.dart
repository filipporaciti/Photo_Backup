import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';


class ResumeBackup extends StatefulWidget {

    // get from previus page backup informations
    ResumeBackup(this.total_num, this.success_num, this.falied_num, this.falied_backup);
    final int total_num;
    final int success_num;
    final int falied_num;
    final Map<String, String> falied_backup;

    @override
    _ResumeBackupState createState() => _ResumeBackupState(this.total_num, this.success_num, this.falied_num, this.falied_backup);
}

class _ResumeBackupState extends State<ResumeBackup> {
    // get informations from ResumeBackup class
    _ResumeBackupState(this.total_num, this.success_num, this.falied_num, this.falied_backup);
    final int total_num;
    final int success_num;
    final int falied_num;
    final Map<String, String> falied_backup;

    /*
    Init state function
    Input:
    Output:
    */
    @override
    void initState() {
        super.initState();  
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Resume'),
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
                        // total image number
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Total images: $total_num')
                        ),

                        Divider(),
                        
                        // success image number
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Recieved: $success_num')
                        ),

                        Divider(),

                        // falied image number
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Falied: $falied_num')
                        ),
                        // list of falied image's name
                        Expanded(
                            child:
                            ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: falied_backup.keys.length,
                                itemBuilder: (context, index) {
                                    var key = falied_backup.keys.toList()[index];
                                    return Column(
                                        children: [
                                            Row(
                                                children: [

                                                   Container(
                                                    width: 250,
                                                    child: Text(
                                                        key!,
                                                        overflow: TextOverflow.visible
                                                        )
                                                    ),
                                                    Spacer(),
                                                    Container(
                                                        width: 120,
                                                        child: 
                                                        Align(
                                                            alignment: Alignment.centerRight,
                                                            child: Text(
                                                                falied_backup[key]!,
                                                                overflow: TextOverflow.visible
                                                            )
                                                        ),
                                                    ),

                                                ]
                                            ),
                                            
                                            Divider(),
                                            
                                        ]
                                    );
                                },
                            ),
                        ),

                        // to divide list of falied backup from close button
                        SizedBox(
                            height:10
                        ),

                        // close button
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
                                child: Text('Close'),
                            ),
                        ),
                    ]
                )
            )
        );
    }
}



import 'dart:io';

import 'package:mime/mime.dart';

// class that indicate every backup in selected folder
class Backup_info {
    String backup_name;
    int media_num;
    int photo_num;
    int video_num;
    int size;
    String path;
    Backup_info(this.backup_name, this.media_num, this.photo_num, this.video_num, this.size, this.path);
}

/*
Return home directory
Input:
Output: String (home directory)
*/
String getHomeDirectory() {
    String out = '';
    String os = Platform.operatingSystem;
    Map<String, String> envVars = Platform.environment;

    if (Platform.isMacOS) {
        out = envVars['HOME'] ?? '';
    } else if (Platform.isLinux) {
        out = envVars['HOME'] ?? '';
    } else if (Platform.isWindows) {
        out = envVars['UserProfile'] ?? '';
    }

    return out;
}

/*
Return a list of backups in selected directory
Input: String path (directory path)
Output: List<Backup_info> (list of Backup_info)
*/
Future<List<Backup_info>> getOldBackups(String path) async {
    List<Backup_info> out = [];
    var myDir = await Directory(path).list().toList();

    // for every files I take only directories to take informations
    for (var dir in myDir) {
        if (dir.runtimeType.toString() == '_Directory') {
            var bkp_dir = await Directory(dir.path).list().toList();

            String bkp_name = dir.path.split('/').last;
            int video_num = 0;
            int photo_num = 0;
            int size = 0;

            // get number of videos and photos
            for (var media in bkp_dir) {
                if (lookupMimeType(media.path) != null && lookupMimeType(media.path)!.contains('video')) {
                    video_num += 1;
                    size += await File(media.path).length();
                } else if (lookupMimeType(media.path) != null && lookupMimeType(media.path)!.contains('image')) {
                    photo_num += 1;
                    size += await File(media.path).length();
                }
            }
            // add item to returned list
            out.add(Backup_info(bkp_name, (video_num+photo_num), photo_num, video_num, size, dir.path));
        }
    }
    return out;
}

/*
Return local private address to en0 interface
Input:
Output: String (private address)
*/
Future<String> getPrivateAddress() async {
    for (var x in await NetworkInterface.list()) {
        if (x.name == 'en0' && (Platform.isLinux || Platform.isMacOS)) {
            for (var y in x.addresses) {
                if (y.type.name == 'IPv4') {
                    return y.address;
                }
            }
        }
        if (x.name == 'Ethernet' && Platform.isWindows) {
            for (var y in x.addresses) {
                if (y.type.name == 'IPv4') {
                    return y.address;
                }
            }
        }
    }
    return '';
}

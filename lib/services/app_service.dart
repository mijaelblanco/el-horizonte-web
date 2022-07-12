import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart';
import 'package:news_admin/utils/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class AppService {
  
  Future openLink(context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    } else {
      openToast(context, "Can't launch the url");
    }
  }


  static getNormalText (String text){
    return HtmlUnescape().convert(parse(text).documentElement!.text);
  }

  
}
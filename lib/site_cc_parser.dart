library site_cc_parser;

import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

const _BASE_URL_SITE_UFFS = 'https://cc.uffs.edu.br';

abstract class Scrapper {
  static Future<HtmlParsed> getContentFromUrl(String url) async {
    await initializeDateFormatting('pt_BR', null);

    final res = await http.get(url);
    final document = parse(res.body);

    final article = document.querySelector('#content');

    final List<Map<String, String>> list = [];

    for (var i = 0; i < article.children.length; i++) {
      final element = article.children[i];

      if (element.localName == 'p') {
        if (element.children.isNotEmpty &&
            element.children[0].localName == 'img') {
          if (element.children[0].localName == 'img') {
            list.add({HtmlParsed.img: element.children[0].attributes['src']});
          }
        } else {
          list.add({HtmlParsed.p: element.text});
        }
      }
      if (element.localName == 'h4') {
        list.add({HtmlParsed.h4: element.text});
      }

      if (element.className == 'embed-responsive embed-responsive-16by9') {
        list.add({
          HtmlParsed.video: element.querySelector('iframe').attributes['src'],
        });
      }
    }

    return HtmlParsed(list);
  }

  static Future<List<ParserSiteResponse>> getNews() async {
    await initializeDateFormatting('pt_BR', null);

    final res = await http.get(_BASE_URL_SITE_UFFS + '/noticias');

    final document = parse(res.body);

    final rows = document
        .querySelector('.page-content')
        .querySelectorAll('.row')
        .where((element) => element.classes.length == 1)
        .toList()
        .sublist(1);

    final response = rows.map((div) {
      final img = div.querySelector('img');
      final a = div.querySelector('a');
      final title = div.querySelector('h4');
      final liTags = div.querySelectorAll('li');
      final content = div.querySelector('p');

      String formatedDate;

      final date = DateTime.parse(liTags[1].text.trim());

      // final days = DateTime.now().difference(date); // / 864 * 100000;
      // if (days.inDays <= 2) {
      //   if (days.inDays == 0)
      //     formatedDate = 'Hoje';
      //   else if (days.inDays == 1)
      //     formatedDate = 'Ontem';
      //   else if (days.inDays == 2) formatedDate = 'Anteontem';
      // } else
      formatedDate = DateFormat("d 'de' MMM 'de y", 'pt-br').format(date);

      return ParserSiteResponse(
        image: img.attributes['src'],
        shortDescription: content.text.trim(),
        title: title.text.trim(),
        url: _BASE_URL_SITE_UFFS + a.attributes['href'],
        formatedDate: formatedDate,
        date: date,
        author: liTags[0].text.trim(),
        authorImage: liTags[0].querySelector('img').attributes['src'],
      );
    }).toList();

    response.sort((a, b) => b.date.compareTo(a.date));
    return response;
  }
}

class HtmlParsed {
  static const p = 'p';
  static const h4 = 'h4';
  static const img = 'img';
  static const video = 'video';

  final List<Map<String, String>> items;

  HtmlParsed(this.items);
}

class ParserSiteResponse {
  final String image;
  final String url;
  final String title;
  final DateTime date;
  final String formatedDate;
  final String author;
  final String authorImage;
  final String shortDescription;
  HtmlParsed htmlContent;

  ParserSiteResponse({
    this.image,
    this.url,
    this.title,
    this.date,
    this.author,
    this.authorImage,
    this.shortDescription,
    this.htmlContent,
    this.formatedDate,
  });

  Map<String, dynamic> toMap() => {
        'image': image,
        'url': url,
        'title': title,
        'date': date,
        'formatedDate': formatedDate,
        'author': author,
        'authorImage': authorImage,
        'shortDescription': shortDescription,
        'htmlParsed': jsonEncode(htmlContent),
      };

  String listToString(List<ParserSiteResponse> list) {
    return json.encode(list.map((e) => e.toMap()).toList());
  }

  static List<ParserSiteResponse> fromJsonList(String jsonEncoded) {
    final List<Map<String, dynamic>> map =
        json.decode(jsonEncoded).cast<List<Map<String, dynamic>>>();

    return map.map((item) => ParserSiteResponse.fromJson(item)).toList();
  }

  Future<bool> fetchUrlContent() async {
    try {
      final html = await Scrapper.getContentFromUrl(this.url);
      this.htmlContent = html;
      return true;
    } catch (error) {
      return false;
    }
  }

  factory ParserSiteResponse.fromJson(dynamic jsonEncoded) {
    final Map<String, dynamic> map =
        json.decode(jsonEncoded).cast<Map<String, dynamic>>();

    return ParserSiteResponse(
      author: map['author'] as String,
      image: map['image'] as String,
      url: map['url'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date']),
      formatedDate: map['formatedDate'],
      authorImage: map['authorImage'] as String,
      shortDescription: map['shortDescription'] as String,
      htmlContent:
          map['htmlContent'] != null ? jsonDecode(map['htmlContent']) : null,
    );
  }
}

// void main() async {
//   // final a = (await Scrapper.getNews(
//   //     'https://cc.uffs.edu.br/noticias/programa-practice/'));
//   final a = await Scrapper.getNews();
//   // print(a);
//   await a[0].fetchUrlContent();

//   print(a[0].htmlContent.items);
// }

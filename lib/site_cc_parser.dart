library site_cc_parser;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

const _BASE_URL_SITE_UFFS = 'https://cc.uffs.edu.br';

abstract class Scrapper {
  static Future<dynamic> getContentFromUrl(String url) async {
    final res = await http.get(url);
    final document = parse(res.body);

    final article = document.querySelector('#content');

    // print(article.children.length);

    final list = [];

    for (var i = 0; i < article.children.length; i++) {
      final element = article.children[i];

      // print(element.className);

      if (element.localName == 'p') {
        if (element.children.isNotEmpty &&
            element.children[0].localName == 'img') {
          print(element.children);

          if (element.children[0].localName == 'img') {
            list.add({'img': element.children[0].attributes['src']});
          }
        } else {
          list.add({'text': element.text});
        }
      }
      if (element.localName == 'h4') {
        list.add({'title': element.text});
      }

      if (element.className == 'embed-responsive embed-responsive-16by9') {
        list.add({'video': element.querySelector('iframe').attributes['src']});
      }
    }

    return list;
  }

  static Future<List<ParserSiteResponse>> getNews() async {
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

      return ParserSiteResponse(
        image: img.attributes['src'],
        shortDescription: content.text.trim(),
        title: title.text.trim(),
        url: _BASE_URL_SITE_UFFS + a.attributes['href'],
        date: DateTime.parse(liTags[1].text.trim()),
        author: liTags[0].text.trim(),
        authorImage: liTags[0].querySelector('img').attributes['src'],
      );
    }).toList();

    response.sort((a, b) => a.date.compareTo(b.date));
    return response;
  }
}

class ParserSiteResponse {
  final String image;
  final String url;
  final String title;
  final DateTime date;
  final String author;
  final String authorImage;
  final String shortDescription;

  ParserSiteResponse({
    this.image,
    this.url,
    this.title,
    this.date,
    this.author,
    this.authorImage,
    this.shortDescription,
  });

  Map<String, dynamic> toMap() => {
        'image': image,
        'url': url,
        'title': title,
        'date': date.toIso8601String(),
        'author': author,
        'authorImage': authorImage,
        'shortDescription': shortDescription,
      };

  String listToString(List<ParserSiteResponse> list) {
    return json.encode(list.map((e) => e.toMap()).toList());
  }
}

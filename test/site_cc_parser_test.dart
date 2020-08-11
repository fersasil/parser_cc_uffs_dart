import 'package:site_cc_parser/site_cc_parser.dart';

void main() async {
  // final a = (await Scrapper.getContent(FetchContentFrom.news
  //     'https://cc.uffs.edu.br/noticias/programa-practice/'));
  final a = await Scrapper.getContent(FetchContentFrom.vacancies);
  // print(a);
  await a[0].fetchUrlContent();

  print(a[0].htmlContent.items);
}

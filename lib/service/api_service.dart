import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:localstore/localstore.dart';
import '../model/Article.dart';

class ApiService {
  String apiKey = "74ba9bb09016446e9cd45de54a6e3513";
  final List<String> _categories = ['Business', 'Technology', 'Health', 'Sports'];

  ApiService({required this.apiKey});

  Future<List<Article>> fetchTopHeadlinesByCategory(String category) async {
    final localStorage = Localstore.instance;
    final articles =
        await localStorage.collection('articles').doc(category).get();
    if (articles != null && articles.isNotEmpty) {
      // Trả về dữ liệu từ local storage nếu có
      return List<Article>.from(
          articles['data'].map((article) => Article.fromJson(article)));
    } else {
      // Lấy dữ liệu từ API và ghi vào local storage
      final url = Uri.parse(
          'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=ad9ac20fef9840e790870d8629d8abf7');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> articlesJson = json['articles'];
        final articles =
            articlesJson.map((json) => Article.fromJson(json)).toList();

        // Lưu dữ liệu vào local storage
        await localStorage
            .collection('articles')
            .doc(category)
            .set({'data': articles});

        return articles;
      } else {
        throw Exception('Failed to load top headlines for $category');
      }
    }
  }

  Future<List<Article>> fetchAllCategories() async {
    final localStorage = Localstore.instance;
    final allArticles =
        await localStorage.collection('articles').doc('all').get();
    if (allArticles != null && allArticles.isNotEmpty) {
      // Trả về dữ liệu từ local storage nếu có
      return List<Article>.from(
          allArticles['data'].map((article) => Article.fromJson(article)));
    } else {
      List<Article> allArticles = [];
      for (String category in _categories) {
        List<Article> categoryArticles =
            await fetchTopHeadlinesByCategory(category);
        allArticles.addAll(categoryArticles);
      }
      // Lưu dữ liệu vào local storage
      await localStorage
          .collection('articles')
          .doc('all')
          .set({'data': allArticles});

      return allArticles;
    }
  }

  Future<List<Article>> searchArticles(String query) async {
    final url =
        Uri.parse('https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> articlesJson = json['articles'];
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search articles');
    }
  }
}
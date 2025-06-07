import 'package:flutter/foundation.dart';
import 'package:parking_app/core/api/parking/parking_search_api.dart';
import 'package:parking_app/core/models/parking_search_model.dart';
import 'package:parking_app/core/utils/logger.dart';

/// 駐車場検索サービス - ビジネスロジック層
///
/// API呼び出し、データ変換、エラーハンドリング、状態管理を統合
/// UIコンポーネントとAPI層の間の橋渡しを行う
class ParkingSearchService extends ChangeNotifier {
  final ParkingSearchApi _api;

  // Provider 用: ParkingSearchApi を引数で受け取る
  ParkingSearchService(this._api);

  // ===== 状態管理 =====

  /// 論理名: ローディング状態
  bool _isLoading = false;

  /// 論理名: エラーメッセージ
  String? _error;

  /// 論理名: 検索結果
  List<ParkingLotModel> _searchResults = [];

  /// 論理名: 総件数
  int _totalCount = 0;

  /// 論理名: 現在のページ
  int _currentPage = 1;

  /// 論理名: 1ページあたりの件数
  int _perPage = 20;

  /// 論理名: 総ページ数
  int _totalPages = 0;

  /// 論理名: 次のページがあるか
  bool _hasNext = false;

  /// 論理名: 前のページがあるか
  bool _hasPrev = false;

  /// 論理名: 現在の検索条件
  ParkingSearchRequestModel? _currentSearchRequest;

  /// 論理名: お気に入り駐車場一覧
  List<ParkingLotModel> _favorites = [];

  /// 論理名: お気に入りローディング状態
  bool _isFavoritesLoading = false;

  // ===== ゲッター =====

  /// ローディング状態を取得
  bool get isLoading => _isLoading;

  /// エラーメッセージを取得
  String? get error => _error;

  /// 検索結果を取得
  List<ParkingLotModel> get searchResults => List.unmodifiable(_searchResults);

  /// 総件数を取得
  int get totalCount => _totalCount;

  /// 現在のページを取得
  int get currentPage => _currentPage;

  /// 1ページあたりの件数を取得
  int get perPage => _perPage;

  /// 総ページ数を取得
  int get totalPages => _totalPages;

  /// 次のページがあるかを取得
  bool get hasNext => _hasNext;

  /// 前のページがあるかを取得
  bool get hasPrev => _hasPrev;

  /// 現在の検索条件を取得
  ParkingSearchRequestModel? get currentSearchRequest => _currentSearchRequest;

  /// お気に入り駐車場一覧を取得
  List<ParkingLotModel> get favorites => List.unmodifiable(_favorites);

  /// お気に入りローディング状態を取得
  bool get isFavoritesLoading => _isFavoritesLoading;

  /// 検索結果が空かどうかを判定
  bool get hasSearchResults => _searchResults.isNotEmpty;

  /// エラー状態かどうかを判定
  bool get hasError => _error != null;

  // ===== パブリックメソッド =====

  /// 駐車場検索を実行
  ///
  /// [searchModel] 検索条件
  /// Returns: 検索が成功したかどうか
  Future<bool> searchParkingLots(ParkingSearchRequestModel searchModel) async {
    try {
      _setLoading(true);
      _clearError();
      _currentSearchRequest = searchModel;

      if (kDebugMode) {
        appLogger.debug('🔍 駐車場検索開始: ${searchModel.toJson()}');
      }

      final result = await _api.searchParkingLots(searchModel);

      if (result.isSuccess && result.data != null) {
        _updateSearchResults(result.data!);

        if (kDebugMode) {
          appLogger.debug('✅ 駐車場検索成功: ${_searchResults.length}件');
        }

        return true;
      } else {
        _setError(result.message ?? '駐車場検索に失敗しました');

        if (kDebugMode) {
          appLogger.error('💥 駐車場検索エラー: ${result.message}');
        }

        return false;
      }
    } catch (e) {
      _setError('検索中に予期しないエラーが発生しました: $e');

      if (kDebugMode) {
        appLogger.error('💥 駐車場検索予期しないエラー: $e');
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 次のページを読み込み
  ///
  /// Returns: 読み込みが成功したかどうか
  Future<bool> loadNextPage() async {
    if (!_hasNext || _currentSearchRequest == null) {
      return false;
    }

    final nextPageRequest = _currentSearchRequest!.copyWith(
      page: _currentPage + 1,
    );

    return await searchParkingLots(nextPageRequest);
  }

  /// 前のページを読み込み
  ///
  /// Returns: 読み込みが成功したかどうか
  Future<bool> loadPreviousPage() async {
    if (!_hasPrev || _currentSearchRequest == null) {
      return false;
    }

    final prevPageRequest = _currentSearchRequest!.copyWith(
      page: _currentPage - 1,
    );

    return await searchParkingLots(prevPageRequest);
  }

  /// 指定ページを読み込み
  ///
  /// [page] ページ番号
  /// Returns: 読み込みが成功したかどうか
  Future<bool> loadPage(int page) async {
    if (page < 1 || page > _totalPages || _currentSearchRequest == null) {
      return false;
    }

    final pageRequest = _currentSearchRequest!.copyWith(page: page);
    return await searchParkingLots(pageRequest);
  }

  /// 駐車場詳細を取得
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: 駐車場詳細データ（取得に失敗した場合はnull）
  Future<ParkingLotDetailModel?> getParkingLotDetail(
    String parkingLotId,
  ) async {
    try {
      if (kDebugMode) {
        appLogger.debug('🏢 駐車場詳細取得開始: $parkingLotId');
      }

      final result = await _api.getParkingLotDetail(parkingLotId);

      if (result.isSuccess && result.data != null) {
        if (kDebugMode) {
          appLogger.debug('✅ 駐車場詳細取得成功: ${result.data!.parkingLotName}');
        }

        return result.data;
      } else {
        if (kDebugMode) {
          appLogger.error('💥 駐車場詳細取得エラー: ${result.message}');
        }

        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('💥 駐車場詳細取得予期しないエラー: $e');
      }

      return null;
    }
  }

  /// お気に入りに追加
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: 追加が成功したかどうか
  Future<bool> addToFavorites(String parkingLotId) async {
    try {
      if (kDebugMode) {
        appLogger.debug('❤️ お気に入り追加開始: $parkingLotId');
      }

      final result = await _api.addToFavorites(parkingLotId);

      if (result.isSuccess) {
        // 検索結果内の該当駐車場のお気に入り状態を更新
        _updateFavoriteStatus(parkingLotId, true);

        // お気に入り一覧を再取得
        await loadFavorites();

        if (kDebugMode) {
          appLogger.debug('✅ お気に入り追加成功');
        }

        return true;
      } else {
        if (kDebugMode) {
          appLogger.error('💥 お気に入り追加エラー: ${result.message}');
        }

        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('💥 お気に入り追加予期しないエラー: $e');
      }

      return false;
    }
  }

  /// お気に入りから削除
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: 削除が成功したかどうか
  Future<bool> removeFromFavorites(String parkingLotId) async {
    try {
      if (kDebugMode) {
        appLogger.debug('💔 お気に入り削除開始: $parkingLotId');
      }

      final result = await _api.removeFromFavorites(parkingLotId);

      if (result.isSuccess) {
        // 検索結果内の該当駐車場のお気に入り状態を更新
        _updateFavoriteStatus(parkingLotId, false);

        // お気に入り一覧を再取得
        await loadFavorites();

        if (kDebugMode) {
          appLogger.debug('✅ お気に入り削除成功');
        }

        return true;
      } else {
        if (kDebugMode) {
          appLogger.error('💥 お気に入り削除エラー: ${result.message}');
        }

        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('💥 お気に入り削除予期しないエラー: $e');
      }

      return false;
    }
  }

  /// お気に入り状態を切り替え
  ///
  /// [parkingLotId] 駐車場ID
  /// [currentStatus] 現在のお気に入り状態
  /// Returns: 切り替えが成功したかどうか
  Future<bool> toggleFavorite(String parkingLotId, bool currentStatus) async {
    if (currentStatus) {
      return await removeFromFavorites(parkingLotId);
    } else {
      return await addToFavorites(parkingLotId);
    }
  }

  /// お気に入り一覧を読み込み
  ///
  /// [page] ページ番号（デフォルト: 1）
  /// [perPage] 1ページあたりの件数（デフォルト: 20）
  /// Returns: 読み込みが成功したかどうか
  Future<bool> loadFavorites({int page = 1, int perPage = 20}) async {
    try {
      _setFavoritesLoading(true);

      if (kDebugMode) {
        appLogger.debug('💖 お気に入り一覧読み込み開始: page=$page, perPage=$perPage');
      }

      final result = await _api.getFavorites(page: page, perPage: perPage);

      if (result.isSuccess && result.data != null) {
        _favorites = result.data!.parkingLots;
        notifyListeners();

        if (kDebugMode) {
          appLogger.debug('✅ お気に入り一覧読み込み成功: ${_favorites.length}件');
        }

        return true;
      } else {
        if (kDebugMode) {
          appLogger.error('💥 お気に入り一覧読み込みエラー: ${result.message}');
        }

        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        appLogger.error('💥 お気に入り一覧読み込み予期しないエラー: $e');
      }

      return false;
    } finally {
      _setFavoritesLoading(false);
    }
  }

  /// 検索条件をリセット
  void resetSearch() {
    _searchResults = [];
    _totalCount = 0;
    _currentPage = 1;
    _totalPages = 0;
    _hasNext = false;
    _hasPrev = false;
    _currentSearchRequest = null;
    _clearError();
    notifyListeners();

    if (kDebugMode) {
      appLogger.debug('🔄 検索条件リセット完了');
    }
  }

  /// エラーをクリア
  void clearError() {
    _clearError();
  }

  // ===== プライベートメソッド =====

  /// ローディング状態を設定
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// お気に入りローディング状態を設定
  void _setFavoritesLoading(bool loading) {
    if (_isFavoritesLoading != loading) {
      _isFavoritesLoading = loading;
      notifyListeners();
    }
  }

  /// エラーを設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// エラーをクリア
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// 検索結果を更新
  void _updateSearchResults(ParkingSearchResponse response) {
    _searchResults = response.parkingLots;
    _totalCount = response.totalCount;
    _currentPage = response.currentPage;
    _perPage = response.perPage;
    _totalPages = response.totalPages;
    _hasNext = response.hasNext;
    _hasPrev = response.hasPrev;
    notifyListeners();
  }

  /// お気に入り状態を更新
  void _updateFavoriteStatus(String parkingLotId, bool isFavorite) {
    bool updated = false;

    // 検索結果内の該当駐車場を更新
    for (int i = 0; i < _searchResults.length; i++) {
      if (_searchResults[i].parkingLotId == parkingLotId) {
        _searchResults[i] = _searchResults[i].copyWith(isFavorite: isFavorite);
        updated = true;
        break;
      }
    }

    // お気に入り一覧内の該当駐車場を更新
    for (int i = 0; i < _favorites.length; i++) {
      if (_favorites[i].parkingLotId == parkingLotId) {
        if (!isFavorite) {
          // お気に入りから削除された場合はリストから除去
          _favorites.removeAt(i);
        } else {
          // お気に入り状態を更新
          _favorites[i] = _favorites[i].copyWith(isFavorite: isFavorite);
        }
        updated = true;
        break;
      }
    }

    if (updated) {
      notifyListeners();
    }
  }

  // ===== ユーティリティメソッド =====

  /// 指定された駐車場がお気に入りかどうかを判定
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: お気に入りかどうか
  bool isFavorite(String parkingLotId) {
    return _favorites.any((parking) => parking.parkingLotId == parkingLotId);
  }

  /// 検索結果から指定IDの駐車場を取得
  ///
  /// [parkingLotId] 駐車場ID
  /// Returns: 駐車場データ（見つからない場合はnull）
  ParkingLotModel? findParkingLotById(String parkingLotId) {
    try {
      return _searchResults.firstWhere(
        (parking) => parking.parkingLotId == parkingLotId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 距離による並び替え
  ///
  /// [ascending] 昇順かどうか（デフォルト: true）
  void sortByDistance({bool ascending = true}) {
    _searchResults.sort((a, b) {
      if (a.distance == null && b.distance == null) return 0;
      if (a.distance == null) return ascending ? 1 : -1;
      if (b.distance == null) return ascending ? -1 : 1;

      return ascending
          ? a.distance!.compareTo(b.distance!)
          : b.distance!.compareTo(a.distance!);
    });
    notifyListeners();
  }

  /// 料金による並び替え
  ///
  /// [ascending] 昇順かどうか（デフォルト: true）
  void sortByPrice({bool ascending = true}) {
    _searchResults.sort((a, b) {
      if (a.hourlyRate == null && b.hourlyRate == null) return 0;
      if (a.hourlyRate == null) return ascending ? 1 : -1;
      if (b.hourlyRate == null) return ascending ? -1 : 1;

      return ascending
          ? a.hourlyRate!.compareTo(b.hourlyRate!)
          : b.hourlyRate!.compareTo(a.hourlyRate!);
    });
    notifyListeners();
  }

  /// 評価による並び替え
  ///
  /// [ascending] 昇順かどうか（デフォルト: false）
  void sortByRating({bool ascending = false}) {
    _searchResults.sort((a, b) {
      if (a.rating == null && b.rating == null) return 0;
      if (a.rating == null) return ascending ? 1 : -1;
      if (b.rating == null) return ascending ? -1 : 1;

      return ascending
          ? a.rating!.compareTo(b.rating!)
          : b.rating!.compareTo(a.rating!);
    });
    notifyListeners();
  }

  @override
  void dispose() {
    // リソースクリーンアップ
    _api.dispose();

    if (kDebugMode) {
      appLogger.debug('🧹 ParkingSearchService disposed');
    }

    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:parking_app/views/parking/parking_search_screen.dart';
import 'package:parking_app/views/reservation/reservation_confirmation_screen.dart'
    as confirmation;
import 'package:parking_app/views/reservation/reservation_usage_datetime_screen.dart';
import 'package:parking_app/views/auth/signin_screen.dart';
import 'package:parking_app/views/user/user_home_screen.dart';

class DummyScreen extends StatelessWidget {
  const DummyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dummy UI 画面')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Dummy UI 画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ParkingSearchScreen(),
                  ),
                );
              },
              child: const Text('駐車場検索画面へ'),
            ),
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: () {
            //     // 要件に合わせて修正されたAuthUserModelの作成
            //     final dummyUser = AuthUserModel(
            //       id: 'user_123456',
            //       name: 'テストユーザー',
            //       email: 'test@example.com',
            //       phoneNumber: '090-1234-5678',
            //       avatarUrl: null,
            //       token: 'dummy_user_token',
            //       refreshToken: 'dummy_user_refresh_token',
            //       isEmailVerified: true,
            //       role: 'user',
            //     );

            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder:
            //             (context) =>
            //                 HomePage(authUserModel: dummyUser, isOwner: false),
            //       ),
            //     );
            //   },
            //   child: const Text('ユーザーホーム画面へ'),
            // ),
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: () {
            //     try {
            //       // 要件に合わせて修正されたオーナー用AuthUserModelの作成
            //       final dummyOwner = AuthUserModel(
            //         id: 'owner_654321',
            //         name: 'オーナーさん',
            //         email: 'owner@example.com',
            //         phoneNumber: '090-8765-4321',
            //         avatarUrl: 'https://example.com/avatar.jpg',
            //         token: 'dummy_owner_token',
            //         refreshToken: 'dummy_owner_refresh_token',
            //         isEmailVerified: true,
            //         role: 'owner',
            //       );

            //       Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder:
            //               (context) => HomePage(
            //                 authUserModel: dummyOwner,
            //                 isOwner: true,
            //               ),
            //         ),
            //       );
            //     } catch (e) {
            //       // エラー発生時にスナックバーで表示
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(
            //           content: Text('エラーが発生しました: $e'),
            //           backgroundColor: Colors.red,
            //         ),
            //       );
            //       print('Error: $e');
            //     }
            //   },
            //   style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            //   child: const Text('オーナーホーム画面へ'),
            // ),
            // const SizedBox(height: 16),
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (context) => const ReservationDetailScreen(),
            //       ),
            //     );
            //   },
            //   child: const Text('予約「詳細」画面へ'),
            // ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => UserHomeScreen(user_id: 'user_000001'),
                  ),
                );
              },
              child: const Text('ユーザーホーム画面へ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => const ReservationUsageDatetimeScreen(),
                  ),
                );
              },
              child: const Text('利用日時選択画面へ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            const confirmation.ReservationConfirmationScreen(),
                  ),
                );
              },
              child: const Text('予約「確認」画面へ'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: const Text('サインイン画面へ'),
            ),
          ],
        ),
      ),
    );
  }
}

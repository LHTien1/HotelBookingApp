import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:booking_app/models/room_model.dart';

import 'package:booking_app/providers/auth_providers.dart';
import 'package:booking_app/providers/booking_providers.dart';
import 'package:booking_app/providers/chat_providers.dart';
import 'package:booking_app/providers/hotel_providers.dart';
import 'package:booking_app/providers/notification_provider.dart';
import 'package:booking_app/providers/report_providers.dart' as rpt; // ✅ ALIAS
import 'package:booking_app/providers/theme_provider.dart';

// ✅ SETTINGS
import 'package:booking_app/screens/settings/general_settings_screen.dart'
    show GeneralSettingsScreen;

// ✅ chỉ lấy đúng class cần dùng
import 'package:booking_app/screens/admin/approve_rooms_screen.dart'
    show ApproveRoomsScreen;
import 'package:booking_app/screens/admin/monitor_bookings_screen.dart'
    show MonitorBookingsScreen;
import 'package:booking_app/screens/admin/reports_screen.dart'
    show ReportsScreen;

import 'package:booking_app/screens/auth/login_screen.dart' show LoginScreen;
import 'package:booking_app/screens/auth/register_screen.dart'
    show RegisterScreen;

import 'package:booking_app/screens/chat/chat_list_screen.dart'
    show ChatListScreen;
import 'package:booking_app/screens/chat/chat_screen.dart' show ChatScreen;

import 'package:booking_app/screens/home_screen.dart' show HomeScreen;

import 'package:booking_app/screens/hotel_owner/manage_rooms_screen.dart'
    show ManageRoomsScreen;
import 'package:booking_app/screens/hotel_owner/post_room_screen.dart'
    show PostRoomScreen;
import 'package:booking_app/screens/hotel_owner/revenue_stats_screen.dart'
    show RevenueStatsScreen;
import 'package:booking_app/screens/hotel_owner/reviews_screen.dart'
    show ReviewsScreen;
import 'package:booking_app/screens/admin/room_detail_admin_screen.dart'
    show AdminRoomDetailScreen;

// ✅ NEW: màn chọn khách sạn
import 'package:booking_app/screens/hotel_owner/select_hotel_screen.dart'
    show SelectHotelScreen;

import 'package:booking_app/screens/notifications/notifications_screen.dart'
    show NotificationsScreen;

import 'package:booking_app/screens/room_details_screen.dart'
    show RoomDetailsScreen;
import 'package:booking_app/screens/search/search_screen.dart'
    show SearchScreen;

import 'package:booking_app/screens/user/add_report_screen.dart' as user_report;

import 'package:booking_app/screens/user/add_review_screen.dart'
    show AddReviewScreen;
import 'package:booking_app/screens/user/booking_screen.dart'
    show BookingScreen;
import 'package:booking_app/screens/user/edit_profile_screen.dart'
    show EditProfileScreen;
import 'package:booking_app/screens/user/my_booking_screen.dart'
    show MyBookingsScreen;
import 'package:booking_app/screens/user/profile_screen.dart'
    show ProfileScreen;
import 'package:booking_app/screens/user/vnpay_payment_screen.dart'
    show VNPayPaymentScreen, VNPayResultScreen;
import 'package:booking_app/screens/user/momo_payment_screen.dart'
    show MomoPaymentScreen, MomoResultScreen;
import 'package:app_links/app_links.dart';

import 'package:booking_app/services/firebase_services.dart'
    show FirebaseService;

import 'package:booking_app/intro/splash_screen.dart' show SplashScreen;
import 'package:booking_app/intro/home_before_login.dart' show HomeBeforeLogin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.loadAll();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HotelProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => rpt.ReportProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Handle incoming links when app is running
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });

    // Handle initial link if app was launched from a link
    _appLinks.getInitialLink().then((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    // Check if this is a VNPay return URL
    if (uri.scheme == 'bookingapp' &&
        uri.host == 'vnpay' &&
        uri.path.startsWith('/return')) {
      final queryParams = uri.queryParameters;

      // Navigate to result screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamed(VNPayResultScreen.routeName, arguments: queryParams);
      });
    }

    // Check if this is a Momo return URL
    if (uri.scheme == 'bookingapp' &&
        uri.host == 'momo' &&
        uri.path.startsWith('/return')) {
      final queryParams = uri.queryParameters;

      // Navigate to result screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushNamed(MomoResultScreen.routeName, arguments: queryParams);
      });
    }
  }

  // ===================== Helpers =====================
  static Widget _routeError(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lỗi điều hướng')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  static String? _readHotelId(dynamic args) {
    if (args is String) return args.trim();
    if (args is Map && args['hotelId'] != null) {
      return args['hotelId'].toString().trim();
    }
    return null;
  }

  static String? _readHotelName(dynamic args) {
    if (args is Map && args['hotelName'] != null) {
      return args['hotelName'].toString().trim();
    }
    return null;
  }

  static RoomModel? _readRoom(dynamic args) {
    if (args is RoomModel) return args;
    if (args is Map && args['room'] is RoomModel) {
      return args['room'] as RoomModel;
    }
    return null;
  }

  // ===================== Themes (mockup) =====================
  ThemeData _lightTheme() {
    // mockup light: nền #F5F7F8, primary #11A7F2
    const seed = Color(0xFF11A7F2);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    final cs = base.copyWith(
      primary: const Color(0xFF11A7F2),
      secondary: const Color(0xFF22C55E),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFF1F5F9),
      outlineVariant: const Color(0xFFE2E8F0),
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF64748B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F7F8),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: cs.onSurface,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: cs.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.45),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  ThemeData _darkTheme() {
    // mockup dark admin: nền #0F1B23, surface #1A2C38, primary #1FADF3
    const seed = Color(0xFF1FADF3);
    final base = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    final cs = base.copyWith(
      primary: const Color(0xFF1FADF3),
      secondary: const Color(0xFF34D399),
      surface: const Color(0xFF1A2C38),
      surfaceContainerHighest: const Color(0xFF223947),
      outlineVariant: const Color(0xFF2C4B5E),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFB6C2CF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF0F1B23),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: cs.onSurface,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),

      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F1B23),
        selectedItemColor: cs.primary,
        unselectedItemColor: Colors.white.withValues(alpha: 0.55),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  // ✅ Sync role an toàn: không đè role khi user đang switch trong HomeScreen
  void _syncRole(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final auth = context.read<AuthProvider>();

    final desiredRole = auth.currentUser?.role; // null = guest
    final currentRole = themeProvider.currentRole;

    // Logout: về guest
    if (auth.currentUser == null) {
      if (currentRole != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          themeProvider.setCurrentRole(null);
        });
      }
      return;
    }

    // Login lần đầu: nếu currentRole chưa set -> set theo role user
    if (currentRole == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        themeProvider.setCurrentRole(desiredRole);
      });
    }

    // Nếu currentRole đã có (do HomeScreen switch) => KHÔNG đè
  }

  @override
  Widget build(BuildContext context) {
    _syncRole(context);

    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Booking App',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.mode,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const AuthWrapper(),
        '/intro': (context) => const HomeBeforeLogin(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        '/search': (context) => const SearchScreen(),
        '/my-bookings': (context) => const MyBookingsScreen(),

        '/chat-list': (context) => const ChatListScreen(),

        '/approve-rooms': (context) => const ApproveRoomsScreen(),
        '/monitor-bookings': (context) => const MonitorBookingsScreen(),
        '/reports': (context) => const ReportsScreen(),

        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),

        // ✅ Notifications: map cả 2 để khỏi lệch routeName trong các file khác nhau
        '/notifications': (context) => const NotificationsScreen(),

        RoomDetailsScreen.routeName: (context) => const RoomDetailsScreen(),

        '/reviews': (context) => const ReviewsScreen(),
        '/revenue-stats': (context) => const RevenueStatsScreen(),

        // ✅ SETTINGS ROUTE
        GeneralSettingsScreen.routeName: (context) =>
            const GeneralSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/manage-rooms':
            {
              final hotelId = _readHotelId(settings.arguments);
              final hotelName = _readHotelName(settings.arguments);

              if (hotelId == null || hotelId.isEmpty) {
                return MaterialPageRoute(
                  builder: (_) => const SelectHotelScreen(
                    targetRoute: '/manage-rooms',
                    title: 'Chọn khách sạn để quản lý phòng',
                  ),
                );
              }

              return MaterialPageRoute(
                builder: (_) => ManageRoomsScreen(
                  hotelId: hotelId,
                  hotelName: (hotelName != null && hotelName.isNotEmpty)
                      ? hotelName
                      : null,
                ),
              );
            }

          case '/room-detail':
            {
              final args = settings.arguments;
              final hotelId = _readHotelId(args);
              final hotelName = _readHotelName(args);
              final room = _readRoom(args);

              if (room == null) {
                return MaterialPageRoute(
                  builder: (_) => _routeError(
                    "Thiếu RoomModel cho '/room-detail'.\n\n"
                    "Gọi đúng:\n"
                    "Navigator.pushNamed(context, '/room-detail', arguments: {\n"
                    "  'hotelId': hotelId,\n"
                    "  'hotelName': hotelName,\n"
                    "  'room': room,\n"
                    "});",
                  ),
                );
              }

              final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                  ? hotelId
                  : room.hotelId;

              if (effectiveHotelId.isEmpty) {
                return MaterialPageRoute(
                  builder: (_) => _routeError(
                    "Thiếu hotelId cho '/room-detail'.\n\n"
                    "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                  ),
                );
              }

              return MaterialPageRoute(
                builder: (_) => AdminRoomDetailScreen(
                  hotelId: effectiveHotelId,
                  hotelName: (hotelName != null && hotelName.isNotEmpty)
                      ? hotelName
                      : null,
                  room: room,
                ),
              );
            }

          case '/post-room':
            {
              final args = settings.arguments;
              final hotelId = _readHotelId(args);
              final hotelName = _readHotelName(args);
              final room = _readRoom(args);

              final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                  ? hotelId
                  : (room?.hotelId);

              if ((effectiveHotelId == null || effectiveHotelId.isEmpty) &&
                  room == null) {
                return MaterialPageRoute(
                  builder: (_) => const SelectHotelScreen(
                    targetRoute: '/post-room',
                    title: 'Chọn khách sạn để đăng phòng',
                  ),
                );
              }

              if (effectiveHotelId == null || effectiveHotelId.isEmpty) {
                return MaterialPageRoute(
                  builder: (_) => _routeError(
                    "Thiếu hotelId cho '/post-room'.\n\n"
                    "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                  ),
                );
              }

              return MaterialPageRoute(
                builder: (_) => PostRoomScreen(
                  hotelId: effectiveHotelId,
                  hotelName: (hotelName != null && hotelName.isNotEmpty)
                      ? hotelName
                      : null,
                  room: room,
                ),
              );
            }

          case '/edit-room':
            {
              final args = settings.arguments;
              final hotelId = _readHotelId(args);
              final hotelName = _readHotelName(args);
              final room = _readRoom(args);

              if (room == null) {
                return MaterialPageRoute(
                  builder: (_) => _routeError(
                    "Thiếu RoomModel cho '/edit-room'.\n\n"
                    "Gọi đúng:\n"
                    "Navigator.pushNamed(context, '/edit-room', arguments: {\n"
                    "  'hotelId': hotelId,\n"
                    "  'hotelName': hotelName,\n"
                    "  'room': room,\n"
                    "});",
                  ),
                );
              }

              final effectiveHotelId = (hotelId != null && hotelId.isNotEmpty)
                  ? hotelId
                  : room.hotelId;

              if (effectiveHotelId.isEmpty) {
                return MaterialPageRoute(
                  builder: (_) => _routeError(
                    "Thiếu hotelId khi sửa phòng.\n\n"
                    "Hãy truyền Map {'hotelId','hotelName','room'} hoặc đảm bảo room.hotelId có dữ liệu.",
                  ),
                );
              }

              return MaterialPageRoute(
                builder: (_) => PostRoomScreen(
                  hotelId: effectiveHotelId,
                  hotelName: (hotelName != null && hotelName.isNotEmpty)
                      ? hotelName
                      : null,
                  room: room,
                ),
              );
            }

          case '/booking':
            {
              final room = settings.arguments as RoomModel;
              return MaterialPageRoute(
                builder: (_) => BookingScreen(room: room),
              );
            }

          case VNPayPaymentScreen.routeName:
            {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => VNPayPaymentScreen(
                  bookingId: args['bookingId']! as String,
                  room: args['room']! as RoomModel,
                  totalAmount: args['totalAmount']! as double,
                  checkInDate: args['checkInDate']! as DateTime,
                  checkOutDate: args['checkOutDate']! as DateTime,
                ),
              );
            }

          case VNPayResultScreen.routeName:
            {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (_) => VNPayResultScreen(queryParams: args),
              );
            }

          case MomoPaymentScreen.routeName:
            {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => MomoPaymentScreen(
                  bookingId: args['bookingId']! as String,
                  room: args['room']! as RoomModel,
                  totalAmount: args['totalAmount']! as double,
                  checkInDate: args['checkInDate']! as DateTime,
                  checkOutDate: args['checkOutDate']! as DateTime,
                ),
              );
            }

          case MomoResultScreen.routeName:
            {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (_) => MomoResultScreen(queryParams: args),
              );
            }

          case '/add-review':
            {
              final args = settings.arguments as Map;
              return MaterialPageRoute(
                builder: (_) => AddReviewScreen(
                  roomId: args['roomId']!.toString(),
                  hotelId: args['hotelId']!.toString(),
                ),
              );
            }

          case '/add-report':
            {
              final args = settings.arguments as Map;
              final hotelId = args['hotelId']?.toString() ?? '';
              final roomId = args['roomId']?.toString();

              if (hotelId.trim().isEmpty) {
                return MaterialPageRoute(
                  builder: (_) =>
                      _routeError("Thiếu hotelId cho '/add-report'."),
                );
              }

              return MaterialPageRoute(
                builder: (_) => user_report.AddReportScreen(
                  hotelId: hotelId.trim(),
                  roomId: roomId,
                  hotelName: args['hotelName']?.toString(),
                  roomLabel: args['roomLabel']?.toString(),
                  address: args['address']?.toString(),
                  thumbnailUrl: args['thumbnailUrl']?.toString(),
                ),
              );
            }

          case '/chat':
            {
              final args = settings.arguments as Map<String, String>;
              return MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: args['chatId']!,
                  currentUserId: args['currentUserId']!,
                  otherUserName: args['otherUserName']!,
                ),
              );
            }

          default:
            return null;
        }
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => _routeError("Route không tồn tại: ${settings.name}"),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (auth.isLoggedIn && auth.currentUser != null) {
          return const HomeScreen();
        }

        return const HomeBeforeLogin();
      },
    );
  }
}

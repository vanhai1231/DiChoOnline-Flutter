Flutter Online Market App 🛒

Ứng dụng chợ online được xây dựng bằng Flutter và Dart, cung cấp trải nghiệm mua sắm trực tuyến tiện lợi và an toàn.

Tính năng chính 🌟

- Xác thực người dùng: Đăng ký, đăng nhập bằng email/số điện thoại
- Quản lý sản phẩm: Tìm kiếm, lọc, xem chi tiết, đánh giá sản phẩm
- Giỏ hàng: Thêm/xóa sản phẩm, cập nhật số lượng, tính tổng tiền
- Thanh toán: Hỗ trợ nhiều phương thức (COD, Banking, E-wallet)
- Quản lý đơn hàng: Theo dõi trạng thái, lịch sử mua hàng
- Chat: Nhắn tin trực tiếp với người bán

Công nghệ sử dụng 🛠

- Frontend: Flutter, Dart
- Backend: Firebase (Authentication, Firestore, Storage)
- State Management: Provider/Bloc
- Database: Cloud Firestore
- Payment Integration: Stripe/PayPal
- Push Notifications: Firebase Cloud Messaging

Cấu trúc project 📁

```
lib/
├── config/          # Cấu hình ứng dụng
├── models/          # Data models
├── screens/         # Màn hình UI
├── widgets/         # Widget tái sử dụng
├── services/        # API, services
├── utils/           # Helper functions
└── main.dart        # Entry point
```

Yêu cầu cài đặt 📋

- Flutter SDK >= 3.0.0
- Dart >= 2.17.0
- Android Studio/VS Code
- Firebase project setup

 Hướng dẫn cài đặt 🚀

1. Clone repository: 
git clone https://github.com/vanhai1231/DiChoOnline-Flutter.git

2. Cài đặt dependencies

flutter pub get


3. Cấu hình Firebase
- Thêm file `google-services.json` vào `/android/app`
- Thêm file `GoogleService-Info.plist` vào `/ios/Runner`

4. Chạy ứng dụng
flutter run


License 📄

MIT License - Xem file [LICENSE.md](LICENSE.md) để biết thêm chi tiết

Đóng góp 🤝

Nhóm 2:

1. Hà Văn Hải
2. Đinh Trọng Khang
3. Nguyễn Hữu Khải
4. Đặng Trần Tiến Dũng
Mọi thắc mắc vui lòng liên hệ gmail: vanhai11203@gmail.com

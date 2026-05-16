Quy trình Git & Setup cho team

📌 Cấu trúc nhánh
main          # Production - chỉ leader được merge
develop       # Nhánh tích hợp chính
feature/tuan  # Nhánh của Tuấn
feature/tho   # Nhánh của Thọ
feature/duy   # Nhánh của Duy

⚙️ Setup lần đầu khi clone project
Sau khi clone repo về, chạy lần lượt các lệnh sau:
[flutter pub get]
[flutter pub run build_runner build --delete-conflicting-outputs]

⚠️ Bắt buộc chạy để generate các file .g.dart, nếu không sẽ bị lỗi khi build.

🪟 Windows: Flutter SDK trên C: nhưng repo trên E: (ổ khác)
Nếu `flutter pub get` báo lỗi symlink plugin (`ERROR_INVALID_FUNCTION`), làm một trong hai:
- Bật **Settings → Privacy & security → For developers → Developer Mode**, hoặc
- Mở project qua junction cùng ổ C: (ví dụ đã tạo): `C:\dev\FE_SOSBIKE_Flutter` → trùng nội dung với thư mục repo thật. Chạy `flutter pub get` / `dart run build_runner build` trong đường dẫn đó.
Tạo lại junction (thay đúng đường dẫn repo của bạn): `cmd /c mklink /J C:\dev\FE_SOSBIKE_Flutter E:\đường\dẫn\FE_SOSBIKE_Flutter`


🔄 Quy trình làm việc hàng ngày
1. Trước khi bắt đầu code - pull code mới nhất về:
git checkout develop
git pull origin develop
git checkout feature/tên-bạn
git merge develop
2. Sau khi pull - chạy lại lệnh generate:
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
3. Code xong - push lên nhánh cá nhân:
git add .
git commit -m "mô tả ngắn những gì bạn đã làm"
git push origin feature/tên-bạn
4. Tạo Pull Request vào develop:

Vào GitHub → nhấn "Compare & pull request"
Chọn merge vào develop (không phải main)
Mô tả những thay đổi → nhấn "Create pull request"

5. Merge vào main:

Chỉ leader được merge từ develop → main
Sau khi tính năng hoàn chỉnh và đã test kỹ


✅ Quy tắc commit message
feat: thêm tính năng mới
fix: sửa lỗi
update: cập nhật code
refactor: tối ưu code
Ví dụ:
git commit -m "feat: thêm màn hình đăng nhập"
git commit -m "fix: sửa lỗi call API post"

⚠️ Lưu ý quan trọng

❌ Không push thẳng lên main
❌ Không push file build/ và các file .g.dart lên repo
✅ Luôn pull code mới nhất trước khi bắt đầu code
✅ Luôn chạy build_runner sau khi pull về

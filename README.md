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

🪟 Windows: repo trên ổ ngoài / ổ khác
- Nếu ổ đựng project là **NTFS**: `ERROR_INVALID_FUNCTION` thường hết khi bật **Developer Mode** hoặc làm việc qua junction trên **NTFS** (vd. `C:\dev\FE_SOSBIKE_Flutter` trỏ tới repo).
- Nếu ổ là **exFAT** (nhiều ổ SSD di động): Windows **không tạo được symlink** cho thư mục `windows/.../plugin_symlinks` → `flutter pub get` vẫn lỗi. Làm một trong hai:
  - Clone / copy project sang phân vùng **NTFS** (ổ C hoặc ổ nội bộ NTFS) để build; hoặc
  - Giữ app **Android/iOS/Web** và bỏ platform **Windows** trong repo (thư mục `windows/` không có) — chỉ dùng khi team không cần build desktop Windows.
- Có thể đặt `PUB_CACHE` trên cùng ổ SDK/project (vd. User env `PUB_CACHE=E:\pub-cache`) để giảm chỗ C:; **exFAT vẫn không symlink** nên không thay thế NTFS.
Tạo junction (NTFS → repo): `cmd /c mklink /J C:\dev\FE_SOSBIKE_Flutter E:\đường\dẫn\FE_SOSBIKE_Flutter`


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

# Nguồn ảnh tham khảo loại phòng

Ứng dụng tải trực tiếp các URL ảnh HTTPS dưới đây. Đây là ảnh tham khảo tìm qua tìm kiếm hình ảnh, không phải ảnh thực tế của các nhà trọ trong dữ liệu mẫu. Google là công cụ tìm kiếm; ảnh được tải từ website nguồn.

| Loại phòng | Trang nguồn | URL ảnh |
|---|---|---|
| Studio | [Phongtro123 – Studio Trần Duy Hưng](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/4f462a177212b04ce90323_1659520123.jpg |
| Phòng ban công | [Phongtro123 – CHDV Master ban công](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415474499-f37e78d3842cb00c00e93a8741eaf8c8_1693974014.jpg |
| Phòng có gác | [Thư Viện Nhà Đất – Phòng Phan Văn Sửu](https://thuviennhadat.vn/cho-thue-can-ho-chung-cu-phuong-13/cho-thue-can-ho-chung-cu-30m2-full-noi-that-cua-so-tai-duong-phan-van-suu-tan-binh-tien-loi-di-lai-va-an-ninh-tot-pst3074.html) | https://cdn.thuviennhadat.vn/upload/tin-dang/hinh-anh/20250311144334/20250311144334638773010148943147.jpg |
| Phòng ở nhóm | [Reatimes – Nhà trọ dạng homestay](https://dulich.reatimes.vn/no-ro-xu-huong-nha-tro-cao-cap-tien-ich-dang-homestay-20236542.htm) | https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/6084966023202165616342311685105387516198912n.jpg |

Đường dẫn khai báo trong `lib/pages/shared/media/room_photo.dart`. Bộ ảnh cũ trong SQLite được đổi sang ảnh online khi đọc lại dữ liệu; ảnh người dùng tự thêm không bị thay thế. Nếu tải thất bại, giao diện hiển thị trạng thái không tải được ảnh.

# Nguồn ảnh tham khảo loại phòng

## Bổ sung từ endpoint JSON Nhà Tốt / Chợ Tốt

Đã lấy 28 album qua `https://gateway.chotot.com/v1/public/ad-listing` (chuyên mục `cg=1050`), chọn và nén 83 ảnh WebP; đã bỏ một ảnh trùng. Kết hợp 18 ảnh cũ thành 101 ảnh, khoảng 2,21 MiB. Loại phòng ở mỗi nhà dùng album khác nhau; ảnh tự chọn và album đã xóa được giữ nguyên.

Đây là endpoint JSON đang truy cập được của website, không phải API đối tác có cam kết ổn định. Những lần GET đã kiểm tra không cần API key. Không dùng endpoint chi tiết đang trả 403, không lấy số điện thoại hay hồ sơ người đăng.

ID tin, URL nguồn và SHA256: [manifest](../assets/images/rental_api/manifest.json). Danh sách Flutter sinh tại `lib/pages/shared/media/rental_api_photos.dart`. Đã xem contact sheet và sửa nhóm ảnh trong `tool/rental_photo_review.json`; phân loại tự động theo tiêu đề chỉ là gợi ý.

```powershell
python tool/import_rental_photos.py --limit 24 --per-listing 3
python tool/import_rental_photos.py --limit 4 --per-listing 3 --keyword ktx --append
python -m unittest discover -s tool -p test_rental_photo_api.py
```

Ảnh chỉ minh họa cho dữ liệu mẫu. Tin thật, giá, địa chỉ và liên hệ không được gán thành phòng do app quản lý. [Chuyên mục phòng trọ Nhà Tốt](https://www.nhatot.com/thue-phong-tro).

## Các ảnh gốc giữ lại

Ứng dụng dùng ảnh minh họa WebP đi kèm tại `assets/images/room_types/`, không cần tải ảnh mẫu qua mạng khi mở danh sách. 18 ảnh có tổng dung lượng 419.314 byte (khoảng 410 KiB), cạnh dài tối đa 800 px. Đây là ảnh tham khảo, không phải ảnh thực tế của các nhà trọ mẫu. Ảnh người dùng tự chọn vẫn được ưu tiên.

| Loại phòng | Trang nguồn | URL ảnh |
|---|---|---|
| Studio | [Phongtro123 – Studio Trần Duy Hưng](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/4f462a177212b04ce90323_1659520123.jpg |
| Phòng ban công | [Phongtro123 – CHDV Master ban công](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415474499-f37e78d3842cb00c00e93a8741eaf8c8_1693974014.jpg |
| Phòng có gác | [Thư Viện Nhà Đất – Phòng Phan Văn Sửu](https://thuviennhadat.vn/cho-thue-can-ho-chung-cu-phuong-13/cho-thue-can-ho-chung-cu-30m2-full-noi-that-cua-so-tai-duong-phan-van-suu-tan-binh-tien-loi-di-lai-va-an-ninh-tot-pst3074.html) | https://cdn.thuviennhadat.vn/upload/tin-dang/hinh-anh/20250311144334/20250311144334638773010148943147.jpg |
| Phòng ở nhóm | [Reatimes – Nhà trọ dạng homestay](https://dulich.reatimes.vn/no-ro-xu-huong-nha-tro-cao-cap-tien-ich-dang-homestay-20236542.htm) | https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/6084966023202165616342311685105387516198912n.jpg |

Hai ảnh nội thất bổ sung dùng minh họa cho thẻ nhà trọ:

- `interior.webp`: [Max Vakhtbovych — Pexels](https://www.pexels.com/photo/interior-of-miniature-modern-apartment-with-furniture-6447390/).
- `cozy.webp`: [Amina Filkins — Pexels](https://www.pexels.com/photo/part-of-cozy-bedroom-in-apartment-5425123/).

Đường dẫn khai báo trong `lib/pages/shared/media/room_photo.dart`. Album mẫu cũ dùng đúng các URL trên được ánh xạ sang ảnh đi kèm khi đọc; ảnh riêng và album người dùng chủ động xóa vẫn được giữ nguyên. URL nguồn được giữ để đối chiếu.

## Album bổ sung

Mỗi loại phòng có 2 góc ảnh; 10 nhà trọ có ảnh đại diện nội thất khác nhau. Ảnh có thể cùng một căn hộ nhưng khác góc chụp; không khẳng định đây là nhà trọ thực tế. Giữ nguyên watermark và nguồn.

| Asset | Trang nguồn | Ảnh gốc |
|---|---|---|
| `studio_2.webp` | [Source](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/5fe176b02eb5ecebb5a425_1659520123.jpg |
| `balcony_2.webp` | [Source](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415416997-d41e37ed1dbd28297236857bebfb0713_1693974007.jpg |
| `loft_2.webp` | [Source](https://phongtro.vn/cho-thue-phong-tro-phuong-binh-trung-tp-ho-chi-minh/328097) | https://file.phongtro.vn/2/rent_1791879384402_0_f7f5fefaed.jpg |
| `group_2.webp` | [Source](https://dulich.reatimes.vn/no-ro-xu-huong-nha-tro-cao-cap-tien-ich-dang-homestay-20236542.htm) | https://cdn1z.reatimes.vn/mediav2/media/uploaded/92/2019/06/07/169320425.jpg |
| `property_3.webp` | [Source](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/8b266c703475f62baf6419_1659520125.jpg |
| `property_4.webp` | [Source](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/56a3b5a841ad83f3dabc22_1659520125.jpg |
| `property_5.webp` | [Source](https://phongtro123.com/cho-thue-can-ho-studio-full-noi-that-204-tran-duy-hung-gan-bigc-vincom-d-capitale-charmvit-tower-grand-plaza-pr605327.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2022/08/03/8907293cdd391f67462820_1659520127.jpg |
| `property_6.webp` | [Source](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415419273-c2d07131174d3957c167df744a09663b_1693974007.jpg |
| `property_7.webp` | [Source](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415428565-8fa7ce201d1f16f22c1f5490aef62760_1693974009.jpg |
| `property_8.webp` | [Source](https://phongtro123.com/chdv-master-full-noi-that-ban-cong-55m2-pr634708.html) | https://pt123.cdn.static123.com/images/thumbs/900x600/fit/2023/09/06/z4665415435064-51e9ab4391d60ab733d99999313502ef_1693974009.jpg |
| `property_9.webp` | [Source](https://phongtro.vn/cho-thue-phong-tro-phuong-binh-trung-tp-ho-chi-minh/328097) | https://file.phongtro.vn/2/rent_1791879386324_1_d73497b4b4.jpg |
| `property_10.webp` | [Source](https://phongtro.vn/cho-thue-phong-tro-phuong-binh-trung-tp-ho-chi-minh/328097) | https://file.phongtro.vn/2/rent_1791879387327_2_b43472429b.jpg |

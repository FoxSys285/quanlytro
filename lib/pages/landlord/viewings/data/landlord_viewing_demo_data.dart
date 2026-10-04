import '../../../tenant/discovery/models/tenant_room_listing.dart';
import '../models/landlord_viewing.dart';

class LandlordViewingDemoData {
  static List<LandlordViewing> create({DateTime? referenceDate}) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rooms = TenantRoomDemoData.listings;
    LandlordViewing appointment(
      int index,
      int day,
      int hour,
      int minute,
      String name,
      String phone,
      String needs,
      ViewingStatus status,
    ) {
      final date = today.add(Duration(days: day));
      final room = rooms[index];
      return LandlordViewing(
        id: 'viewing-demo-$index',
        roomName: room.name,
        address: room.address,
        startsAt: DateTime(date.year, date.month, date.day, hour, minute),
        customerName: name,
        phone: phone,
        personalNeeds: needs,
        status: status,
      );
    }

    // Deliberately unordered: the page sorts by appointment time.
    return [
      appointment(
        0,
        2,
        14,
        30,
        'Nguyễn Minh Anh',
        '0900000001',
        'Ở một mình, cần phòng có ban công, máy lạnh và bếp riêng. '
            'Ngân sách khoảng 4 triệu/tháng, muốn chuyển vào đầu tháng sau.',
        ViewingStatus.confirmed,
      ),
      appointment(
        1,
        1,
        9,
        0,
        'Trần Hoàng Nam',
        '0900000002',
        'Hai sinh viên cần phòng có gác, chỗ để hai xe máy và giờ giấc tự do. '
            'Ưu tiên gần trường, ngân sách tối đa 3,5 triệu/tháng.',
        ViewingStatus.pending,
      ),
      appointment(
        2,
        1,
        16,
        0,
        'Lê Thu Hà',
        '0900000003',
        'Làm việc tại nhà, cần không gian yên tĩnh, internet ổn định và '
            'nội thất sẵn. Muốn xem khu vực giặt đồ và bếp.',
        ViewingStatus.confirmed,
      ),
      appointment(
        3,
        3,
        10,
        30,
        'Phạm Gia Bảo',
        '0900000004',
        'Tìm phòng cho một người đi làm, có cửa sổ và máy lạnh. '
            'Cần hỏi thêm tiền cọc, phí điện nước và thời hạn hợp đồng.',
        ViewingStatus.pending,
      ),
      appointment(
        4,
        2,
        8,
        30,
        'Võ Ngọc Linh',
        '0900000005',
        'Hai người thuê lâu dài, muốn có thang máy, ban công và bếp riêng. '
            'Dự kiến nhận phòng sau hai tuần.',
        ViewingStatus.confirmed,
      ),
      appointment(
        5,
        1,
        9,
        30,
        'Đặng Tuấn Kiệt',
        '0900000006',
        'Cần phòng gác cho hai người, đủ chỗ làm việc và để xe. '
            'Muốn xem thực tế độ cao gác và hệ thống thông gió.',
        ViewingStatus.pending,
      ),
    ];
  }
}

class PickupPoint {
  const PickupPoint({
    required this.id,
    required this.city,
    required this.receiver,
    required this.phoneCn,
    required this.warehouse,
  });

  final String id;
  final String city;
  final String receiver;
  final String phoneCn;
  final String warehouse;
}

const pickupPoints = <PickupPoint>[
  PickupPoint(
    id: 'dushanbe',
    city: 'Душанбе',
    receiver: 'TEZBOR-DUSHANBE',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼DU.1仓库分部',
  ),
  PickupPoint(
    id: 'yovon',
    city: 'Ёвон',
    receiver: 'TEZBOR-YOVON',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼YN.5仓库分部',
  ),
  PickupPoint(
    id: 'rasht',
    city: 'Рашт',
    receiver: 'TEZBOR-RASHT',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼RSH-7仓库分部',
  ),
  PickupPoint(
    id: 'istaravshan',
    city: 'Истаравшан',
    receiver: 'TEZBOR-ISTARAVSHAN',
    phoneCn: '17795595357',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼[KHJ-2/IST]仓库分部',
  ),
  PickupPoint(
    id: 'hisor',
    city: 'Хисор',
    receiver: 'TEZBOR-HISOR',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼HI.3仓库分部',
  ),
  PickupPoint(
    id: 'bokhtar',
    city: 'Бохтар',
    receiver: 'TEZBOR-BOKHTAR',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼BKH.6仓库分部',
  ),
  PickupPoint(
    id: 'khujand',
    city: 'Худжанд',
    receiver: 'TEZBOR-KHUJAND',
    phoneCn: '17795595357',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼[KHJ-2]仓库分部',
  ),
  PickupPoint(
    id: 'kulob',
    city: 'Кулоб',
    receiver: 'TEZBOR-KULOB',
    phoneCn: '18413362130',
    warehouse: '浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼KB.4仓库分部',
  ),
];

PickupPoint pickupById(String? id) {
  for (final p in pickupPoints) {
    if (p.id == id) return p;
  }
  return pickupPoints.first;
}

String pickupAddressText({
  required PickupPoint point,
  required String userName,
  required String userPhone,
}) {
  final name = userName.trim().isEmpty ? 'Пользователь' : userName.trim();
  final phone = userPhone.trim().isEmpty ? '+992' : userPhone.trim();
  return '收货人: ${point.receiver}\n'
      '手机号: ${point.phoneCn}\n'
      '${point.warehouse}\n'
      '$name, $phone';
}

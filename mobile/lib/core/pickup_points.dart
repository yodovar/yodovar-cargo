class PickupPoint {
  const PickupPoint({
    required this.id,
    required this.city,
    required this.receiver,
    required this.phoneCn,
    required this.warehouse,
    this.addressTemplate,
  });

  final String id;
  final String city;
  final String receiver;
  final String phoneCn;
  final String warehouse;
  final String? addressTemplate;

  factory PickupPoint.fromJson(Map<String, dynamic> json) {
    final key = (json['key'] as String? ?? '').trim();
    final city = (json['city'] as String? ?? '').trim();
    final template = (json['addressTemplate'] as String? ?? '').trim();
    final rendered = _renderTemplate(
      template: template,
      clientCode: '{{clientCode}}',
      clientName: '{{clientName}}',
      clientPhone: '{{clientPhone}}',
    );
    final lines = rendered.split('\n');
    String receiver = '';
    String phone = '';
    String warehouse = rendered;
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('收货人:') || t.toLowerCase().startsWith('receiver:')) {
        receiver = t.split(':').skip(1).join(':').trim();
      } else if (t.startsWith('手机号:') || t.toLowerCase().startsWith('phone:')) {
        phone = t.split(':').skip(1).join(':').trim();
      }
    }
    if (receiver.isEmpty) receiver = city.toUpperCase();
    if (phone.isEmpty) phone = '00000000000';
    return PickupPoint(
      id: key.isEmpty ? city.toLowerCase() : key,
      city: city.isEmpty ? key : city,
      receiver: receiver,
      phoneCn: phone,
      warehouse: warehouse,
      addressTemplate: template.isEmpty ? null : template,
    );
  }
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
  String clientCode = '',
  bool isTajik = false,
}) {
  final name = userName.trim().isEmpty
      ? (isTajik ? 'Корбар' : 'Пользователь')
      : userName.trim();
  final phone = userPhone.trim().isEmpty ? '+992' : userPhone.trim();

  // For admin-managed pickup points use exact template from backend.
  final backendTemplate = point.addressTemplate?.trim() ?? '';
  if (backendTemplate.isNotEmpty) {
    return _renderTemplate(
      template: backendTemplate,
      clientCode: clientCode.trim().isEmpty ? '-----' : clientCode.trim(),
      clientName: name,
      clientPhone: phone,
    );
  }

  // Fallback for legacy hardcoded points.
  final template = '${isTajik ? 'Қабулкунанда' : '收货人'}: ${point.receiver}\n'
      '${isTajik ? 'Рақами телефон' : '手机号'}: ${point.phoneCn}\n'
      '${point.warehouse}\n'
      '$name, $phone';
  return _renderTemplate(
    template: template,
    clientCode: clientCode.trim().isEmpty ? '-----' : clientCode.trim(),
    clientName: name,
    clientPhone: phone,
  );
}

String _renderTemplate({
  required String template,
  required String clientCode,
  required String clientName,
  required String clientPhone,
}) {
  return template
      .replaceAll('{{clientCode}}', clientCode)
      .replaceAll('{{clientName}}', clientName)
      .replaceAll('{{clientPhone}}', clientPhone);
}

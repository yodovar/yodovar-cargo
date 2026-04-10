import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type TariffDetail = {
  icon: string;
  text: string;
};

type SupportContactSeed = {
  key: string;
  label: string;
  usernameOrPhone: string;
  appUrl: string;
  webUrl: string;
};

type TariffSeed = {
  key: string;
  title: string;
  pricePerKgUsd: number;
  pricePerCubicUsd: number;
  minChargeWeightG: number;
  etaDaysMin: number;
  etaDaysMax: number;
  details: TariffDetail[];
};

type PickupPointSeed = {
  key: string;
  city: string;
  addressTemplate: string;
};

const DEFAULT_TARIFFS: TariffSeed[] = [
  {
    key: 'marketplace',
    title: 'Тариф для маркетплейса',
    pricePerKgUsd: 2.5,
    pricePerCubicUsd: 220,
    minChargeWeightG: 100,
    etaDaysMin: 14,
    etaDaysMax: 25,
    details: [
      { icon: 'scale', text: 'Минимальный оплачиваемый вес: 100 г.' },
      {
        icon: 'inventory_2',
        text: 'Если товар весит 80 г, в расчет берется 100 г.',
      },
      {
        icon: 'schedule',
        text: 'Средний срок доставки после приема на склад: 14-25 дней.',
      },
      {
        icon: 'payments',
        text: 'Оплата рассчитывается по фактическому весу или объему.',
      },
    ],
  },
  {
    key: 'wholesale',
    title: 'Тариф для оптовых клиентов',
    pricePerKgUsd: 2.1,
    pricePerCubicUsd: 200,
    minChargeWeightG: 500,
    etaDaysMin: 12,
    etaDaysMax: 22,
    details: [
      {
        icon: 'local_shipping',
        text: 'Подходит для регулярных и крупных поставок.',
      },
      {
        icon: 'percent',
        text: 'При больших партиях возможны индивидуальные скидки.',
      },
      {
        icon: 'handshake',
        text: 'Условия согласовываются менеджером отдельно.',
      },
      {
        icon: 'calendar_month',
        text: 'Рекомендуем планировать отправки заранее по партиям.',
      },
    ],
  },
];

const DEFAULT_SUPPORT_CONTACTS: SupportContactSeed[] = [
  {
    key: 'instagram',
    label: 'Instagram',
    usernameOrPhone: 'yodovar7',
    appUrl: 'instagram://user?username=yodovar7',
    webUrl: 'https://instagram.com/yodovar7',
  },
  {
    key: 'telegram',
    label: 'Telegram',
    usernameOrPhone: 'yodovar7',
    appUrl: 'tg://resolve?domain=yodovar7',
    webUrl: 'https://t.me/yodovar7',
  },
  {
    key: 'whatsapp',
    label: 'WhatsApp',
    usernameOrPhone: '800064064',
    appUrl: 'whatsapp://send?phone=800064064',
    webUrl: 'https://wa.me/800064064',
  },
];

const DEFAULT_PICKUP_POINTS: PickupPointSeed[] = [
  {
    key: 'dushanbe',
    city: 'Душанбе',
    addressTemplate:
      '收货人: TEZBOR-DUSHANBE\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼DU.1仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'yovon',
    city: 'Ёвон',
    addressTemplate:
      '收货人: TEZBOR-YOVON\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼YN.5仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'rasht',
    city: 'Рашт',
    addressTemplate:
      '收货人: TEZBOR-RASHT\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼RSH-7仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'istaravshan',
    city: 'Истаравшан',
    addressTemplate:
      '收货人: TEZBOR-ISTARAVSHAN\n手机号: 17795595357\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼[KHJ-2/IST]仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'hisor',
    city: 'Хисор',
    addressTemplate:
      '收货人: TEZBOR-HISOR\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼HI.3仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'bokhtar',
    city: 'Бохтар',
    addressTemplate:
      '收货人: TEZBOR-BOKHTAR\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼BKH.6仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'khujand',
    city: 'Худжанд',
    addressTemplate:
      '收货人: TEZBOR-KHUJAND\n手机号: 17795595357\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼[KHJ-2]仓库分部\n{{clientName}}, {{clientPhone}}',
  },
  {
    key: 'kulob',
    city: 'Кулоб',
    addressTemplate:
      '收货人: TEZBOR-KULOB\n手机号: 18413362130\n浙江省金华市义乌市后宅街道洪华小区46栋2单元一楼KB.4仓库分部\n{{clientName}}, {{clientPhone}}',
  },
];

@Injectable()
export class TariffsService {
  constructor(private readonly prisma: PrismaService) {}

  async listPublicTariffs() {
    await this.ensureTariffDefaults();
    const rows = await this.prisma.tariff.findMany({ orderBy: { createdAt: 'asc' } });
    return rows.map((row) => ({
      key: row.key,
      title: row.title,
      pricePerKgUsd: row.pricePerKgUsd,
      pricePerCubicUsd: row.pricePerCubicUsd,
      minChargeWeightG: row.minChargeWeightG,
      etaDaysMin: row.etaDaysMin,
      etaDaysMax: row.etaDaysMax,
      details: this.safeParseDetails(row.detailsJson),
    }));
  }

  async listSupportContacts() {
    await this.ensureSupportDefaults();
    return this.prisma.supportContact.findMany({ orderBy: { createdAt: 'asc' } });
  }

  async listPickupPoints() {
    await this.ensurePickupPointDefaults();
    return this.prisma.pickupPoint.findMany({ orderBy: { createdAt: 'asc' } });
  }

  private async ensureTariffDefaults() {
    const count = await this.prisma.tariff.count();
    if (count > 0) return;
    await this.prisma.tariff.createMany({
      data: DEFAULT_TARIFFS.map((item) => ({
        key: item.key,
        title: item.title,
        pricePerKgUsd: item.pricePerKgUsd,
        pricePerCubicUsd: item.pricePerCubicUsd,
        minChargeWeightG: item.minChargeWeightG,
        etaDaysMin: item.etaDaysMin,
        etaDaysMax: item.etaDaysMax,
        detailsJson: JSON.stringify(item.details),
      })),
    });
  }

  private async ensureSupportDefaults() {
    const count = await this.prisma.supportContact.count();
    if (count > 0) return;
    await this.prisma.supportContact.createMany({
      data: DEFAULT_SUPPORT_CONTACTS,
    });
  }

  private async ensurePickupPointDefaults() {
    const count = await this.prisma.pickupPoint.count();
    if (count > 0) return;
    await this.prisma.pickupPoint.createMany({
      data: DEFAULT_PICKUP_POINTS,
    });
  }

  private safeParseDetails(detailsJson: string): TariffDetail[] {
    try {
      const raw = JSON.parse(detailsJson);
      if (!Array.isArray(raw)) return [];
      return raw
        .map((item) => ({
          icon: typeof item?.icon === 'string' ? item.icon : 'info',
          text: typeof item?.text === 'string' ? item.text : '',
        }))
        .filter((item) => item.text.length > 0);
    } catch {
      return [];
    }
  }
}

/** Статусы, которые может выставлять склад КНР. */
export const WAREHOUSE_CN_STATUSES = ['received_china', 'in_transit', 'sorting'] as const;

/** Заказы, готовые к выдаче на складе ТЖ. */
export const WAREHOUSE_TJ_READY_STATUSES = ['ready_pickup', 'with_courier'] as const;

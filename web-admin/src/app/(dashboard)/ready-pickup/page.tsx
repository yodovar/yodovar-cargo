import { StatusFlowPage } from '@/components/StatusFlowPage';

export default function ReadyPickupPage() {
  return (
    <StatusFlowPage
      title="Готово к выдаче"
      subtitle="Поиск клиента и обновление статуса его товаров на 'Готово к выдаче'"
      mode="status-update"
      targetStatus="ready_pickup"
    />
  );
}

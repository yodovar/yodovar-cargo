import { StatusFlowPage } from '@/components/StatusFlowPage';

export default function InTransitPage() {
  return (
    <StatusFlowPage
      title="В пути"
      subtitle="Поиск клиента и обновление статуса его товаров на 'В пути'"
      mode="status-update"
      targetStatus="in_transit"
    />
  );
}

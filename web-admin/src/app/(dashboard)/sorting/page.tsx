import { StatusFlowPage } from '@/components/StatusFlowPage';

export default function SortingPage() {
  return (
    <StatusFlowPage
      title="Сортировка"
      subtitle="Поиск клиента и обновление статуса его товаров на 'Сортировка'"
      mode="status-update"
      targetStatus="sorting"
    />
  );
}

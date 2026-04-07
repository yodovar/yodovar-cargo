import { AdminShell } from '@/components/AdminShell';
import { RequireAuth } from '@/components/RequireAuth';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <RequireAuth>
      <AdminShell>{children}</AdminShell>
    </RequireAuth>
  );
}

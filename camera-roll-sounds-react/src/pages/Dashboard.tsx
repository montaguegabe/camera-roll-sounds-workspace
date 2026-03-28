import DashboardLayout from "@/components/layouts/ExampleLayout";
import { useFullUser } from "openbase-react-shared";

const Dashboard = () => {
  const { user, isLoading } = useFullUser();

  return (
    <DashboardLayout>
      <div className="space-y-6">TODO: Add content here</div>
    </DashboardLayout>
  );
};

export default Dashboard;

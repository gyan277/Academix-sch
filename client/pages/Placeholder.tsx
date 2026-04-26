import Layout from "@/components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";
import { ArrowRight } from "lucide-react";

interface PlaceholderProps {
  title: string;
  subtitle: string;
  icon: React.ReactNode;
}

export default function Placeholder({ title, subtitle, icon }: PlaceholderProps) {
  const navigate = useNavigate();

  return (
    <Layout title={title} subtitle={subtitle}>
      <Card className="border-border/50 shadow-sm">
        <CardHeader className="text-center py-12">
          <div className="flex justify-center mb-4">
            <div className="p-4 bg-primary/10 rounded-full">
              <div className="text-primary">{icon}</div>
            </div>
          </div>
          <CardTitle className="text-2xl mb-2">Coming Soon</CardTitle>
        </CardHeader>
        <CardContent className="text-center space-y-4 pb-12">
          <p className="text-muted-foreground max-w-md mx-auto">
            The {title} module is being developed. Continue prompting to fill in this page's contents if you'd like to see it built out.
          </p>
          <div className="flex gap-4 justify-center pt-4">
            <Button onClick={() => navigate("/dashboard")} variant="outline">
              Back to Dashboard
            </Button>
            <Button className="gap-2">
              Request Features
              <ArrowRight className="w-4 h-4" />
            </Button>
          </div>
        </CardContent>
      </Card>
    </Layout>
  );
}

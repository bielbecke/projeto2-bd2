import React, { useEffect, useState } from "react";
import Sidebar from "./components/Sidebar.jsx";
import { ToastProvider } from "./components/Toast.jsx";
import Dashboard from "./pages/Dashboard.jsx";
import Pedidos from "./pages/Pedidos.jsx";
import Empresas from "./pages/Empresas.jsx";
import Clientes from "./pages/Clientes.jsx";
import Servicos from "./pages/Servicos.jsx";
import Funcionarios from "./pages/Funcionarios.jsx";
import Cidades from "./pages/Cidades.jsx";

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

const PAGES = {
  dashboard: Dashboard,
  pedidos: Pedidos,
  empresas: Empresas,
  clientes: Clientes,
  servicos: Servicos,
  funcionarios: Funcionarios,
  cidades: Cidades,
};

export default function App() {
  const [page, setPage] = useState("dashboard");
  const [apiOnline, setApiOnline] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const check = () => {
      fetch(`${BASE_URL}/`)
        .then((res) => !cancelled && setApiOnline(res.ok))
        .catch(() => !cancelled && setApiOnline(false));
    };
    check();
    const id = setInterval(check, 15000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  const Page = PAGES[page] || Dashboard;

  return (
    <ToastProvider>
      <div className="app-shell">
        <Sidebar page={page} setPage={setPage} apiOnline={apiOnline} />
        <main className="main">
          <Page />
        </main>
      </div>
    </ToastProvider>
  );
}

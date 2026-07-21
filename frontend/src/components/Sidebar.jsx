import React from "react";

const ITEMS = [
  { key: "dashboard", label: "Painel geral" },
  { key: "pedidos", label: "Pedidos" },
  { key: "empresas", label: "Empresas" },
  { key: "clientes", label: "Clientes" },
  { key: "servicos", label: "Serviços & preços" },
  { key: "funcionarios", label: "Funcionários" },
  { key: "cidades", label: "Cidades" },
];

export default function Sidebar({ page, setPage, apiOnline }) {
  return (
    <aside className="sidebar">
      <div className="brand">
        <div className="brand-mark">
          <svg width="30" height="26" viewBox="0 0 32 28" fill="none">
            <path
              d="M2 24V9.5L16 2l14 7.5V24"
              stroke="#E3B23C"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path d="M9 24V14h14v10" stroke="#FBF8F1" strokeWidth="2" strokeLinejoin="round" />
          </svg>
          <div>
            <div className="brand-title">Muda Brasil</div>
          </div>
        </div>
        <div className="brand-tag">Sistema de mudanças</div>
      </div>

      <nav className="nav">
        {ITEMS.map((item) => (
          <button
            key={item.key}
            className={`nav-item ${page === item.key ? "active" : ""}`}
            onClick={() => setPage(item.key)}
          >
            <span className="nav-check" />
            {item.label}
          </button>
        ))}
      </nav>

      <div className="sidebar-foot">
        <span className={`api-dot ${apiOnline ? "ok" : ""}`} />
        {apiOnline ? "API conectada" : "API sem resposta"}
      </div>
    </aside>
  );
}

import React from "react";

export function StatCard({ label, value }) {
  return (
    <div className="stat-card">
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
    </div>
  );
}

export function RankList({ title, rows, valueKey, nameKey, formatValue }) {
  return (
    <div className="ticket">
      <div className="ticket-title">{title}</div>
      {rows.length === 0 ? (
        <div className="empty-state">Sem dados ainda.</div>
      ) : (
        <ul className="rank-list">
          {rows.map((row, i) => (
            <li key={i}>
              <span className="rank-name">{row[nameKey]}</span>
              <span className="rank-value">
                {formatValue ? formatValue(row[valueKey]) : row[valueKey]}
              </span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function RouteLine({ from, to }) {
  return (
    <div className="route">
      <span className="route-city">{from}</span>
      <span className="route-line" />
      <span className="route-city">{to}</span>
    </div>
  );
}

export function StatusStamp({ aceite, dataResolucao }) {
  if (aceite && dataResolucao) {
    return <span className="stamp concluido">Concluído</span>;
  }
  if (aceite) {
    return <span className="stamp aceito">Aceito</span>;
  }
  return <span className="stamp pendente">Pendente</span>;
}

export function formatBRL(value) {
  const n = Number(value || 0);
  return n.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
}

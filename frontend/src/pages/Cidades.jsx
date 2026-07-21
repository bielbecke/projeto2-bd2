import React, { useEffect, useState } from "react";
import { criarCidade, getCidades } from "../api.js";
import { useToast } from "../components/Toast.jsx";

export default function Cidades() {
  const [cidades, setCidades] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ nome_cidade: "", estado: "" });
  const [saving, setSaving] = useState(false);
  const [busca, setBusca] = useState("");
  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    getCidades()
      .then(setCidades)
      .catch((e) => toast(e.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const salvar = async (e) => {
    e.preventDefault();
    if (!form.nome_cidade || !form.estado) return;
    setSaving(true);
    try {
      await criarCidade(form.nome_cidade, form.estado);
      toast(`Cidade "${form.nome_cidade}/${form.estado.toUpperCase()}" cadastrada.`);
      setForm({ nome_cidade: "", estado: "" });
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  const filtradas = cidades.filter((c) =>
    `${c.nome_cidade} ${c.estado}`.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Área de atuação</p>
          <h1>Cidades</h1>
          <p className="page-sub">
            Toda rota, oferta de serviço e pedido referencia uma cidade cadastrada aqui —
            é a base geográfica de todo o manifesto.
          </p>
        </div>
      </div>

      <div className="grid-2">
        <div className="ticket">
          <div className="ticket-title-row">
            <div className="ticket-title">Cidades cadastradas</div>
            <input
              className="pill-search"
              placeholder="buscar…"
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
            />
          </div>
          {loading ? (
            <div className="loading-line">carregando manifesto…</div>
          ) : filtradas.length === 0 ? (
            <div className="empty-state">Nenhuma cidade encontrada.</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Cidade</th>
                  <th>UF</th>
                </tr>
              </thead>
              <tbody>
                {filtradas.map((c) => (
                  <tr key={`${c.nome_cidade}-${c.estado}`}>
                    <td>{c.nome_cidade}</td>
                    <td className="mono">{c.estado}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <form className="ticket" onSubmit={salvar}>
          <div className="ticket-title">Nova cidade</div>
          <div className="field">
            <label>Nome da cidade</label>
            <input
              value={form.nome_cidade}
              onChange={(e) => setForm({ ...form, nome_cidade: e.target.value })}
              placeholder="Sorocaba"
              required
            />
          </div>
          <div className="field">
            <label>UF</label>
            <input
              value={form.estado}
              onChange={(e) => setForm({ ...form, estado: e.target.value })}
              placeholder="SP"
              maxLength={2}
              required
            />
            <span className="field-hint">Duas letras — será salvo em maiúsculas.</span>
          </div>
          <div className="btn-row">
            <button className="btn btn-accent" disabled={saving}>
              {saving ? "Salvando…" : "Cadastrar cidade"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

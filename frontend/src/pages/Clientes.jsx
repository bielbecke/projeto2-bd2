import React, { useEffect, useState } from "react";
import { criarCliente, getClientes } from "../api.js";
import { useToast } from "../components/Toast.jsx";

const EMPTY = { cpf: "", rg: "", nome_completo: "", endereco: "", telefone: "" };

export default function Clientes() {
  const [clientes, setClientes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);
  const [busca, setBusca] = useState("");
  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    getClientes()
      .then(setClientes)
      .catch((e) => toast(e.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const salvar = async (e) => {
    e.preventDefault();
    if (!form.cpf || !form.nome_completo) return;
    setSaving(true);
    try {
      await criarCliente(form);
      toast(`Cliente "${form.nome_completo}" cadastrado.`);
      setForm(EMPTY);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  const filtrados = clientes.filter((c) =>
    `${c.nome_completo} ${c.cpf}`.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Quem solicita a mudança</p>
          <h1>Clientes</h1>
          <p className="page-sub">
            Todo pedido precisa de um cliente vinculado. CPF é a chave de identificação —
            não pode repetir.
          </p>
        </div>
      </div>

      <div className="grid-2">
        <div className="ticket">
          <div className="ticket-title-row">
            <div className="ticket-title">Clientes cadastrados</div>
            <input
              className="pill-search"
              placeholder="buscar por nome ou CPF…"
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
            />
          </div>
          {loading ? (
            <div className="loading-line">carregando manifesto…</div>
          ) : filtrados.length === 0 ? (
            <div className="empty-state">Nenhum cliente encontrado.</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Nome</th>
                  <th>CPF</th>
                  <th>Endereço</th>
                  <th>Telefones</th>
                </tr>
              </thead>
              <tbody>
                {filtrados.map((c) => (
                  <tr key={c.cod_cliente}>
                    <td className="mono">{c.cod_cliente}</td>
                    <td>{c.nome_completo}</td>
                    <td className="mono">{c.cpf}</td>
                    <td>{c.endereco || "—"}</td>
                    <td>
                      <div className="chip-list">
                        {(c.telefones || []).map((t) => (
                          <span className="chip" key={t}>
                            {t}
                          </span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <form className="ticket" onSubmit={salvar}>
          <div className="ticket-title">Novo cliente</div>
          <div className="field">
            <label>Nome completo</label>
            <input
              value={form.nome_completo}
              onChange={(e) => setForm({ ...form, nome_completo: e.target.value })}
              placeholder="Marina Alves Costa"
              required
            />
          </div>
          <div className="field-row">
            <div className="field">
              <label>CPF</label>
              <input
                value={form.cpf}
                onChange={(e) => setForm({ ...form, cpf: e.target.value })}
                placeholder="000.000.000-00"
                required
              />
            </div>
            <div className="field">
              <label>RG</label>
              <input
                value={form.rg}
                onChange={(e) => setForm({ ...form, rg: e.target.value })}
                placeholder="00.000.000-0"
              />
            </div>
          </div>
          <div className="field">
            <label>Endereço</label>
            <input
              value={form.endereco}
              onChange={(e) => setForm({ ...form, endereco: e.target.value })}
              placeholder="Av. Brasil, 500"
            />
          </div>
          <div className="field">
            <label>Telefone</label>
            <input
              value={form.telefone}
              onChange={(e) => setForm({ ...form, telefone: e.target.value })}
              placeholder="(11) 98888-7777"
            />
          </div>
          <div className="btn-row">
            <button className="btn btn-accent" disabled={saving}>
              {saving ? "Salvando…" : "Cadastrar cliente"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

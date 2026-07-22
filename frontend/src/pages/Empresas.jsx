import React, { useEffect, useState } from "react";
import { criarEmpresa, getEmpresas } from "../api.js";
import { useToast } from "../components/Toast.jsx";

const EMPTY = { nome: "", endereco: "", telefones: "" };

export default function Empresas() {
  const [empresas, setEmpresas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState(EMPTY);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    getEmpresas()
      .then(setEmpresas)
      .catch((e) => toast(e.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const salvar = async (e) => {
    e.preventDefault();
    if (!form.nome || !form.endereco) return;
    setSaving(true);
    try {
      const telefones = form.telefones
        .split(",")
        .map((t) => t.trim())
        .filter(Boolean);
      await criarEmpresa({ nome: form.nome, endereco: form.endereco, telefones });
      toast(`Empresa "${form.nome}" cadastrada.`);
      setForm(EMPTY);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Transportadoras</p>
          <h1>Empresas</h1>
          <p className="page-sub">
            Cada empresa define, cidade a cidade, quais serviços oferece e a que preço/hora —
            isso é feito na aba "Serviços & preços".
          </p>
        </div>
      </div>

      <div className="grid-2">
        <div className="ticket">
          <div className="ticket-title">Empresas cadastradas</div>
          {loading ? (
            <div className="loading-line">carregando Muda Brasil…</div>
          ) : empresas.length === 0 ? (
            <div className="empty-state">Nenhuma empresa cadastrada ainda.</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Nome</th>
                  <th>Endereço</th>
                  <th>Telefones</th>
                </tr>
              </thead>
              <tbody>
                {empresas.map((e) => (
                  <tr key={e.id_empresa}>
                    <td className="mono">{e.id_empresa}</td>
                    <td>{e.nome}</td>
                    <td>{e.endereco}</td>
                    <td>
                      <div className="chip-list">
                        {(e.telefones || []).map((t) => (
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
          <div className="ticket-title">Nova empresa</div>
          <div className="field">
            <label>Nome</label>
            <input
              value={form.nome}
              onChange={(e) => setForm({ ...form, nome: e.target.value })}
              placeholder="Mudanças Vitória Ltda"
              required
            />
          </div>
          <div className="field">
            <label>Endereço</label>
            <input
              value={form.endereco}
              onChange={(e) => setForm({ ...form, endereco: e.target.value })}
              placeholder="Rua das Palmeiras, 120"
              required
            />
          </div>
          <div className="field">
            <label>Telefones</label>
            <input
              value={form.telefones}
              onChange={(e) => setForm({ ...form, telefones: e.target.value })}
              placeholder="(11) 4002-8922, (11) 99999-0000"
            />
            <span className="field-hint">Separe por vírgula, se houver mais de um.</span>
          </div>
          <div className="btn-row">
            <button className="btn btn-accent" disabled={saving}>
              {saving ? "Salvando…" : "Cadastrar empresa"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

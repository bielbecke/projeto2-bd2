import React, { useEffect, useState } from "react";
import {
  criarFuncionario,
  criarVinculo,
  encerrarVinculo,
  getEmpresas,
  getFuncionarios,
  getVinculos,
} from "../api.js";
import { useToast } from "../components/Toast.jsx";

const EMPTY_FUNC = {
  cpf_func: "",
  rg_func: "",
  nome_completo_func: "",
  endereco_func: "",
  telefone_contato: "",
  salario: "",
  tipo_func: "",
};

const EMPTY_VINC = { id_empresa: "", cpf_func: "", data_inicio: "", data_fim: "" };

export default function Funcionarios() {
  const [tab, setTab] = useState("funcionarios");
  const [funcionarios, setFuncionarios] = useState([]);
  const [empresas, setEmpresas] = useState([]);
  const [vinculos, setVinculos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [formFunc, setFormFunc] = useState(EMPTY_FUNC);
  const [formVinc, setFormVinc] = useState(EMPTY_VINC);
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    Promise.all([getFuncionarios(), getEmpresas(), getVinculos()])
      .then(([f, e, v]) => {
        setFuncionarios(f);
        setEmpresas(e);
        setVinculos(v);
      })
      .catch((err) => toast(err.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const salvarFuncionario = async (e) => {
    e.preventDefault();
    if (!formFunc.cpf_func || !formFunc.nome_completo_func) return;
    setSaving(true);
    try {
      await criarFuncionario({
        ...formFunc,
        salario: formFunc.salario ? Number(formFunc.salario) : null,
      });
      toast(`Funcionário "${formFunc.nome_completo_func}" cadastrado.`);
      setFormFunc(EMPTY_FUNC);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  const salvarVinculo = async (e) => {
    e.preventDefault();
    if (!formVinc.id_empresa || !formVinc.cpf_func || !formVinc.data_inicio) return;
    setSaving(true);
    try {
      await criarVinculo({
        id_empresa: Number(formVinc.id_empresa),
        cpf_func: formVinc.cpf_func,
        data_inicio: formVinc.data_inicio,
        data_fim: formVinc.data_fim || null,
      });
      toast("Vínculo registrado.");
      setFormVinc(EMPTY_VINC);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  const encerrar = async (id_empresa, cpf_func) => {
    try {
      await encerrarVinculo(id_empresa, cpf_func);
      toast("Vínculo encerrado hoje.");
      carregar();
    } catch (err) {
      toast(err.message, "error");
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Equipe de campo</p>
          <h1>Funcionários</h1>
          <p className="page-sub">
            Um funcionário pode trabalhar para mais de uma empresa, em períodos diferentes —
            é isso que a aba "Vínculos" controla.
          </p>
        </div>
      </div>

      <div className="tab-row">
        <button
          className={`tab-btn ${tab === "funcionarios" ? "active" : ""}`}
          onClick={() => setTab("funcionarios")}
        >
          Funcionários
        </button>
        <button
          className={`tab-btn ${tab === "vinculos" ? "active" : ""}`}
          onClick={() => setTab("vinculos")}
        >
          Vínculos com empresas
        </button>
      </div>

      {tab === "funcionarios" ? (
        <div className="grid-2">
          <div className="ticket">
            <div className="ticket-title">Funcionários cadastrados</div>
            {loading ? (
              <div className="loading-line">carregando manifesto…</div>
            ) : funcionarios.length === 0 ? (
              <div className="empty-state">Nenhum funcionário cadastrado ainda.</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Nome</th>
                    <th>CPF</th>
                    <th>Cargo</th>
                    <th>Salário</th>
                  </tr>
                </thead>
                <tbody>
                  {funcionarios.map((f) => (
                    <tr key={f.cpf_func}>
                      <td>{f.nome_completo_func}</td>
                      <td className="mono">{f.cpf_func}</td>
                      <td>{f.tipo_func || "—"}</td>
                      <td className="mono">{f.salario ? `R$ ${f.salario}` : "—"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <form className="ticket" onSubmit={salvarFuncionario}>
            <div className="ticket-title">Novo funcionário</div>
            <div className="field">
              <label>Nome completo</label>
              <input
                value={formFunc.nome_completo_func}
                onChange={(e) =>
                  setFormFunc({ ...formFunc, nome_completo_func: e.target.value })
                }
                placeholder="João Pedro Silva"
                required
              />
            </div>
            <div className="field-row">
              <div className="field">
                <label>CPF</label>
                <input
                  value={formFunc.cpf_func}
                  onChange={(e) => setFormFunc({ ...formFunc, cpf_func: e.target.value })}
                  placeholder="000.000.000-00"
                  required
                />
              </div>
              <div className="field">
                <label>RG</label>
                <input
                  value={formFunc.rg_func}
                  onChange={(e) => setFormFunc({ ...formFunc, rg_func: e.target.value })}
                />
              </div>
            </div>
            <div className="field">
              <label>Endereço</label>
              <input
                value={formFunc.endereco_func}
                onChange={(e) => setFormFunc({ ...formFunc, endereco_func: e.target.value })}
              />
            </div>
            <div className="field-row">
              <div className="field">
                <label>Telefone</label>
                <input
                  value={formFunc.telefone_contato}
                  onChange={(e) =>
                    setFormFunc({ ...formFunc, telefone_contato: e.target.value })
                  }
                />
              </div>
              <div className="field">
                <label>Salário (R$)</label>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  value={formFunc.salario}
                  onChange={(e) => setFormFunc({ ...formFunc, salario: e.target.value })}
                />
              </div>
            </div>
            <div className="field">
              <label>Cargo / tipo</label>
              <input
                value={formFunc.tipo_func}
                onChange={(e) => setFormFunc({ ...formFunc, tipo_func: e.target.value })}
                placeholder="Ajudante, motorista, operador de guindaste…"
              />
            </div>
            <div className="btn-row">
              <button className="btn btn-accent" disabled={saving}>
                {saving ? "Salvando…" : "Cadastrar funcionário"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <div className="grid-2">
          <div className="ticket">
            <div className="ticket-title">Vínculos registrados</div>
            {loading ? (
              <div className="loading-line">carregando manifesto…</div>
            ) : vinculos.length === 0 ? (
              <div className="empty-state">Nenhum vínculo registrado ainda.</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Funcionário</th>
                    <th>Empresa</th>
                    <th>Início</th>
                    <th>Fim</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {vinculos.map((v) => (
                    <tr key={`${v.id_empresa}-${v.cpf_func}-${v.data_inicio}`}>
                      <td>{v.nome_completo_func}</td>
                      <td>{v.nome_empresa}</td>
                      <td className="mono">{v.data_inicio}</td>
                      <td className="mono">
                        {v.data_fim || <span className="stamp aceito">ativo</span>}
                      </td>
                      <td>
                        {!v.data_fim && (
                          <button
                            className="btn btn-danger btn-sm"
                            onClick={() => encerrar(v.id_empresa, v.cpf_func)}
                          >
                            Encerrar
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <form className="ticket" onSubmit={salvarVinculo}>
            <div className="ticket-title">Novo vínculo</div>
            <div className="field">
              <label>Empresa</label>
              <select
                value={formVinc.id_empresa}
                onChange={(e) => setFormVinc({ ...formVinc, id_empresa: e.target.value })}
                required
              >
                <option value="">Selecione…</option>
                {empresas.map((e) => (
                  <option key={e.id_empresa} value={e.id_empresa}>
                    {e.nome}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Funcionário</label>
              <select
                value={formVinc.cpf_func}
                onChange={(e) => setFormVinc({ ...formVinc, cpf_func: e.target.value })}
                required
              >
                <option value="">Selecione…</option>
                {funcionarios.map((f) => (
                  <option key={f.cpf_func} value={f.cpf_func}>
                    {f.nome_completo_func} — {f.cpf_func}
                  </option>
                ))}
              </select>
            </div>
            <div className="field-row">
              <div className="field">
                <label>Início</label>
                <input
                  type="date"
                  value={formVinc.data_inicio}
                  onChange={(e) => setFormVinc({ ...formVinc, data_inicio: e.target.value })}
                  required
                />
              </div>
              <div className="field">
                <label>Fim (opcional)</label>
                <input
                  type="date"
                  value={formVinc.data_fim}
                  onChange={(e) => setFormVinc({ ...formVinc, data_fim: e.target.value })}
                />
              </div>
            </div>
            <div className="btn-row">
              <button className="btn btn-accent" disabled={saving}>
                {saving ? "Salvando…" : "Registrar vínculo"}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

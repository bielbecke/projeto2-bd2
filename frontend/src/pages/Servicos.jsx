import React, { useEffect, useState } from "react";
import {
  criarOferta,
  criarServico,
  getCidades,
  getEmpresas,
  getOfertas,
  getServicos,
} from "../api.js";
import { useToast } from "../components/Toast.jsx";
import { formatBRL } from "../components/Bits.jsx";

const EMPTY_SERVICO = {
  nome_servico: "",
  tipo_servico: "",
  especializacao: "",
  tamanho_base: "",
  altura: "",
  bonus_aum: "",
  limite_carga: "",
};

const EMPTY_OFERTA = { id_empresa: "", cidade: "", nome_servico: "", preco_hora: "" };

export default function Servicos() {
  const [tab, setTab] = useState("catalogo");
  const [servicos, setServicos] = useState([]);
  const [empresas, setEmpresas] = useState([]);
  const [cidades, setCidades] = useState([]);
  const [ofertas, setOfertas] = useState([]);
  const [loading, setLoading] = useState(true);

  const [formServico, setFormServico] = useState(EMPTY_SERVICO);
  const [faixas, setFaixas] = useState([]);
  const [savingServico, setSavingServico] = useState(false);

  const [formOferta, setFormOferta] = useState(EMPTY_OFERTA);
  const [savingOferta, setSavingOferta] = useState(false);

  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    Promise.all([getServicos(), getEmpresas(), getCidades(), getOfertas()])
      .then(([s, e, c, o]) => {
        setServicos(s);
        setEmpresas(e);
        setCidades(c);
        setOfertas(o);
      })
      .catch((err) => toast(err.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const addFaixa = () => setFaixas([...faixas, { limite_carga: "", percentual: "" }]);
  const removeFaixa = (i) => setFaixas(faixas.filter((_, idx) => idx !== i));
  const setFaixa = (i, field, value) => {
    const next = [...faixas];
    next[i] = { ...next[i], [field]: value };
    setFaixas(next);
  };

  const salvarServico = async (e) => {
    e.preventDefault();
    if (!formServico.nome_servico) return;
    setSavingServico(true);
    try {
      await criarServico({
        nome_servico: formServico.nome_servico,
        tipo_servico: formServico.tipo_servico || null,
        especializacao: formServico.especializacao || null,
        tamanho_base: formServico.tamanho_base ? Number(formServico.tamanho_base) : null,
        altura: formServico.altura ? Number(formServico.altura) : null,
        bonus_aum: formServico.bonus_aum ? Number(formServico.bonus_aum) : 0,
        limite_carga: formServico.limite_carga ? Number(formServico.limite_carga) : null,
        faixas: faixas
          .filter((f) => f.limite_carga && f.percentual)
          .map((f) => ({
            limite_carga: Number(f.limite_carga),
            percentual: Number(f.percentual),
          })),
      });
      toast(`Serviço "${formServico.nome_servico}" cadastrado.`);
      setFormServico(EMPTY_SERVICO);
      setFaixas([]);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSavingServico(false);
    }
  };

  const salvarOferta = async (e) => {
    e.preventDefault();
    if (
      !formOferta.id_empresa ||
      !formOferta.cidade ||
      !formOferta.nome_servico ||
      !formOferta.preco_hora
    )
      return;
    setSavingOferta(true);
    try {
      const [nome_cidade, estado] = formOferta.cidade.split("::");
      await criarOferta(
        Number(formOferta.id_empresa),
        nome_cidade,
        estado,
        formOferta.nome_servico,
        Number(formOferta.preco_hora)
      );
      toast("Preço/hora cadastrado para essa combinação.");
      setFormOferta(EMPTY_OFERTA);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSavingOferta(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Catálogo</p>
          <h1>Serviços & preços</h1>
          <p className="page-sub">
            Guindaste e Transporte são especializações — disjuntas e parciais — de um Serviço
            base. Cada empresa define, por cidade, o preço/hora de cada serviço que oferece.
          </p>
        </div>
      </div>

      <div className="tab-row">
        <button
          className={`tab-btn ${tab === "catalogo" ? "active" : ""}`}
          onClick={() => setTab("catalogo")}
        >
          Catálogo de serviços
        </button>
        <button
          className={`tab-btn ${tab === "precos" ? "active" : ""}`}
          onClick={() => setTab("precos")}
        >
          Preços por cidade
        </button>
      </div>

      {tab === "catalogo" ? (
        <div className="grid-2">
          <div className="ticket">
            <div className="ticket-title">Serviços cadastrados</div>
            {loading ? (
              <div className="loading-line">carregando manifesto…</div>
            ) : servicos.length === 0 ? (
              <div className="empty-state">Nenhum serviço cadastrado ainda.</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Nome</th>
                    <th>Tipo</th>
                    <th>Especialização</th>
                  </tr>
                </thead>
                <tbody>
                  {servicos.map((s) => (
                    <tr key={s.nome_servico}>
                      <td>{s.nome_servico}</td>
                      <td>{s.tipo_servico || "—"}</td>
                      <td>
                        {s.especializacao ? (
                          <span className="chip">{s.especializacao}</span>
                        ) : (
                          "—"
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <form className="ticket" onSubmit={salvarServico}>
            <div className="ticket-title">Novo serviço</div>
            <div className="field">
              <label>Nome do serviço</label>
              <input
                value={formServico.nome_servico}
                onChange={(e) =>
                  setFormServico({ ...formServico, nome_servico: e.target.value })
                }
                placeholder="Guindaste 15t"
                required
              />
            </div>
            <div className="field">
              <label>Tipo (livre)</label>
              <input
                value={formServico.tipo_servico}
                onChange={(e) =>
                  setFormServico({ ...formServico, tipo_servico: e.target.value })
                }
                placeholder="Içamento, embalagem, frete…"
              />
            </div>
            <div className="field">
              <label>Especialização</label>
              <select
                value={formServico.especializacao}
                onChange={(e) =>
                  setFormServico({ ...formServico, especializacao: e.target.value })
                }
              >
                <option value="">Nenhuma (serviço genérico)</option>
                <option value="GUINDASTE">Guindaste</option>
                <option value="TRANSPORTE">Transporte</option>
              </select>
              <span className="field-hint">
                Um serviço não pode ser Guindaste e Transporte ao mesmo tempo — o banco
                garante isso por trigger.
              </span>
            </div>

            {formServico.especializacao === "GUINDASTE" && (
              <div className="item-card">
                <div className="field-row">
                  <div className="field">
                    <label>Tamanho base (m)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={formServico.tamanho_base}
                      onChange={(e) =>
                        setFormServico({ ...formServico, tamanho_base: e.target.value })
                      }
                    />
                  </div>
                  <div className="field">
                    <label>Altura (m)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={formServico.altura}
                      onChange={(e) =>
                        setFormServico({ ...formServico, altura: e.target.value })
                      }
                    />
                  </div>
                </div>
                <div className="field">
                  <label>Bônus (% sobre preço/hora)</label>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={formServico.bonus_aum}
                    onChange={(e) =>
                      setFormServico({ ...formServico, bonus_aum: e.target.value })
                    }
                  />
                </div>
              </div>
            )}

            {formServico.especializacao === "TRANSPORTE" && (
              <div className="item-card">
                <div className="field">
                  <label>Limite de carga (kg)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={formServico.limite_carga}
                    onChange={(e) =>
                      setFormServico({ ...formServico, limite_carga: e.target.value })
                    }
                  />
                </div>
                <div className="field">
                  <label>Faixas de acréscimo por carga</label>
                  {faixas.map((f, i) => (
                    <div className="field-row" key={i} style={{ marginBottom: 6 }}>
                      <input
                        type="number"
                        placeholder="até (kg)"
                        value={f.limite_carga}
                        onChange={(e) => setFaixa(i, "limite_carga", e.target.value)}
                      />
                      <input
                        type="number"
                        placeholder="acréscimo (%)"
                        value={f.percentual}
                        onChange={(e) => setFaixa(i, "percentual", e.target.value)}
                      />
                    </div>
                  ))}
                  <button type="button" className="btn btn-ghost btn-sm" onClick={addFaixa}>
                    + adicionar faixa
                  </button>
                </div>
              </div>
            )}

            <div className="btn-row">
              <button className="btn btn-accent" disabled={savingServico}>
                {savingServico ? "Salvando…" : "Cadastrar serviço"}
              </button>
            </div>
          </form>
        </div>
      ) : (
        <div className="grid-2">
          <div className="ticket">
            <div className="ticket-title">Preços/hora cadastrados</div>
            {loading ? (
              <div className="loading-line">carregando manifesto…</div>
            ) : ofertas.length === 0 ? (
              <div className="empty-state">Nenhum preço cadastrado ainda.</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Empresa</th>
                    <th>Cidade</th>
                    <th>Serviço</th>
                    <th>Preço/hora</th>
                  </tr>
                </thead>
                <tbody>
                  {ofertas.map((o) => (
                    <tr key={o.id_oferta}>
                      <td>{o.nome_empresa}</td>
                      <td className="mono">
                        {o.nome_cidade}/{o.estado}
                      </td>
                      <td>{o.nome_servico}</td>
                      <td className="mono">{formatBRL(o.preco_hora)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <form className="ticket" onSubmit={salvarOferta}>
            <div className="ticket-title">Novo preço/hora</div>
            <p className="field-hint" style={{ marginBottom: 12 }}>
              Um pedido só pode incluir um serviço se a empresa tiver cadastrado esse serviço
              para a cidade de destino — isso também é garantido por trigger.
            </p>
            <div className="field">
              <label>Empresa</label>
              <select
                value={formOferta.id_empresa}
                onChange={(e) => setFormOferta({ ...formOferta, id_empresa: e.target.value })}
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
              <label>Cidade</label>
              <select
                value={formOferta.cidade}
                onChange={(e) => setFormOferta({ ...formOferta, cidade: e.target.value })}
                required
              >
                <option value="">Selecione…</option>
                {cidades.map((c) => (
                  <option
                    key={`${c.nome_cidade}-${c.estado}`}
                    value={`${c.nome_cidade}::${c.estado}`}
                  >
                    {c.nome_cidade}/{c.estado}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Serviço</label>
              <select
                value={formOferta.nome_servico}
                onChange={(e) =>
                  setFormOferta({ ...formOferta, nome_servico: e.target.value })
                }
                required
              >
                <option value="">Selecione…</option>
                {servicos.map((s) => (
                  <option key={s.nome_servico} value={s.nome_servico}>
                    {s.nome_servico}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Preço/hora (R$)</label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                value={formOferta.preco_hora}
                onChange={(e) => setFormOferta({ ...formOferta, preco_hora: e.target.value })}
                required
              />
            </div>
            <div className="btn-row">
              <button className="btn btn-accent" disabled={savingOferta}>
                {savingOferta ? "Salvando…" : "Cadastrar preço"}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

import React, { useEffect, useState } from "react";
import {
  atribuirFuncionario,
  criarPedido,
  getCidades,
  getClientes,
  getEmpresas,
  getFuncionarios,
  getPedidos,
  getServicos,
  resolverPedido,
} from "../api.js";
import { useToast } from "../components/Toast.jsx";
import { RouteLine, StatusStamp, formatBRL } from "../components/Bits.jsx";

const EMPTY_PEDIDO = {
  id_empresa: "",
  cod_cliente: "",
  cidade_dest: "",
  endereco_dest: "",
  cidade_part: "",
  endereco_part: "",
  aceite: false,
};

const EMPTY_ITEM = { nome_servico: "", tempo_duracao: "", carga: "", funcionarios: [] };

export default function Pedidos() {
  const [pedidos, setPedidos] = useState([]);
  const [empresas, setEmpresas] = useState([]);
  const [clientes, setClientes] = useState([]);
  const [cidades, setCidades] = useState([]);
  const [servicos, setServicos] = useState([]);
  const [funcionarios, setFuncionarios] = useState([]);
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState(EMPTY_PEDIDO);
  const [itens, setItens] = useState([{ ...EMPTY_ITEM }]);
  const [saving, setSaving] = useState(false);

  const toast = useToast();

  const carregar = () => {
    setLoading(true);
    Promise.all([
      getPedidos(),
      getEmpresas(),
      getClientes(),
      getCidades(),
      getServicos(),
      getFuncionarios(),
    ])
      .then(([p, e, c, ci, s, f]) => {
        setPedidos(p);
        setEmpresas(e);
        setClientes(c);
        setCidades(ci);
        setServicos(s);
        setFuncionarios(f);
      })
      .catch((err) => toast(err.message, "error"))
      .finally(() => setLoading(false));
  };

  useEffect(carregar, []);

  const addItem = () => setItens([...itens, { ...EMPTY_ITEM }]);
  const removeItem = (i) => setItens(itens.filter((_, idx) => idx !== i));
  const setItem = (i, field, value) => {
    const next = [...itens];
    next[i] = { ...next[i], [field]: value };
    setItens(next);
  };
  const toggleFuncionario = (i, cpf) => {
    const next = [...itens];
    const atual = next[i].funcionarios;
    next[i] = {
      ...next[i],
      funcionarios: atual.includes(cpf)
        ? atual.filter((c) => c !== cpf)
        : [...atual, cpf],
    };
    setItens(next);
  };

  const criar = async (e) => {
    e.preventDefault();
    const [nome_cidade_dest, estado_dest] = (form.cidade_dest || "").split("::");
    const [nome_cidade_part, estado_part] = (form.cidade_part || "").split("::");

    if (!form.id_empresa || !form.cod_cliente || !nome_cidade_dest || !nome_cidade_part) {
      toast("Preencha empresa, cliente e as duas cidades.", "error");
      return;
    }
    const itensValidos = itens.filter((it) => it.nome_servico && it.tempo_duracao);
    if (itensValidos.length === 0) {
      toast("Adicione ao menos um serviço com duração.", "error");
      return;
    }

    setSaving(true);
    try {
      const resultado = await criarPedido({
        id_empresa: Number(form.id_empresa),
        cod_cliente: Number(form.cod_cliente),
        cidade_dest: nome_cidade_dest,
        estado_dest,
        endereco_dest: form.endereco_dest || null,
        cidade_part: nome_cidade_part,
        estado_part,
        endereco_part: form.endereco_part || null,
        aceite: form.aceite,
        itens: itensValidos.map((it) => ({
          nome_servico: it.nome_servico,
          tempo_duracao: Number(it.tempo_duracao),
          carga: it.carga ? Number(it.carga) : null,
          funcionarios: it.funcionarios,
        })),
      });
      toast(`Pedido #${resultado.codigo} criado — total ${formatBRL(resultado.preco_total)}.`);
      setForm(EMPTY_PEDIDO);
      setItens([{ ...EMPTY_ITEM }]);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    } finally {
      setSaving(false);
    }
  };

  const marcarResolvido = async (codigo) => {
    try {
      await resolverPedido(codigo);
      toast(`Pedido #${codigo} marcado como concluído.`);
      carregar();
    } catch (err) {
      toast(err.message, "error");
    }
  };

  const atribuir = async (id_solicitacao, cpf_func) => {
    if (!cpf_func) return;
    try {
      await atribuirFuncionario(id_solicitacao, cpf_func);
      toast("Funcionário atribuído ao serviço.");
      carregar();
    } catch (err) {
      toast(err.message, "error");
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Manifesto de despacho</p>
          <h1>Pedidos</h1>
          <p className="page-sub">
            O preço de cada serviço solicitado e o preço total do pedido são sempre
            recalculados pelo banco — a interface nunca envia esses valores.
          </p>
        </div>
      </div>

      <div className="grid-2">
        <div>
          {loading ? (
            <div className="loading-line">carregando manifesto…</div>
          ) : pedidos.length === 0 ? (
            <div className="ticket empty-state">Nenhum pedido cadastrado ainda.</div>
          ) : (
            pedidos.map((p) => (
              <div className="ticket" key={p.codigo}>
                <div className="ticket-title-row">
                  <div className="ticket-title mono">Pedido #{p.codigo}</div>
                  <StatusStamp aceite={p.aceite} dataResolucao={p.data_resolucao} />
                </div>
                <RouteLine
                  from={`${p.cidade_part}/${p.estado_part}`}
                  to={`${p.cidade_dest}/${p.estado_dest}`}
                />
                <p className="field-hint" style={{ margin: "2px 0 12px" }}>
                  {p.empresa} · cliente {p.cliente} · solicitado em {p.data_solicitacao}
                  {p.data_resolucao ? ` · concluído em ${p.data_resolucao}` : ""}
                </p>

                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Serviço</th>
                      <th>Duração</th>
                      <th>Carga</th>
                      <th>Preço</th>
                      <th>Equipe</th>
                    </tr>
                  </thead>
                  <tbody>
                    {p.itens.map((item) => (
                      <tr key={item.id_solicitacao}>
                        <td>{item.nome_servico}</td>
                        <td className="mono">{item.tempo_duracao}h</td>
                        <td className="mono">{item.carga ?? "—"}</td>
                        <td className="mono">{formatBRL(item.preco)}</td>
                        <td>
                          <div className="chip-list" style={{ marginBottom: 6 }}>
                            {item.funcionarios.length === 0 ? (
                              <span className="field-hint">sem equipe</span>
                            ) : (
                              item.funcionarios.map((nome) => (
                                <span className="chip" key={nome}>
                                  {nome}
                                </span>
                              ))
                            )}
                          </div>
                          {!p.data_resolucao && (
                            <AtribuirFuncionario
                              funcionarios={funcionarios}
                              onAtribuir={(cpf) => atribuir(item.id_solicitacao, cpf)}
                            />
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>

                <div className="btn-row" style={{ marginTop: 14 }}>
                  <span className="stat-value" style={{ fontSize: 18, flex: 1 }}>
                    {formatBRL(p.preco_total)}
                  </span>
                  {!p.data_resolucao ? (
                    <button className="btn btn-ghost btn-sm" onClick={() => marcarResolvido(p.codigo)}>
                      Marcar como concluído
                    </button>
                  ) : null}
                </div>
              </div>
            ))
          )}
        </div>

        <form className="ticket" onSubmit={criar}>
          <div className="ticket-title">Novo pedido</div>

          <div className="field">
            <label>Empresa</label>
            <select
              value={form.id_empresa}
              onChange={(e) => setForm({ ...form, id_empresa: e.target.value })}
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
            <label>Cliente</label>
            <select
              value={form.cod_cliente}
              onChange={(e) => setForm({ ...form, cod_cliente: e.target.value })}
              required
            >
              <option value="">Selecione…</option>
              {clientes.map((c) => (
                <option key={c.cod_cliente} value={c.cod_cliente}>
                  {c.nome_completo}
                </option>
              ))}
            </select>
          </div>

          <div className="field-row">
            <div className="field">
              <label>Cidade de partida</label>
              <select
                value={form.cidade_part}
                onChange={(e) => setForm({ ...form, cidade_part: e.target.value })}
                required
              >
                <option value="">Selecione…</option>
                {cidades.map((c) => (
                  <option key={`p-${c.nome_cidade}-${c.estado}`} value={`${c.nome_cidade}::${c.estado}`}>
                    {c.nome_cidade}/{c.estado}
                  </option>
                ))}
              </select>
            </div>
            <div className="field">
              <label>Cidade de destino</label>
              <select
                value={form.cidade_dest}
                onChange={(e) => setForm({ ...form, cidade_dest: e.target.value })}
                required
              >
                <option value="">Selecione…</option>
                {cidades.map((c) => (
                  <option key={`d-${c.nome_cidade}-${c.estado}`} value={`${c.nome_cidade}::${c.estado}`}>
                    {c.nome_cidade}/{c.estado}
                  </option>
                ))}
              </select>
              <span className="field-hint">
                A empresa precisa oferecer o serviço nessa cidade, ou o trigger recusa o pedido.
              </span>
            </div>
          </div>

          <div className="field-row">
            <div className="field">
              <label>Endereço de partida</label>
              <input
                value={form.endereco_part}
                onChange={(e) => setForm({ ...form, endereco_part: e.target.value })}
              />
            </div>
            <div className="field">
              <label>Endereço de destino</label>
              <input
                value={form.endereco_dest}
                onChange={(e) => setForm({ ...form, endereco_dest: e.target.value })}
              />
            </div>
          </div>

          <div className="check-row">
            <input
              type="checkbox"
              checked={form.aceite}
              onChange={(e) => setForm({ ...form, aceite: e.target.checked })}
              id="aceite"
            />
            <label htmlFor="aceite">Já nasce aceito pela empresa</label>
          </div>

          <div className="field">
            <label>Serviços solicitados</label>
            {itens.map((item, i) => (
              <div className="item-card" key={i}>
                {itens.length > 1 && (
                  <button
                    type="button"
                    className="btn btn-danger btn-sm item-card-remove"
                    onClick={() => removeItem(i)}
                  >
                    remover
                  </button>
                )}
                <div className="field">
                  <label>Serviço</label>
                  <select
                    value={item.nome_servico}
                    onChange={(e) => setItem(i, "nome_servico", e.target.value)}
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
                <div className="field-row">
                  <div className="field">
                    <label>Duração (horas)</label>
                    <input
                      type="number"
                      step="0.5"
                      min="0.5"
                      value={item.tempo_duracao}
                      onChange={(e) => setItem(i, "tempo_duracao", e.target.value)}
                      required
                    />
                  </div>
                  <div className="field">
                    <label>Carga (kg, se transporte)</label>
                    <input
                      type="number"
                      step="0.01"
                      value={item.carga}
                      onChange={(e) => setItem(i, "carga", e.target.value)}
                    />
                  </div>
                </div>
                <div className="field">
                  <label>Equipe (opcional)</label>
                  <select
                    multiple
                    value={item.funcionarios}
                    onChange={(e) =>
                      setItem(
                        i,
                        "funcionarios",
                        Array.from(e.target.selectedOptions, (o) => o.value)
                      )
                    }
                    style={{ minHeight: 74 }}
                  >
                    {funcionarios.map((f) => (
                      <option key={f.cpf_func} value={f.cpf_func}>
                        {f.nome_completo_func}
                      </option>
                    ))}
                  </select>
                  <span className="field-hint">Ctrl/Cmd + clique para selecionar vários.</span>
                </div>
              </div>
            ))}
            <button type="button" className="btn btn-ghost btn-sm" onClick={addItem}>
              + adicionar serviço
            </button>
          </div>

          <div className="btn-row" style={{ marginTop: 14 }}>
            <button className="btn btn-accent" disabled={saving}>
              {saving ? "Salvando…" : "Criar pedido"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

function AtribuirFuncionario({ funcionarios, onAtribuir }) {
  const [cpf, setCpf] = useState("");
  return (
    <div style={{ display: "flex", gap: 6 }}>
      <select value={cpf} onChange={(e) => setCpf(e.target.value)} style={{ fontSize: 12 }}>
        <option value="">+ atribuir…</option>
        {funcionarios.map((f) => (
          <option key={f.cpf_func} value={f.cpf_func}>
            {f.nome_completo_func}
          </option>
        ))}
      </select>
      <button
        type="button"
        className="btn btn-ghost btn-sm"
        onClick={() => {
          onAtribuir(cpf);
          setCpf("");
        }}
      >
        ok
      </button>
    </div>
  );
}

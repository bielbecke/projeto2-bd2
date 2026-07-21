const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

class ApiError extends Error {}

async function request(path, { method = "GET", body } = {}) {
  let res;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (err) {
    throw new ApiError(
      `Não foi possível falar com a API em ${BASE_URL}. O backend Flask está rodando?`
    );
  }

  let data = null;
  try {
    data = await res.json();
  } catch {
    /* resposta sem corpo */
  }

  if (!res.ok) {
    throw new ApiError(data?.erro || `Erro ${res.status} ao chamar ${path}`);
  }

  return data;
}

export { ApiError };

/* ---------------------------- cidades ---------------------------- */
export const getCidades = () => request("/cidades");
export const criarCidade = (nome_cidade, estado) =>
  request("/cidades", { method: "POST", body: { nome_cidade, estado } });

/* ---------------------------- clientes ---------------------------- */
export const getClientes = () => request("/clientes");
export const criarCliente = (payload) =>
  request("/clientes", { method: "POST", body: payload });

/* ---------------------------- empresas ---------------------------- */
export const getEmpresas = () => request("/empresas");
export const criarEmpresa = (payload) =>
  request("/empresas", { method: "POST", body: payload });

/* --------------------------- funcionarios --------------------------- */
export const getFuncionarios = (id_empresa) =>
  request(id_empresa ? `/funcionarios?id_empresa=${id_empresa}` : "/funcionarios");
export const criarFuncionario = (payload) =>
  request("/funcionarios", { method: "POST", body: payload });
export const getVinculos = () => request("/funcionarios/vinculos");
export const criarVinculo = (payload) =>
  request("/funcionarios/vinculos", { method: "POST", body: payload });
export const encerrarVinculo = (id_empresa, cpf_func) =>
  request(`/funcionarios/vinculos/${id_empresa}/${cpf_func}/encerrar`, { method: "PATCH" });

/* ---------------------------- serviços ---------------------------- */
export const getServicos = () => request("/servicos");
export const criarServico = (payload) =>
  request("/servicos", { method: "POST", body: payload });
export const getOfertas = ({ id_empresa, nome_cidade, estado } = {}) => {
  const params = new URLSearchParams();
  if (id_empresa) params.set("id_empresa", id_empresa);
  if (nome_cidade) params.set("nome_cidade", nome_cidade);
  if (estado) params.set("estado", estado);
  const qs = params.toString();
  return request(`/oferece${qs ? `?${qs}` : ""}`);
};
export const criarOferta = (payload) =>
  request("/oferece", { method: "POST", body: payload });

/* ---------------------------- pedidos ---------------------------- */
export const getPedidos = () => request("/pedidos");
export const criarPedido = (payload) =>
  request("/pedidos", { method: "POST", body: payload });
export const resolverPedido = (codigo) =>
  request(`/pedidos/${codigo}/resolver`, { method: "PATCH" });
export const atribuirFuncionario = (id_solicitacao, cpf_func) =>
  request(`/pedidos/servicos/${id_solicitacao}/funcionarios`, {
    method: "POST",
    body: { cpf_func },
  });

/* ---------------------------- dashboard ---------------------------- */
export const getResumo = async () => {
  const data = await request("/dashboard/resumo");
  return { ...data, faturado: Number(data.faturado) };
};

export const getQtdPorCidade = () => request("/dashboard/qtd-por-cidade");

export const getValorPorCidade = async () => {
  const data = await request("/dashboard/valor-por-cidade");
  return data.map((item) => ({ ...item, valor: Number(item.valor) }));
};

export const getTopCidadesValor = async () => {
  const data = await request("/dashboard/top-cidades-valor");
  return data.map((item) => ({ ...item, valor: Number(item.valor) }));
};

export const getTopCidadesQtd = () => request("/dashboard/top-cidades-qtd");
export const getTopEmpresasQtd = () => request("/dashboard/top-empresas-qtd");

export const getTopEmpresasValor = async () => {
  const data = await request("/dashboard/top-empresas-valor");
  return data.map((item) => ({ ...item, valor: Number(item.valor) }));
};
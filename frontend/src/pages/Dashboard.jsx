import React, { useEffect, useState } from "react";
import {
  getQtdPorCidade,
  getResumo,
  getTopCidadesQtd,
  getTopCidadesValor,
  getTopEmpresasQtd,
  getTopEmpresasValor,
  getValorPorCidade,
} from "../api.js";
import { useToast } from "../components/Toast.jsx";
import { StatCard, RankList, formatBRL } from "../components/Bits.jsx";
import BarChartCard from "../components/BarChartCard.jsx";

export default function Dashboard() {
  const [resumo, setResumo] = useState(null);
  const [qtdCidade, setQtdCidade] = useState([]);
  const [valorCidade, setValorCidade] = useState([]);
  const [topCidadesValor, setTopCidadesValor] = useState([]);
  const [topCidadesQtd, setTopCidadesQtd] = useState([]);
  const [topEmpresasQtd, setTopEmpresasQtd] = useState([]);
  const [topEmpresasValor, setTopEmpresasValor] = useState([]);
  const [loading, setLoading] = useState(true);
  const toast = useToast();

  useEffect(() => {
    let cancelado = false;

    async function carregar() {
      setLoading(true);
      try {
        // buscas em sequência, não em paralelo: o backend reusa o mesmo
        // cursor psycopg2 entre requisições (bug dele, não daqui), então
        // chamadas simultâneas podem misturar o resultado de uma consulta
        // com a outra. Uma por vez evita isso até o backend ser corrigido.
        const r = await getResumo();
        const qc = await getQtdPorCidade();
        const vc = await getValorPorCidade();
        const tcv = await getTopCidadesValor();
        const tcq = await getTopCidadesQtd();
        const teq = await getTopEmpresasQtd();
        const tev = await getTopEmpresasValor();

        if (cancelado) return;
        setResumo(r);
        setQtdCidade(qc);
        setValorCidade(vc);
        setTopCidadesValor(tcv);
        setTopCidadesQtd(tcq);
        setTopEmpresasQtd(teq);
        setTopEmpresasValor(tev);
      } catch (err) {
        if (!cancelado) toast(err.message, "error");
      } finally {
        if (!cancelado) setLoading(false);
      }
    }

    carregar();
    return () => {
      cancelado = true;
    };
  }, []);

  return (
    <div>
      <div className="page-header">
        <div>
          <p className="page-eyebrow">Visão geral da operação</p>
          <h1>Painel geral</h1>
          <p className="page-sub">
            Números consolidados de todos os pedidos, cidades e empresas cadastrados no
            Muda Brasil.
          </p>
        </div>
      </div>

      {loading || !resumo ? (
        <div className="loading-line">carregando dashboard…</div>
      ) : (
        <>
          <div className="stat-row">
            <StatCard label="Pedidos no total" value={resumo.pedidos} />
            <StatCard label="Faturado (concluídos)" value={formatBRL(resumo.faturado)} />
            <StatCard label="Pedidos pendentes" value={resumo.pendentes} />
            <StatCard label="Serviços no catálogo" value={resumo.servicos_cadastrados} />
          </div>

          <div className="charts-row">
            <BarChartCard
              title="Serviços solicitados por cidade"
              data={qtdCidade}
              dataKey="qtd"
              labelKey="cidade"
              color="#2f5d4f"
            />
            <BarChartCard
              title="Valor pago em serviços por cidade"
              data={valorCidade}
              dataKey="valor"
              labelKey="cidade"
              color="#e3b23c"
              formatTooltip={(v) => formatBRL(v)}
            />
          </div>

          <div className="lists-row">
            <RankList
              title="Top 5 cidades · valor investido"
              rows={topCidadesValor}
              nameKey="cidade"
              valueKey="valor"
              formatValue={formatBRL}
            />
            <RankList
              title="Top 5 cidades · nº de serviços"
              rows={topCidadesQtd}
              nameKey="cidade"
              valueKey="qtd"
            />
            <RankList
              title="Top 5 empresas · nº de serviços"
              rows={topEmpresasQtd}
              nameKey="nome"
              valueKey="qtd"
            />
            <RankList
              title="Top 5 empresas · valor ganho"
              rows={topEmpresasValor}
              nameKey="nome"
              valueKey="valor"
              formatValue={formatBRL}
            />
          </div>
        </>
      )}
    </div>
  );
}
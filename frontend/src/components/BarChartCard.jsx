import React from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

export default function BarChartCard({
  title,
  data = [],
  dataKey,
  labelKey,
  color = "#f0b52d",
  formatTooltip,
}) {
  // Garante que os valores sejam números
  const parsedData = data.map((item) => ({
    ...item,
    [dataKey]: Number(item[dataKey]),
  }));

  const chartKey = parsedData
    .map((d) => d[dataKey])
    .join("-");

  // Maior valor do gráfico
  const maxValue = Math.max(
    0,
    ...parsedData.map((d) => d[dataKey])
  );

  // Calcula um passo "bonito"
  function getNiceStep(max, targetTicks = 5) {
    if (max <= targetTicks) return 1;

    const rawStep = max / targetTicks;
    const magnitude = Math.pow(
      10,
      Math.floor(Math.log10(rawStep))
    );

    const residual = rawStep / magnitude;

    let niceResidual;

    if (residual <= 1) niceResidual = 1;
    else if (residual <= 2) niceResidual = 2;
    else if (residual <= 5) niceResidual = 5;
    else niceResidual = 10;

    return niceResidual * magnitude;
  }

  const step = getNiceStep(maxValue);
  const maxY = Math.ceil(maxValue / step) * step;

  const ticks = [];
  for (let i = 0; i <= maxY; i += step) {
    ticks.push(i);
  }

  return (
    <div className="ticket">
      <div className="ticket-title">{title}</div>

      {parsedData.length === 0 ? (
        <div className="empty-state">
          Sem dados ainda.
        </div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart
            key={chartKey}
            data={parsedData}
            margin={{
              top: 8,
              right: 12,
              left: 8,
              bottom: 42,
            }}
          >
            <CartesianGrid
              stroke="#cfc5a6"
              strokeDasharray="3 4"
              vertical={false}
            />

            <XAxis
              dataKey={labelKey}
              interval={0}
              angle={-25}
              textAnchor="end"
              height={55}
              tick={{
                fontFamily: "JetBrains Mono",
                fontSize: 10.5,
                fill: "#6f5533",
              }}
              tickLine={false}
              axisLine={{ stroke: "#a9895c" }}
            />

            <YAxis
              domain={[0, maxY]}
              ticks={ticks}
              allowDecimals={false}
              tickFormatter={(value) =>
                value.toLocaleString("pt-BR")
              }
              tick={{
                fontFamily: "JetBrains Mono",
                fontSize: 10.5,
                fill: "#6f5533",
              }}
              tickLine={false}
              axisLine={false}
            />

            <Tooltip
              formatter={(value) =>
                formatTooltip
                  ? formatTooltip(value)
                  : value.toLocaleString("pt-BR")
              }
              contentStyle={{
                fontFamily: "Inter",
                fontSize: 12,
                border: "1px solid #a9895c",
                borderRadius: 4,
                background: "#f4efe1",
              }}
            />

            <Bar
              dataKey={dataKey}
              fill={color}
              radius={[3, 3, 0, 0]}
              maxBarSize={38}
            />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}
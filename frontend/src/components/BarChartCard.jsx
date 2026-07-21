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

export default function BarChartCard({ title, data, dataKey, labelKey, color, formatTooltip }) {
  return (
    <div className="ticket">
      <div className="ticket-title">{title}</div>
      {data.length === 0 ? (
        <div className="empty-state">Sem dados ainda.</div>
      ) : (
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={data} margin={{ top: 6, right: 6, left: -18, bottom: 0 }}>
            <CartesianGrid stroke="#cfc5a6" strokeDasharray="3 4" vertical={false} />
            <XAxis
              dataKey={labelKey}
              tick={{ fontFamily: "JetBrains Mono", fontSize: 10.5, fill: "#6f5533" }}
              tickLine={false}
              axisLine={{ stroke: "#a9895c" }}
              interval={0}
              angle={-28}
              textAnchor="end"
              height={54}
            />
            <YAxis
              tick={{ fontFamily: "JetBrains Mono", fontSize: 10.5, fill: "#6f5533" }}
              tickLine={false}
              axisLine={false}
              width={44}
            />
            <Tooltip
              formatter={formatTooltip}
              contentStyle={{
                fontFamily: "Inter",
                fontSize: 12.5,
                border: "1px solid #a9895c",
                borderRadius: 3,
                background: "#f4efe1",
              }}
            />
            <Bar dataKey={dataKey} fill={color} radius={[2, 2, 0, 0]} maxBarSize={38} />
          </BarChart>
        </ResponsiveContainer>
      )}
    </div>
  );
}

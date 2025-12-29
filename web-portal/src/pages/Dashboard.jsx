import React, { useState, useEffect } from 'react';
import {
    Users,
    CreditCard,
    TrendingUp,
    Activity,
    Megaphone
} from 'lucide-react';
import {
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer
} from 'recharts';

const mockChartData = [
    { name: 'Seg', valor: 4000 },
    { name: 'Ter', valor: 3000 },
    { name: 'Qua', valor: 5000 },
    { name: 'Qui', valor: 2780 },
    { name: 'Sex', valor: 1890 },
    { name: 'Sab', valor: 2390 },
    { name: 'Dom', valor: 3490 },
];

export default function Dashboard() {
    const [stats, setStats] = useState(null);
    const [campaigns, setCampaigns] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const apiKey = localStorage.getItem('apiKey');

        // Fetch stats
        Promise.all([
            fetch('/api/v1/stats', {
                headers: { 'X-API-Key': apiKey }
            }),
            fetch('/api/v1/campaigns', {
                headers: { 'X-API-Key': apiKey }
            })
        ])
            .then(([statsRes, campaignsRes]) => Promise.all([statsRes.json(), campaignsRes.json()]))
            .then(([statsData, campaignsData]) => {
                setStats(statsData);
                setCampaigns(campaignsData || []);
                setLoading(false);
            })
            .catch(err => {
                console.error('Error fetching dashboard data:', err);
                setLoading(false);
            });
    }, []);

    const activeCampaigns = campaigns.filter(c => c.isActive).length;
    const totalCustomers = stats?.total_customers || 0;
    const conversionRate = stats?.conversion_rate || 0;

    return (
        <div className="space-y-8">
            <div>
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Visão Geral</h1>
                <p className="text-gray-500 dark:text-gray-400">Bem-vindo de volta! Aqui está o resumo da sua loja.</p>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <StatCard
                    title="Total de Clientes"
                    value={loading ? '...' : totalCustomers.toLocaleString('pt-BR')}
                    icon={Users}
                />
                <StatCard
                    title="Campanhas Ativas"
                    value={loading ? '...' : activeCampaigns.toString()}
                    change={`${campaigns.length} total`}
                    icon={Megaphone}
                />
                <StatCard
                    title="Taxa de Conversão"
                    value={loading ? '...' : `${(conversionRate * 100).toFixed(1)}%`}
                    icon={TrendingUp}
                />
                <StatCard
                    title="Transações Hoje"
                    value={loading ? '...' : (stats?.transactions_today || 0).toString()}
                    change="Últimas 24h"
                    icon={Activity}
                />
            </div>

            {/* Charts Section */}
            <div className="bg-white dark:bg-[#161b22] p-6 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800">
                <div className="flex items-center justify-between mb-6">
                    <h2 className="text-lg font-bold text-gray-900 dark:text-white">Performance Semanal</h2>
                    <select className="bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 text-sm rounded-lg p-2.5 outline-none focus:border-blue-500">
                        <option>Últimos 7 dias</option>
                        <option>Últimos 30 dias</option>
                    </select>
                </div>
                <div className="h-[300px] w-full">
                    <ResponsiveContainer width="100%" height="100%">
                        <AreaChart data={mockChartData}>
                            <defs>
                                <linearGradient id="colorValor" x1="0" y1="0" x2="0" y2="1">
                                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.1} />
                                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                                </linearGradient>
                            </defs>
                            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#374151" opacity={0.3} />
                            <XAxis
                                dataKey="name"
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#9ca3af', fontSize: 12 }}
                                dy={10}
                            />
                            <YAxis
                                axisLine={false}
                                tickLine={false}
                                tick={{ fill: '#9ca3af', fontSize: 12 }}
                            />
                            <Tooltip
                                contentStyle={{
                                    borderRadius: '12px',
                                    border: 'none',
                                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                                    backgroundColor: '#1f2937',
                                    color: '#fff'
                                }}
                            />
                            <Area
                                type="monotone"
                                dataKey="valor"
                                stroke="#3b82f6"
                                strokeWidth={3}
                                fillOpacity={1}
                                fill="url(#colorValor)"
                            />
                        </AreaChart>
                    </ResponsiveContainer>
                </div>
            </div>
        </div>
    );
}

function StatCard({ title, value, change, icon: Icon, trend = 'neutral' }) {
    const trendColors = {
        up: 'text-green-600 bg-green-50 dark:text-green-400 dark:bg-green-900/30',
        down: 'text-red-600 bg-red-50 dark:text-red-400 dark:bg-red-900/30',
        neutral: 'text-gray-600 bg-gray-50 dark:text-gray-400 dark:bg-gray-800/50'
    };

    return (
        <div className="bg-white dark:bg-[#161b22] p-6 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-800 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between mb-4">
                <div className="p-3 bg-gray-50 dark:bg-gray-900/50 rounded-xl">
                    <Icon className="w-6 h-6 text-gray-900 dark:text-gray-100" />
                </div>
                {change && (
                    <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full ${trendColors[trend]}`}>
                        {change}
                    </span>
                )}
            </div>
            <p className="text-gray-500 dark:text-gray-400 text-sm font-medium">{title}</p>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">{value}</h3>
        </div>
    );
}

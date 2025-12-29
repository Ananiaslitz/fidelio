import React, { useState } from 'react';
import { X, ArrowRight, ArrowLeft, Check, Percent, Gift, CreditCard, Calendar, AlertCircle } from 'lucide-react';

const CAMPAIGN_TYPES = [
    {
        id: 'CASHBACK',
        name: 'Cashback',
        description: 'Cliente ganha % de volta em cada compra',
        icon: Percent,
        color: 'bg-green-500'
    },
    {
        id: 'PROGRESSIVE',
        name: 'Pontos Progressivos',
        description: 'Quanto mais compra, mais pontos ganha',
        icon: Gift,
        color: 'bg-purple-600'
    },
    {
        id: 'PUNCH_CARD',
        name: 'Cartão Fidelidade',
        description: 'A cada X compras, ganha recompensa',
        icon: CreditCard,
        color: 'bg-blue-600'
    }
];

export default function CampaignWizard({ isOpen, onClose, onSuccess }) {
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [formData, setFormData] = useState({
        type: '',
        name: '',
        description: '',
        startsAt: '',
        endsAt: '',
        config: {}
    });

    if (!isOpen) return null;

    const handleTypeSelect = (type) => {
        setFormData({ ...formData, type });
        setStep(2);
    };

    const handleBasicInfo = (e) => {
        e.preventDefault();
        setStep(3);
    };

    const handleConfigSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const response = await fetch('/api/v1/campaigns', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': localStorage.getItem('apiKey') || 'demo-key'
                },
                body: JSON.stringify({
                    ...formData,
                    config: JSON.stringify(formData.config)
                }),
            });

            if (response.status === 403) {
                // Plan limit reached
                const errorData = await response.json();
                onClose();
                // Trigger upgrade modal in parent
                if (window.showUpgradeModal) {
                    window.showUpgradeModal(errorData);
                }
                return;
            }

            if (!response.ok) {
                throw new Error('Failed to create campaign');
            }

            onSuccess?.();
            onClose();
            resetForm();
        } catch (error) {
            console.error('Error creating campaign:', error);
            alert('Erro ao criar campanha. Tente novamente.');
        } finally {
            setLoading(false);
        }
    };

    const resetForm = () => {
        setStep(1);
        setFormData({
            type: '',
            name: '',
            description: '',
            startsAt: '',
            endsAt: '',
            config: {}
        });
    };

    const handleClose = () => {
        resetForm();
        onClose();
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div className="bg-white rounded-3xl shadow-2xl w-full max-w-2xl overflow-hidden">
                {/* Header */}
                <div className="px-8 py-6 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
                    <div>
                        <h2 className="text-xl font-bold text-gray-900">Nova Campanha</h2>
                        <p className="text-sm text-gray-500">Passo {step} de 3</p>
                    </div>
                    <button
                        onClick={handleClose}
                        className="p-2 hover:bg-gray-100 rounded-full transition-colors text-gray-400 hover:text-gray-600"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                <div className="p-8">
                    {/* Step 1: Type Selection */}
                    {step === 1 && (
                        <div className="space-y-6">
                            <div className="text-center mb-8">
                                <h3 className="text-2xl font-bold text-gray-900 mb-2">Escolha o Tipo de Campanha</h3>
                                <p className="text-gray-500">Selecione a mecânica de fidelidade ideal para seu negócio</p>
                            </div>

                            <div className="grid gap-4">
                                {CAMPAIGN_TYPES.map((type) => {
                                    const Icon = type.icon;
                                    return (
                                        <button
                                            key={type.id}
                                            onClick={() => handleTypeSelect(type.id)}
                                            className="p-6 border-2 border-gray-200 rounded-2xl hover:border-blue-500 hover:bg-blue-50/50 transition-all text-left group"
                                        >
                                            <div className="flex items-start gap-4">
                                                <div className={`${type.color} text-white p-3 rounded-xl group-hover:scale-110 transition-transform`}>
                                                    <Icon className="w-6 h-6" />
                                                </div>
                                                <div className="flex-1">
                                                    <h4 className="font-bold text-gray-900 mb-1">{type.name}</h4>
                                                    <p className="text-sm text-gray-500">{type.description}</p>
                                                </div>
                                                <ArrowRight className="w-5 h-5 text-gray-400 group-hover:text-blue-600 group-hover:translate-x-1 transition-all" />
                                            </div>
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    )}

                    {/* Step 2: Basic Info */}
                    {step === 2 && (
                        <form onSubmit={handleBasicInfo} className="space-y-6">
                            <div className="text-center mb-6">
                                <h3 className="text-2xl font-bold text-gray-900 mb-2">Informações Básicas</h3>
                                <p className="text-gray-500">Defina nome e período da campanha</p>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Nome da Campanha</label>
                                <input
                                    required
                                    type="text"
                                    value={formData.name}
                                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                    placeholder="Ex: Cashback de Verão 2024"
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-2">Descrição (Opcional)</label>
                                <textarea
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    placeholder="Descreva os benefícios da campanha..."
                                    rows={3}
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all resize-none"
                                />
                            </div>

                            <div className="grid md:grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Data de Início</label>
                                    <input
                                        type="date"
                                        value={formData.startsAt}
                                        onChange={(e) => setFormData({ ...formData, startsAt: e.target.value })}
                                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-2">Data de Término (Opcional)</label>
                                    <input
                                        type="date"
                                        value={formData.endsAt}
                                        onChange={(e) => setFormData({ ...formData, endsAt: e.target.value })}
                                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                                    />
                                </div>
                            </div>

                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setStep(1)}
                                    className="flex-1 py-3 rounded-xl border-2 border-gray-200 font-medium hover:bg-gray-50 transition-all flex items-center justify-center gap-2"
                                >
                                    <ArrowLeft className="w-5 h-5" />
                                    Voltar
                                </button>
                                <button
                                    type="submit"
                                    className="flex-1 py-3 rounded-xl bg-blue-600 text-white font-medium hover:bg-blue-700 transition-all flex items-center justify-center gap-2"
                                >
                                    Continuar
                                    <ArrowRight className="w-5 h-5" />
                                </button>
                            </div>
                        </form>
                    )}

                    {/* Step 3: Configuration */}
                    {step === 3 && (
                        <form onSubmit={handleConfigSubmit} className="space-y-6">
                            <div className="text-center mb-6">
                                <h3 className="text-2xl font-bold text-gray-900 mb-2">Configuração da Campanha</h3>
                                <p className="text-gray-500">Defina as regras e recompensas</p>
                            </div>

                            {formData.type === 'CASHBACK' && (
                                <CashbackConfig formData={formData} setFormData={setFormData} />
                            )}

                            {formData.type === 'PUNCH_CARD' && (
                                <PunchCardConfig formData={formData} setFormData={setFormData} />
                            )}

                            {formData.type === 'PROGRESSIVE' && (
                                <ProgressiveConfig formData={formData} setFormData={setFormData} />
                            )}

                            <div className="flex gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={() => setStep(2)}
                                    className="flex-1 py-3 rounded-xl border-2 border-gray-200 font-medium hover:bg-gray-50 transition-all flex items-center justify-center gap-2"
                                >
                                    <ArrowLeft className="w-5 h-5" />
                                    Voltar
                                </button>
                                <button
                                    type="submit"
                                    disabled={loading}
                                    className="flex-1 py-3 rounded-xl bg-green-600 text-white font-medium hover:bg-green-700 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                                >
                                    {loading ? 'Criando...' : (
                                        <>
                                            <Check className="w-5 h-5" />
                                            Criar Campanha
                                        </>
                                    )}
                                </button>
                            </div>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
}

// Cashback Configuration Component
function CashbackConfig({ formData, setFormData }) {
    const updateConfig = (field, value) => {
        setFormData({
            ...formData,
            config: { ...formData.config, [field]: parseFloat(value) || 0 }
        });
    };

    return (
        <div className="space-y-4">
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Percentual de Cashback (%)</label>
                <input
                    required
                    type="number"
                    step="0.1"
                    min="0"
                    max="100"
                    value={formData.config.percentage || ''}
                    onChange={(e) => updateConfig('percentage', e.target.value)}
                    placeholder="Ex: 5"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Cashback Máximo por Compra (R$) - Opcional</label>
                <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={formData.config.max_cashback || ''}
                    onChange={(e) => updateConfig('max_cashback', e.target.value)}
                    placeholder="Ex: 50"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Compra Mínima (R$) - Opcional</label>
                <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={formData.config.min_purchase || ''}
                    onChange={(e) => updateConfig('min_purchase', e.target.value)}
                    placeholder="Ex: 20"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
        </div>
    );
}

// Punch Card Configuration Component
function PunchCardConfig({ formData, setFormData }) {
    const updateConfig = (field, value) => {
        setFormData({
            ...formData,
            config: { ...formData.config, [field]: field === 'reward_type' ? value : (parseFloat(value) || 0) }
        });
    };

    return (
        <div className="space-y-4">
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Número de Carimbos Necessários</label>
                <input
                    required
                    type="number"
                    min="1"
                    value={formData.config.required_punches || ''}
                    onChange={(e) => updateConfig('required_punches', e.target.value)}
                    placeholder="Ex: 10"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Tipo de Recompensa</label>
                <select
                    required
                    value={formData.config.reward_type || ''}
                    onChange={(e) => updateConfig('reward_type', e.target.value)}
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all bg-white"
                >
                    <option value="">Selecione...</option>
                    <option value="points">Pontos</option>
                    <option value="discount">Desconto</option>
                    <option value="free_item">Produto Grátis</option>
                </select>
            </div>
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Valor da Recompensa (R$ ou Pontos)</label>
                <input
                    required
                    type="number"
                    step="0.01"
                    min="0"
                    value={formData.config.reward_amount || ''}
                    onChange={(e) => updateConfig('reward_amount', e.target.value)}
                    placeholder="Ex: 50"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
        </div>
    );
}

// Progressive Configuration Component
function ProgressiveConfig({ formData, setFormData }) {
    const updateConfig = (field, value) => {
        setFormData({
            ...formData,
            config: { ...formData.config, [field]: parseFloat(value) || 0 }
        });
    };

    return (
        <div className="space-y-4">
            <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Pontos Base por R$ 1 Gasto</label>
                <input
                    required
                    type="number"
                    step="0.1"
                    min="0"
                    value={formData.config.base_points_ratio || ''}
                    onChange={(e) => updateConfig('base_points_ratio', e.target.value)}
                    placeholder="Ex: 1"
                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 outline-none transition-all"
                />
            </div>
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4">
                <div className="flex gap-2 items-start">
                    <AlertCircle className="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" />
                    <div className="text-sm text-blue-800">
                        <p className="font-medium mb-1">Sistema Progressivo Simplificado</p>
                        <p>Os níveis e multiplicadores serão configurados automaticamente baseados no histórico de compras do cliente.</p>
                    </div>
                </div>
            </div>
        </div>
    );
}

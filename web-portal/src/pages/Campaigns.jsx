import React, { useState, useEffect } from 'react';
import { Plus, Percent, Gift, CreditCard, Play, Pause, Trash2, Users, TrendingUp, Calendar } from 'lucide-react';
import CampaignWizard from '../components/CampaignWizard';
import UpgradeModal from '../components/UpgradeModal';

export default function Campaigns() {
    const [isWizardOpen, setIsWizardOpen] = useState(false);
    const [campaigns, setCampaigns] = useState([]);
    const [loading, setLoading] = useState(true);
    const [upgradeModal, setUpgradeModal] = useState({ isOpen: false, currentPlan: '', limit: 0 });

    // Expose function to window for CampaignWizard to call
    useEffect(() => {
        window.showUpgradeModal = (errorData) => {
            setUpgradeModal({
                isOpen: true,
                currentPlan: errorData.currentPlan || 'Starter',
                limit: errorData.limit || 1
            });
        };
        return () => {
            delete window.showUpgradeModal;
        };
    }, []);

    useEffect(() => {
        fetchCampaigns();
    }, []);

    const fetchCampaigns = async () => {
        try {
            const response = await fetch('/api/v1/campaigns', {
                headers: {
                    'X-API-Key': localStorage.getItem('apiKey') || 'demo-key'
                }
            });

            if (response.ok) {
                const data = await response.json();
                setCampaigns(data || []);
            }
        } catch (error) {
            console.error('Error fetching campaigns:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleToggleCampaign = async (id, currentStatus) => {
        try {
            const response = await fetch(`/api/v1/campaigns/${id}/toggle`, {
                method: 'PATCH',
                headers: {
                    'X-API-Key': localStorage.getItem('apiKey') || 'demo-key'
                }
            });

            if (response.ok) {
                fetchCampaigns();
            }
        } catch (error) {
            console.error('Error toggling campaign:', error);
        }
    };

    const handleDeleteCampaign = async (id) => {
        if (!confirm('Tem certeza que deseja excluir esta campanha?')) return;

        try {
            const response = await fetch(`/api/v1/campaigns/${id}`, {
                method: 'DELETE',
                headers: {
                    'X-API-Key': localStorage.getItem('apiKey') || 'demo-key'
                }
            });

            if (response.ok) {
                fetchCampaigns();
            }
        } catch (error) {
            console.error('Error deleting campaign:', error);
        }
    };

    const getCampaignIcon = (type) => {
        switch (type) {
            case 'CASHBACK': return Percent;
            case 'PROGRESSIVE': return Gift;
            case 'PUNCH_CARD': return CreditCard;
            default: return Gift;
        }
    };

    const getCampaignColor = (type) => {
        switch (type) {
            case 'CASHBACK': return 'bg-green-500';
            case 'PROGRESSIVE': return 'bg-purple-600';
            case 'PUNCH_CARD': return 'bg-blue-600';
            default: return 'bg-gray-500';
        }
    };

    const getCampaignTypeName = (type) => {
        switch (type) {
            case 'CASHBACK': return 'Cashback';
            case 'PROGRESSIVE': return 'Pontos Progressivos';
            case 'PUNCH_CARD': return 'Cartão Fidelidade';
            default: return type;
        }
    };

    return (
        <div className="p-8">
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Campanhas</h1>
                    <p className="text-gray-500">Gerencie suas campanhas de fidelidade.</p>
                </div>
                <button
                    onClick={() => setIsWizardOpen(true)}
                    className="bg-gray-900 text-white px-4 py-2 rounded-xl text-sm font-medium flex items-center gap-2 hover:bg-black transition-colors shadow-lg"
                >
                    <Plus className="w-4 h-4" />
                    Nova Campanha
                </button>
            </div>

            {loading ? (
                <div className="text-center py-12">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900"></div>
                    <p className="text-gray-500 mt-4">Carregando campanhas...</p>
                </div>
            ) : campaigns.length === 0 ? (
                <div className="bg-white rounded-2xl border-2 border-dashed border-gray-200 p-12 text-center">
                    <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Gift className="w-8 h-8 text-gray-400" />
                    </div>
                    <h3 className="text-lg font-bold text-gray-900 mb-2">Nenhuma campanha criada</h3>
                    <p className="text-gray-500 mb-6 max-w-md mx-auto">
                        Comece criando sua primeira campanha de fidelidade para engajar seus clientes.
                    </p>
                    <button
                        onClick={() => setIsWizardOpen(true)}
                        className="bg-gray-900 text-white px-6 py-3 rounded-xl font-medium hover:bg-black transition-colors inline-flex items-center gap-2"
                    >
                        <Plus className="w-5 h-5" />
                        Criar Primeira Campanha
                    </button>
                </div>
            ) : (
                <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {campaigns.map((campaign) => {
                        const Icon = getCampaignIcon(campaign.type);
                        const colorClass = getCampaignColor(campaign.type);

                        return (
                            <div key={campaign.id} className="bg-white rounded-2xl border border-gray-200 overflow-hidden hover:shadow-lg transition-shadow">
                                {/* Header */}
                                <div className="p-6 border-b border-gray-100">
                                    <div className="flex items-start justify-between mb-4">
                                        <div className={`${colorClass} text-white p-3 rounded-xl`}>
                                            <Icon className="w-6 h-6" />
                                        </div>
                                        <span className={`px-3 py-1 rounded-full text-xs font-medium ${campaign.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'}`}>
                                            {campaign.is_active ? 'Ativa' : 'Pausada'}
                                        </span>
                                    </div>
                                    <h3 className="font-bold text-gray-900 mb-1">{campaign.name}</h3>
                                    <p className="text-sm text-gray-500">{getCampaignTypeName(campaign.type)}</p>
                                </div>

                                {/* Stats */}
                                <div className="p-6 bg-gray-50 grid grid-cols-2 gap-4">
                                    <div>
                                        <div className="flex items-center gap-2 text-gray-500 text-xs mb-1">
                                            <Users className="w-3 h-3" />
                                            Participantes
                                        </div>
                                        <p className="text-lg font-bold text-gray-900">-</p>
                                    </div>
                                    <div>
                                        <div className="flex items-center gap-2 text-gray-500 text-xs mb-1">
                                            <TrendingUp className="w-3 h-3" />
                                            Conversões
                                        </div>
                                        <p className="text-lg font-bold text-gray-900">-</p>
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="p-4 border-t border-gray-100 flex gap-2">
                                    <button
                                        onClick={() => handleToggleCampaign(campaign.id, campaign.is_active)}
                                        className="flex-1 py-2 px-3 rounded-lg text-sm font-medium bg-gray-100 hover:bg-gray-200 transition-colors flex items-center justify-center gap-2"
                                    >
                                        {campaign.is_active ? (
                                            <>
                                                <Pause className="w-4 h-4" />
                                                Pausar
                                            </>
                                        ) : (
                                            <>
                                                <Play className="w-4 h-4" />
                                                Ativar
                                            </>
                                        )}
                                    </button>
                                    <button
                                        onClick={() => handleDeleteCampaign(campaign.id)}
                                        className="p-2 rounded-lg text-red-600 hover:bg-red-50 transition-colors"
                                    >
                                        <Trash2 className="w-4 h-4" />
                                    </button>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            <CampaignWizard
                isOpen={isWizardOpen}
                onClose={() => setIsWizardOpen(false)}
                onSuccess={fetchCampaigns}
            />

            <UpgradeModal
                isOpen={upgradeModal.isOpen}
                onClose={() => setUpgradeModal({ ...upgradeModal, isOpen: false })}
                currentPlan={upgradeModal.currentPlan}
                limit={upgradeModal.limit}
            />
        </div>
    );
}

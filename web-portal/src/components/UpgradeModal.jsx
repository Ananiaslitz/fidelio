import React from 'react';
import { X, Zap, Check } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function UpgradeModal({ isOpen, onClose, currentPlan, limit }) {
    const navigate = useNavigate();

    if (!isOpen) return null;

    const plans = [
        {
            name: 'Pro',
            price: 199,
            features: ['Campanhas ilimitadas', 'Até 1.000 clientes', 'Suporte prioritário', 'Analytics avançado'],
            popular: true
        },
        {
            name: 'Enterprise',
            price: 499,
            features: ['Tudo do Pro', 'Clientes ilimitados', 'Suporte 24/7', 'API dedicada', 'Gerente de conta']
        }
    ];

    const handleUpgrade = (planName) => {
        // Navigate to checkout with selected plan
        navigate('/checkout', { state: { plan: planName.toLowerCase() } });
    };

    return (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
                {/* Header */}
                <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900">Limite de Campanhas Atingido</h2>
                        <p className="text-gray-600 mt-1">
                            Você atingiu o limite de <span className="font-semibold">{limit} campanha{limit > 1 ? 's' : ''}</span> do plano {currentPlan}
                        </p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                {/* Content */}
                <div className="p-6">
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
                        <div className="flex items-start gap-3">
                            <Zap className="w-5 h-5 text-blue-600 mt-0.5" />
                            <div>
                                <h3 className="font-semibold text-blue-900">Faça upgrade e cresça sem limites!</h3>
                                <p className="text-blue-700 text-sm mt-1">
                                    Escolha um plano superior para criar campanhas ilimitadas e alcançar mais clientes.
                                </p>
                            </div>
                        </div>
                    </div>

                    {/* Plans Grid */}
                    <div className="grid md:grid-cols-2 gap-6">
                        {plans.map((plan) => (
                            <div
                                key={plan.name}
                                className={`relative border-2 rounded-xl p-6 transition-all hover:shadow-lg ${plan.popular
                                        ? 'border-blue-500 bg-gradient-to-b from-blue-50 to-white'
                                        : 'border-gray-200 hover:border-blue-300'
                                    }`}
                            >
                                {plan.popular && (
                                    <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                                        <span className="bg-blue-600 text-white text-xs font-bold px-3 py-1 rounded-full">
                                            MAIS POPULAR
                                        </span>
                                    </div>
                                )}

                                <div className="text-center mb-6">
                                    <h3 className="text-2xl font-bold text-gray-900">{plan.name}</h3>
                                    <div className="mt-3">
                                        <span className="text-4xl font-bold text-gray-900">R$ {plan.price}</span>
                                        <span className="text-gray-600">/mês</span>
                                    </div>
                                </div>

                                <ul className="space-y-3 mb-6">
                                    {plan.features.map((feature, idx) => (
                                        <li key={idx} className="flex items-start gap-2">
                                            <Check className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
                                            <span className="text-gray-700">{feature}</span>
                                        </li>
                                    ))}
                                </ul>

                                <button
                                    onClick={() => handleUpgrade(plan.name)}
                                    className={`w-full py-3 px-4 rounded-lg font-semibold transition-colors ${plan.popular
                                            ? 'bg-blue-600 text-white hover:bg-blue-700'
                                            : 'bg-gray-100 text-gray-900 hover:bg-gray-200'
                                        }`}
                                >
                                    Fazer Upgrade
                                </button>
                            </div>
                        ))}
                    </div>

                    <p className="text-center text-sm text-gray-500 mt-6">
                        Você pode cancelar ou fazer downgrade a qualquer momento
                    </p>
                </div>
            </div>
        </div>
    );
}

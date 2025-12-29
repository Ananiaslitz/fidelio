import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { loadStripe } from '@stripe/stripe-js';
import {
    Elements,
    CardNumberElement,
    CardExpiryElement,
    CardCvcElement,
    useStripe,
    useElements
} from '@stripe/react-stripe-js';
import { ShieldCheck, Lock, ArrowRight, Loader2, Building, Mail, Key, CreditCard, Calendar } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import Logo from '../components/Logo';

// Replace with your actual Publishable Key
const stripePromise = loadStripe('pk_test_TYooMQauvdEDq54NiTphI7jx');

function CheckoutForm({ plan }) {
    const stripe = useStripe();
    const elements = useElements();
    const { login } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const navigate = useNavigate();

    // Form State
    const [formData, setFormData] = useState({
        companyName: '',
        cnpj: '',
        email: '',
        password: ''
    });

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (event) => {
        event.preventDefault();
        setLoading(true);
        setError(null);

        if (!stripe || !elements) {
            setLoading(false);
            return;
        }

        // Basic validation
        if (!formData.companyName || !formData.cnpj || !formData.email || !formData.password) {
            setError('Por favor, preencha todos os campos da empresa.');
            setLoading(false);
            return;
        }

        // Mock payment processing since we don't have a backend here
        setTimeout(() => {
            setLoading(false);
            // Log the user in with the registered data
            login({
                name: formData.companyName,
                email: formData.email,
                cnpj: formData.cnpj
            });
            alert('Conta criada e pagamento processado com sucesso! Bem-vindo ao Backly.');
            navigate('/dashboard');
        }, 2000);
    };

    return (
        <form onSubmit={handleSubmit} className="space-y-8">
            {/* Business Details Section */}
            <div className="space-y-6">
                <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2 border-b border-gray-100 pb-2">
                    <Building className="w-5 h-5 text-fidelio-primary" />
                    Dados da Empresa
                </h3>

                <div className="grid md:grid-cols-2 gap-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Nome da Loja</label>
                        <input
                            type="text"
                            name="companyName"
                            required
                            value={formData.companyName}
                            onChange={handleInputChange}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                            placeholder="Sua Loja"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">CNPJ</label>
                        <input
                            type="text"
                            name="cnpj"
                            required
                            value={formData.cnpj}
                            onChange={handleInputChange}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                            placeholder="00.000.000/0000-00"
                        />
                    </div>
                </div>

                <div className="grid md:grid-cols-2 gap-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Email Admin</label>
                        <div className="relative">
                            <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                            <input
                                type="email"
                                name="email"
                                required
                                value={formData.email}
                                onChange={handleInputChange}
                                className="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                placeholder="admin@loja.com"
                            />
                        </div>
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Senha</label>
                        <div className="relative">
                            <Key className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                            <input
                                type="password"
                                name="password"
                                required
                                value={formData.password}
                                onChange={handleInputChange}
                                className="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                placeholder="••••••••"
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* Payment Section */}
            <div className="space-y-6">
                <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2 border-b border-gray-100 pb-2">
                    <ShieldCheck className="w-5 h-5 text-fidelio-primary" />
                    Pagamento
                </h3>

                <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Nome no Cartão</label>
                    <input
                        type="text"
                        required
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                        placeholder="Nome como está no cartão"
                    />
                </div>
                <div className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Número do Cartão</label>
                        <div className="relative">
                            <CreditCard className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 z-10" />
                            <div className="p-3.5 pl-12 rounded-xl border border-gray-200 focus-within:border-fidelio-primary focus-within:ring-2 focus-within:ring-fidelio-primary/20 bg-white transition-all">
                                <CardNumberElement options={{
                                    showIcon: false,
                                    style: {
                                        base: { fontSize: '16px', color: '#1f2937', '::placeholder': { color: '#9ca3af' } },
                                        invalid: { color: '#ef4444' },
                                    }
                                }} />
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Validade</label>
                            <div className="relative">
                                <Calendar className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 z-10" />
                                <div className="p-3.5 pl-12 rounded-xl border border-gray-200 focus-within:border-fidelio-primary focus-within:ring-2 focus-within:ring-fidelio-primary/20 bg-white transition-all">
                                    <CardExpiryElement options={{
                                        style: {
                                            base: { fontSize: '16px', color: '#1f2937', '::placeholder': { color: '#9ca3af' } },
                                            invalid: { color: '#ef4444' },
                                        }
                                    }} />
                                </div>
                            </div>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">CVC</label>
                            <div className="relative">
                                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 z-10" />
                                <div className="p-3.5 pl-12 rounded-xl border border-gray-200 focus-within:border-fidelio-primary focus-within:ring-2 focus-within:ring-fidelio-primary/20 bg-white transition-all">
                                    <CardCvcElement options={{
                                        style: {
                                            base: { fontSize: '16px', color: '#1f2937', '::placeholder': { color: '#9ca3af' } },
                                            invalid: { color: '#ef4444' },
                                        }
                                    }} />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {error && <div className="text-red-500 text-sm bg-red-50 p-3 rounded-lg border border-red-100">{error}</div>}

            <button
                type="submit"
                disabled={!stripe || loading}
                className="w-full bg-blue-600 text-white py-4 rounded-xl font-bold hover:bg-blue-700 transition-all shadow-lg hover:shadow-xl flex items-center justify-center gap-2 group disabled:opacity-70 disabled:cursor-not-allowed"
            >
                {loading ? (
                    <Loader2 className="w-5 h-5 animate-spin" />
                ) : (
                    <>
                        Pagar & Cadastrar
                        <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                    </>
                )}
            </button>
            <p className="text-center text-xs text-gray-400 flex items-center justify-center gap-1">
                <ShieldCheck className="w-3 h-3" />
                Seus dados estão protegidos.
            </p>
        </form>
    );
}

export default function Checkout() {
    const location = useLocation();
    const plan = location.state?.plan || { title: 'Unknown', price: 'R$ 0' };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col">
            <header className="bg-white border-b border-gray-100 py-6">
                <div className="container mx-auto px-6 flex items-center justify-between">
                    <Logo className="text-3xl" />
                </div>
            </header>

            <div className="flex-1 container mx-auto px-6 py-12">
                <div className="max-w-4xl mx-auto grid md:grid-cols-2 gap-12 text-left">
                    {/* Order Summary */}
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900 mb-6">Resumo do Pedido</h2>
                        <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
                            <div className="flex justify-between items-center mb-4">
                                <div>
                                    <h3 className="text-lg font-bold text-gray-900">Plano {plan.title}</h3>
                                    <p className="text-gray-500 text-sm">Cobrado mensalmente</p>
                                </div>
                                <span className="text-2xl font-bold text-fidelio-primary">{plan.price}</span>
                            </div>
                            <hr className="border-gray-100 my-4" />
                            <ul className="space-y-3">
                                <li className="flex items-center gap-2 text-sm text-gray-600">
                                    <ShieldCheck className="w-4 h-4 text-green-500" />
                                    Garantia de 7 dias
                                </li>
                                <li className="flex items-center gap-2 text-sm text-gray-600">
                                    <ShieldCheck className="w-4 h-4 text-green-500" />
                                    Cancele quando quiser
                                </li>
                            </ul>
                        </div>
                    </div>

                    {/* Payment Form */}
                    <div>
                        <h2 className="text-2xl font-bold text-gray-900 mb-6">Pagamento</h2>
                        <Elements stripe={stripePromise}>
                            <CheckoutForm plan={plan} />
                        </Elements>
                    </div>
                </div>
            </div>
        </div>
    );
}

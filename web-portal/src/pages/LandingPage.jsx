import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { CheckCircle, BarChart3, ShieldCheck, ArrowRight, Instagram, Facebook, Linkedin } from 'lucide-react';
import Logo from '../components/Logo';
import DemoModal from '../components/DemoModal';

export default function LandingPage() {
    const navigate = useNavigate();
    const [isDemoModalOpen, setIsDemoModalOpen] = useState(false);
    const [plans, setPlans] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Fetch plans from backend
        fetch('/api/v1/plans')
            .then(res => res.json())
            .then(data => {
                // Parse features from JSON string to array
                const parsedPlans = data.map(plan => ({
                    ...plan,
                    features: typeof plan.features === 'string' ? JSON.parse(plan.features) : plan.features
                }));
                setPlans(parsedPlans);
                setLoading(false);
            })
            .catch(err => {
                console.error('Error fetching plans:', err);
                setLoading(false);
            });
    }, []);

    const handlePlanSelect = (plan) => {
        navigate('/checkout', { state: { plan: plan.slug } });
    };

    return (
        <div className="min-h-screen bg-white">
            <DemoModal isOpen={isDemoModalOpen} onClose={() => setIsDemoModalOpen(false)} />
            {/* Header */}
            <header className="border-b border-gray-100 sticky top-0 bg-white/80 backdrop-blur-md z-50">
                <div className="container mx-auto px-6 h-20 flex items-center justify-between">
                    <Logo className="text-3xl" />
                    <div className="flex items-center gap-6">
                        <nav className="hidden md:flex gap-6 text-sm font-medium text-gray-600">
                            <a href="#features" className="hover:text-fidelio-primary transition-colors">Funcionalidades</a>
                            <a href="#pricing" className="hover:text-fidelio-primary transition-colors">Preços</a>
                        </nav>
                        <Link
                            to="/login"
                            className="bg-blue-600 text-white px-5 py-2.5 rounded-full text-sm font-medium hover:bg-blue-700 transition-all shadow-lg hover:shadow-xl"
                        >
                            Acesso Lojista
                        </Link>
                    </div>
                </div>
            </header>

            {/* Hero Section */}
            <section className="relative pt-24 pb-32 overflow-hidden">
                <div className="container mx-auto px-6 text-center max-w-4xl">
                    <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-fidelio-secondary/10 text-fidelio-secondary text-xs font-bold uppercase tracking-wider mb-8">
                        <span className="w-2 h-2 rounded-full bg-fidelio-secondary animate-pulse"></span>
                        Nova Versão 2.0 Disponível
                    </div>
                    <h1 className="text-5xl md:text-7xl font-bold text-fidelio-black leading-tight mb-6 tracking-tight">
                        Fidelize seus clientes com <span className="text-fidelio-secondary">inteligência</span> e estilo.
                    </h1>
                    <p className="text-xl text-gray-500 mb-10 max-w-2xl mx-auto leading-relaxed">
                        Uma plataforma completa de fidelidade digital que substitui cartões de papel por dados, engajamento e retorno garantido.
                    </p>
                    <div className="flex flex-col sm:flex-row gap-4 justify-center">
                        <a href="#pricing" className="bg-blue-600 text-white px-8 py-4 rounded-full font-bold text-lg hover:bg-blue-700 transition-all shadow-xl hover:shadow-2xl flex items-center justify-center gap-2 group">
                            Começar Agora
                            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                        </a>
                        <button
                            onClick={() => setIsDemoModalOpen(true)}
                            className="bg-gray-100 text-gray-700 px-8 py-4 rounded-full font-bold text-lg hover:bg-gray-200 transition-all"
                        >
                            Agendar Demo
                        </button>
                    </div>
                </div>
            </section>

            {/* Features Grid */}
            <section id="features" className="py-24 bg-gray-50">
                <div className="container mx-auto px-6">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl font-bold text-fidelio-black mb-4">Tudo o que você precisa</h2>
                        <p className="text-gray-500">Ferramentas poderosas para crescer seu negócio.</p>
                    </div>
                    <div className="grid md:grid-cols-3 gap-8">
                        <FeatureCard
                            icon={<ShieldCheck className="w-10 h-10 text-fidelio-secondary" />}
                            title="Segurança Total"
                            description="Validação via QR Code dinâmico e geolocalização antifraude."
                        />
                        <FeatureCard
                            icon={<BarChart3 className="w-10 h-10 text-blue-500" />}
                            title="Dashboard em Tempo Real"
                            description="Acompanhe o ROI de cada campanha e conheça seus melhores clientes."
                        />
                        <FeatureCard
                            icon={<CheckCircle className="w-10 h-10 text-green-500" />}
                            title="Campanhas Automáticas"
                            description="Recupere clientes inativos com disparos automáticos de ofertas."
                        />
                    </div>
                </div>
            </section>

            {/* Pricing Section */}
            <section id="pricing" className="py-24 bg-white">
                <div className="container mx-auto px-6">
                    <div className="text-center mb-16">
                        <h2 className="text-3xl font-bold text-fidelio-black mb-4">Planos que cabem no seu bolso</h2>
                        <p className="text-gray-500">Comece grátis e escale conforme seu negócio cresce.</p>
                    </div>

                    <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
                        {loading ? (
                            <p className="col-span-3 text-center text-gray-500">Carregando planos...</p>
                        ) : (
                            plans.map((plan) => (
                                <PricingCard
                                    key={plan.slug}
                                    title={plan.name}
                                    price={plan.priceMonthly === 0 ? 'R$ 0' : `R$ ${plan.priceMonthly}`}
                                    period={plan.priceMonthly !== 0 ? '/mês' : ''}
                                    highlighted={plan.isPopular}
                                    features={plan.features}
                                    onSelect={() => handlePlanSelect(plan)}
                                />
                            ))
                        )}
                    </div>
                </div>
            </section>

            {/* Footer */}
            {/* Footer */}
            <footer className="bg-fidelio-black text-white pt-20 pb-10">
                <div className="container mx-auto px-6">
                    <div className="grid md:grid-cols-4 gap-12 mb-16">
                        <div className="space-y-6">
                            <Logo className="text-3xl" white={true} />
                            <p className="text-gray-400 text-sm leading-relaxed">
                                Transformando clientes ocasionais em fãs leais através da tecnologia e inteligência de dados.
                            </p>
                            <div className="flex gap-4">
                                <a href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-fidelio-primary transition-colors">
                                    <Instagram className="w-5 h-5" />
                                </a>
                                <a href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-fidelio-primary transition-colors">
                                    <Facebook className="w-5 h-5" />
                                </a>
                                <a href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-fidelio-primary transition-colors">
                                    <Linkedin className="w-5 h-5" />
                                </a>
                            </div>
                        </div>

                        <div>
                            <h4 className="font-bold mb-6">Produto</h4>
                            <ul className="space-y-4 text-sm text-gray-400">
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Recursos</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Preços</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Integrações</a></li>
                            </ul>
                        </div>

                        <div>
                            <h4 className="font-bold mb-6">Empresa</h4>
                            <ul className="space-y-4 text-sm text-gray-400">
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Sobre Nós</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Carreiras</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Blog</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Contato</a></li>
                            </ul>
                        </div>

                        <div>
                            <h4 className="font-bold mb-6">Legal</h4>
                            <ul className="space-y-4 text-sm text-gray-400">
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Termos de Uso</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Privacidade</a></li>
                                <li><a href="#" className="hover:text-fidelio-primary transition-colors">Cookies</a></li>
                            </ul>
                        </div>
                    </div>

                    <div className="border-t border-white/10 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
                        <p className="text-gray-500 text-sm">
                            &copy; 2024 Backly Platform. Todos os direitos reservados.
                        </p>
                        <p className="text-gray-600 text-xs flex items-center gap-1">
                            Feito com <span className="text-red-500">♥</span> em São Paulo
                        </p>
                    </div>
                </div>
            </footer>
        </div>
    );
}

function FeatureCard({ icon, title, description }) {
    return (
        <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
            <div className="mb-6 bg-gray-50 w-16 h-16 rounded-2xl flex items-center justify-center">
                {icon}
            </div>
            <h3 className="text-xl font-bold mb-3 text-fidelio-black">{title}</h3>
            <p className="text-gray-500 leading-relaxed">{description}</p>
        </div>
    );
}

function PricingCard({ title, price, period, features, highlighted = false }) {
    const navigate = useNavigate();

    const handleSelectPlan = () => {
        navigate('/checkout', { state: { plan: { title, price } } });
    };

    return (
        <div className={`p-8 rounded-2xl border ${highlighted ? 'bg-gradient-to-b from-blue-600 to-blue-800 text-white border-blue-600 shadow-xl scale-105' : 'bg-white border-gray-100 shadow-sm'} relative flex flex-col`}>
            {highlighted && (
                <div className="absolute top-0 right-0 bg-white text-blue-600 text-xs font-bold px-3 py-1 rounded-bl-xl rounded-tr-xl border-l border-b border-blue-100">
                    POPULAR
                </div>
            )}
            <h3 className={`text-xl font-bold mb-2 ${highlighted ? 'text-white' : 'text-fidelio-black'}`}>{title}</h3>
            <div className="mb-6">
                <span className="text-4xl font-bold">{price}</span>
                {period && <span className={`text-sm ${highlighted ? 'text-blue-100' : 'text-gray-500'}`}>{period}</span>}
            </div>

            <ul className="space-y-4 mb-8 flex-1">
                {features.map((feature, index) => (
                    <li key={index} className="flex items-center gap-3">
                        <CheckCircle className={`w-5 h-5 ${highlighted ? 'text-fidelio-secondary' : 'text-green-500'}`} />
                        <span className={`text-sm ${highlighted ? 'text-blue-50' : 'text-gray-600'}`}>{feature}</span>
                    </li>
                ))}
            </ul>

            <button
                onClick={handleSelectPlan}
                className={`w-full py-3 rounded-xl font-bold transition-all ${highlighted
                    ? 'bg-white text-blue-600 hover:bg-blue-50'
                    : 'bg-gray-50 text-gray-900 hover:bg-gray-100'
                    }`}>
                Escolher {title}
            </button>
        </div>
    );
}

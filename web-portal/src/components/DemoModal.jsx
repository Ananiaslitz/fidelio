import React, { useState } from 'react';
import { X, CheckCircle, Loader2, Calendar } from 'lucide-react';

export default function DemoModal({ isOpen, onClose }) {
    const [loading, setLoading] = useState(false);
    const [submitted, setSubmitted] = useState(false);

    // Form state
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        company: '',
        preferredDate: ''
    });

    if (!isOpen) return null;

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            const response = await fetch('/api/v1/demo-request', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData),
            });

            if (!response.ok) {
                throw new Error('Failed to submit demo request');
            }

            setSubmitted(true);
        } catch (error) {
            console.error('Error submitting demo request:', error);
            alert('Erro ao enviar solicitação. Por favor, tente novamente.');
        } finally {
            setLoading(false);
        }
    };

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200">
            <div className="bg-white rounded-3xl shadow-2xl w-full max-w-lg overflow-hidden animate-in zoom-in-95 duration-200">
                {/* Header */}
                <div className="px-8 py-6 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
                    <div>
                        <h2 className="text-xl font-bold text-gray-900">Agendar Demonstração</h2>
                        <p className="text-sm text-gray-500">Conheça o poder do Backly na prática</p>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-gray-100 rounded-full transition-colors text-gray-400 hover:text-gray-600"
                    >
                        <X className="w-5 h-5" />
                    </button>
                </div>

                <div className="p-8">
                    {submitted ? (
                        <div className="text-center py-8">
                            <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
                                <CheckCircle className="w-8 h-8" />
                            </div>
                            <h3 className="text-2xl font-bold text-gray-900 mb-2">Solicitação Recebida!</h3>
                            <p className="text-gray-500 mb-8 max-w-xs mx-auto">
                                Nosso time de especialistas entrará em contato em breve para agendar sua demo personalizada.
                            </p>
                            <button
                                onClick={onClose}
                                className="bg-gray-900 text-white px-8 py-3 rounded-xl font-bold hover:bg-gray-800 transition-all w-full"
                            >
                                Fechar
                            </button>
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className="space-y-5">
                            <div className="grid md:grid-cols-2 gap-5">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Seu Nome</label>
                                    <input
                                        required
                                        type="text"
                                        name="name"
                                        placeholder="João Silva"
                                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                        onChange={handleChange}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Nome da Empresa</label>
                                    <input
                                        required
                                        type="text"
                                        name="company"
                                        placeholder="Minha Loja"
                                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                        onChange={handleChange}
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1.5">Email Corporativo</label>
                                <input
                                    required
                                    type="email"
                                    name="email"
                                    placeholder="joao@empresa.com"
                                    className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                    onChange={handleChange}
                                />
                            </div>

                            <div className="grid md:grid-cols-2 gap-5">
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">WhatsApp</label>
                                    <input
                                        required
                                        type="tel"
                                        name="phone"
                                        placeholder="(11) 99999-9999"
                                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                        onChange={handleChange}
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-gray-700 mb-1.5">Melhor Horário</label>
                                    <select
                                        name="preferredDate"
                                        className="w-full px-4 py-2.5 rounded-xl border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all bg-white"
                                        onChange={handleChange}
                                    >
                                        <option value="">Selecione...</option>
                                        <option value="morning">Manhã (09h - 12h)</option>
                                        <option value="afternoon">Tarde (13h - 18h)</option>
                                        <option value="flexible">Horário Flexível</option>
                                    </select>
                                </div>
                            </div>

                            <button
                                type="submit"
                                disabled={loading}
                                className="w-full py-4 rounded-xl font-bold text-lg bg-purple-600 text-white hover:bg-purple-700 transition-all flex items-center justify-center gap-2 mt-4 shadow-lg hover:shadow-xl disabled:opacity-70 disabled:cursor-not-allowed"
                            >
                                {loading ? (
                                    <>
                                        <Loader2 className="w-5 h-5 animate-spin" />
                                        Enviando...
                                    </>
                                ) : (
                                    <>
                                        <Calendar className="w-5 h-5" />
                                        Agendar Conversa
                                    </>
                                )}
                            </button>

                            <p className="text-center text-xs text-gray-400 mt-4">
                                Ao enviar, você concorda com nossa Política de Privacidade.
                            </p>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
}

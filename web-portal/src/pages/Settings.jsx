import React from 'react';
import { Settings as SettingsIcon, Save } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export default function Settings() {
    const { user } = useAuth();

    return (
        <div className="space-y-6">
            <div>
                <h1 className="text-2xl font-bold text-gray-900">Configurações</h1>
                <p className="text-gray-500">Gerencie os dados da sua loja e preferências.</p>
            </div>

            <div className="bg-white rounded-2xl border border-gray-100 p-8 max-w-2xl">
                <h2 className="text-lg font-bold text-gray-900 mb-6 flex items-center gap-2">
                    <SettingsIcon className="w-5 h-5 text-gray-400" />
                    Dados da Loja
                </h2>

                <form className="space-y-6">
                    <div className="grid md:grid-cols-2 gap-6">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Nome da Loja</label>
                            <input
                                type="text"
                                className="w-full px-4 py-2 rounded-lg border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                defaultValue={user?.name || "Loja Exemplo"}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">CNPJ</label>
                            <input
                                type="text"
                                className="w-full px-4 py-2 rounded-lg border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                                defaultValue={user?.cnpj || "00.000.000/0001-00"}
                            />
                        </div>
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Email de Contato</label>
                        <input
                            type="email"
                            className="w-full px-4 py-2 rounded-lg border border-gray-200 focus:border-fidelio-primary focus:ring-2 focus:ring-fidelio-primary/20 outline-none transition-all"
                            defaultValue={user?.email || "loja@exemplo.com"}
                        />
                    </div>

                    <div className="pt-4">
                        <button className="bg-blue-600 text-white px-6 py-2.5 rounded-xl text-sm font-medium flex items-center gap-2 hover:bg-blue-700 transition-colors shadow-lg">
                            <Save className="w-4 h-4" />
                            Salvar Alterações
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

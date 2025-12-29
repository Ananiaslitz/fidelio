import React from 'react';
import { Link, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, Trophy, Settings, LogOut, Menu, X, User, Megaphone, Moon, Sun } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import Logo from '../components/Logo';

export default function DashboardLayout() {
    const { logout, user } = useAuth();
    const { isDark, toggleTheme } = useTheme();
    const navigate = useNavigate();
    const location = useLocation();
    const [sidebarOpen, setSidebarOpen] = React.useState(false);

    const handleLogout = () => {
        logout();
        navigate('/');
    };

    // Default values if user is not set (backwards compatibility)
    const displayName = user?.name || 'Loja Exemplo';
    const displayEmail = user?.email || 'loja@exemplo.com';

    const navItems = [
        { icon: LayoutDashboard, label: 'Visão Geral', path: '/dashboard' },
        { icon: Megaphone, label: 'Campanhas', path: '/dashboard/campaigns' },
        { icon: Settings, label: 'Configurações', path: '/dashboard/settings' },
    ];

    return (
        <div className="flex h-screen bg-gray-50 dark:bg-[#0d1117]">
            {/* Mobile Sidebar Overlay */}
            {sidebarOpen && (
                <div
                    className="fixed inset-0 bg-black/50 z-40 lg:hidden"
                    onClick={() => setSidebarOpen(false)}
                />
            )}

            {/* Sidebar */}
            <aside className={`
                fixed inset-y-0 left-0 z-50 w-72 
                bg-gradient-to-br from-[#0d1117] via-[#161b22] to-[#0d1117]
                transform transition-transform duration-300 ease-in-out
                ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
                lg:translate-x-0 lg:static
                shadow-2xl border-r border-gray-800/50
            `}>
                <div className="flex flex-col h-full">
                    {/* Logo */}
                    <div className="p-6 border-b border-gray-800/50">
                        <Link to="/" className="block">
                            <Logo className="text-2xl brightness-0 invert" />
                        </Link>
                    </div>

                    {/* Navigation */}
                    <nav className="flex-1 px-4 py-6 space-y-2">
                        {navItems.map((item) => {
                            const isActive = location.pathname === item.path;
                            return (
                                <Link
                                    key={item.path}
                                    to={item.path}
                                    className={`
                                        group flex items-center gap-3 px-4 py-3.5 rounded-xl text-sm font-medium 
                                        transition-all duration-200 relative overflow-hidden
                                        ${isActive
                                            ? 'bg-gradient-to-r from-blue-600 to-blue-500 text-white shadow-lg shadow-blue-500/30'
                                            : 'text-gray-300 hover:bg-gray-800/50 hover:text-white'
                                        }
                                    `}
                                >
                                    {isActive && (
                                        <div className="absolute inset-0 bg-gradient-to-r from-blue-400/20 to-transparent animate-pulse" />
                                    )}
                                    <item.icon className={`w-5 h-5 relative z-10 ${isActive ? 'text-white' : 'text-gray-400 group-hover:text-white'}`} />
                                    <span className="relative z-10">{item.label}</span>
                                </Link>
                            );
                        })}
                    </nav>

                    {/* User Profile Section */}
                    <div className="p-4 border-t border-gray-700/50">
                        <div className="bg-gray-800/50 rounded-xl p-4 mb-3">
                            <div className="flex items-center gap-3 mb-3">
                                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                                    <User className="w-5 h-5 text-white" />
                                </div>
                                <div className="flex-1 min-w-0">
                                    <p className="text-sm font-semibold text-white truncate">{displayName}</p>
                                    <p className="text-xs text-gray-400 truncate">{displayEmail}</p>
                                </div>
                            </div>
                        </div>

                        <button
                            onClick={handleLogout}
                            className="flex items-center gap-3 w-full px-4 py-3 text-sm font-medium text-red-400 rounded-xl hover:bg-red-500/10 hover:text-red-300 transition-all duration-200 group"
                        >
                            <LogOut className="w-5 h-5 group-hover:rotate-12 transition-transform" />
                            Sair
                        </button>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
                <header className="h-20 bg-white dark:bg-[#161b22] border-b border-gray-100 dark:border-gray-800 flex items-center justify-between px-6 lg:px-8">
                    <button
                        className="lg:hidden p-2 text-gray-500 dark:text-gray-400"
                        onClick={() => setSidebarOpen(true)}
                    >
                        <Menu className="w-6 h-6" />
                    </button>

                    <div className="flex items-center justify-end w-full gap-4">
                        {/* Dark Mode Toggle */}
                        <button
                            onClick={toggleTheme}
                            className="p-2.5 rounded-xl bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                            aria-label="Toggle dark mode"
                        >
                            {isDark ? (
                                <Sun className="w-5 h-5 text-yellow-500" />
                            ) : (
                                <Moon className="w-5 h-5 text-gray-600" />
                            )}
                        </button>

                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                                <User className="w-5 h-5 text-white" />
                            </div>
                            <div className="hidden sm:block">
                                <p className="text-sm font-medium text-gray-900 dark:text-white">{displayName}</p>
                                <p className="text-xs text-gray-500 dark:text-gray-400">{displayEmail}</p>
                            </div>
                        </div>
                    </div>
                </header>

                <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-[#0d1117] p-6 lg:p-8">
                    <Outlet />
                </main>
            </div>
        </div>
    );
}

import React, { createContext, useContext, useState, useEffect } from 'react';

const ThemeContext = createContext();

export function ThemeProvider({ children }) {
    const [isDark, setIsDark] = useState(() => {
        // Check localStorage or system preference
        const saved = localStorage.getItem('theme');
        const shouldBeDark = saved ? saved === 'dark' : window.matchMedia('(prefers-color-scheme: dark)').matches;

        // Apply immediately to prevent flash
        if (shouldBeDark) {
            document.documentElement.classList.add('dark');
        } else {
            document.documentElement.classList.remove('dark');
        }

        return shouldBeDark;
    });

    useEffect(() => {
        // Update localStorage and document class
        const theme = isDark ? 'dark' : 'light';
        localStorage.setItem('theme', theme);

        const root = document.documentElement;

        // Force update
        if (isDark) {
            root.classList.add('dark');
            console.log('✅ Dark mode enabled - classList:', root.classList.value);
        } else {
            root.classList.remove('dark');
            console.log('☀️ Light mode enabled - classList:', root.classList.value);
        }

        // Double check after a tick
        setTimeout(() => {
            console.log('🔍 Final classList check:', root.classList.value);
        }, 100);
    }, [isDark]);

    const toggleTheme = () => {
        console.log('🔄 Toggling theme from', isDark ? 'dark' : 'light', 'to', isDark ? 'light' : 'dark');
        setIsDark(!isDark);
    };

    return (
        <ThemeContext.Provider value={{ isDark, toggleTheme }}>
            {children}
        </ThemeContext.Provider>
    );
}

export function useTheme() {
    const context = useContext(ThemeContext);
    if (!context) {
        throw new Error('useTheme must be used within ThemeProvider');
    }
    return context;
}

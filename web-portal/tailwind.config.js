/** @type {import('tailwindcss').Config} */
export default {
    darkMode: 'class',
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                fidelio: {
                    purple: '#6B2FBA',
                    blue: '#2E65F3',
                    bg: '#F5F5F7',
                    black: '#1D1D1D',
                    primary: '#2E65F3',
                    secondary: '#6B2FBA',
                }
            },
            fontFamily: {
                sans: ['Outfit', 'sans-serif'],
                nunito: ['Nunito', 'sans-serif'],
            },
        },
    },
    plugins: [],
}

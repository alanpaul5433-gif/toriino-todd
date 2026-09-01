/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f4ff',
          100: '#dde6ff',
          200: '#c3d0ff',
          300: '#9fb3ff',
          400: '#758aff',
          500: '#4f5fff',
          600: '#3a3df5',
          700: '#2f2ddb',
          800: '#2828b1',
          900: '#27268c',
          950: '#191752',
        },
      },
    },
  },
  plugins: [],
};

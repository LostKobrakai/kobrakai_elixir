// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")

const range = [...Array(100).keys()]
const delays = range.reduce((acc, i) => {
  return { ...acc, [`${i * 55}`]: `${i * 55}ms` };
}, {})
const delays_safe = range.map(i => `animation-delay-${i * 55}`)

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  darkMode: 'class',
  safelist: [...delays_safe],
  theme: {
    animationDelay: delays,
    screens: {
      'sm': '640px',
      'md': '768px',
      'lg': '1024px',
      'xl': '1280px',
      '2xl': '1800px',
    },
    fontSize: {
      xs: '0.75rem',
      sm: '0.875rem',
      base: '1rem',
      lg: '1.125rem',
      xl: '1.25rem',
      '2xl': '1.5rem',
      '3xl': '1.875rem',
      '4xl': '2.25rem',
      '5xl': '3rem',
      '6xl': '4rem',
    },
    extend: {
      typography: ({ theme }) => ({
        DEFAULT: {
          css: {
            '--tw-prose-body': '#333',
            '--tw-prose-headings': theme('colors.black')
          }
        }
      }),
      colors: {
        gray: {
          '100': '#f5f5f5',
          '200': '#eeeeee',
          '300': '#e0e0e0',
          '400': '#bdbdbd',
          '500': '#9e9e9e',
          '600': '#757575',
          '700': '#616161',
          '800': '#424242',
          '900': '#212121',
        }
      },
      animation: {
        'in': 'animateIn 250ms ease-out',
        'in-small': 'animateInSmall 250ms ease-out'
      },
      keyframes: {
        animateIn: {
          '0%': { opacity: 0, transform: 'translate3d(0,100%,0)' },
          '100%': { opacity: 1 }
        },
        animateInSmall: {
          '0%': { opacity: 0, transform: 'translate3d(0,2rem,0)' },
          '100%': { opacity: 1 }
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography')({
      target: 'legacy'
    }),
    require("@tailwindcss/forms"),
    require('@tailwindcss/aspect-ratio'),
    plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
    plugin(function ({ addUtilities, theme, e }) {
      const values = theme('animationDelay')
      var utilities = Object.entries(values).map(([key, value]) => {
        return {
          [`.${e(`animation-delay-${key}`)}`]: { animationDelay: `${value}` },
        }
      })
      addUtilities(utilities)
    })
  ]
}
// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex',
    "../deps/petal_components/**/*.*ex",
  ],
  theme: {
    extend: {
      colors: {
        primary: colors.teal,
        secondar: colors.blue,
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}

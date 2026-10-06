import {defineConfig} from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['js/**/*.test.js'],
    setupFiles: ['./vitest.setup.js']
  }
})

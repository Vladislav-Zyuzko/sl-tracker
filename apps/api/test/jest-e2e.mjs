import { swcTransform } from '../jest.config.mjs';

/**
 * Тесты, которым нужна настоящая PostgreSQL: проверка выдачи ключей задач под нагрузкой
 * и e2e на эндпоинты. Тестовая база создаётся и мигрируется самим тестом
 * (`prepareTestDatabase`) — jest-овский globalSetup грузится как CommonJS и до ESM-модулей
 * проекта не дотягивается.
 *
 * @type {import('jest').Config}
 */
export default {
  rootDir: '..',
  testEnvironment: 'node',
  testRegex: '.*\\.e2e-spec\\.ts$',
  extensionsToTreatAsEsm: ['.ts'],
  resolver: '<rootDir>/jest-resolver.cjs',
  transform: { '^.+\\.(t|j)s$': swcTransform },
  testTimeout: 120000,
};

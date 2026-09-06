/**
 * Unit-тесты: доменная логика без внешних зависимостей.
 * Тесты, которым нужна БД, живут в `test/` и запускаются через `test/jest-e2e.mjs`.
 *
 * NestJS 12 распространяется только в ESM, поэтому проект целиком ESM,
 * а Jest запускается с `--experimental-vm-modules` (см. npm-скрипты).
 */
export const swcTransform = [
  '@swc/jest',
  {
    jsc: {
      target: 'es2023',
      parser: { syntax: 'typescript', decorators: true },
      transform: { legacyDecorator: true, decoratorMetadata: true },
    },
    module: { type: 'es6' },
  },
];

/** См. комментарий в jest-resolver.cjs: `.js` в импортах, `.ts` на диске. */
export const esmResolver = './jest-resolver.cjs';

/** @type {import('jest').Config} */
export default {
  rootDir: 'src',
  testEnvironment: 'node',
  testRegex: '.*\\.spec\\.ts$',
  extensionsToTreatAsEsm: ['.ts'],
  resolver: '<rootDir>/../jest-resolver.cjs',
  transform: { '^.+\\.(t|j)s$': swcTransform },
  collectCoverageFrom: ['**/*.(t|j)s'],
  coverageDirectory: '../coverage',
};

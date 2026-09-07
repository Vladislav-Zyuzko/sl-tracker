export { AuthModule } from './auth.module.js';
export { AuthService, safeNextPath } from './auth.service.js';
export type { LoginResult } from './auth.service.js';
export { AuthRepository } from './auth.repository.js';
export type { ProviderProfile } from './auth.repository.js';
export {
  ACCESS_DENIED_PATH,
  AUTH_ERROR_CODES,
  DEFAULT_AFTER_LOGIN_PATH,
  LOGIN_PATH,
  SESSION_COOKIE_NAME,
  YANDEX_PROVIDER,
} from './auth.constants.js';
export type { AuthErrorCode } from './auth.constants.js';
export type { AuthContext, AuthenticatedUser } from './auth.types.js';
export { CurrentSession, CurrentUser } from './decorators/current-user.decorator.js';
export { Public } from './decorators/public.decorator.js';
export { RateLimit } from './decorators/rate-limit.decorator.js';
export { SessionGuard, extractToken } from './guards/session.guard.js';
export { AccessDeniedTicketStore } from './access-denied-ticket.store.js';
export { OauthStateStore } from './oauth-state.store.js';
export type { OauthStatePayload } from './oauth-state.store.js';
export {
  YANDEX_OAUTH,
  YandexOAuthError,
  type YandexOAuthPort,
  type YandexProfile,
} from './yandex/yandex-oauth.port.js';

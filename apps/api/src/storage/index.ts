export { StorageModule } from './storage.module.js';
export { ObjectStorageService, SIGNED_URL_TTL_SECONDS } from './object-storage.service.js';
export type { StoredObject } from './object-storage.service.js';
export { COVER_ALLOWED_TYPES, COVER_MAX_BYTES, detectImageType, extensionFor } from './image.js';
export type { ImageType } from './image.js';
export {
  ATTACHMENT_FILE_NAME_MAX_LENGTH,
  ATTACHMENT_MAX_BYTES,
  FALLBACK_CONTENT_TYPE,
  PREVIEWABLE_IMAGE_TYPES,
  detectFileType,
  isPreviewableImage,
  safeFileName,
} from './file-type.js';
export type { DetectedFileType } from './file-type.js';

export { CommentsModule } from './comments.module.js';
export { CommentsService, commentPermissionsFor } from './comments.service.js';
export type { CommentPermissions, CommentsPage, CommentView } from './comments.service.js';
export { CommentsRepository } from './comments.repository.js';
export type { CommentRow } from './comments.repository.js';
export { COMMENT_BODY_MAX_LENGTH, normalizeCommentBody } from './comment-body.js';

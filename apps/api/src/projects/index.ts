export { ProjectsModule } from './projects.module.js';
export { ProjectsService } from './projects.service.js';
export { ProjectsRepository } from './projects.repository.js';
export type { ProjectLookup, ProjectRole, ProjectRow } from './projects.repository.js';
export { MembersRepository } from './members.repository.js';
export type { MemberRow } from './members.repository.js';
export { MembersService } from './members.service.js';
export { ProjectAccessService } from './project-access.service.js';
export type { ProjectContext } from './project-access.service.js';
export {
  FALLBACK_SLUG_BASE,
  RESERVED_SLUGS,
  SLUG_MAX_LENGTH,
  SLUG_PATTERN,
  slugBase,
  slugCandidate,
  slugify,
  transliterate,
  validateSlug,
} from './project-slug.js';
export { ProjectDto, ProjectListDto } from './dto/project.dto.js';

/**
 * Резолвер для ESM-проекта на TypeScript.
 *
 * В ESM импорты пишутся с расширением `.js`, а на диске рядом лежит `.ts`.
 * Обычный приём — `moduleNameMapper`, который срезает `.js` у всех относительных путей, —
 * ломает зависимости из node_modules: там `.js` и `.mjs` настоящие.
 *
 * Поэтому сначала пробуем разрешить путь как есть и только при неудаче отбрасываем
 * расширение. node_modules при этом не затрагиваются.
 */
module.exports = (request, options) => {
  try {
    return options.defaultResolver(request, options);
  } catch (error) {
    if (/^\.{1,2}\//.test(request) && request.endsWith('.js')) {
      return options.defaultResolver(request.slice(0, -'.js'.length), options);
    }
    throw error;
  }
};

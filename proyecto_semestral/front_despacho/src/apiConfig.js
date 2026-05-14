/**
 * Base de API: vacío = mismo origen (Nginx en Docker reenvía a los backends).
 * En desarrollo, Vite proxy redirige /api/v1/* a los puertos locales.
 */
export const API_BASE = (import.meta.env.VITE_API_BASE_URL || "").replace(
  /\/$/,
  ""
);

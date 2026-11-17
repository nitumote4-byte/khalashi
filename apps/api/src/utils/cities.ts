/**
 * All-India free-text cities: trim, casefold, collapse spaces, apply common aliases.
 */
const ALIASES: Record<string, string> = {
  bombay: "mumbai",
  bangalore: "bengaluru",
  bengalooru: "bengaluru",
  calcutta: "kolkata",
  madras: "chennai",
  poona: "pune",
  trivandrum: "thiruvananthapuram",
  baroda: "vadodara",
  gauhati: "guwahati",
  benares: "varanasi",
  banaras: "varanasi",
  simla: "shimla",
};

export function normalizeCity(raw: string): string {
  const collapsed = raw.trim().toLowerCase().replace(/\s+/g, " ");
  return ALIASES[collapsed] ?? collapsed;
}

export function displayCity(raw: string): string {
  return raw.trim().replace(/\s+/g, " ");
}

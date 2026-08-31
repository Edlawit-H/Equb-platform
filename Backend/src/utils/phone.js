/** Returns all phone format variants for a lookup query. */
export const phoneLookupVariants = (phone) => {
  const trimmed = phone.trim();
  const variants = new Set([trimmed]);

  if (trimmed.startsWith('0') && trimmed.length >= 10) {
    variants.add(`+251${trimmed.slice(1)}`);
    variants.add(`251${trimmed.slice(1)}`);
  }

  if (trimmed.startsWith('+251') && trimmed.length >= 12) {
    variants.add(`0${trimmed.slice(4)}`);
    variants.add(trimmed.slice(1));
  }

  if (trimmed.startsWith('251') && !trimmed.startsWith('+') && trimmed.length >= 11) {
    variants.add(`+${trimmed}`);
    variants.add(`0${trimmed.slice(3)}`);
  }

  return [...variants];
};

/** Normalizes any Ethiopian phone format to +251XXXXXXXXX. */
export const normalizePhone = (phone) => {
  const t = phone.trim();
  if (t.startsWith('+251')) return t;
  if (t.startsWith('251') && t.length >= 11) return `+${t}`;
  if (t.startsWith('0') && t.length >= 10) return `+251${t.slice(1)}`;
  return t;
};

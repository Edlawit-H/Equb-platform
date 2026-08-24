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

export const isValidPhoneNumber = (phone) => {
  if (!phone || typeof phone !== 'string') return false;
  const clean = phone.trim().replaceAll(/\s+/g, '');
  // Valid Ethiopian / international formats:
  // 09xxxxxxxx or 07xxxxxxxx (10 digits)
  // +2519xxxxxxxx or +2517xxxxxxxx (13 chars)
  // 2519xxxxxxxx or 2517xxxxxxxx (12 digits)
  // 9xxxxxxxx or 7xxxxxxxx (9 digits)
  // Or standard E.164: ^\+?[1-9]\d{7,14}$
  const ethiopianRegex = /^(?:\+251|251|0)?[79]\d{8}$/;
  const generalE164Regex = /^\+?[1-9]\d{7,14}$/;
  return ethiopianRegex.test(clean) || generalE164Regex.test(clean);
};

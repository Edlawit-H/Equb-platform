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

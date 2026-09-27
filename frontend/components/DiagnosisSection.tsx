export function DiagnosisSection({
  title,
  items,
  icon,
}: {
  title: string;
  items: string[];
  icon: React.ReactNode;
}) {
  if (items.length === 0) return null;

  return (
    <>
      <div className="flex items-center gap-1.5 text-xs font-bold uppercase text-muted mt-4 mb-1.5">
        {icon}
        {title}
      </div>
      <ul className="list-disc pl-5 space-y-1">
        {items.map((item, i) => (
          <li key={i} className="text-[0.92rem] text-body">
            {item}
          </li>
        ))}
      </ul>
    </>
  );
}

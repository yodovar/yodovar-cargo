'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { apiFetch } from '@/lib/api';

type PickupPoint = {
  id: string;
  key: string;
  city: string;
  addressTemplate: string;
};

const TEMPLATE_VARS = [
  { label: 'Код клиента', token: '{{clientCode}}' },
  { label: 'Имя', token: '{{clientName}}' },
  { label: 'Телефон', token: '{{clientPhone}}' },
] as const;
type TemplateToken = (typeof TEMPLATE_VARS)[number]['token'];

function withRequiredVars(text: string) {
  let out = text.trim();
  for (const v of TEMPLATE_VARS) {
    if (!out.includes(v.token)) {
      out = out ? `${out}\n${v.token}` : v.token;
    }
  }
  return out;
}

export default function PickupPointsPage() {
  const [items, setItems] = useState<PickupPoint[]>([]);
  const [err, setErr] = useState('');
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [createKey, setCreateKey] = useState('');
  const [createCity, setCreateCity] = useState('');
  const [createTemplate, setCreateTemplate] = useState(
    '收货人: ...\n手机号: ...\n...\n{{clientName}}, {{clientPhone}}',
  );

  const load = useCallback(async () => {
    setLoading(true);
    setErr('');
    try {
      const data = await apiFetch<PickupPoint[]>('/tariffs/pickup-points');
      setItems(data);
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  async function save(p: PickupPoint) {
    setErr('');
    try {
      await apiFetch(`/admin/pickup-points/${encodeURIComponent(p.key)}`, {
        method: 'PATCH',
        body: JSON.stringify({
          city: p.city,
          addressTemplate: p.addressTemplate,
        }),
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  async function remove(key: string) {
    if (!confirm(`Удалить пункт выдачи ${key}?`)) return;
    setErr('');
    try {
      await apiFetch(`/admin/pickup-points/${encodeURIComponent(key)}`, {
        method: 'DELETE',
      });
      await load();
    } catch (e) {
      setErr(e instanceof Error ? e.message : 'Ошибка');
    }
  }

  async function create(e: React.FormEvent) {
    e.preventDefault();
    const key = createKey.trim();
    const city = createCity.trim();
    const addressTemplate = withRequiredVars(createTemplate);
    setErr('');
    try {
      await apiFetch('/admin/pickup-points', {
        method: 'POST',
        body: JSON.stringify({ key, city, addressTemplate }),
      });
      setCreateKey('');
      setCreateCity('');
      setCreateTemplate('收货人: ...\n手机号: ...\n...\n{{clientName}}, {{clientPhone}}');
      setShowCreate(false);
      await load();
    } catch (error) {
      setErr(error instanceof Error ? error.message : 'Ошибка');
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900">Пункты выдачи</h1>
      <p className="mt-1 text-slate-600">
        Нажимайте на кнопки переменных — они вставляются в адрес по курсору.
      </p>

      {err && (
        <div className="mt-4 rounded-lg bg-orange-50 px-3 py-2 text-sm text-orange-700">
          {err}
        </div>
      )}

      {loading ? (
        <p className="mt-6">Загрузка…</p>
      ) : (
        <div className="mt-6 space-y-6">
          {items.map((p) => (
            <PickupPointRow key={p.id} initial={p} onSave={save} onDelete={remove} />
          ))}
        </div>
      )}

      <div className="mt-8">
        {!showCreate ? (
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            className="inline-flex h-10 items-center justify-center rounded-lg bg-slate-800 px-4 text-sm font-medium text-white hover:bg-slate-900"
          >
            + Новый пункт выдачи
          </button>
        ) : (
          <form
            onSubmit={create}
            className="space-y-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-4"
          >
            <h3 className="font-semibold">Новый пункт выдачи</h3>
            <div className="grid gap-2 sm:grid-cols-2">
              <input
                name="key"
                className="rounded border px-3 py-2 text-sm"
                placeholder="key (например dushanbe)"
                value={createKey}
                onChange={(e) => setCreateKey(e.target.value)}
                required
              />
              <input
                name="city"
                className="rounded border px-3 py-2 text-sm"
                placeholder="Город"
                value={createCity}
                onChange={(e) => setCreateCity(e.target.value)}
                required
              />
              <div className="sm:col-span-2">
                <TemplateEditor value={createTemplate} onChange={setCreateTemplate} />
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              <button type="submit" className="rounded-lg bg-slate-800 px-4 py-2 text-sm text-white">
                Создать
              </button>
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700"
              >
                Отмена
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

function PickupPointRow({
  initial,
  onSave,
  onDelete,
}: {
  initial: PickupPoint;
  onSave: (p: PickupPoint) => void;
  onDelete: (key: string) => void;
}) {
  const [p, setP] = useState(initial);
  const [editing, setEditing] = useState(false);
  useEffect(() => {
    setP(initial);
    setEditing(false);
  }, [initial]);

  return (
    <div className="rounded-xl border border-slate-200 bg-white p-4">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <span className="font-mono font-semibold">{p.key}</span>
        <div className="flex items-center gap-3">
          {!editing && (
            <button
              type="button"
              onClick={() => setEditing(true)}
              className="text-sm text-slate-700 hover:underline"
            >
              Изменить
            </button>
          )}
          <button type="button" onClick={() => onDelete(p.key)} className="text-sm text-orange-600">
            Удалить
          </button>
        </div>
      </div>
      {!editing ? (
        <div className="mt-3 grid gap-2 text-sm text-slate-700">
          <div><span className="text-slate-500">city:</span> {p.city}</div>
          <div>
            <span className="text-slate-500">addressTemplate:</span>
            <pre className="mt-1 whitespace-pre-wrap rounded border border-slate-200 bg-slate-50 p-2 text-xs">
              {p.addressTemplate}
            </pre>
          </div>
        </div>
      ) : (
        <>
          <div className="mt-3 grid gap-2">
            <label className="block text-sm">
              <span className="text-slate-600">city</span>
              <input
                className="mt-1 w-full rounded border border-slate-300 px-2 py-1"
                value={p.city}
                onChange={(e) => setP({ ...p, city: e.target.value })}
              />
            </label>
            <label className="block text-sm">
              <span className="text-slate-600">addressTemplate</span>
              <div className="mt-1">
                <TemplateEditor
                  value={p.addressTemplate}
                  onChange={(next) => setP({ ...p, addressTemplate: next })}
                />
              </div>
            </label>
          </div>
          <div className="mt-3 flex items-center gap-3">
            <button
              type="button"
              onClick={() => onSave({ ...p, addressTemplate: withRequiredVars(p.addressTemplate) })}
              className="rounded-lg bg-orange-600 px-4 py-2 text-sm text-white"
            >
              Сохранить
            </button>
            <button
              type="button"
              onClick={() => {
                setP(initial);
                setEditing(false);
              }}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm text-slate-700"
            >
              Отмена
            </button>
          </div>
        </>
      )}
    </div>
  );
}

function TemplateEditor({
  value,
  onChange,
}: {
  value: string;
  onChange: (next: string) => void;
}) {
  const editorRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const editor = editorRef.current;
    if (!editor) return;
    const current = readTemplateFromEditor(editor);
    if (current === value) return;
    renderTemplateToEditor(editor, value, onChange);
  }, [value, onChange]);

  function insertToken(token: TemplateToken) {
    const editor = editorRef.current;
    if (!editor) return;
    editor.focus();
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) {
      editor.appendChild(document.createTextNode(' '));
      const chip = createTokenChip(token, onChange);
      editor.appendChild(chip);
      editor.appendChild(document.createTextNode(' '));
      onChange(readTemplateFromEditor(editor));
      return;
    }
    const range = selection.getRangeAt(0);
    if (!editor.contains(range.commonAncestorContainer)) {
      editor.appendChild(document.createTextNode(' '));
      const chip = createTokenChip(token, onChange);
      editor.appendChild(chip);
      editor.appendChild(document.createTextNode(' '));
      onChange(readTemplateFromEditor(editor));
      return;
    }
    range.deleteContents();
    const rightSpace = document.createTextNode(' ');
    const chip = createTokenChip(token, onChange);
    const leftSpace = document.createTextNode(' ');
    range.insertNode(rightSpace);
    range.insertNode(chip);
    range.insertNode(leftSpace);
    range.setStartAfter(rightSpace);
    range.collapse(true);
    selection.removeAllRanges();
    selection.addRange(range);
    onChange(readTemplateFromEditor(editor));
  }

  return (
    <div className="rounded-lg border border-slate-300 p-2">
      <div
        ref={editorRef}
        contentEditable
        suppressContentEditableWarning
        onInput={(e) => onChange(readTemplateFromEditor(e.currentTarget))}
        className="min-h-[150px] rounded border border-slate-300 bg-white px-2 py-1 text-sm outline-none focus:ring-2 focus:ring-orange-200"
      />
      <div className="mt-2 flex flex-wrap items-center gap-2">
        {TEMPLATE_VARS.map((row) => (
          <button
            key={row.token}
            type="button"
            onClick={() => insertToken(row.token)}
            className="rounded-full border border-slate-300 bg-slate-50 px-3 py-1 text-xs font-medium text-slate-700 hover:bg-slate-100"
          >
            {row.label}
          </button>
        ))}
      </div>
      <p className="mt-2 text-xs text-slate-500">
        Нажмите кнопку, чтобы вставить оранжевый блок в текст. Удаление блока только через маленький × на самом блоке.
      </p>
    </div>
  );
}

function createTokenChip(token: TemplateToken, onChange: (next: string) => void): HTMLSpanElement {
  const chip = document.createElement('span');
  chip.setAttribute('data-token', token);
  chip.setAttribute('contenteditable', 'false');
  chip.className =
    'mx-1 inline-flex items-center gap-1 rounded-full bg-orange-100 px-2 py-[2px] text-xs font-semibold text-orange-800 align-middle';
  const label = TEMPLATE_VARS.find((x) => x.token === token)?.label ?? token;
  const text = document.createElement('span');
  text.textContent = label;
  const remove = document.createElement('button');
  remove.type = 'button';
  remove.textContent = '×';
  remove.className =
    'rounded-full bg-orange-200 px-1 text-[10px] leading-none text-orange-900 hover:bg-orange-300';
  remove.onclick = (ev) => {
    ev.preventDefault();
    const parent = chip.parentElement as HTMLDivElement | null;
    chip.remove();
    if (parent) onChange(readTemplateFromEditor(parent));
  };
  chip.appendChild(text);
  chip.appendChild(remove);
  return chip;
}

function readTemplateFromEditor(editor: HTMLDivElement): string {
  const out: string[] = [];
  editor.childNodes.forEach((node) => {
    if (node.nodeType === Node.TEXT_NODE) {
      out.push(node.textContent ?? '');
      return;
    }
    if (node.nodeType === Node.ELEMENT_NODE) {
      const el = node as HTMLElement;
      const token = el.getAttribute('data-token');
      if (token) out.push(token);
      else out.push(el.textContent ?? '');
    }
  });
  return out.join('');
}

function renderTemplateToEditor(
  editor: HTMLDivElement,
  value: string,
  onChange: (next: string) => void,
) {
  const tokenRegex = /(\{\{clientCode\}\}|\{\{clientName\}\}|\{\{clientPhone\}\})/g;
  editor.innerHTML = '';
  let last = 0;
  for (const m of value.matchAll(tokenRegex)) {
    const idx = m.index ?? 0;
    const text = value.slice(last, idx);
    if (text) editor.appendChild(document.createTextNode(text));
    const token = m[0] as TemplateToken;
    editor.appendChild(createTokenChip(token, onChange));
    last = idx + token.length;
  }
  const tail = value.slice(last);
  if (tail) editor.appendChild(document.createTextNode(tail));
}

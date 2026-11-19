import { useMemo, useState } from 'react';
import JSZip from 'jszip';
import { Check, Copy, Download, FileCode2, FolderOpen, Search } from 'lucide-react';

const rawModules = import.meta.glob('/flutter_app/**/*', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

interface FileEntry {
  path: string;
  content: string;
  lines: number;
  group: string;
}

function getGroup(path: string): string {
  if (!path.startsWith('lib/')) return 'Root & Firebase Config';
  if (path.startsWith('lib/core/')) return 'lib/core';
  if (path.startsWith('lib/shared/')) return 'lib/shared';
  if (path.startsWith('lib/features/')) {
    const parts = path.split('/');
    return `lib/features/${parts[2] ?? ''}`;
  }
  return 'lib (Entry)';
}

export function FlutterCodeExplorer() {
  const files = useMemo<FileEntry[]>(() => {
    return Object.entries(rawModules)
      .map(([fullPath, content]) => {
        const cleanPath = fullPath.replace(/^\/flutter_app\//, '');
        return {
          path: cleanPath,
          content,
          lines: content.split('\n').length,
          group: getGroup(cleanPath),
        };
      })
      .sort((a, b) => a.path.localeCompare(b.path));
  }, []);

  const [selectedPath, setSelectedPath] = useState<string>(
    () => files.find((f) => f.path === 'README.md')?.path ?? files[0]?.path ?? '',
  );
  const [search, setSearch] = useState('');
  const [copied, setCopied] = useState(false);
  const [downloadingZip, setDownloadingZip] = useState(false);

  const filteredFiles = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return files;
    return files.filter(
      (f) =>
        f.path.toLowerCase().includes(q) || f.content.toLowerCase().includes(q),
    );
  }, [files, search]);

  const grouped = useMemo(() => {
    const map = new Map<string, FileEntry[]>();
    for (const file of filteredFiles) {
      const list = map.get(file.group) ?? [];
      list.push(file);
      map.set(file.group, list);
    }
    return Array.from(map.entries());
  }, [filteredFiles]);

  const activeFile =
    files.find((f) => f.path === selectedPath) ?? filteredFiles[0] ?? null;

  const handleCopy = async () => {
    if (!activeFile) return;
    await navigator.clipboard.writeText(activeFile.content);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  };

  const handleDownloadZip = async () => {
    setDownloadingZip(true);
    try {
      const zip = new JSZip();
      for (const file of files) {
        zip.file(`truckflow/${file.path}`, file.content);
      }
      const blob = await zip.generateAsync({ type: 'blob' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'truckflow-flutter-firebase.zip';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } finally {
      setDownloadingZip(false);
    }
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl p-4">
        <div>
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
            Flutter 3.22+ & Firebase Complete Codebase
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            {files.length} production files ·{' '}
            {files.reduce((s, f) => s + f.lines, 0).toLocaleString()} total lines ·
            Riverpod 2 + GoRouter + Firestore Rules & Indexes
          </p>
        </div>
        <button
          onClick={handleDownloadZip}
          disabled={downloadingZip}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-slate-950 text-sm font-semibold transition-colors whitespace-nowrap shrink-0 cursor-pointer"
        >
          <Download className="w-4 h-4" />
          {downloadingZip ? 'Packaging ZIP...' : 'Download Flutter ZIP'}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 items-start">
        <aside className="lg:col-span-4 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
          <div className="p-3 border-b border-slate-200 dark:border-slate-800">
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Filter files or Dart symbols..."
                className="w-full pl-9 pr-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-slate-900 dark:text-slate-100 focus:outline-none focus:ring-2 focus:ring-amber-500"
              />
            </div>
          </div>
          <div className="max-h-[640px] overflow-y-auto p-2 space-y-3">
            {grouped.map(([group, groupFiles]) => (
              <div key={group}>
                <div className="flex items-center gap-1.5 px-2 py-1 text-xs font-semibold text-slate-500 dark:text-slate-400">
                  <FolderOpen className="w-3.5 h-3.5" />
                  <span>{group}</span>
                </div>
                <div className="space-y-0.5 mt-0.5">
                  {groupFiles.map((file) => {
                    const isSelected = activeFile?.path === file.path;
                    return (
                      <button
                        key={file.path}
                        onClick={() => setSelectedPath(file.path)}
                        className={`w-full flex items-center justify-between gap-2 px-2.5 py-1.5 rounded-lg text-left text-xs transition-colors cursor-pointer ${
                          isSelected
                            ? 'bg-slate-900 text-white dark:bg-amber-500 dark:text-slate-950 font-semibold'
                            : 'text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800'
                        }`}
                      >
                        <span className="flex items-center gap-1.5 truncate">
                          <FileCode2 className="w-3.5 h-3.5 shrink-0 opacity-70" />
                          <span className="truncate">{file.path}</span>
                        </span>
                        <span className="tabular-nums opacity-65 shrink-0">
                          {file.lines}L
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        </aside>

        <section className="lg:col-span-8 border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 rounded-xl overflow-hidden">
          {activeFile ? (
            <>
              <div className="flex items-center justify-between gap-4 px-4 py-3 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950/60">
                <div className="min-w-0">
                  <div className="font-mono text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">
                    {activeFile.path}
                  </div>
                  <div className="text-xs text-slate-500 dark:text-slate-400 tabular-nums">
                    {activeFile.lines} lines
                  </div>
                </div>
                <button
                  onClick={handleCopy}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 text-xs font-medium text-slate-800 dark:text-slate-100 transition-colors whitespace-nowrap shrink-0 cursor-pointer"
                >
                  {copied ? (
                    <>
                      <Check className="w-3.5 h-3.5 text-emerald-600" />
                      Copied
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      Copy File
                    </>
                  )}
                </button>
              </div>
              <div className="max-h-[640px] overflow-auto bg-slate-950 text-slate-100 p-4">
                <pre className="font-mono text-xs leading-5 whitespace-pre">
                  <code>{activeFile.content}</code>
                </pre>
              </div>
            </>
          ) : (
            <div className="p-12 text-center text-sm text-slate-500">
              No matching files found.
            </div>
          )}
        </section>
      </div>
    </div>
  );
}

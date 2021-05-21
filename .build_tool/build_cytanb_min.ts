import * as fs from 'fs';
import * as readline from 'readline';
import { spawn } from 'child_process';
import { minify } from 'luamin';

const cytanb_function_set = async () => {
  const p = spawn('lua', ['list_cytanb_functions.lua']);
  const rl = readline.createInterface({
    input: p.stdout,
  });

  try {
    const s = new Set<string>();
    for await (const line of rl) {
      s.add(line);
    }
    return s;
  } finally {
    rl.close();
  }
};

type ReadState = {
  it: AsyncIterableIterator<string>;
  source: string;
  translated: string;
  done: boolean;
};

const read_header_line = async (state: ReadState) => {
  const elm = await state.it.next();
  if (elm.done) {
    return { ...state, done: true };
  } else {
    const line = elm.value;
    const preserved_comment = /^--\!/.test(line);
    const done = !preserved_comment && /^---@type\s+cytanb\s+/.test(line);

    const source = state.source + line + '\n';
    const translated =
      preserved_comment || done
        ? state.translated + line + '\n'
        : state.translated;
    return { ...state, source, translated, done };
  }
};

const read_headers = async (it: AsyncIterableIterator<string>) => {
  let state: ReadState = {
    it,
    source: '',
    translated: '',
    done: false,
  };

  while (!state.done) {
    state = await read_header_line(state);
  }

  return state;
};

const read_module_line = async (state: ReadState) => {
  const elm = await state.it.next();
  if (elm.done) {
    return { ...state, done: true };
  } else {
    const line = elm.value;
    const m = /^local\s+(cytanb\s*=[\s\S]*)$/.exec(line);
    const source = state.source + line + '\n';
    const translated = state.translated + (m ? m[1] : line) + '\n';
    return { ...state, source, translated, done: !!m };
  }
};

const read_body = async (it: AsyncIterableIterator<string>, source: string) => {
  let translated = source + '\n';
  while (true) {
    const elm = await it.next();
    if (elm.done) {
      break;
    }

    translated += elm.value + '\n';
  }

  return translated;
};

const read_full = async (function_set: Set<string>) => {
  const stream = fs.createReadStream('../src/cytanb.lua', 'utf-8');
  try {
    const rl = readline.createInterface({
      input: stream,
    });

    try {
      const it = rl[Symbol.asyncIterator]();
      const headerState = await read_headers(it);
      const moduleState = await read_module_line({
        it,
        source: '',
        translated: '',
        done: false,
      });

      return {
        header: headerState.translated,
        translated: await read_body(it, moduleState.translated),
      };
    } finally {
      rl.close();
    }
  } finally {
    stream.close();
  }
};

const prefix_module_identifier = (prefix: string, min_source: string) => {
  const target = 'return cytanb';
  const index = min_source.lastIndexOf(target);
  const translated =
    index >= 0
      ? min_source.substring(0, index) +
        'return ' +
        prefix +
        'cytanb' +
        min_source.substring(index + target.length)
      : min_source;

  return prefix + translated;
};

const format_body = (
  max_line_length: number,
  function_set: Set<string>,
  min_source: string
) => {
  let acc = '';
  let start_index = 0;
  let end_index = 0;

  const re = /(end,|end\)\(\),)([a-z,A-Z]\w*)=(?:function|\(function\(\))/g;
  for (const m of min_source.matchAll(re)) {
    if (function_set.has(m[2]) && m.index && m.input) {
      const next_index = m.index + m[1].length;
      if (next_index - start_index >= max_line_length) {
        acc = acc + min_source.substring(start_index, end_index) + '\n';
        start_index = end_index;
      }
      end_index = next_index;
    }
  }

  if (min_source.length - start_index >= max_line_length) {
    acc = acc + min_source.substring(start_index, end_index) + '\n';
    start_index = end_index;
  }

  if (start_index < min_source.length) {
    acc = acc + min_source.substring(start_index) + '\n';
  }

  return acc;
};

(async () => {
  const max_line_length = 9999;
  const temporary_name_prefix = '__temporary_min_name_prefix_';
  const function_set = await cytanb_function_set();
  const { header, translated } = await read_full(function_set);
  const min_source =
    'local ' +
    minify(
      prefix_module_identifier(temporary_name_prefix, translated)
    ).replaceAll(temporary_name_prefix, '');

  const formatted = format_body(max_line_length, function_set, min_source);

  await fs.promises.writeFile(
    '../src/cytanb_min.lua',
    header + formatted,
    'utf-8'
  );

  return 0;
})();

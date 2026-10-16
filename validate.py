"""Rebuild the checked CRM results from preserved CSVs using Python and SQLite."""

import csv
import json
import math
import pathlib
import sqlite3


ROOT = pathlib.Path(__file__).resolve().parent


def statements(path):
    """These project SQL files contain no semicolons inside quoted values."""
    return [part.strip() for part in path.read_text(encoding='utf-8-sig').split(';') if part.strip()]


def run():
    con = sqlite3.connect(':memory:')
    con.row_factory = sqlite3.Row
    table_counts = {}
    for name in ('accounts', 'products', 'sales_teams', 'sales_pipeline'):
        with (ROOT / f'{name}.csv').open(encoding='utf-8-sig', newline='') as source:
            reader = csv.DictReader(source)
            fields = reader.fieldnames
            rows = [[None if row[field] == '' else row[field] for field in fields] for row in reader]
        columns = ', '.join(f'"{field}" TEXT' for field in fields)
        con.execute(f'CREATE TABLE "{name}" ({columns})')
        placeholders = ', '.join('?' for _ in fields)
        con.executemany(f'INSERT INTO "{name}" VALUES ({placeholders})', rows)
        table_counts[name] = len(rows)

    source_checks = []
    for statement in statements(ROOT / 'source-data-validation.sql'):
        cursor = con.execute(statement)
        if cursor.description:
            source_checks.append([dict(row) for row in cursor])

    result = {'tables': table_counts, 'original_sql_checks_run': len(source_checks)}
    for statement in statements(ROOT / 'analysis.sql'):
        cursor = con.execute(statement)
        if cursor.description:
            # Each output SELECT has a single-line name immediately above it.
            label = statement.splitlines()[0].removeprefix('-- ').strip()
            result[label] = [dict(row) for row in cursor]
    con.close()
    return result


def compare(actual, expected, path='results'):
    if isinstance(expected, dict):
        if set(actual) != set(expected):
            raise ValueError(f'{path}: result fields differ from checked snapshot')
        for key, value in expected.items():
            compare(actual[key], value, f'{path}.{key}')
    elif isinstance(expected, list):
        if len(actual) != len(expected):
            raise ValueError(f'{path}: row count differs from checked snapshot')
        for i, value in enumerate(expected):
            compare(actual[i], value, f'{path}[{i}]')
    elif isinstance(expected, (int, float)):
        if not isinstance(actual, (int, float)) or not math.isclose(actual, expected, rel_tol=1e-10, abs_tol=1e-8):
            raise ValueError(f'{path}: expected {expected!r}, received {actual!r}')
    elif actual != expected:
        raise ValueError(f'{path}: expected {expected!r}, received {actual!r}')


if __name__ == '__main__':
    actual = run()
    expected = json.loads((ROOT / 'validation-summary.json').read_text(encoding='utf-8'))
    compare(actual, expected)
    out = ROOT / 'output'
    out.mkdir(exist_ok=True)
    (out / 'validation-summary.json').write_text(json.dumps(actual, indent=2) + '\n', encoding='utf-8')
    summary = actual['summary'][0]
    print(f"Validated {summary['total_opportunities']:,} opportunities and {actual['original_sql_checks_run']} original SQL checks.")
    print(f"Won revenue: ${summary['won_revenue']:,.0f}; closed-deal win rate: {summary['closed_win_rate_percent']:.2f}%.")
    print('Results match validation-summary.json. New output: output/validation-summary.json')

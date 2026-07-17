import sys
import json
import pandas as pd

path = sys.argv[1] if len(sys.argv) > 1 else 'afrimarket_dataset_senior.csv'

print(f"Loading: {path}")
try:
    df = pd.read_csv(path)
except Exception as e:
    print('ERROR reading csv:', e)
    sys.exit(1)

report = {}
report['path'] = path
report['shape'] = df.shape
report['columns'] = {col: str(dtype) for col, dtype in df.dtypes.items()}
report['missing_counts'] = df.isna().sum().to_dict()
report['missing_percent'] = (df.isna().mean()*100).round(2).to_dict()
report['duplicate_count'] = int(df.duplicated().sum())

numeric = df.select_dtypes(include=['number'])
report['numeric_describe'] = numeric.describe().to_dict()

# top values for object columns
report['top_values'] = {}
for col in df.select_dtypes(include=['object','category']).columns:
    report['top_values'][col] = df[col].value_counts(dropna=False).head(10).to_dict()

print('\n=== Quick Overview ===')
print('Shape:', df.shape)
print('\nColumns and dtypes:')
for c, t in df.dtypes.items():
    print(f" - {c}: {t}")

print('\nMissing values (percent > 0):')
for k, v in report['missing_percent'].items():
    if v > 0:
        print(f" - {k}: {v}%")

print('\nDuplicate rows:', report['duplicate_count'])

print('\nSample head:')
print(df.head().to_string(index=False))

out_path = 'resultats_analyses_audit.json'
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(report, f, indent=2, ensure_ascii=False)

print(f"\nSaved audit JSON to {out_path}")

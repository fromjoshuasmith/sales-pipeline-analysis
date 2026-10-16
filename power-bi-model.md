# Extracted Power BI model

This documentation was extracted read-only from the original PBIX. DAX and Power Query source were inspected without executing or refreshing the model.

## Power Query portability

`power-query.m` preserves the extracted query logic. The only source-code adjustment replaces each original local `File.Contents` path with `DataFolder` plus its original filename. Set `DataFolder` to your own dataset directory. The file groups the definitions as an M section for review; individual queries can be copied into the Power Query Advanced Editor.

The four CSVs are provided in this repository. The DAX source includes 21 original measures, two opportunity calculated columns, and the explicit Date Table. The weighted pipeline formula uses 20% for Prospecting and 50% for Engaging. Applied to the full snapshot, it produces $2,160,911.70, which rounds to the displayed $2.2 million. These stage probabilities are assumptions, not statistically calibrated conversion rates.

## Relationships

| From | To | Cardinality | Active | Cross filtering |
| --- | --- | --- | --- | --- |
| Sales Pipeline.product | Products.product | M:1 | Yes | Single |
| Sales Pipeline.sales_agent | Sales Teams.sales_agent | M:1 | Yes | Single |
| Sales Pipeline.account | Accounts.account | M:1 | Yes | Single |

## Tables and columns

### Accounts

85 embedded rows.

| Column | Extracted type |
| --- | --- |
| account | string |
| sector | string |
| year_established | Int64 |
| revenue | Float64 |
| employees | Int64 |
| office_location | string |
| subsidiary_of | string |

### DAX Measures

1 embedded row.

| Column | Extracted type |
| --- | --- |
| Measure Table | string |

### Date Table

438 embedded rows.

| Column | Extracted type |
| --- | --- |
| Date | datetime64[ns] |
| Year | Int64 |
| Month Number | Int64 |
| Month Name | string |
| Quarter | string |
| Year Quarter | string |
| Year Month | string |

### Products

7 embedded rows.

| Column | Extracted type |
| --- | --- |
| product | string |
| series | string |
| sales_price | Float64 |

### Sales Pipeline

8,800 embedded rows.

| Column | Extracted type |
| --- | --- |
| opportunity_id | string |
| sales_agent | string |
| product | string |
| account | string |
| deal_stage | string |
| engage_date | datetime64[ns] |
| close_date | datetime64[ns] |
| close_value | Float64 |
| Close Year Quarter | string |
| Close Year Quarter Sort | Int64 |

### Sales Teams

35 embedded rows.

| Column | Extracted type |
| --- | --- |
| sales_agent | string |
| manager | string |
| regional_office | string |


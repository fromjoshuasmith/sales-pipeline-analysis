// Actual extracted M expressions. Portability adjustment: local file paths
// were replaced with DataFolder plus the original filename. Set DataFolder
// to your own data directory before using these queries. Queries are not run here.

section Section1;

shared DataFolder = "C:\Path\To\Dataset";

shared #"Accounts" =
let
    Source = Csv.Document(File.Contents(DataFolder & "\accounts.csv"),[Delimiter=",", Columns=7, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"account", type text}, {"sector", type text}, {"year_established", Int64.Type}, {"revenue", type number}, {"employees", Int64.Type}, {"office_location", type text}, {"subsidiary_of", type text}}),
    #"Replaced Value" = Table.ReplaceValue(#"Changed Type","technolgy","technology",Replacer.ReplaceText,{"sector"}),
    #"Capitalized Each Word" = Table.TransformColumns(#"Replaced Value",{{"sector", Text.Proper, type text}})
in
    #"Capitalized Each Word";

shared #"Products" =
let
    Source = Csv.Document(File.Contents(DataFolder & "\products.csv"),[Delimiter=",", Columns=3, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"product", type text}, {"series", type text}, {"sales_price", type number}})
in
    #"Changed Type";

shared #"Sales Teams" =
let
    Source = Csv.Document(File.Contents(DataFolder & "\sales_teams.csv"),[Delimiter=",", Columns=3, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Column1", type text}, {"Column2", type text}, {"Column3", type text}}),
    #"Promoted Headers" = Table.PromoteHeaders(#"Changed Type", [PromoteAllScalars=true]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Promoted Headers",{{"sales_agent", type text}, {"manager", type text}, {"regional_office", type text}})
in
    #"Changed Type1";

shared #"Sales Pipeline" =
let
    Source = Csv.Document(File.Contents(DataFolder & "\sales_pipeline.csv"),[Delimiter=",", Columns=8, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    #"Promoted Headers" = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    #"Changed Type" = Table.TransformColumnTypes(#"Promoted Headers",{{"opportunity_id", type text}, {"sales_agent", type text}, {"product", type text}, {"account", type text}, {"deal_stage", type text}, {"engage_date", type date}, {"close_date", type date}, {"close_value", type number}}),
    #"Replaced Value" = Table.ReplaceValue(#"Changed Type","GTXPro","GTX Pro",Replacer.ReplaceText,{"product"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Replaced Value",{{"engage_date", type date}, {"close_date", type date}, {"close_value", type number}})
in
    #"Changed Type1";

shared #"DAX Measures" =
let
    Source = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i45W8k1NLC4tSi1Wio0FAA==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Measure Table" = _t]),
    #"Changed Type" = Table.TransformColumnTypes(Source,{{"Measure Table", type text}})
in
    #"Changed Type";


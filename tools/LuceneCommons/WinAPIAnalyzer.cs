using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Core;
using Lucene.Net.Analysis.Pattern;
using Lucene.Net.Util;
using System.IO;
using System.Text.RegularExpressions;

namespace LuceneCommons;

public partial class WinAPIAnalyzer : Analyzer
{
    [GeneratedRegex("(?:[A-Z0-9])+(?![a-z])|(?>[A-Z][a-z0-9]+)|[a-z0-9]+")]
    private static partial Regex WinAPIRegex();

    protected override TokenStreamComponents CreateComponents(string fieldName, TextReader reader)
    {
        PatternTokenizer pattern = new PatternTokenizer(reader, WinAPIRegex(), 0);
        LowerCaseFilter filter = new(LuceneVersion.LUCENE_48, pattern);
        return new TokenStreamComponents(pattern, filter);
    }
}
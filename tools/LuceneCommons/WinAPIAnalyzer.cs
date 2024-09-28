using Lucene.Net.Analysis;
using Lucene.Net.Analysis.Core;
using Lucene.Net.Analysis.TokenAttributes;
using Lucene.Net.Util;
using System.Text;
using System.Text.RegularExpressions;

namespace LuceneCommons;

public partial class WinAPIAnalyzer : Analyzer
{
    protected override TokenStreamComponents CreateComponents(string fieldName, TextReader reader)
    {
        WinAPITokenizer tokenizer = new(reader);
        LowerCaseFilter filter = new(LuceneVersion.LUCENE_48, tokenizer);
        return new TokenStreamComponents(tokenizer, filter);
    }
}

sealed partial class WinAPITokenizerRegex
{
    [GeneratedRegex("(?:[A-Z0-9])+(?![a-z])|(?>[A-Z][a-z0-9]+)|[a-z0-9]+")]
    public static partial Regex WinAPIRegex();
}

sealed partial class WinAPITokenizer : Tokenizer
{
    private readonly ICharTermAttribute termAtt;
    private readonly IOffsetAttribute offsetAtt;
    private static readonly Regex pattern = WinAPITokenizerRegex.WinAPIRegex();
    private readonly StringBuilder str = new StringBuilder();
    private int index;
    private MatchCollection? matches;


    public WinAPITokenizer(TextReader input)
            : this(AttributeFactory.DEFAULT_ATTRIBUTE_FACTORY, input)
    {
    }

    public WinAPITokenizer(AttributeFactory factory, TextReader input)
        : base(factory, input)
    {
        this.termAtt = AddAttribute<ICharTermAttribute>();
        this.offsetAtt = AddAttribute<IOffsetAttribute>();
    }

    public override void End()
    {
        base.End();
        int ofs = CorrectOffset(str.Length);
        offsetAtt.SetOffset(ofs, ofs);
    }

    public override bool IncrementToken()
    {
        if (matches is null)
            return false;

        if (index >= matches.Count)
            return false;

        ClearAttributes();

        Match match = matches[index];
        int start = match.Index;
        int end = start + match.Length;

        if (start == end)
        {
            index++;
            return IncrementToken();
        }

        termAtt.SetEmpty().Append(match.Value, 0, match.Length);
        offsetAtt.SetOffset(CorrectOffset(start), CorrectOffset(end));
        index++;
        return true;
    }

    public override void Reset()
    {
        base.Reset();
        FillBuffer(str, m_input);

        // LUCENENET: Since we need to "reset" the Match
        // object, we also need an "isReset" flag to indicate
        // whether we are at the head of the match and to 
        // take the appropriate measures to ensure we don't 
        // overwrite our matcher variable with 
        // matcher = matcher.NextMatch();
        // before it is time. A string could potentially
        // match on index 0, so we need another variable to
        // manage this state.
        matches = pattern.Matches(str.ToString());
        index = 0;
    }

    // TODO: we should see if we can make this tokenizer work without reading
    // the entire document into RAM, perhaps with Matcher.hitEnd/requireEnd ?
    private readonly char[] buffer = new char[8192];

    private void FillBuffer(StringBuilder sb, TextReader input)
    {
        int len;
        sb.Length = 0;
        while ((len = input.Read(buffer, 0, buffer.Length)) > 0)
        {
            sb.Append(buffer, 0, len);
        }
    }
}
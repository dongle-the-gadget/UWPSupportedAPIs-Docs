using Lucene.Net.Analysis.Standard;
using Lucene.Net.Index;
using Lucene.Net.QueryParsers.Classic;
using Lucene.Net.Search;
using Lucene.Net.Search.Grouping;
using Lucene.Net.Store;
using Lucene.Net.Util;
using UWPSupportedAPIsWeb.Models;

namespace UWPSupportedAPIsWeb.Services;

public class SearchService : IDisposable
{
    private FSDirectory fsdir;
    private DirectoryReader reader;
    private IndexSearcher searcher;
    private StandardAnalyzer analyzer;
    private static readonly Sort docSort = new Sort(new SortField("build", SortFieldType.STRING));

    private const LuceneVersion version = LuceneVersion.LUCENE_48;

    public SearchService()
    {
        fsdir = FSDirectory.Open("LuceneIndex");
        reader = DirectoryReader.Open(fsdir);
        searcher = new IndexSearcher(reader);
        analyzer = new StandardAnalyzer(version);
    }

    public SearchViewModel ReturnMethods(string query, int offset = 0)
    {
        GroupingSearch groupingSearch = new("name");
        groupingSearch.SetAllGroups(true);
        groupingSearch.SetGroupDocsLimit(1);
        groupingSearch.SetSortWithinGroup(docSort);

        QueryParser parser = new(version, "name", analyzer);
        parser.AllowLeadingWildcard = true;
        parser.LowercaseExpandedTerms = true;
        Query q = parser.Parse(query);

        ITopGroups<object> returnedMethods = groupingSearch.Search(searcher, q, offset, 10);
        Method[] methods = new Method[returnedMethods.Groups.Length];
        for (int i = 0; i < returnedMethods.Groups.Length; i++)
        {
            var methodDocGroup = returnedMethods.Groups[i];
            var doc = searcher.Doc(methodDocGroup.ScoreDocs[0].Doc);
            methods[i] = new Method
            {
                Name = doc.GetField("name").GetStringValue(),
                MinVersion = doc.GetField("build").GetStringValue()
            };
        }

        return new SearchViewModel
        {
            Query = query,
            Methods = methods,
            Max = returnedMethods.TotalGroupCount.GetValueOrDefault(),
            Skipped = offset
        };
    }

    public void Dispose()
    {
        reader.Dispose();
        fsdir.Dispose();
    }
}